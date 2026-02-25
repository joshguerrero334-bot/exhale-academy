"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { generateMasterTestQuestions } from "../../lib/supabase/master-test";
import { toQuizMode } from "../../lib/supabase/quiz";
import { assertRateLimit } from "../../lib/security/rate-limit";

export async function startMasterAttempt(formData: FormData) {
  const mode = toQuizMode(String(formData.get("mode") ?? "tutor"));
  const limit = await assertRateLimit({
    bucket: "start-master-tmc",
    identifier: mode,
    max: 20,
    windowMs: 10 * 60 * 1000,
  });
  if (!limit.ok) {
    redirect(`/master?error=${encodeURIComponent(`Too many new attempts. Try again in about ${limit.retryAfterSec} seconds.`)}`);
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const generated = await generateMasterTestQuestions(supabase, 160);
  if (generated.error || generated.rows.length === 0) {
    redirect(
      `/master?error=${encodeURIComponent(
        generated.error ?? "No questions available for master test generation."
      )}`
    );
  }

  const { data: attemptRow, error: attemptError } = await supabase
    .from("master_test_attempts")
    .insert({
      user_id: user.id,
      mode,
      total: generated.rows.length,
      score: 0,
    })
    .select("id")
    .single();

  if (attemptError || !attemptRow) {
    redirect(
      `/master?error=${encodeURIComponent(
        `Could not create attempt. ${attemptError?.message ?? "Unknown error"}`
      )}`
    );
  }

  const itemRows = generated.rows.map((question, index) => ({
    attempt_id: attemptRow.id,
    question_id: question.id,
    order_index: index,
  }));

  const { error: itemsError } = await supabase
    .from("master_test_attempt_questions")
    .insert(itemRows);

  if (itemsError) {
    redirect(
      `/master?error=${encodeURIComponent(
        `Could not create attempt questions. ${itemsError.message}`
      )}`
    );
  }

  redirect(`/master/${encodeURIComponent(attemptRow.id)}`);
}
