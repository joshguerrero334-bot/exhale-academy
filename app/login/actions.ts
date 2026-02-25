"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { assertRateLimit } from "../../lib/security/rate-limit";

function sanitizeNext(raw: string) {
  if (!raw.startsWith("/")) return "/dashboard";
  if (raw.startsWith("//")) return "/dashboard";
  return raw;
}

export async function login(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const nextRaw = String(formData.get("next") ?? "").trim();
  const nextPath = nextRaw ? sanitizeNext(nextRaw) : "/dashboard";

  const limit = await assertRateLimit({
    bucket: "login",
    identifier: email || "anonymous",
    max: 8,
    windowMs: 10 * 60 * 1000,
  });
  if (!limit.ok) {
    redirect(`/login?error=${encodeURIComponent(`Too many login attempts. Try again in about ${limit.retryAfterSec} seconds.`)}${nextRaw ? `&next=${encodeURIComponent(nextPath)}` : ""}`);
  }

  if (!email || !password) {
    redirect(`/login?error=Email%20and%20password%20are%20required${nextRaw ? `&next=${encodeURIComponent(nextPath)}` : ""}`);
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    redirect(`/login?error=${encodeURIComponent(error.message)}${nextRaw ? `&next=${encodeURIComponent(nextPath)}` : ""}`);
  }

  redirect(nextPath);
}
