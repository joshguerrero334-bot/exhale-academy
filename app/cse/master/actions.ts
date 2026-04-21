"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import {
  generateCseMasterCaseBlueprint,
  generateFocusedCseCaseSet,
} from "../../../lib/supabase/cse-master";
import type { CseMasterBlueprintPick } from "../../../lib/supabase/cse-master";
import { toQuizMode } from "../../../lib/supabase/quiz";
import { assertRateLimit } from "../../../lib/security/rate-limit";

async function createMasterAttempt(args: {
  rows: CseMasterBlueprintPick[];
  mode: "tutor" | "exam";
  userId: string;
  errorPrefix: string;
}) {
  const { rows, mode, userId, errorPrefix } = args;
  const supabase = await createClient();

  const { data: attemptRow, error: attemptError } = await supabase
    .from("cse_master_attempts")
    .insert({
      user_id: userId,
      mode,
      status: "in_progress",
      total_cases: rows.length,
      completed_cases: 0,
      total_score: 0,
    })
    .select("id")
    .single();

  if (attemptError || !attemptRow) {
    redirect(
      `/cse/master?error=${encodeURIComponent(
        `${errorPrefix} ${attemptError?.message ?? "Unknown error"}`
      )}`
    );
  }

  const itemRows = rows.map((row, index) => ({
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
        `Could not create CSE case set. ${itemsError.message}`
      )}`
    );
  }

  return attemptRow.id as string;
}

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

  const attemptId = await createMasterAttempt({
    rows: generated.rows,
    mode,
    userId: user.id,
    errorPrefix: "Could not create CSE master attempt.",
  });

  const warning = generated.error ? `&warning=${encodeURIComponent(generated.error)}` : "";
  redirect(`/cse/master/${encodeURIComponent(attemptId)}?new=1${warning}`);
}

export async function startFocusedCseAttempt(formData: FormData) {
  const mode = toQuizMode(String(formData.get("mode") ?? "tutor"));
  const focusSlug = String(formData.get("focus_slug") ?? "").trim();
  const limit = await assertRateLimit({
    bucket: "start-focused-cse",
    identifier: `${focusSlug}:${mode}`,
    max: 30,
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

  const generated = await generateFocusedCseCaseSet(supabase, focusSlug);
  if (generated.rows.length < 2) {
    redirect(
      `/cse/master?error=${encodeURIComponent(
        generated.error ?? "Could not build focused CSE practice from the current case pool."
      )}`
    );
  }

  const attemptId = await createMasterAttempt({
    rows: generated.rows,
    mode,
    userId: user.id,
    errorPrefix: "Could not create focused CSE practice attempt.",
  });

  const warning = generated.error ? `&warning=${encodeURIComponent(generated.error)}` : "";
  redirect(`/cse/master/${encodeURIComponent(attemptId)}?new=1${warning}`);
}
