import { NextResponse } from "next/server";
import { getSiteUrl } from "../../../lib/site";
import { createClient } from "../../../lib/supabase/server";

function sanitizeNext(raw: string | null) {
  if (!raw || !raw.startsWith("/")) return "/billing";
  if (raw.startsWith("//")) return "/billing";
  return raw;
}

function getBaseUrl(request: Request) {
  const explicit = String(process.env.NEXT_PUBLIC_SITE_URL ?? "").trim();
  if (explicit) return explicit.replace(/\/+$/, "");
  const vercelUrl = String(process.env.VERCEL_URL ?? "").trim();
  if (vercelUrl) {
    const withProtocol = /^https?:\/\//.test(vercelUrl) ? vercelUrl : `https://${vercelUrl}`;
    return withProtocol.replace(/\/+$/, "");
  }
  const requestUrl = new URL(request.url);
  const origin = `${requestUrl.protocol}//${requestUrl.host}`;
  if (process.env.NODE_ENV === "production" && origin.includes("localhost")) {
    return getSiteUrl();
  }
  return origin;
}

function withQuery(path: string, key: string, value: string) {
  const separator = path.includes("?") ? "&" : "?";
  return `${path}${separator}${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
}

export async function GET(request: Request) {
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get("code");
  const next = sanitizeNext(requestUrl.searchParams.get("next"));
  const baseUrl = getBaseUrl(request);

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (error) {
      return NextResponse.redirect(
        `${baseUrl}/login?error=${encodeURIComponent("Email verification failed. Please request a new link.")}`
      );
    }
    return NextResponse.redirect(
      `${baseUrl}/auth/confirmed?next=${encodeURIComponent(
        withQuery(next, "message", "Email verified successfully.")
      )}`
    );
  }

  return NextResponse.redirect(
    `${baseUrl}/login?error=${encodeURIComponent("Invalid verification link. Please request a new email.")}`
  );
}
