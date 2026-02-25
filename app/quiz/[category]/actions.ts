"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import { loadQuestionsBySlug, shuffleArray, toQuizMode } from "../../../lib/supabase/quiz";
import { assertRateLimit } from "../../../lib/security/rate-limit";

export async function startCategoryAttempt(formData: FormData) {
  const slug = String(formData.get("category_slug") ?? "").trim().toLowerCase();
  const mode = toQuizMode(String(formData.get("mode") ?? "tutor"));

  if (!slug) {
    redirect("/dashboard?error=Missing%20category%20slug");
  }

  const limit = await assertRateLimit({
    bucket: "start-category-attempt",
    identifier: `${slug}:${mode}`,
    max: 25,
    windowMs: 10 * 60 * 1000,
  });
  if (!limit.ok) {
    redirect(`/quiz/${encodeURIComponent(slug)}?error=${encodeURIComponent(`Too many new attempts. Try again in about ${limit.retryAfterSec} seconds.`)}`);
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const match = await loadQuestionsBySlug(supabase, slug);
  if (match.error) {
    redirect(`/quiz/${encodeURIComponent(slug)}?error=${encodeURIComponent(match.error)}`);
  }

  if (match.rows.length === 0) {
    redirect(
      `/quiz/${encodeURIComponent(slug)}?error=${encodeURIComponent(
        "No questions found. category_slug may not be filled yet."
      )}`
    );
  }

  const picked = shuffleArray(match.rows).slice(0, Math.min(20, match.rows.length));

  const { data: attemptRow, error: attemptError } = await supabase
    .from("category_quiz_attempts")
    .insert({
      user_id: user.id,
      category_slug: slug,
      mode,
      total: picked.length,
      score: 0,
    })
    .select("id")
    .single();

  if (attemptError || !attemptRow) {
    redirect(
      `/quiz/${encodeURIComponent(slug)}?error=${encodeURIComponent(
        `Could not create category attempt. ${attemptError?.message ?? "Unknown error"}`
      )}`
    );
  }

  const attemptQuestions = picked.map((row, index) => ({
    attempt_id: attemptRow.id,
    question_id: row.id,
    order_index: index,
  }));

  const { error: itemsError } = await supabase
    .from("category_quiz_attempt_questions")
    .insert(attemptQuestions);

  if (itemsError) {
    redirect(
      `/quiz/${encodeURIComponent(slug)}?error=${encodeURIComponent(
        `Could not initialize questions. ${itemsError.message}`
      )}`
    );
  }

  redirect(`/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptRow.id)}`);
}
