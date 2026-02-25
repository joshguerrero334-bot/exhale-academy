import Link from "next/link";
import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../../../../components/PracticeSwitchBar";
import { createClient } from "../../../../../lib/supabase/server";
import { fetchStepOptions, parseVitalsState } from "../../../../../lib/supabase/cse";

type PageProps = {
  params: Promise<{ attemptId: string }>;
};

type AttemptRow = {
  id: string;
  user_id: string;
  case_id: string;
  mode: "tutor" | "exam";
  status: "in_progress" | "completed";
  total_score: number;
  vitals: Record<string, unknown> | null;
};

type EventRow = {
  id: string;
  step_id: string;
  selected_keys: string[] | null;
  step_score: number;
  outcome_text: string;
  vitals_after: Record<string, unknown>;
  created_at: string;
};

type MasterAttemptLinkRow = {
  id: string;
  attempt_id: string;
  order_index: number;
  status: "pending" | "in_progress" | "completed";
  case_score: number | null;
};

export default async function CseAttemptCompletePage({ params }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fcases");
  }

  const { attemptId } = await params;

  const { data: attemptData, error: attemptError } = await supabase
    .from("cse_attempts")
    .select("id, user_id, case_id, mode, status, total_score, vitals")
    .eq("id", attemptId)
    .single();

  if (attemptError || !attemptData) {
    redirect("/cse/cases?error=Attempt%20not%20found");
  }

  const attempt = attemptData as AttemptRow;
  if (attempt.user_id !== user.id) {
    redirect("/cse/cases");
  }

  if (attempt.status !== "completed") {
    redirect(`/cse/attempt/${encodeURIComponent(attemptId)}`);
  }

  const [{ data: caseData }, { data: eventsData }] = await Promise.all([
    supabase.from("cse_cases").select("id, slug, title, source").eq("id", attempt.case_id).single(),
    supabase
      .from("cse_attempt_events")
      .select("id, step_id, selected_keys, step_score, outcome_text, vitals_after, created_at")
      .eq("attempt_id", attemptId)
      .order("created_at", { ascending: true }),
  ]);

  if (!caseData) {
    redirect("/cse/cases?error=Case%20missing");
  }
  const caseRef = caseData.slug && String(caseData.slug).trim().length > 0 ? caseData.slug : attempt.case_id;

  const events = (eventsData ?? []) as EventRow[];
  const stepIds = [...new Set(events.map((event) => event.step_id))];

  const { data: stepsData } = await supabase
    .from("cse_steps")
    .select("id, step_order, prompt")
    .in("id", stepIds);

  const stepById = new Map((stepsData ?? []).map((step) => [step.id, step]));
  const optionsByStep = new Map<string, Awaited<ReturnType<typeof fetchStepOptions>>["rows"]>();

  for (const stepId of stepIds) {
    const result = await fetchStepOptions(supabase, stepId);
    optionsByStep.set(stepId, result.rows);
  }

  const finalVitals = parseVitalsState(attempt.vitals);
  let masterAttemptId: string | null = null;
  let masterIsCompleted = false;
  let masterCaseIndex: number | null = null;
  let masterTotalCases: number | null = null;

  const { data: masterItemRaw } = await supabase
    .from("cse_master_attempt_cases")
    .select("id, attempt_id, order_index, status, case_score")
    .eq("cse_attempt_id", attemptId)
    .maybeSingle();
  const masterItem = (masterItemRaw ?? null) as MasterAttemptLinkRow | null;

  if (masterItem?.attempt_id) {
    masterAttemptId = String(masterItem.attempt_id);
    const currentScore = Number(masterItem.case_score ?? 0);
    if (masterItem.status !== "completed" || currentScore !== attempt.total_score) {
      await supabase
        .from("cse_master_attempt_cases")
        .update({
          status: "completed",
          case_score: attempt.total_score,
          completed_at: new Date().toISOString(),
        })
        .eq("id", masterItem.id);
    }

    const [{ data: masterItems }, { data: masterAttempt }] = await Promise.all([
      supabase
        .from("cse_master_attempt_cases")
        .select("status, case_score")
        .eq("attempt_id", masterAttemptId),
      supabase
        .from("cse_master_attempts")
        .select("id, total_cases")
        .eq("id", masterAttemptId)
        .maybeSingle(),
    ]);

    const completedCases = (masterItems ?? []).filter((row) => row.status === "completed").length;
    const totalScore = (masterItems ?? []).reduce((sum, row) => sum + Number(row.case_score ?? 0), 0);
    const expectedTotal = Number(masterAttempt?.total_cases ?? 0);
    masterTotalCases = expectedTotal > 0 ? expectedTotal : null;
    masterCaseIndex = Number(masterItem.order_index ?? 0) + 1;
    masterIsCompleted = expectedTotal > 0 && completedCases >= expectedTotal;

    await supabase
      .from("cse_master_attempts")
      .update({
        completed_cases: completedCases,
        total_score: totalScore,
        status: masterIsCompleted ? "completed" : "in_progress",
        completed_at: masterIsCompleted ? new Date().toISOString() : null,
      })
      .eq("id", masterAttemptId);
  }

  return (
    <main className="page-shell">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />
      <div className="mx-auto w-full max-w-4xl space-y-5 pt-4">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">
            {masterAttemptId
              ? `Master CSE · Case ${masterCaseIndex ?? "?"} of ${masterTotalCases ?? "?"}`
              : (caseData.source ?? "cse")}
          </p>
          <h1 className="mt-2 text-3xl font-bold text-[color:var(--brand-navy)]">Case Complete</h1>
          <p className="mt-2 text-sm text-slate-600">
            {masterAttemptId
              ? `Case ${masterCaseIndex ?? "?"} complete.`
              : caseData.title}
          </p>
          <div className="mt-5 grid gap-3 sm:grid-cols-3">
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Mode</p>
              <p className="mt-1 text-lg font-semibold text-[color:var(--brand-navy)]">{attempt.mode === "tutor" ? "Tutor" : "Exam"}</p>
            </div>
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Total Score</p>
              <p className="mt-1 text-lg font-semibold text-[color:var(--brand-navy)]">{attempt.total_score}</p>
            </div>
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Submitted Steps</p>
              <p className="mt-1 text-lg font-semibold text-[color:var(--brand-navy)]">{events.length}</p>
            </div>
          </div>
          <div className="mt-4 flex flex-wrap gap-2 text-xs">
            {Object.entries(finalVitals).map(([key, value]) => (
              <span key={key} className="rounded-full bg-slate-100 px-3 py-1 text-slate-700">
                {key}: {value}
              </span>
            ))}
          </div>
          <div className="mt-5 flex gap-3">
            <Link href="/cse/cases" className="rounded-lg bg-[color:var(--brand-navy)] px-4 py-2.5 text-sm font-semibold text-white">
              Back to Cases
            </Link>
            {masterAttemptId ? (
              <Link
                href={
                  masterIsCompleted
                    ? `/cse/master/${encodeURIComponent(masterAttemptId)}/results`
                    : `/cse/master/${encodeURIComponent(masterAttemptId)}`
                }
                className="rounded-lg border border-[color:var(--brand-navy)] px-4 py-2.5 text-sm font-semibold text-[color:var(--brand-navy)]"
              >
                {masterIsCompleted ? "View Master Results" : "Next Master Case"}
              </Link>
            ) : null}
            <Link
              href={`/cse/case/${encodeURIComponent(caseRef)}`}
              className="rounded-lg border border-[color:var(--brand-gold)] px-4 py-2.5 text-sm font-semibold text-[color:var(--brand-navy)]"
            >
              Start New Attempt
            </Link>
          </div>
        </section>

        <section className="space-y-3">
          {events.map((event) => {
            const step = stepById.get(event.step_id);
            const selected = new Set((event.selected_keys ?? []).map((key) => String(key).toUpperCase()));
            const options = (optionsByStep.get(event.step_id) ?? []).sort((a, b) => a.option_key.localeCompare(b.option_key));

            return (
              <article key={event.id} className="rounded-xl border border-[color:var(--border)] bg-[color:var(--surface)] p-4 shadow-sm">
                <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[color:var(--brand-navy)]">
                  Step {step?.step_order ?? "?"}
                </p>
                <h2 className="mt-1 text-sm font-semibold text-[color:var(--text)] sm:text-base">{step?.prompt ?? "Step prompt unavailable"}</h2>
                <p className="mt-2 text-xs text-slate-700">Step score: {event.step_score > 0 ? `+${event.step_score}` : event.step_score}</p>
                <p className="mt-2 whitespace-pre-line rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-3 text-xs text-slate-700">
                  {event.outcome_text}
                </p>

                {options.length > 0 ? (
                  <div className="mt-3 space-y-2">
                    {options.map((option) => {
                      const isSelected = selected.has(option.option_key.toUpperCase());
                      const isCorrect = Number(option.score ?? 0) > 0;
                      const isIncorrect = Number(option.score ?? 0) < 0;

                      return (
                        <div
                          key={option.id}
                          className={`rounded-lg border px-3 py-2 text-xs ${
                            isCorrect
                              ? isSelected
                                ? "border-emerald-500 bg-emerald-100"
                                : "border-emerald-300 bg-emerald-50"
                              : isIncorrect
                                ? isSelected
                                  ? "border-red-600 bg-red-100"
                                  : "border-red-300 bg-red-50"
                                : isSelected
                                  ? "border-[color:var(--brand-navy)] bg-slate-50"
                                  : "border-[color:var(--cool-gray)] bg-white"
                          }`}
                        >
                          <p className="font-semibold text-slate-700">
                            {isSelected ? "Selected" : "Not selected"} · {option.option_key}. {option.option_text}
                          </p>
                          <p className="mt-1 text-slate-600">Score: {option.score > 0 ? `+${option.score}` : option.score}</p>
                          <p className="mt-1 text-slate-600">{option.rationale}</p>
                        </div>
                      );
                    })}
                  </div>
                ) : null}
              </article>
            );
          })}
        </section>
      </div>
    </main>
  );
}
