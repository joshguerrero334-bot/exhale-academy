"use server";

import { redirect } from "next/navigation";
import { isStrongPassword } from "../../lib/auth/password-policy";
import { createClient } from "../../lib/supabase/server";

function cleanName(value: FormDataEntryValue | null) {
  return String(value ?? "").trim();
}

function extensionFromMime(mimeType: string) {
  switch (mimeType) {
    case "image/jpeg":
      return "jpg";
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    default:
      return null;
  }
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

export async function updateProfilePhoto(formData: FormData) {
  const file = formData.get("avatar");
  if (!(file instanceof File) || file.size <= 0) {
    redirect("/account?error=Please%20choose%20an%20image%20to%20upload.");
  }

  const allowedTypes = new Set(["image/jpeg", "image/png", "image/webp"]);
  if (!allowedTypes.has(file.type)) {
    redirect("/account?error=Only%20JPG,%20PNG,%20or%20WEBP%20images%20are%20allowed.");
  }

  const maxBytes = 5 * 1024 * 1024;
  if (file.size > maxBytes) {
    redirect("/account?error=Image%20must%20be%205MB%20or%20smaller.");
  }

  const ext = extensionFromMime(file.type);
  if (!ext) {
    redirect("/account?error=Unsupported%20image%20type.");
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Faccount");
  }

  const filePath = `${user.id}/avatar-${Date.now()}.${ext}`;
  const { error: uploadError } = await supabase.storage.from("avatars").upload(filePath, file, {
    upsert: true,
    contentType: file.type,
  });

  if (uploadError) {
    redirect(`/account?error=${encodeURIComponent(`Image upload failed: ${uploadError.message}`)}`);
  }

  const { data: publicUrlData } = supabase.storage.from("avatars").getPublicUrl(filePath);
  const avatarUrl = publicUrlData.publicUrl;
  if (!avatarUrl) {
    redirect("/account?error=Could%20not%20build%20image%20URL.");
  }

  const { error: authUpdateError } = await supabase.auth.updateUser({
    data: { avatar_url: avatarUrl },
  });
  if (authUpdateError) {
    redirect(`/account?error=${encodeURIComponent(authUpdateError.message)}`);
  }

  const { error: profileUpdateError } = await supabase
    .from("profiles")
    .upsert(
      {
        user_id: user.id,
        avatar_url: avatarUrl,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" }
    );

  if (profileUpdateError) {
    redirect(`/account?error=${encodeURIComponent(profileUpdateError.message)}`);
  }

  redirect("/account?message=Profile%20photo%20updated.");
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
