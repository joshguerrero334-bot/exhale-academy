"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../../../lib/supabase/server";
import {
  evaluateOutcomesForStep,
  fetchStepOptions,
  fetchStepOutcomes,
  parseVitalsState,
} from "../../../../lib/supabase/cse";

function toSelectedKeys(value: FormDataEntryValue[]) {
  return value.map((entry) => String(entry).trim().toUpperCase()).filter(Boolean);
}

type RevealRule = {
  text?: string;
  keys_any?: string[];
};

function buildStableTerminalVitals(args: {
  categoryCode?: string | null;
  current: Record<string, number>;
}) {
  const category = String(args.categoryCode ?? "").toUpperCase();

  const adult = {
    hr: 88,
    rr: 16,
    spo2: 96,
    bp_sys: 120,
    bp_dia: 78,
    etco2: 38,
    temp_c: 37.0,
  };
  const pediatric = {
    hr: 110,
    rr: 24,
    spo2: 96,
    bp_sys: 100,
    bp_dia: 65,
    etco2: 36,
    temp_c: 37.0,
  };
  const neonatal = {
    hr: 140,
    rr: 42,
    spo2: 95,
    bp_sys: 72,
    bp_dia: 45,
    etco2: 35,
    temp_c: 36.8,
  };

  const target = category === "F" ? pediatric : category === "G" ? neonatal : adult;
  const next = { ...args.current };

  for (const [key, value] of Object.entries(target)) {
    if (typeof next[key] === "number") {
      next[key] = value;
    }
  }
  return next;
}

type StepRevealMetadata = {
  show_appearance_after_submit?: boolean;
  appearance_text?: string;
  appearance_keys_any?: string[];
  show_vitals_after_submit?: boolean;
  vitals_keys_any?: string[];
  vitals_fields?: string[];
  extra_reveals?: RevealRule[];
};

function formatVitalsLine(
  vitals: Record<string, number>,
  fields?: string[]
) {
  const preferred = fields && fields.length > 0 ? fields : ["hr", "rr", "spo2", "bp"];
  const parts: string[] = [];

  for (const rawField of preferred) {
    const field = String(rawField).toLowerCase();
    if (field === "bp") {
      const bp =
        typeof vitals.bp_sys === "number" && typeof vitals.bp_dia === "number"
          ? `${vitals.bp_sys}/${vitals.bp_dia} mmHg`
          : "--";
      parts.push(`BP ${bp}`);
      continue;
    }
    if (field === "hr") {
      const hr = typeof vitals.hr === "number" ? `${vitals.hr} bpm` : "--";
      parts.push(`HR ${hr}`);
      continue;
    }
    if (field === "rr") {
      const rr = typeof vitals.rr === "number" ? `${vitals.rr} /min` : "--";
      parts.push(`RR ${rr}`);
      continue;
    }
    if (field === "spo2") {
      const spo2 = typeof vitals.spo2 === "number" ? `${vitals.spo2}%` : "--";
      parts.push(`SpO2 ${spo2}`);
      continue;
    }
    if (field === "temp_c") {
      const temp = typeof vitals.temp_c === "number" ? `${vitals.temp_c.toFixed(1)} C` : "--";
      parts.push(`Temp ${temp}`);
      continue;
    }
    if (field === "etco2") {
      const etco2 = typeof vitals.etco2 === "number" ? `${vitals.etco2} mmHg` : "--";
      parts.push(`EtCO2 ${etco2}`);
    }
  }

  return `Vitals: ${parts.join(", ")}.`;
}

function parseStepRevealMetadata(raw: unknown): StepRevealMetadata {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return {};
  return raw as StepRevealMetadata;
}

function includesAnySelected(selected: Set<string>, keys?: string[]) {
  if (!keys || keys.length === 0) return true;
  return keys.some((key) => selected.has(String(key).toUpperCase()));
}

function buildDynamicFindings(args: {
  stepOrder: number;
  metadata: StepRevealMetadata;
  selectedKeys: string[];
  vitalsAfter: Record<string, number>;
}) {
  const selected = new Set(args.selectedKeys.map((k) => k.toUpperCase()));
  const lines: string[] = [];
  const md = args.metadata;

  if (md.show_appearance_after_submit && md.appearance_text && includesAnySelected(selected, md.appearance_keys_any)) {
    lines.push(`Appearance: ${md.appearance_text}`);
  }

  if (md.show_vitals_after_submit && includesAnySelected(selected, md.vitals_keys_any)) {
    lines.push(formatVitalsLine(args.vitalsAfter, md.vitals_fields));
  }

  for (const rule of md.extra_reveals ?? []) {
    if (!rule?.text) continue;
    if (includesAnySelected(selected, rule.keys_any)) {
      lines.push(rule.text);
    } else {
      continue;
    }
  }

  // Backward-compatible fallback for older cases without metadata.
  if (lines.length === 0 && args.stepOrder > 1) {
    lines.push("Appearance: clinical status has shifted after intervention; continue focused reassessment.");
    lines.push(formatVitalsLine(args.vitalsAfter));
  }

  if (lines.length === 0) return null;
  return `\n\nUpdated Findings:\n${lines.join("\n")}`;
}

export async function submitCseBranchStep(formData: FormData) {
  const attemptId = String(formData.get("attempt_id") ?? "").trim();
  const selectedKeys = toSelectedKeys(formData.getAll("selected_keys"));

  if (!attemptId) {
    redirect("/cse/cases?error=Invalid%20attempt");
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fcases");
  }

  const { data: attempt, error: attemptError } = await supabase
    .from("cse_attempts")
    .select("id, user_id, case_id, mode, current_step_id, status, total_score, vitals")
    .eq("id", attemptId)
    .single();

  if (attemptError || !attempt || attempt.user_id !== user.id) {
    redirect("/cse/cases?error=Attempt%20not%20found");
  }

  if (attempt.status === "completed" || !attempt.current_step_id) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}/complete`);
  }

  const { data: step, error: stepError } = await supabase
    .from("cse_steps")
    .select("id, case_id, step_order, step_type, max_select, metadata")
    .eq("id", attempt.current_step_id)
    .eq("case_id", attempt.case_id)
    .single();

  if (stepError || !step) {
    redirect(`/cse/cases?error=${encodeURIComponent(stepError?.message ?? "Step unavailable")}`);
  }

  const { data: caseRow } = await supabase
    .from("cse_cases")
    .select("nbrc_category_code")
    .eq("id", attempt.case_id)
    .single();

  const optionsResult = await fetchStepOptions(supabase, step.id);
  if (optionsResult.error) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(optionsResult.error)}`);
  }

  const optionsByKey = new Map(optionsResult.rows.map((option) => [option.option_key.toUpperCase(), option]));
  const selectedOptions = selectedKeys.map((key) => optionsByKey.get(key)).filter(Boolean);

  if (selectedOptions.length !== selectedKeys.length) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}?error=Invalid%20option%20selected`);
  }

  if (step.step_type === "DM" && selectedOptions.length !== 1) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}?error=DM%20requires%20exactly%20one%20selection`);
  }

  if (step.step_type === "DM") {
    const selected = selectedOptions[0];
    const selectedScore = Number(selected?.score ?? 0);
    const maxScore = Math.max(...optionsResult.rows.map((option) => Number(option.score ?? 0)));
    const selectedKey = encodeURIComponent(String(selected?.option_key ?? "").toUpperCase());

    // DM retry path: if best available option is not selected, keep learner on same step.
    if (selectedScore < maxScore) {
      redirect(
        `/cse/attempt/${encodeURIComponent(attemptId)}?dm_feedback=disagree&selected=${selectedKey}`
      );
    }
  }

  const maxSelect = Number(step.max_select ?? (step.step_type === "IG" ? 3 : 1));
  if (step.step_type === "IG" && (selectedOptions.length < 1 || selectedOptions.length > maxSelect)) {
    redirect(
      `/cse/attempt/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(
        "Select only the options that are clinically indicated."
      )}`
    );
  }

  const stepScore = selectedOptions.reduce((sum, option) => sum + Number(option?.score ?? 0), 0);

  const outcomesResult = await fetchStepOutcomes(supabase, step.id);
  if (outcomesResult.error || outcomesResult.rows.length === 0) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}?error=No%20outcomes%20configured%20for%20step`);
  }

  const evaluated = evaluateOutcomesForStep({
    outcomes: outcomesResult.rows,
    selectedKeys,
    stepScore,
  });

  const vitalsBefore = parseVitalsState(attempt.vitals);
  const vitalsAfterBase = evaluated.vitalsOverride ? { ...vitalsBefore, ...evaluated.vitalsOverride } : vitalsBefore;
  const isCompleted = !evaluated.nextStepId;
  const vitalsAfter =
    isCompleted && Number(evaluated.outcome.rule_priority ?? 99) === 1
      ? buildStableTerminalVitals({
          categoryCode: caseRow?.nbrc_category_code,
          current: vitalsAfterBase,
        })
      : vitalsAfterBase;
  const revealMetadata = parseStepRevealMetadata(step.metadata);
  const findingsSuffix = buildDynamicFindings({
    stepOrder: Number(step.step_order ?? 0),
    metadata: revealMetadata,
    selectedKeys,
    vitalsAfter,
  });
  const outcomeText = `${evaluated.outcomeText}${findingsSuffix ?? ""}`;
  const totalScore = Number(attempt.total_score ?? 0) + stepScore;

  const { data: eventRow, error: eventError } = await supabase
    .from("cse_attempt_events")
    .insert({
      attempt_id: attemptId,
      step_id: step.id,
      selected_keys: selectedKeys,
      step_score: stepScore,
      outcome_text: outcomeText,
      vitals_after: vitalsAfter,
      outcome_id: evaluated.outcome.id,
    })
    .select("id")
    .single();

  if (eventError || !eventRow) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(eventError?.message ?? "Failed to save event")}`);
  }

  const { error: updateError } = await supabase
    .from("cse_attempts")
    .update({
      total_score: totalScore,
      vitals: vitalsAfter,
      current_step_id: evaluated.nextStepId,
      status: isCompleted ? "completed" : "in_progress",
      completed_at: isCompleted ? new Date().toISOString() : null,
    })
    .eq("id", attemptId)
    .eq("user_id", user.id);

  if (updateError) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(updateError.message)}`);
  }

  redirect(`/cse/attempt/${encodeURIComponent(attemptId)}?event=${encodeURIComponent(eventRow.id)}`);
}
