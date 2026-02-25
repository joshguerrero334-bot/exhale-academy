import { createHmac, timingSafeEqual } from "node:crypto";

type StripeSignatureParts = {
  timestamp: string | null;
  signatures: string[];
};

function parseStripeSignature(header: string | null): StripeSignatureParts {
  if (!header) return { timestamp: null, signatures: [] };
  const parts = header
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  let timestamp: string | null = null;
  const signatures: string[] = [];

  for (const part of parts) {
    const [k, ...rest] = part.split("=");
    const value = rest.join("=");
    if (!k || !value) continue;
    if (k === "t") timestamp = value;
    if (k === "v1") signatures.push(value);
  }

  return { timestamp, signatures };
}

function safeCompareHex(expectedHex: string, candidateHex: string) {
  try {
    const expected = Buffer.from(expectedHex, "hex");
    const candidate = Buffer.from(candidateHex, "hex");
    if (expected.length !== candidate.length) return false;
    return timingSafeEqual(expected, candidate);
  } catch {
    return false;
  }
}

export function verifyStripeWebhookSignature(args: {
  rawBody: string;
  stripeSignatureHeader: string | null;
  webhookSecret: string;
  toleranceSec?: number;
}) {
  const toleranceSec = args.toleranceSec ?? 300;
  const parsed = parseStripeSignature(args.stripeSignatureHeader);
  if (!parsed.timestamp || parsed.signatures.length === 0) {
    return { ok: false as const, reason: "Missing or invalid stripe-signature header." };
  }

  const ts = Number.parseInt(parsed.timestamp, 10);
  if (Number.isNaN(ts)) {
    return { ok: false as const, reason: "Invalid Stripe timestamp." };
  }

  const nowSec = Math.floor(Date.now() / 1000);
  if (Math.abs(nowSec - ts) > toleranceSec) {
    return { ok: false as const, reason: "Stripe signature timestamp outside tolerance window." };
  }

  const signedPayload = `${parsed.timestamp}.${args.rawBody}`;
  const expected = createHmac("sha256", args.webhookSecret).update(signedPayload, "utf8").digest("hex");
  const match = parsed.signatures.some((sig) => safeCompareHex(expected, sig));
  if (!match) {
    return { ok: false as const, reason: "Stripe signature mismatch." };
  }

  return { ok: true as const };
}
