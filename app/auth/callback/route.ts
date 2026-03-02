import { NextResponse } from "next/server";
import { createClient } from "../../../lib/supabase/server";

function sanitizeNext(raw: string | null) {
  if (!raw || !raw.startsWith("/")) return "/billing";
  if (raw.startsWith("//")) return "/billing";
  return raw;
}

export async function GET(request: Request) {
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get("code");
  const next = sanitizeNext(requestUrl.searchParams.get("next"));
  const baseUrl = `${requestUrl.protocol}//${requestUrl.host}`;

  if (code) {
    const supabase = await createClient();
    await supabase.auth.exchangeCodeForSession(code);
  }

  return NextResponse.redirect(`${baseUrl}${next}`);
}
