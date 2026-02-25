"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { assertRateLimit } from "../../lib/security/rate-limit";

export async function signup(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  const limit = await assertRateLimit({
    bucket: "signup",
    identifier: email || "anonymous",
    max: 5,
    windowMs: 60 * 60 * 1000,
  });
  if (!limit.ok) {
    redirect(`/signup?error=${encodeURIComponent(`Too many signup attempts. Try again in about ${limit.retryAfterSec} seconds.`)}`);
  }

  if (!email || !password) {
    redirect("/signup?error=Email%20and%20password%20are%20required");
  }

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({ email, password });

  if (error) {
    redirect(`/signup?error=${encodeURIComponent(error.message)}`);
  }

  if (data.session) {
    redirect("/dashboard");
  }

  redirect("/login?message=Account%20created.%20Check%20your%20email%20to%20confirm.");
}
