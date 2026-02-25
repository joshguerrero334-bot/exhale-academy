"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { assertRateLimit } from "../../lib/security/rate-limit";

function normalizeText(value: FormDataEntryValue | null) {
  return String(value ?? "").trim();
}

export async function submitFeedback(formData: FormData) {
  const whatLooksGreat = normalizeText(formData.get("what_looks_great"));
  const whereImprove = normalizeText(formData.get("where_improve"));
  const additionalNotes = normalizeText(formData.get("additional_notes"));
  const area = normalizeText(formData.get("product_area"));
  const ratingRaw = normalizeText(formData.get("rating"));

  const limit = await assertRateLimit({
    bucket: "feedback-submit",
    identifier: area || "general",
    max: 6,
    windowMs: 30 * 60 * 1000,
  });
  if (!limit.ok) {
    redirect(`/feedback?error=${encodeURIComponent(`Too many submissions. Try again in about ${limit.retryAfterSec} seconds.`)}`);
  }

  if (whatLooksGreat.length < 10 || whereImprove.length < 10) {
    redirect("/feedback?error=Please%20share%20a%20bit%20more%20detail%20before%20submitting.");
  }

  const rating = Number.parseInt(ratingRaw, 10);
  const safeRating = Number.isNaN(rating) ? null : Math.max(1, Math.min(5, rating));

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Ffeedback");
  }

  const { error } = await supabase.from("user_feedback").insert({
    user_id: user.id,
    email: user.email ?? null,
    product_area: area || null,
    rating: safeRating,
    what_looks_great: whatLooksGreat,
    where_improve: whereImprove,
    additional_notes: additionalNotes || null,
  });

  if (error) {
    redirect(`/feedback?error=${encodeURIComponent(`Could not submit feedback: ${error.message}`)}`);
  }

  redirect("/feedback?success=Thanks%20for%20helping%20us%20improve%20Exhale%20Academy.");
}
