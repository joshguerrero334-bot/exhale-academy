import Stripe from "stripe";
import { getSiteUrl } from "./site";

const CHECKED_CONTEXTS = new Set<string>();

function logMissingEnv(context: string, keys: string[]) {
  const missing = keys.filter((key) => !process.env[key] || !String(process.env[key]).trim());
  if (missing.length > 0) {
    console.error(`[stripe][${context}] Missing required env vars: ${missing.join(", ")}`);
  }
  return missing;
}

export function requireServerEnv(context: string, keys: string[]) {
  const cacheKey = `${context}:${keys.join(",")}`;
  if (!CHECKED_CONTEXTS.has(cacheKey)) {
    CHECKED_CONTEXTS.add(cacheKey);
    logMissingEnv(context, keys);
  }

  const missing = keys.filter((key) => !process.env[key] || !String(process.env[key]).trim());
  if (missing.length > 0) {
    throw new Error(`[stripe][${context}] Missing required env vars: ${missing.join(", ")}`);
  }

  return Object.fromEntries(
    keys.map((key) => [key, String(process.env[key] ?? "").trim()])
  ) as Record<string, string>;
}

export function getStripeClient(context: string) {
  const env = requireServerEnv(context, ["STRIPE_SECRET_KEY"]);
  return new Stripe(env.STRIPE_SECRET_KEY);
}

export function getBaseUrl(request?: Request) {
  const explicit = String(process.env.NEXT_PUBLIC_SITE_URL ?? "").trim();
  if (explicit) return explicit.replace(/\/+$/, "");

  const vercelUrl = String(process.env.VERCEL_URL ?? "").trim();
  if (vercelUrl) {
    const withProtocol = /^https?:\/\//.test(vercelUrl) ? vercelUrl : `https://${vercelUrl}`;
    return withProtocol.replace(/\/+$/, "");
  }

  if (!request) return getSiteUrl();

  const requestUrl = new URL(request.url);
  return requestUrl.origin.replace(/\/+$/, "");
}
