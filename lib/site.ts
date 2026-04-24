const DEFAULT_PRODUCTION_SITE_URL = "https://exhaleacademy.net";

export function getSiteUrl() {
  const explicit = String(process.env.NEXT_PUBLIC_SITE_URL ?? "").trim();
  if (explicit) {
    return explicit.replace(/\/+$/, "");
  }

  const vercelUrl = String(process.env.VERCEL_URL ?? "").trim();
  if (vercelUrl) {
    const withProtocol = /^https?:\/\//.test(vercelUrl) ? vercelUrl : `https://${vercelUrl}`;
    return withProtocol.replace(/\/+$/, "");
  }

  if (process.env.NODE_ENV === "production") {
    return DEFAULT_PRODUCTION_SITE_URL;
  }

  return "http://localhost:3000";
}

export function toAbsoluteUrl(pathname: string) {
  const base = getSiteUrl();
  const path = pathname.startsWith("/") ? pathname : `/${pathname}`;
  return `${base}${path}`;
}
