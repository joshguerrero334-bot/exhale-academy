import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import {
  QUESTION_FIELDS,
  QUESTION_FIELDS_FALLBACK,
  clampIndex,
  normalizeRationaleWhyOthers,
  type QuestionRow,
} from "../../../lib/supabase/quiz";
import { finalizeMasterAttempt, saveMasterAnswer } from "./actions";

type PageProps = {
  params: Promise<{ attemptId: string }>;
  searchParams: Promise<{ i?: string; error?: string }>;
};

type AttemptRow = {
  id: string;
  user_id: string;
  mode: "tutor" | "exam";
  total: number;
  completed_at: string | null;
};

type AttemptItemRow = {
  id: string;
  question_id: string | number;
  order_index: number;
  selected_answer: "A" | "B" | "C" | "D" | null;
  is_correct: boolean | null;
};

export default async function MasterAttemptPage({ params, searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const [{ attemptId }, query] = await Promise.all([params, searchParams]);
  if (!attemptId) redirect("/master");

  const { data: attemptData, error: attemptError } = await supabase
    .from("master_test_attempts")
    .select("*")
    .eq("id", attemptId)
    .single();

  if (attemptError || !attemptData) {
    redirect("/master?error=Attempt%20not%20found");
  }

  const attempt = attemptData as AttemptRow;
  if (attempt.user_id !== user.id) {
    redirect("/master");
  }

  if (attempt.completed_at) {
    redirect(`/master/${encodeURIComponent(attemptId)}/results`);
  }

  const { data: itemsData, error: itemsError } = await supabase
    .from("master_test_attempt_questions")
    .select("id, question_id, order_index, selected_answer, is_correct")
    .eq("attempt_id", attemptId)
    .order("order_index", { ascending: true });

  if (itemsError || !itemsData || itemsData.length === 0) {
    redirect(
      `/master?error=${encodeURIComponent(
        `Attempt questions missing. ${itemsError?.message ?? "No rows found"}`
      )}`
    );
  }

  const items = itemsData as AttemptItemRow[];
  const questionIds = items.map((row) => row.question_id);

  let compatibilityMode = false;
  let questions: QuestionRow[] = [];

  const primary = await supabase.from("questions").select(QUESTION_FIELDS).in("id", questionIds);
  if (primary.error) {
    const fallback = await supabase
      .from("questions")
      .select(QUESTION_FIELDS_FALLBACK)
      .in("id", questionIds);

    if (fallback.error) {
      redirect(
        `/master?error=${encodeURIComponent(`Failed loading questions. ${fallback.error.message}`)}`
      );
    }

    compatibilityMode = true;
    questions = (fallback.data ?? []) as QuestionRow[];
  } else {
    questions = (primary.data ?? []) as QuestionRow[];
  }

  const questionMap = new Map(questions.map((row) => [String(row.id), row]));
  const ordered = items
    .map((item) => ({ item, question: questionMap.get(String(item.question_id)) }))
    .filter((entry) => Boolean(entry.question)) as Array<{ item: AttemptItemRow; question: QuestionRow }>;

  if (ordered.length === 0) {
    redirect("/master?error=No%20questions%20found%20for%20attempt");
  }

  const firstUnanswered = ordered.findIndex((entry) => !entry.item.selected_answer);
  const rawIndex = Number.parseInt(query.i ?? "", 10);
  const defaultIndex = firstUnanswered >= 0 ? firstUnanswered : 0;
  const safeIndex = clampIndex(Number.isNaN(rawIndex) ? defaultIndex : rawIndex, 0, ordered.length - 1);

  const current = ordered[safeIndex];
  const selected = current.item.selected_answer;
  const isTutor = attempt.mode === "tutor";
  const showFeedback = isTutor && Boolean(selected);
  const answeredCount = ordered.filter((entry) => entry.item.selected_answer).length;
  const hasPrev = safeIndex > 0;
  const hasNext = safeIndex < ordered.length - 1;
  const canAdvance = Boolean(selected);
  const rationaleWhyOthers = normalizeRationaleWhyOthers(current.question.rationale_why_others_wrong);

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-3xl space-y-5">
        {compatibilityMode ? (
          <section className="rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm text-amber-800">
            Compatibility mode: optional rationale_why_others_wrong column not found.
          </section>
        ) : null}

        {query.error ? (
          <section className="rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
            {query.error}
          </section>
        ) : null}

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm sm:p-8">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[color:var(--brand-navy)]">
                Master Test ({isTutor ? "Tutor Mode" : "Exam Mode"})
              </p>
              <p className="mt-1 text-sm text-slate-600">
                Question {safeIndex + 1} of {ordered.length}
              </p>
            </div>
            <p className="text-sm font-semibold text-[color:var(--brand-navy)]">
              Answered {answeredCount}/{ordered.length}
            </p>
          </div>

          <div className="mt-4 h-2 overflow-hidden rounded-full bg-[color:var(--cool-gray)]">
            <div
              className="h-full rounded-full bg-[color:var(--brand-navy)] transition-all duration-300"
              style={{ width: `${((safeIndex + 1) / ordered.length) * 100}%` }}
            />
          </div>
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">
            {current.question.category_slug ?? "unknown"}
          </p>
          <h2 className="mt-2 text-lg font-semibold leading-relaxed text-[color:var(--text)] sm:text-xl">
            {current.question.stem ?? "Question text unavailable"}
          </h2>

          <form action={saveMasterAnswer} className="mt-5 space-y-3">
            <input type="hidden" name="attempt_id" value={attemptId} />
            <input type="hidden" name="item_id" value={current.item.id} />
            <input type="hidden" name="index" value={safeIndex} />

            {(["A", "B", "C", "D"] as const).map((label) => {
              const optionText =
                label === "A"
                  ? current.question.option_a
                  : label === "B"
                    ? current.question.option_b
                    : label === "C"
                      ? current.question.option_c
                      : current.question.option_d;

              const isSelected = selected === label;
              const isCorrect = current.question.correct_answer === label;

              let cardClass =
                "border-[color:var(--border)] bg-[color:var(--surface)] hover:border-[color:var(--brand-gold)]";
              if (showFeedback && isCorrect) {
                cardClass = "border-emerald-500 bg-emerald-50";
              } else if (showFeedback && isSelected && !isCorrect) {
                cardClass = "border-red-500 bg-red-50";
              } else if (isSelected) {
                cardClass = "border-[color:var(--brand-navy)] bg-slate-50";
              }

              return (
                <button
                  key={label}
                  type="submit"
                  name="selected_answer"
                  value={label}
                  className={`w-full rounded-xl border px-4 py-4 text-left text-sm transition-all duration-200 ${cardClass}`}
                >
                  <span className="mr-2 font-semibold text-[color:var(--brand-navy)]">{label}.</span>
                  <span className="text-[color:var(--text)]">{optionText ?? "Option unavailable"}</span>
                </button>
              );
            })}
          </form>

          {showFeedback ? (
            <div className="mt-5 rounded-xl border border-[color:var(--cool-gray)] bg-white p-4">
              <p
                className={`text-sm font-semibold ${
                  current.item.is_correct ? "text-emerald-700" : "text-red-700"
                }`}
              >
                {current.item.is_correct ? "Correct" : "Incorrect"}
              </p>
              <p className="mt-2 text-sm text-slate-700">
                Correct answer: <span className="font-semibold">{current.question.correct_answer ?? "Unknown"}</span>
              </p>

              <details className="mt-3 rounded-lg border border-[color:var(--border)] p-3">
                <summary className="cursor-pointer text-sm font-semibold text-[color:var(--brand-navy)]">
                  View Rationale
                </summary>
                <p className="mt-2 text-sm leading-relaxed text-slate-700">
                  {current.question.rationale_correct ?? "No rationale available."}
                </p>
                {rationaleWhyOthers ? (
                  <pre className="mt-3 whitespace-pre-wrap text-xs text-slate-600">{rationaleWhyOthers}</pre>
                ) : null}
              </details>
            </div>
          ) : null}

          <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            {hasPrev ? (
              <Link
                href={`/master/${encodeURIComponent(attemptId)}?i=${safeIndex - 1}`}
                className="w-full rounded-lg border border-[color:var(--cool-gray)] px-4 py-2 text-center text-sm font-semibold text-[color:var(--brand-navy)] sm:w-auto sm:text-left"
              >
                Back
              </Link>
            ) : (
              <span className="rounded-lg border border-[color:var(--cool-gray)] px-4 py-2 text-center text-sm text-slate-400 sm:text-left">
                Back
              </span>
            )}

            {hasNext ? (
              canAdvance ? (
                <Link
                  href={`/master/${encodeURIComponent(attemptId)}?i=${safeIndex + 1}`}
                  className="w-full rounded-lg bg-[color:var(--brand-gold)] px-5 py-2 text-center text-sm font-semibold text-[color:var(--brand-navy)] sm:w-auto sm:text-left"
                >
                  Next
                </Link>
              ) : (
                <span className="rounded-lg border border-[color:var(--cool-gray)] px-4 py-2 text-center text-sm text-slate-500 sm:text-left">
                  Select an answer to continue
                </span>
              )
            ) : (
              <form action={finalizeMasterAttempt}>
                <input type="hidden" name="attempt_id" value={attemptId} />
                <button className="w-full rounded-lg bg-[color:var(--brand-gold)] px-5 py-2 text-sm font-semibold text-[color:var(--brand-navy)] sm:w-auto">
                  Submit Test
                </button>
              </form>
            )}
          </div>
        </section>
      </div>
    </main>
  );
}
