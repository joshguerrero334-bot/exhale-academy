import type { createClient as createServerClient } from "./server";

type SupabaseServerClient = Awaited<ReturnType<typeof createServerClient>>;

export type CseCaseRow = {
  id: string;
  slug: string | null;
  intro_text: string | null;
  source: string | null;
  nbrc_category_code: string | null;
  nbrc_category_name: string | null;
  nbrc_subcategory: string | null;
  disease_slug: string | null;
  disease_track: string | null;
  title: string;
  description: string | null;
  stem: string | null;
  difficulty: string | null;
  is_active: boolean | null;
  is_published: boolean | null;
  baseline_vitals: Record<string, unknown> | null;
  created_at: string | null;
};

export type CseStepRow = {
  id: string;
  case_id: string;
  step_order: number;
  step_type: "IG" | "DM";
  prompt: string;
  max_select: number | null;
  stop_label: string | null;
  created_at: string | null;
};

export type CseOptionRow = {
  id: string;
  step_id: string;
  option_key: string;
  option_text: string;
  score: number;
  rationale: string;
  created_at: string | null;
};

export type CseRuleRow = {
  id: string;
  step_id: string;
  rule_priority: number;
  rule_type: "INCLUDES_ANY" | "INCLUDES_ALL" | "SCORE_AT_LEAST" | "SCORE_AT_MOST" | "DEFAULT";
  rule_value: unknown;
  next_step_id: string | null;
  outcome_text: string;
  vitals_delta: Record<string, unknown> | null;
  created_at: string | null;
};

export type CseOutcomeRow = {
  id: string;
  step_id: string;
  label: string | null;
  rule_priority: number;
  rule_type: "INCLUDES_ANY" | "INCLUDES_ALL" | "SCORE_AT_LEAST" | "SCORE_AT_MOST" | "DEFAULT";
  rule_value: unknown;
  next_step_id: string | null;
  outcome_text: string;
  vitals_override: Record<string, unknown> | null;
  created_at: string | null;
};

export type VitalsState = Record<string, number>;

export type EvaluatedRule = {
  rule: CseRuleRow;
  nextStepId: string | null;
  outcomeText: string;
  vitalsDelta: VitalsState;
};

export type EvaluatedOutcome = {
  outcome: CseOutcomeRow;
  nextStepId: string | null;
  outcomeText: string;
  vitalsOverride: VitalsState | null;
};

function toNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

export function parseVitalsState(value: unknown): VitalsState {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};

  const state: VitalsState = {};
  for (const [key, raw] of Object.entries(value)) {
    const num = toNumber(raw, Number.NaN);
    if (!Number.isNaN(num)) state[key] = num;
  }
  return state;
}

export function parseVitalsDelta(value: unknown): VitalsState {
  return parseVitalsState(value);
}

export function parseVitalsOverride(value: unknown): VitalsState {
  return parseVitalsState(value);
}

export function applyVitalsDelta(current: VitalsState, delta: VitalsState): VitalsState {
  const merged: VitalsState = { ...current };
  for (const [key, rawDelta] of Object.entries(delta)) {
    const base = toNumber(merged[key], 0);
    merged[key] = base + toNumber(rawDelta, 0);
  }
  return merged;
}

function normalizeKeys(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((entry) => String(entry).trim().toUpperCase()).filter(Boolean);
}

function parseRuleKeys(ruleValue: unknown): string[] {
  if (!ruleValue) return [];

  if (Array.isArray(ruleValue)) return normalizeKeys(ruleValue);

  if (typeof ruleValue === "object") {
    const fromKeys = normalizeKeys((ruleValue as { keys?: unknown }).keys);
    if (fromKeys.length > 0) return fromKeys;
    return [];
  }

  if (typeof ruleValue === "string") {
    try {
      const parsed = JSON.parse(ruleValue);
      if (Array.isArray(parsed)) return normalizeKeys(parsed);
      if (parsed && typeof parsed === "object") {
        return normalizeKeys((parsed as { keys?: unknown }).keys);
      }
      return [];
    } catch {
      return [];
    }
  }

  return [];
}

function parseRuleNumber(ruleValue: unknown): number | null {
  if (typeof ruleValue === "number" && Number.isFinite(ruleValue)) return ruleValue;

  if (typeof ruleValue === "string") {
    const numeric = Number(ruleValue);
    if (Number.isFinite(numeric)) return numeric;
    try {
      const parsed = JSON.parse(ruleValue);
      if (typeof parsed === "number" && Number.isFinite(parsed)) return parsed;
      if (parsed && typeof parsed === "object") {
        const fromScore = Number((parsed as { score?: unknown }).score);
        if (Number.isFinite(fromScore)) return fromScore;
      }
    } catch {
      return null;
    }
    return null;
  }

  if (ruleValue && typeof ruleValue === "object") {
    const fromScore = Number((ruleValue as { score?: unknown }).score);
    if (Number.isFinite(fromScore)) return fromScore;
  }

  return null;
}

function matchesRule(rule: CseRuleRow, selectedKeys: string[], stepScore: number): boolean {
  const selectedSet = new Set(selectedKeys.map((key) => key.toUpperCase()));

  switch (rule.rule_type) {
    case "INCLUDES_ANY": {
      const keys = parseRuleKeys(rule.rule_value);
      if (keys.length === 0) return false;
      return keys.some((key) => selectedSet.has(key));
    }
    case "INCLUDES_ALL": {
      const keys = parseRuleKeys(rule.rule_value);
      if (keys.length === 0) return false;
      return keys.every((key) => selectedSet.has(key));
    }
    case "SCORE_AT_LEAST": {
      const threshold = parseRuleNumber(rule.rule_value);
      return threshold !== null && stepScore >= threshold;
    }
    case "SCORE_AT_MOST": {
      const threshold = parseRuleNumber(rule.rule_value);
      return threshold !== null && stepScore <= threshold;
    }
    case "DEFAULT":
      return true;
    default:
      return false;
  }
}

export function evaluateRulesForStep(args: {
  rules: CseRuleRow[];
  selectedKeys: string[];
  stepScore: number;
}): EvaluatedRule {
  const sorted = [...args.rules].sort((a, b) => a.rule_priority - b.rule_priority);
  const matched = sorted.find((rule) => matchesRule(rule, args.selectedKeys, args.stepScore));

  if (!matched) {
    throw new Error("No matching rule found for this step. Ensure a DEFAULT rule exists.");
  }

  return {
    rule: matched,
    nextStepId: matched.next_step_id,
    outcomeText: matched.outcome_text,
    vitalsDelta: parseVitalsDelta(matched.vitals_delta),
  };
}

function matchesOutcome(outcome: CseOutcomeRow, selectedKeys: string[], stepScore: number): boolean {
  const selectedSet = new Set(selectedKeys.map((key) => key.toUpperCase()));

  switch (outcome.rule_type) {
    case "INCLUDES_ANY": {
      const keys = parseRuleKeys(outcome.rule_value);
      if (keys.length === 0) return false;
      return keys.some((key) => selectedSet.has(key));
    }
    case "INCLUDES_ALL": {
      const keys = parseRuleKeys(outcome.rule_value);
      if (keys.length === 0) return false;
      return keys.every((key) => selectedSet.has(key));
    }
    case "SCORE_AT_LEAST": {
      const threshold = parseRuleNumber(outcome.rule_value);
      return threshold !== null && stepScore >= threshold;
    }
    case "SCORE_AT_MOST": {
      const threshold = parseRuleNumber(outcome.rule_value);
      return threshold !== null && stepScore <= threshold;
    }
    case "DEFAULT":
      return true;
    default:
      return false;
  }
}

export function evaluateOutcomesForStep(args: {
  outcomes: CseOutcomeRow[];
  selectedKeys: string[];
  stepScore: number;
}): EvaluatedOutcome {
  const sorted = [...args.outcomes].sort((a, b) => a.rule_priority - b.rule_priority);
  const matched = sorted.find((outcome) => matchesOutcome(outcome, args.selectedKeys, args.stepScore));

  if (!matched) {
    throw new Error("No matching outcome found for this step. Ensure a DEFAULT outcome exists.");
  }

  const parsedOverride = parseVitalsOverride(matched.vitals_override);

  return {
    outcome: matched,
    nextStepId: matched.next_step_id,
    outcomeText: matched.outcome_text,
    vitalsOverride: Object.keys(parsedOverride).length > 0 ? parsedOverride : null,
  };
}

export async function fetchActiveCseCases(client: SupabaseServerClient) {
  const { data, error } = await client
    .from("cse_cases")
    .select(
      "id, slug, intro_text, source, nbrc_category_code, nbrc_category_name, nbrc_subcategory, disease_slug, disease_track, title, description, stem, difficulty, is_active, is_published, baseline_vitals, created_at"
    )
    .eq("is_active", true)
    .eq("is_published", true)
    .order("title", { ascending: true });

  const rows = (data ?? []) as CseCaseRow[];

  return {
    rows,
    error: error?.message ?? null,
  };
}

export async function fetchCaseSteps(client: SupabaseServerClient, caseId: string) {
  const { data, error } = await client
    .from("cse_steps")
    .select("id, case_id, step_order, step_type, prompt, max_select, stop_label, created_at")
    .eq("case_id", caseId)
    .order("step_order", { ascending: true });

  return {
    rows: (data ?? []) as CseStepRow[],
    error: error?.message ?? null,
  };
}

export async function fetchStepOptions(client: SupabaseServerClient, stepId: string) {
  const { data, error } = await client
    .from("cse_options")
    .select("id, step_id, option_key, option_text, score, rationale, created_at")
    .eq("step_id", stepId)
    .order("option_key", { ascending: true });

  return {
    rows: (data ?? []) as CseOptionRow[],
    error: error?.message ?? null,
  };
}

export async function fetchStepRules(client: SupabaseServerClient, stepId: string) {
  const { data, error } = await client
    .from("cse_rules")
    .select("id, step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta, created_at")
    .eq("step_id", stepId)
    .order("rule_priority", { ascending: true });

  return {
    rows: (data ?? []) as CseRuleRow[],
    error: error?.message ?? null,
  };
}

export async function fetchStepOutcomes(client: SupabaseServerClient, stepId: string) {
  const { data, error } = await client
    .from("cse_outcomes")
    .select("id, step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override, created_at")
    .eq("step_id", stepId)
    .order("rule_priority", { ascending: true });

  return {
    rows: (data ?? []) as CseOutcomeRow[],
    error: error?.message ?? null,
  };
}
