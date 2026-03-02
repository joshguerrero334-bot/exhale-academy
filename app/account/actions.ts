"use server";

import { redirect } from "next/navigation";
import { isStrongPassword } from "../../lib/auth/password-policy";
import { createClient } from "../../lib/supabase/server";

function cleanName(value: FormDataEntryValue | null) {
  return String(value ?? "").trim();
}

export async function updateProfile(formData: FormData) {
  const firstName = cleanName(formData.get("first_name"));
  const lastName = cleanName(formData.get("last_name"));

  if (!firstName || !lastName) {
    redirect("/account?error=First%20name%20and%20last%20name%20are%20required.");
  }
  if (firstName.length > 80 || lastName.length > 80) {
    redirect("/account?error=First%20name%20or%20last%20name%20is%20too%20long.");
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Faccount");
  }

  const { error } = await supabase
    .from("profiles")
    .upsert(
      {
        user_id: user.id,
        first_name: firstName,
        last_name: lastName,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" }
    );

  if (error) {
    redirect(`/account?error=${encodeURIComponent(error.message)}`);
  }

  redirect("/account?message=Profile%20updated.");
}

export async function updatePassword(formData: FormData) {
  const password = String(formData.get("new_password") ?? "");
  const confirmPassword = String(formData.get("confirm_password") ?? "");

  if (!password || !confirmPassword) {
    redirect("/account?error=Both%20password%20fields%20are%20required.");
  }

  if (password !== confirmPassword) {
    redirect("/account?error=Passwords%20do%20not%20match.");
  }

  if (!isStrongPassword(password)) {
    redirect(
      "/account?error=Password%20must%20be%20at%20least%208%20characters%20and%20include%201%20uppercase%20letter,%201%20number,%20and%201%20special%20character."
    );
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Faccount");
  }

  const { error } = await supabase.auth.updateUser({ password });
  if (error) {
    redirect(`/account?error=${encodeURIComponent(error.message)}`);
  }

  redirect("/account?message=Password%20updated.");
}
