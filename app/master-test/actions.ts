"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { generateMasterTestQuestions } from "../../lib/supabase/master-test";

export async function startNewMasterTest() {
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
      `/master-test?error=${encodeURIComponent(
        generated.error ?? "No questions available for master test generation."
      )}`
    );
  }

  const { data: attemptRow, error: attemptError } = await supabase
    .from("master_test_attempts")
    .insert({
      user_id: user.id,
      total_questions: generated.rows.length,
      status: "in_progress",
      correct_count: 0,
    })
    .select("id")
    .single();

  if (attemptError || !attemptRow) {
    redirect(
      `/master-test?error=${encodeURIComponent(
        `Failed to create attempt. ${attemptError?.message ?? "Unknown error"}`
      )}`
    );
  }

  const itemRows = generated.rows.map((question, idx) => ({
    attempt_id: attemptRow.id,
    question_id: question.id,
    order_index: idx,
  }));

  const { error: itemError } = await supabase.from("master_test_items").insert(itemRows);
  if (itemError) {
    redirect(
      `/master-test?error=${encodeURIComponent(
        `Failed to create attempt items. ${itemError.message}`
      )}`
    );
  }

  redirect(`/master-test/${encodeURIComponent(attemptRow.id)}`);
}
