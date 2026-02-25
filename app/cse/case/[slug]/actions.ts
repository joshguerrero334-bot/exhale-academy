"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../../../lib/supabase/server";
import { fetchCaseSteps, parseVitalsState } from "../../../../lib/supabase/cse";
import { assertRateLimit } from "../../../../lib/security/rate-limit";

function toMode(value: string): "tutor" | "exam" {
  return value === "exam" ? "exam" : "tutor";
}

function randomInt(min: number, max: number) {
  const lo = Math.ceil(min);
  const hi = Math.floor(max);
  return Math.floor(Math.random() * (hi - lo + 1)) + lo;
}

function randomFloat(min: number, max: number, precision = 1) {
  const n = Math.random() * (max - min) + min;
  const p = 10 ** precision;
  return Math.round(n * p) / p;
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

function varyBaselineVitals(vitals: Record<string, number>) {
  const next = { ...vitals };
  if (typeof next.hr === "number") next.hr = clamp(next.hr + randomInt(-4, 4), 50, 170);
  if (typeof next.rr === "number") next.rr = clamp(next.rr + randomInt(-2, 2), 8, 45);
  if (typeof next.spo2 === "number") next.spo2 = clamp(next.spo2 + randomInt(-2, 1), 70, 100);
  if (typeof next.bp_sys === "number") next.bp_sys = clamp(next.bp_sys + randomInt(-6, 6), 80, 210);
  if (typeof next.bp_dia === "number") next.bp_dia = clamp(next.bp_dia + randomInt(-4, 4), 40, 130);
  if (typeof next.temp_c === "number") next.temp_c = clamp(randomFloat(next.temp_c - 0.2, next.temp_c + 0.2), 35, 41.5);
  if (typeof next.etco2 === "number") next.etco2 = clamp(next.etco2 + randomInt(-3, 3), 20, 80);
  return next;
}

export async function createCseAttempt(formData: FormData) {
  const caseId = String(formData.get("case_id") ?? "").trim();
  const slug = String(formData.get("slug") ?? "").trim();
  const mode = toMode(String(formData.get("mode") ?? "tutor").trim().toLowerCase());
  const previewMode = String(formData.get("preview") ?? "").trim() === "1";

  if (!caseId) {
    redirect("/cse/cases?error=Missing%20case%20id");
  }

  const limit = await assertRateLimit({
    bucket: "start-cse-case-attempt",
    identifier: `${slug || caseId}:${mode}`,
    max: 25,
    windowMs: 10 * 60 * 1000,
  });
  if (!limit.ok) {
    redirect(`/cse/case/${encodeURIComponent(slug || caseId)}?error=${encodeURIComponent(`Too many new attempts. Try again in about ${limit.retryAfterSec} seconds.`)}`);
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fcases");
  }

  const { data: caseRow, error: caseError } = await supabase
    .from("cse_cases")
    .select("id, baseline_vitals, is_published")
    .eq("id", caseId)
    .eq("is_active", true)
    .maybeSingle();

  if (caseError || !caseRow || (!caseRow.is_published && !previewMode)) {
    redirect("/cse/cases?error=Case%20not%20found%20or%20inactive");
  }

  const stepResult = await fetchCaseSteps(supabase, caseId);
  if (stepResult.error || stepResult.rows.length === 0) {
    redirect(
      `/cse/case/${encodeURIComponent(slug || caseId)}?error=${encodeURIComponent(
        stepResult.error ?? "No steps found for this case"
      )}`
    );
  }

  const { data: attempt, error: attemptError } = await supabase
    .from("cse_attempts")
    .insert({
      user_id: user.id,
      case_id: caseId,
      mode,
      status: "in_progress",
      current_step_id: stepResult.rows[0].id,
      total_score: 0,
      vitals: varyBaselineVitals(parseVitalsState(caseRow.baseline_vitals)),
    })
    .select("id")
    .single();

  if (attemptError || !attempt) {
    redirect(
      `/cse/case/${encodeURIComponent(slug || caseId)}?error=${encodeURIComponent(
        `Could not create attempt. ${attemptError?.message ?? "Unknown error"}`
      )}`
    );
  }

  redirect(`/cse/attempt/${encodeURIComponent(attempt.id)}`);
}
