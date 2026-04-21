import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { headingFont } from "../../../../lib/fonts";
import { createClient } from "../../../../lib/supabase/server";
import {
  evaluateOutcomesForStep,
  fetchStepOptions,
  fetchStepOutcomes,
  parseVitalsState,
} from "../../../../lib/supabase/cse";
import { previewCseCases } from "../../../../lib/preview/free-preview-content";

export const metadata: Metadata = {
  title: "Free CSE Scenario Preview | Exhale Academy",
  description: "Preview a fixed Exhale Academy CSE clinical simulation case before subscribing.",
};

type PageProps = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ step?: string; selected?: string | string[]; v?: string; error?: string }>;
};

type CaseRow = {
  id: string;
  slug: string;
  title: string;
  stem: string | null;
  intro_text: string | null;
  baseline_vitals: Record<string, unknown> | null;
};

type StepRow = {
  id: string;
  step_order: number;
  step_type: "IG" | "DM";
  prompt: string;
  max_select: number | null;
  metadata: unknown;
};

type RevealRule = {
  text?: string;
  keys_any?: string[];
};

type StepRevealMetadata = {
  show_appearance_after_submit?: boolean;
  appearance_text?: string;
  appearance_keys_any?: string[];
  show_vitals_after_submit?: boolean;
  vitals_keys_any?: string[];
  vitals_fields?: string[];
  extra_reveals?: RevealRule[];
};

function parseSelected(raw: string | string[] | undefined) {
  const joined = Array.isArray(raw) ? raw.join(",") : String(raw ?? "");
  return joined
    .split(",")
    .map((value) => value.trim().toUpperCase())
    .filter(Boolean);
}

function parseVitalsFromQuery(raw: string | undefined, fallback: Record<string, number>) {
  if (!raw) return fallback;
  try {
    const parsed = JSON.parse(decodeURIComponent(raw));
    return parseVitalsState(parsed);
  } catch {
    return fallback;
  }
}

function serializeVitals(vitals: Record<string, number>) {
  return encodeURIComponent(JSON.stringify(vitals));
}

function parseMetadata(raw: unknown): StepRevealMetadata {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return {};
  return raw as StepRevealMetadata;
}

function includesAnySelected(selected: Set<string>, keys?: string[]) {
  if (!keys || keys.length === 0) return true;
  return keys.some((key) => selected.has(String(key).toUpperCase()));
}

function formatVitalsLine(vitals: Record<string, number>, fields?: string[]) {
  const preferred = fields && fields.length > 0 ? fields : ["hr", "rr", "spo2", "bp"];
  const parts: string[] = [];

  for (const rawField of preferred) {
    const field = String(rawField).toLowerCase();
    if (field === "bp") {
      const bp = typeof vitals.bp_sys === "number" && typeof vitals.bp_dia === "number" ? `${vitals.bp_sys}/${vitals.bp_dia} mmHg` : "--";
      parts.push(`BP ${bp}`);
    }
    if (field === "hr" && typeof vitals.hr === "number") parts.push(`HR ${vitals.hr} bpm`);
    if (field === "rr" && typeof vitals.rr === "number") parts.push(`RR ${vitals.rr} /min`);
    if (field === "spo2" && typeof vitals.spo2 === "number") parts.push(`SpO2 ${vitals.spo2}%`);
    if (field === "temp_c" && typeof vitals.temp_c === "number") parts.push(`Temp ${vitals.temp_c.toFixed(1)} C`);
    if (field === "etco2" && typeof vitals.etco2 === "number") parts.push(`EtCO2 ${vitals.etco2} mmHg`);
  }

  return parts.length > 0 ? `Vitals: ${parts.join(", ")}.` : null;
}

function buildDynamicFindings(args: {
  stepOrder: number;
  metadata: StepRevealMetadata;
  selectedKeys: string[];
  vitalsAfter: Record<string, number>;
}) {
  const selected = new Set(args.selectedKeys.map((key) => key.toUpperCase()));
  const lines: string[] = [];
  const md = args.metadata;

  if (md.show_appearance_after_submit && md.appearance_text && includesAnySelected(selected, md.appearance_keys_any)) {
    lines.push(`Appearance: ${md.appearance_text}`);
  }

  if (md.show_vitals_after_submit && includesAnySelected(selected, md.vitals_keys_any)) {
    const vitalsLine = formatVitalsLine(args.vitalsAfter, md.vitals_fields);
    if (vitalsLine) lines.push(vitalsLine);
  }

  for (const rule of md.extra_reveals ?? []) {
    if (rule?.text && includesAnySelected(selected, rule.keys_any)) {
      lines.push(rule.text);
    }
  }

  if (lines.length === 0 && args.stepOrder > 1) {
    const vitalsLine = formatVitalsLine(args.vitalsAfter);
    if (vitalsLine) lines.push(vitalsLine);
  }

  return lines;
}

export default async function FreeCseScenarioPlayerPage({ params, searchParams }: PageProps) {
  const [{ slug }, query] = await Promise.all([params, searchParams]);
  const allowed = previewCseCases.some((previewCase) => previewCase.slug === slug);
  if (!allowed) notFound();

  const supabase = await createClient();
  const { data: caseData, error: caseError } = await supabase
    .from("cse_cases")
    .select("id, slug, title, stem, intro_text, baseline_vitals")
    .eq("slug", slug)
    .eq("is_active", true)
    .eq("is_published", true)
    .maybeSingle();

  if (caseError || !caseData) {
    redirect("/preview/cse-scenarios?error=Case%20preview%20is%20not%20available%20yet");
  }

  const previewCase = caseData as CaseRow;
  const { data: stepsRaw, error: stepsError } = await supabase
    .from("cse_steps")
    .select("id, step_order, step_type, prompt, max_select, metadata")
    .eq("case_id", previewCase.id)
    .order("step_order", { ascending: true });

  const steps = (stepsRaw ?? []) as StepRow[];
  if (stepsError || steps.length === 0) {
    redirect("/preview/cse-scenarios?error=Case%20steps%20are%20not%20available");
  }

  const requestedStepId = String(query.step ?? "").trim();
  const currentStep = steps.find((step) => step.id === requestedStepId) ?? steps[0];
  const selectedKeys = parseSelected(query.selected);
  const submitted = selectedKeys.length > 0;
  const baselineVitals = parseVitalsState(previewCase.baseline_vitals);
  const currentVitals = parseVitalsFromQuery(query.v, baselineVitals);
  const optionsResult = await fetchStepOptions(supabase, currentStep.id);
  const outcomesResult = await fetchStepOutcomes(supabase, currentStep.id);
  const options = optionsResult.rows;
  const maxSelect = Number(currentStep.max_select ?? (currentStep.step_type === "IG" ? 3 : 1));
  const selectedOptions = options.filter((option) => selectedKeys.includes(option.option_key.toUpperCase()));
  const selectionIsValid = submitted && selectedOptions.length === selectedKeys.length && selectedOptions.length <= maxSelect;
  const stepScore = selectedOptions.reduce((sum, option) => sum + Number(option.score ?? 0), 0);
  const evaluated = selectionIsValid && outcomesResult.rows.length > 0
    ? evaluateOutcomesForStep({ outcomes: outcomesResult.rows, selectedKeys, stepScore })
    : null;
  const vitalsAfter = evaluated?.vitalsOverride ?? currentVitals;
  const currentVitalsState = serializeVitals(currentVitals);
  const nextVitalsState = serializeVitals(vitalsAfter);
  const dynamicFindings = evaluated
    ? buildDynamicFindings({
        stepOrder: currentStep.step_order,
        metadata: parseMetadata(currentStep.metadata),
        selectedKeys,
        vitalsAfter,
      })
    : [];
  const selectedSet = new Set(selectedKeys);
  const nextStep = evaluated?.nextStepId ? steps.find((step) => step.id === evaluated.nextStepId) ?? null : null;
  const completed = Boolean(evaluated && !evaluated.nextStepId);

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Free CSE Clinical Simulation Preview</p>
          <div className="mt-2 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <h1 className={`${headingFont} text-3xl font-semibold text-charcoal sm:text-4xl`}>{previewCase.title}</h1>
              <p className="mt-2 text-sm text-graysoft">Step {currentStep.step_order} · {currentStep.step_type === "IG" ? "Information Gathering" : "Decision Making"}</p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link href="/preview/cse-scenarios" className="btn-secondary">Back to Free Cases</Link>
              <Link href="/signup" className="btn-primary">Unlock Full Master CSE</Link>
            </div>
          </div>
          {currentStep.step_order === 1 ? (
            <p className="mt-4 whitespace-pre-line text-sm leading-relaxed text-graysoft sm:text-base">
              {previewCase.stem ?? previewCase.intro_text}
            </p>
          ) : null}
        </section>

        {query.error ? (
          <section className="rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">{query.error}</section>
        ) : null}

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">
            {currentStep.step_type === "IG" ? `Select as many as indicated. Max ${maxSelect}.` : "Select the best recommendation."}
          </p>
          <h2 className={`${headingFont} mt-2 text-xl font-semibold leading-relaxed text-charcoal sm:text-2xl`}>
            {currentStep.prompt}
          </h2>

          <form method="get" className="mt-5 space-y-3">
            <input type="hidden" name="step" value={currentStep.id} />
            <input type="hidden" name="v" value={currentVitalsState} />
            {options.map((option) => {
              const key = option.option_key.toUpperCase();
              const isSelected = selectedSet.has(key);
              const score = Number(option.score ?? 0);
              return (
                <label
                  key={option.id}
                  className={`block cursor-pointer rounded-xl border p-4 text-sm transition ${
                    submitted && isSelected
                      ? score > 0
                        ? "border-emerald-400 bg-emerald-50"
                        : score < 0
                          ? "border-red-400 bg-red-50"
                          : "border-graysoft/40 bg-background"
                      : "border-graysoft/30 bg-white hover:border-primary"
                  }`}
                >
                  <input
                    className="mr-3"
                    type={currentStep.step_type === "DM" ? "radio" : "checkbox"}
                    name="selected"
                    value={key}
                    defaultChecked={isSelected}
                  />
                  <span className="font-semibold">{key}.</span> {option.option_text}
                </label>
              );
            })}
            <button type="submit" className="btn-primary">Submit Choice</button>
          </form>
        </section>

        {submitted ? (
          <section className="rounded-2xl border border-primary/25 bg-white p-6 shadow-sm sm:p-8">
            {!selectionIsValid ? (
              <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-900">
                Select only clinically indicated options. This step allows up to {maxSelect} choice{maxSelect === 1 ? "" : "s"}.
              </div>
            ) : evaluated ? (
              <>
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Patient Response</p>
                <p className="mt-3 whitespace-pre-line text-base font-semibold leading-relaxed text-charcoal">
                  {evaluated.outcomeText}
                </p>
                {dynamicFindings.length > 0 ? (
                  <div className="mt-4 rounded-xl border border-graysoft/30 bg-background p-4 text-sm text-charcoal">
                    <p className="font-semibold text-primary">Updated Findings</p>
                    <ul className="mt-2 space-y-1">
                      {dynamicFindings.map((line) => <li key={line}>{line}</li>)}
                    </ul>
                  </div>
                ) : null}
                <div className="mt-4 rounded-xl border border-graysoft/30 bg-background p-4 text-sm">
                  <p className="font-semibold text-charcoal">Step score: {stepScore > 0 ? `+${stepScore}` : stepScore}</p>
                </div>
                <div className="mt-5 space-y-2">
                  {options.map((option) => {
                    const key = option.option_key.toUpperCase();
                    if (!selectedSet.has(key) && Number(option.score ?? 0) <= 0) return null;
                    return (
                      <div key={option.id} className="rounded-xl border border-graysoft/30 bg-background p-3 text-sm">
                        <p className="font-semibold text-charcoal">{key}. {option.option_text}{selectedSet.has(key) ? " (selected)" : ""}</p>
                        <p className="mt-1 text-graysoft">{option.rationale}</p>
                      </div>
                    );
                  })}
                </div>
                <div className="mt-6 flex flex-wrap gap-3">
                  {nextStep ? (
                    <Link href={`/preview/cse-scenarios/${slug}?step=${encodeURIComponent(nextStep.id)}&v=${nextVitalsState}`} className="btn-primary">
                      Continue to Step {nextStep.step_order}
                    </Link>
                  ) : null}
                  {completed ? <Link href="/signup" className="btn-primary">Unlock the Full CSE Bank</Link> : null}
                  <Link href={`/preview/cse-scenarios/${slug}?step=${encodeURIComponent(currentStep.id)}&v=${currentVitalsState}`} className="btn-secondary">
                    Retry This Step
                  </Link>
                </div>
              </>
            ) : null}
          </section>
        ) : null}
      </div>
    </main>
  );
}
