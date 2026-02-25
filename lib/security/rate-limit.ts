import { headers } from "next/headers";

type RateLimitOptions = {
  bucket: string;
  identifier?: string | null;
  max: number;
  windowMs: number;
};

type RateLimitResult = {
  ok: boolean;
  retryAfterSec: number;
};

type Entry = {
  count: number;
  resetAt: number;
};

// Process-local limiter to reduce abuse on auth + write endpoints.
// For multi-instance/global enforcement, replace with Redis/Upstash later.
const store = globalThis as typeof globalThis & {
  __exhaleRateLimitStore?: Map<string, Entry>;
};

function getStore() {
  if (!store.__exhaleRateLimitStore) {
    store.__exhaleRateLimitStore = new Map<string, Entry>();
  }
  return store.__exhaleRateLimitStore;
}

function getUpstashConfig() {
  const url = process.env.UPSTASH_REDIS_REST_URL?.trim();
  const token = process.env.UPSTASH_REDIS_REST_TOKEN?.trim();
  if (!url || !token) return null;
  return { url, token };
}

function normalize(value: string | null | undefined, fallback: string) {
  const next = String(value ?? "").trim().toLowerCase();
  return next || fallback;
}

async function getRequestFingerprint() {
  const h = await headers();
  const forwardedFor = h.get("x-forwarded-for");
  const firstIp = forwardedFor?.split(",")[0]?.trim();
  const realIp = h.get("x-real-ip");
  const userAgent = h.get("user-agent");

  return {
    ip: normalize(firstIp || realIp, "unknown-ip"),
    ua: normalize(userAgent, "unknown-ua").slice(0, 120),
  };
}

async function checkUpstashLimit(key: string, max: number, windowMs: number): Promise<RateLimitResult | null> {
  const config = getUpstashConfig();
  if (!config) return null;

  try {
    const res = await fetch(`${config.url}/pipeline`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config.token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify([
        ["INCR", key],
        ["PEXPIRE", key, String(windowMs), "NX"],
        ["PTTL", key],
      ]),
      cache: "no-store",
    });

    if (!res.ok) return null;
    const data = (await res.json()) as Array<{ result?: number | string | null }>;
    const countRaw = data?.[0]?.result;
    const ttlRaw = data?.[2]?.result;

    const count = typeof countRaw === "number" ? countRaw : Number.parseInt(String(countRaw ?? "0"), 10);
    const ttlMs = typeof ttlRaw === "number" ? ttlRaw : Number.parseInt(String(ttlRaw ?? "0"), 10);

    if (Number.isNaN(count)) return null;
    if (count > max) {
      const retryAfterSec = Math.max(1, Math.ceil(Math.max(0, ttlMs) / 1000));
      return { ok: false, retryAfterSec };
    }
    return { ok: true, retryAfterSec: 0 };
  } catch {
    return null;
  }
}

function checkLocalLimit(key: string, max: number, windowMs: number): RateLimitResult {
  const now = Date.now();
  const state = getStore();
  const existing = state.get(key);

  if (!existing || existing.resetAt <= now) {
    state.set(key, { count: 1, resetAt: now + windowMs });
    return { ok: true, retryAfterSec: 0 };
  }

  if (existing.count >= max) {
    const retryAfterSec = Math.max(1, Math.ceil((existing.resetAt - now) / 1000));
    return { ok: false, retryAfterSec };
  }

  existing.count += 1;
  state.set(key, existing);
  return { ok: true, retryAfterSec: 0 };
}

export async function assertRateLimit(options: RateLimitOptions): Promise<RateLimitResult> {
  const fingerprint = await getRequestFingerprint();
  const id = normalize(options.identifier, "anonymous");
  const key = `ratelimit:${options.bucket}:${id}:${fingerprint.ip}:${fingerprint.ua}`;
  const distributed = await checkUpstashLimit(key, options.max, options.windowMs);
  if (distributed) return distributed;
  return checkLocalLimit(key, options.max, options.windowMs);
}
