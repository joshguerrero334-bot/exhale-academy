"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { assertRateLimit } from "../../lib/security/rate-limit";

export async function signup(formData: FormData) {
  const firstName = String(formData.get("first_name") ?? "").trim();
  const lastName = String(formData.get("last_name") ?? "").trim();
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

  if (!firstName || !lastName || !email || !password) {
    redirect("/signup?error=First%20name,%20last%20name,%20email,%20and%20password%20are%20required");
  }

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({ email, password });

  if (error) {
    redirect(`/signup?error=${encodeURIComponent(error.message)}`);
  }

  if (data.user) {
    await supabase.from("profiles").upsert(
      {
        user_id: data.user.id,
        first_name: firstName,
        last_name: lastName,
        is_subscribed: false,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" }
    );
  }

  if (data.session) {
    redirect("/billing");
  }

  redirect("/login?message=Account%20created.%20Check%20your%20email%20to%20confirm%20then%20subscribe.&next=%2Fbilling");
}
