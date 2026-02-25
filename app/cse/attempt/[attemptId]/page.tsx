import Link from "next/link";
import { redirect } from "next/navigation";
import ConfirmSubmitButton from "../../../../components/cse/ConfirmSubmitButton";
import LiveSelectedChoices from "../../../../components/cse/LiveSelectedChoices";
import CseTimer from "../../../../components/cse/CseTimer";
import PracticeSwitchBar from "../../../../components/PracticeSwitchBar";
import { createClient } from "../../../../lib/supabase/server";
import { fetchStepOptions } from "../../../../lib/supabase/cse";
import { submitCseBranchStep } from "./actions";

type PageProps = {
  params: Promise<{ attemptId: string }>;
  searchParams: Promise<{ error?: string; event?: string; dm_feedback?: string; selected?: string }>;
};

type AttemptRow = {
  id: string;
  user_id: string;
  case_id: string;
  mode: "tutor" | "exam";
  current_step_id: string | null;
  status: "in_progress" | "completed";
  total_score: number;
  vitals: Record<string, unknown> | null;
};

type StepRow = {
  id: string;
  step_order: number;
  step_type: "IG" | "DM";
  prompt: string;
  max_select: number | null;
  stop_label: string | null;
};

type EventRow = {
  id: string;
  step_id: string;
  outcome_id?: string | null;
  selected_keys: string[] | null;
  step_score: number;
  outcome_text: string;
  vitals_after: Record<string, unknown>;
  created_at: string;
};

type CaseStepMeta = {
  id: string;
  step_order: number;
};

type OptionLookupRow = {
  step_id: string;
  option_key: string;
  option_text: string;
};

type MasterAttemptLinkRow = {
  attempt_id: string;
  order_index: number;
};

type MasterAttemptMetaRow = {
  id: string;
  total_cases: number;
};

export default async function CseAttemptPlayerPage({ params, searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fcases");
  }

  const [{ attemptId }, query] = await Promise.all([params, searchParams]);

  const { data: attemptData, error: attemptError } = await supabase
    .from("cse_attempts")
    .select("id, user_id, case_id, mode, current_step_id, status, total_score, vitals")
    .eq("id", attemptId)
    .single();

  if (attemptError || !attemptData) {
    redirect("/cse/cases?error=Attempt%20not%20found");
  }

  const attempt = attemptData as AttemptRow;
  if (attempt.user_id !== user.id) {
    redirect("/cse/cases");
  }

  const { data: caseData, error: caseError } = await supabase
    .from("cse_cases")
    .select("id, title, source")
    .eq("id", attempt.case_id)
    .single();

  if (caseError || !caseData) {
    redirect("/cse/cases?error=Case%20missing");
  }

  const { data: masterLinkRaw } = await supabase
    .from("cse_master_attempt_cases")
    .select("attempt_id, order_index")
    .eq("cse_attempt_id", attemptId)
    .maybeSingle();
  const masterLink = (masterLinkRaw ?? null) as MasterAttemptLinkRow | null;

  let masterMeta: MasterAttemptMetaRow | null = null;
  if (masterLink?.attempt_id) {
    const { data: masterAttemptRaw } = await supabase
      .from("cse_master_attempts")
      .select("id, total_cases")
      .eq("id", masterLink.attempt_id)
      .maybeSingle();
    masterMeta = (masterAttemptRaw ?? null) as MasterAttemptMetaRow | null;
  }

  const isMasterCase = Boolean(masterLink && masterMeta);
  const masterCaseIndex = isMasterCase ? Number(masterLink?.order_index ?? 0) + 1 : null;
  const masterTotalCases = isMasterCase ? Number(masterMeta?.total_cases ?? 20) : null;
  const displayCaseTitle =
    isMasterCase && masterCaseIndex && masterTotalCases
      ? `Case ${masterCaseIndex} of ${masterTotalCases}`
      : caseData.title;

  const [{ data: caseStepsData }, { data: historyRaw }] = await Promise.all([
    supabase.from("cse_steps").select("id, step_order").eq("case_id", attempt.case_id).order("step_order", { ascending: true }),
    supabase
      .from("cse_attempt_events")
      .select("id, step_id, selected_keys, step_score, outcome_text, vitals_after, created_at")
      .eq("attempt_id", attemptId)
      .order("created_at", { ascending: false }),
  ]);
  const stepMeta = (caseStepsData ?? []) as CaseStepMeta[];
  const stepOrderById = new Map(stepMeta.map((s) => [s.id, s.step_order]));
  const historyEvents = (historyRaw ?? []) as EventRow[];
  const stepIds = stepMeta.map((s) => s.id);

  const { data: optionLookupRaw } =
    stepIds.length > 0
      ? await supabase.from("cse_options").select("step_id, option_key, option_text").in("step_id", stepIds)
      : { data: [] as OptionLookupRow[] };

  const optionTextByStepAndKey = new Map<string, string>();
  for (const row of (optionLookupRaw ?? []) as OptionLookupRow[]) {
    optionTextByStepAndKey.set(`${row.step_id}::${row.option_key.toUpperCase()}`, row.option_text);
  }

  const getSelectedChoiceTexts = (event: EventRow) => {
    const selectedKeys = (event.selected_keys ?? []).map((k) => String(k).toUpperCase()).filter(Boolean);
    if (selectedKeys.length === 0) return [] as string[];
    return selectedKeys
      .map((key) => {
        const optionText = optionTextByStepAndKey.get(`${event.step_id}::${key}`);
        return optionText ?? "Unknown choice";
      });
  };

  const eventId = String(query.event ?? "").trim();
  const dmFeedback = String(query.dm_feedback ?? "").trim().toLowerCase();
  const selectedAttemptKey = String(query.selected ?? "").trim().toUpperCase();

  if (eventId) {
    const { data: eventDataRaw, error: eventError } = await supabase
      .from("cse_attempt_events")
      .select("id, step_id, selected_keys, step_score, outcome_text, vitals_after, created_at")
      .eq("id", eventId)
      .eq("attempt_id", attemptId)
      .single();

    const eventData = eventDataRaw as EventRow | null;
    if (!eventError && eventData) {
      const { data: eventStep } = await supabase
        .from("cse_steps")
        .select("id, step_order, step_type, prompt")
        .eq("id", eventData.step_id)
        .single();
      const eventOptions = await fetchStepOptions(supabase, eventData.step_id);
      const selected = new Set((eventData.selected_keys ?? []).map((v) => String(v).toUpperCase()));

      return (
        <main className="page-shell pb-24">
          <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />
          <div className="mx-auto w-full max-w-6xl space-y-4 pt-4">
            {query.error ? (
              <section className="rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">{query.error}</section>
            ) : null}

            <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">
                    {isMasterCase
                      ? `Master CSE · Case ${masterCaseIndex} of ${masterTotalCases} · ${attempt.mode === "tutor" ? "Tutor" : "Exam"} Mode`
                      : `Scenario · ${caseData.source ?? "cse"} · ${attempt.mode === "tutor" ? "Tutor" : "Exam"} Mode`}
                  </p>
                  <h1 className="mt-2 text-2xl font-bold text-[color:var(--brand-navy)]">{displayCaseTitle}</h1>
                  <p className="mt-2 text-sm font-semibold text-slate-700">{eventStep ? `Step ${eventStep.step_order}` : "Step"} completed</p>
                </div>
                <div className="h-20 w-20 overflow-hidden rounded-xl border border-[color:var(--cool-gray)] bg-slate-50">
                  {typeof user.user_metadata?.avatar_url === "string" && user.user_metadata.avatar_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={user.user_metadata.avatar_url} alt="Student" className="h-full w-full object-cover" />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center text-xs font-semibold uppercase tracking-[0.12em] text-slate-500">Photo</div>
                  )}
                </div>
              </div>
              <p className="mt-4 whitespace-pre-line text-lg font-bold leading-relaxed text-slate-900">{eventData.outcome_text}</p>
              <div className="mt-4 rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-3 text-sm">
                <p className="font-semibold text-[color:var(--brand-navy)]">Step score: {eventData.step_score > 0 ? `+${eventData.step_score}` : eventData.step_score}</p>
                <p className="mt-1 text-slate-700">Running total: {attempt.total_score}</p>
              </div>
            </section>

            <div className="grid gap-4 lg:grid-cols-2">
              <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm">
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Options</p>
                <div className="mt-3 space-y-2">
                  {(eventOptions.rows ?? []).map((option) => {
                    const isSelected = selected.has(option.option_key.toUpperCase());
                    const isCorrect = Number(option.score ?? 0) > 0;
                    const isIncorrect = Number(option.score ?? 0) < 0;
                    const isBest = Number(option.score ?? 0) >= 2;
                    return (
                      <div
                        key={option.id}
                        className={`rounded-lg border px-3 py-2 text-sm ${
                          attempt.mode === "tutor"
                            ? isSelected
                              ? option.score > 0
                                ? "border-emerald-400 bg-emerald-50"
                                : option.score < 0
                                  ? "border-red-500 bg-red-100"
                                  : "border-[color:var(--cool-gray)] bg-slate-50"
                              : isCorrect
                                ? "border-emerald-300 bg-emerald-50/60"
                                : isIncorrect
                                  ? "border-red-300 bg-red-50/80"
                                  : "border-[color:var(--cool-gray)] bg-white"
                            : isSelected
                              ? option.score > 0
                                ? "border-emerald-400 bg-emerald-50"
                                : option.score < 0
                                  ? "border-red-400 bg-red-50"
                                  : "border-[color:var(--cool-gray)] bg-slate-50"
                              : isCorrect
                                ? "border-emerald-300 bg-emerald-50/60"
                                : "border-[color:var(--cool-gray)] bg-white"
                        }`}
                      >
                        <p className="font-semibold text-slate-800">
                          {option.option_key}. {option.option_text}
                          {isSelected ? " (selected)" : ""}
                          {!isSelected && isCorrect ? isBest ? " (best choice)" : " (helpful choice)" : ""}
                        </p>
                        {isSelected && (eventStep as { step_type?: string } | null)?.step_type === "DM" ? (
                          <p className="mt-1 text-sm font-semibold text-emerald-700">Physician Agrees. Done.</p>
                        ) : null}
                        {attempt.mode === "tutor" ? (
                          <ul className="mt-1 list-disc pl-5 text-sm text-slate-700">
                            <li>
                              <span className="font-bold">{option.score > 0 ? "Correct Explanation:" : "Incorrect Explanation:"}</span>{" "}
                              {option.rationale}
                            </li>
                          </ul>
                        ) : null}
                      </div>
                    );
                  })}
                </div>
              </section>

              <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm">
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Simulation History</p>
                <div className="mt-3 max-h-[420px] space-y-2 overflow-y-auto pr-1">
                  {historyEvents.map((historyEvent) => (
                    <div key={historyEvent.id} className="rounded-lg border border-[color:var(--cool-gray)] bg-white p-3 text-sm">
                      <p className="font-semibold text-[color:var(--brand-navy)]">Section {stepOrderById.get(historyEvent.step_id) ?? "-"}</p>
                      <p className="mt-1 font-semibold text-slate-900">{historyEvent.outcome_text}</p>
                      {getSelectedChoiceTexts(historyEvent).length > 0 ? (
                        <ul className="mt-2 list-disc space-y-1 pl-5 text-slate-700">
                          {getSelectedChoiceTexts(historyEvent).map((choiceText, idx) => (
                            <li key={`${historyEvent.id}-${idx}`}>{choiceText}</li>
                          ))}
                        </ul>
                      ) : (
                        <p className="mt-2 text-slate-600">No selections recorded.</p>
                      )}
                    </div>
                  ))}
                </div>
              </section>
            </div>
          </div>

          <div className="fixed inset-x-0 bottom-0 z-30 border-t border-[color:var(--border)] bg-white/95 px-4 py-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] backdrop-blur">
            <div className="mx-auto flex w-full max-w-6xl flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <Link href="/cse/cases" className="rounded-lg border border-[color:var(--cool-gray)] px-4 py-2 text-sm font-semibold text-[color:var(--brand-navy)]">
                Exit
              </Link>
              {attempt.status === "completed" ? (
                <Link href={`/cse/attempt/${encodeURIComponent(attemptId)}/complete`} className="rounded-lg bg-[color:var(--brand-gold)] px-5 py-2.5 text-sm font-semibold text-[color:var(--brand-navy)]">
                  Go To Next Section
                </Link>
              ) : (
                <Link href={`/cse/attempt/${encodeURIComponent(attemptId)}`} className="rounded-lg bg-[color:var(--brand-gold)] px-5 py-2.5 text-sm font-semibold text-[color:var(--brand-navy)]">
                  Go To Next Section
                </Link>
              )}
            </div>
          </div>
          <CseTimer attemptId={attemptId} canReset={attempt.mode === "tutor"} />
        </main>
      );
    }
  }

  if (attempt.status === "completed" || !attempt.current_step_id) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}/complete`);
  }

  const { data: stepData, error: stepError } = await supabase
    .from("cse_steps")
    .select("id, step_order, step_type, prompt, max_select, stop_label")
    .eq("id", attempt.current_step_id)
    .eq("case_id", attempt.case_id)
    .single();

  if (stepError || !stepData) {
    redirect(`/cse/cases?error=${encodeURIComponent(stepError?.message ?? "Current step missing")}`);
  }

  const step = stepData as StepRow;
  const optionsResult = await fetchStepOptions(supabase, step.id);
  if (optionsResult.error) {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(optionsResult.error)}`);
  }

  const sanitizedPrompt = step.prompt.replace(/\s*\(MAX\s*\d+\)/gi, "");

  return (
    <main className="page-shell pb-24">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />
      <div className="mx-auto w-full max-w-6xl space-y-4 pt-4">
              {query.error ? (
          <section className="rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">{query.error}</section>
        ) : null}

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">
                {isMasterCase
                  ? `Master CSE · Case ${masterCaseIndex} of ${masterTotalCases} · ${attempt.mode === "tutor" ? "Tutor" : "Exam"} Mode`
                  : `Scenario · ${caseData.source ?? "cse"} · ${attempt.mode === "tutor" ? "Tutor" : "Exam"} Mode`}
              </p>
              <h1 className="mt-2 text-2xl font-bold text-[color:var(--brand-navy)]">{displayCaseTitle}</h1>
              <p className="mt-2 text-sm text-slate-600">
                Step {step.step_order} · {step.step_type === "IG" ? "SELECT AS MANY AS INDICATED" : "CHOOSE ONLY ONE"}
              </p>
            </div>
            <div className="h-20 w-20 overflow-hidden rounded-xl border border-[color:var(--cool-gray)] bg-slate-50">
              {typeof user.user_metadata?.avatar_url === "string" && user.user_metadata.avatar_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={user.user_metadata.avatar_url} alt="Student" className="h-full w-full object-cover" />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-xs font-semibold uppercase tracking-[0.12em] text-slate-500">Photo</div>
              )}
            </div>
          </div>
          <p className="mt-4 whitespace-pre-line text-base font-semibold text-[color:var(--text)]">{sanitizedPrompt}</p>
        </section>

        <div className="grid gap-4 lg:grid-cols-2">
          <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Options</p>
            <form id="step-submit-form" action={submitCseBranchStep} className="mt-4 space-y-3">
              <input type="hidden" name="attempt_id" value={attemptId} />
              {optionsResult.rows.map((option) => (
                <label
                  key={option.id}
                  className={`flex items-start gap-3 rounded-xl border px-4 py-3 ${
                    step.step_type === "DM" && selectedAttemptKey === option.option_key.toUpperCase()
                      ? dmFeedback === "disagree"
                        ? "border-amber-400 bg-amber-50"
                        : "border-[color:var(--cool-gray)] bg-white"
                      : "border-[color:var(--cool-gray)] bg-white"
                  }`}
                >
                  <input
                    type={step.step_type === "DM" ? "radio" : "checkbox"}
                    name="selected_keys"
                    value={option.option_key}
                    className="mt-1"
                    defaultChecked={step.step_type === "DM" && selectedAttemptKey === option.option_key.toUpperCase()}
                  />
                  <span className="text-sm text-slate-900">
                    <span className="font-semibold">{option.option_key}.</span> {option.option_text}
                    {step.step_type === "DM" &&
                    selectedAttemptKey === option.option_key.toUpperCase() &&
                    dmFeedback === "disagree" ? (
                      <span className="mt-1 block font-semibold text-amber-700">
                        Physician Disagrees.
                        <br />
                        Make another selection.
                      </span>
                    ) : null}
                  </span>
                </label>
              ))}
            </form>
          </section>

          <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Simulation History</p>
            <div className="mt-3 max-h-[520px] space-y-2 overflow-y-auto pr-1">
              <LiveSelectedChoices
                formId="step-submit-form"
                options={optionsResult.rows.map((option) => ({
                  option_key: option.option_key,
                  option_text: option.option_text,
                }))}
              />
              {historyEvents.length === 0 ? (
                <div className="rounded-lg border border-[color:var(--cool-gray)] bg-white p-3 text-sm text-slate-600">No prior sections yet. Results appear here after each submission.</div>
              ) : (
                historyEvents.map((historyEvent) => (
                  <div key={historyEvent.id} className="rounded-lg border border-[color:var(--cool-gray)] bg-white p-3 text-sm">
                    <p className="font-semibold text-[color:var(--brand-navy)]">Section {stepOrderById.get(historyEvent.step_id) ?? "-"}</p>
                    <p className="mt-1 font-semibold text-slate-900">{historyEvent.outcome_text}</p>
                    {getSelectedChoiceTexts(historyEvent).length > 0 ? (
                      <ul className="mt-2 list-disc space-y-1 pl-5 text-slate-700">
                        {getSelectedChoiceTexts(historyEvent).map((choiceText, idx) => (
                          <li key={`${historyEvent.id}-${idx}`}>{choiceText}</li>
                        ))}
                      </ul>
                    ) : (
                      <p className="mt-2 text-slate-600">No selections recorded.</p>
                    )}
                  </div>
                ))
              )}
            </div>
          </section>
        </div>
      </div>

      <div className="fixed inset-x-0 bottom-0 z-30 border-t border-[color:var(--border)] bg-white/95 px-4 py-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] backdrop-blur">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <Link href="/cse/cases" className="rounded-lg border border-[color:var(--cool-gray)] px-4 py-2 text-sm font-semibold text-[color:var(--brand-navy)]">
            Exit
          </Link>
          <ConfirmSubmitButton
            formId="step-submit-form"
            label="Go To Next Section"
            confirmText="Are you sure you want to go to the next section? You cannot return to this section."
            className="rounded-lg bg-[color:var(--brand-gold)] px-5 py-2.5 text-sm font-semibold text-[color:var(--brand-navy)]"
          />
        </div>
      </div>
      <CseTimer attemptId={attemptId} canReset={attempt.mode === "tutor"} />
    </main>
  );
}
