"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import { generateCseMasterCaseBlueprint } from "../../../lib/supabase/cse-master";
import { toQuizMode } from "../../../lib/supabase/quiz";
import { assertRateLimit } from "../../../lib/security/rate-limit";

export async function startCseMasterAttempt(formData: FormData) {
  const mode = toQuizMode(String(formData.get("mode") ?? "tutor"));
  const limit = await assertRateLimit({
    bucket: "start-master-cse",
    identifier: mode,
    max: 20,
    windowMs: 10 * 60 * 1000,
  });
  if (!limit.ok) {
    redirect(`/cse/master?error=${encodeURIComponent(`Too many new attempts. Try again in about ${limit.retryAfterSec} seconds.`)}`);
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fmaster");
  }

  const generated = await generateCseMasterCaseBlueprint(supabase, 20);
  if (generated.rows.length < 20) {
    redirect(
      `/cse/master?error=${encodeURIComponent(
        generated.error ?? "Could not build a full 20-case master exam from current published case pool."
      )}`
    );
  }

  const { data: attemptRow, error: attemptError } = await supabase
    .from("cse_master_attempts")
    .insert({
      user_id: user.id,
      mode,
      status: "in_progress",
      total_cases: generated.rows.length,
      completed_cases: 0,
      total_score: 0,
    })
    .select("id")
    .single();

  if (attemptError || !attemptRow) {
    redirect(
      `/cse/master?error=${encodeURIComponent(
        `Could not create CSE master attempt. ${attemptError?.message ?? "Unknown error"}`
      )}`
    );
  }

  const itemRows = generated.rows.map((row, index) => ({
    attempt_id: attemptRow.id,
    case_id: row.case_id,
    order_index: index,
    blueprint_category_code: row.blueprint_category_code,
    blueprint_subcategory: row.blueprint_subcategory,
    status: "pending",
  }));

  const { error: itemsError } = await supabase
    .from("cse_master_attempt_cases")
    .insert(itemRows);

  if (itemsError) {
    redirect(
      `/cse/master?error=${encodeURIComponent(
        `Could not create CSE master case set. ${itemsError.message}`
      )}`
    );
  }

  const warning = generated.error ? `&warning=${encodeURIComponent(generated.error)}` : "";
  redirect(`/cse/master/${encodeURIComponent(attemptRow.id)}?new=1${warning}`);
}
