import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "../../../../lib/supabase/server";
import { headingFont } from "../../../../lib/fonts";
import {
  QUESTION_FIELDS,
  QUESTION_FIELDS_FALLBACK,
  clampIndex,
  normalizeRationaleWhyOthers,
  type QuestionRow,
} from "../../../../lib/supabase/quiz";
import { finalizeCategoryAttempt, saveCategoryAnswer } from "./actions";

type PageProps = {
  params: Promise<{ category: string; sessionId: string }>;
  searchParams: Promise<{ i?: string; error?: string }>;
};

type AttemptRow = {
  id: string;
  user_id: string;
  category_slug: string;
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

export default async function CategoryAttemptPage({ params, searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const [{ category: rawSlug, sessionId }, query] = await Promise.all([params, searchParams]);
  const requestedSlug = decodeURIComponent(rawSlug ?? "").trim().toLowerCase();
  if (!requestedSlug || !sessionId) {
    redirect("/dashboard");
  }

  const { data: attemptData, error: attemptError } = await supabase
    .from("category_quiz_attempts")
    .select("*")
    .eq("id", sessionId)
    .single();

  if (attemptError || !attemptData) {
    redirect(`/quiz/${encodeURIComponent(requestedSlug)}?error=Attempt%20not%20found`);
  }

  const attempt = attemptData as AttemptRow;
  if (attempt.user_id !== user.id) {
    redirect("/dashboard");
  }

  const canonicalSlug = String(attempt.category_slug ?? "").trim().toLowerCase();
  if (canonicalSlug && canonicalSlug !== requestedSlug) {
    redirect(`/quiz/${encodeURIComponent(canonicalSlug)}/${encodeURIComponent(sessionId)}`);
  }

  if (attempt.completed_at) {
    redirect(`/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}/${encodeURIComponent(sessionId)}/results`);
  }

  const { data: itemData, error: itemError } = await supabase
    .from("category_quiz_attempt_questions")
    .select("id, question_id, order_index, selected_answer, is_correct")
    .eq("attempt_id", sessionId)
    .order("order_index", { ascending: true });

  if (itemError || !itemData || itemData.length === 0) {
    redirect(
      `/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}?error=${encodeURIComponent(
        `Attempt questions missing. ${itemError?.message ?? "No rows found"}`
      )}`
    );
  }

  const items = itemData as AttemptItemRow[];
  const questionIds = items.map((item) => item.question_id);

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
        `/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}?error=${encodeURIComponent(
          `Failed loading questions. ${fallback.error.message}`
        )}`
      );
    }

    compatibilityMode = true;
    questions = (fallback.data ?? []) as QuestionRow[];
  } else {
    questions = (primary.data ?? []) as QuestionRow[];
  }

  const questionMap = new Map(questions.map((question) => [String(question.id), question]));
  const ordered = items
    .map((item) => ({ item, question: questionMap.get(String(item.question_id)) }))
    .filter((entry) => Boolean(entry.question)) as Array<{ item: AttemptItemRow; question: QuestionRow }>;

  if (ordered.length === 0) {
    redirect(`/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}?error=No%20questions%20available`);
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
  const rationaleWhyOthersLines = rationaleWhyOthers
    ? rationaleWhyOthers
        .split("\n")
        .map((line) => line.trim())
        .filter(Boolean)
    : [];

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
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

        <section className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">
                Category Quiz ({isTutor ? "Tutor Mode" : "Exam Mode"})
              </p>
              <p className="mt-1 text-sm text-graysoft">
                Question {safeIndex + 1} of {ordered.length}
              </p>
            </div>
            <p className="text-sm font-semibold text-charcoal">
              Answered {answeredCount}/{ordered.length}
            </p>
          </div>

          <div className="mt-4 h-2 overflow-hidden rounded-full bg-graysoft/30">
            <div
              className="h-full rounded-full bg-primary transition-all duration-300"
              style={{ width: `${((safeIndex + 1) / ordered.length) * 100}%` }}
            />
          </div>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-graysoft">
            {canonicalSlug || requestedSlug}
          </p>
          <h2 className={`${headingFont} mt-2 text-lg font-semibold leading-relaxed text-charcoal sm:text-xl`}>
            {current.question.stem ?? "Question text unavailable"}
          </h2>

          <form action={saveCategoryAnswer} className="mt-5 space-y-3">
            <input type="hidden" name="attempt_id" value={sessionId} />
            <input type="hidden" name="item_id" value={current.item.id} />
            <input type="hidden" name="category_slug" value={canonicalSlug || requestedSlug} />
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
                "border-graysoft/30 bg-white hover:border-primary";
              if (showFeedback && isCorrect) {
                cardClass = "border-emerald-500 bg-emerald-50";
              } else if (showFeedback && !isCorrect) {
                cardClass = isSelected ? "border-red-600 bg-red-100" : "border-red-300 bg-red-50";
              } else if (isSelected) {
                cardClass = "border-primary bg-primary/5";
              }

              return (
                <button
                  key={label}
                  type="submit"
                  name="selected_answer"
                  value={label}
                  className={`w-full rounded-xl border px-4 py-4 text-left text-sm transition-all duration-200 ${cardClass}`}
                >
                  <span className="mr-2 font-semibold text-charcoal">{label}.</span>
                  <span className="text-charcoal">{optionText ?? "Option unavailable"}</span>
                </button>
              );
            })}
          </form>

          {showFeedback ? (
            <div className="mt-5 rounded-xl border border-graysoft/30 bg-white p-4">
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

              <details className="mt-3 rounded-lg border border-graysoft/30 p-3">
                <summary className="cursor-pointer text-sm font-semibold text-charcoal">
                  View Rationale
                </summary>
                <ul className="mt-2 list-disc space-y-2 pl-5 text-sm leading-relaxed text-slate-700">
                  <li>
                    <span className="font-bold">Correct Explanation:</span>{" "}
                    {current.question.rationale_correct ?? "No rationale available."}
                  </li>
                  {rationaleWhyOthersLines.map((line, idx) => (
                    <li key={`why-other-${idx}`}>
                      <span className="font-bold">Incorrect Explanation:</span> {line}
                    </li>
                  ))}
                </ul>
                {rationaleWhyOthers && rationaleWhyOthersLines.length === 0 ? (
                  <p className="mt-2 text-sm leading-relaxed text-slate-700">
                    <span className="font-bold">Incorrect Explanation:</span> {rationaleWhyOthers}
                  </p>
                ) : null}
              </details>
            </div>
          ) : null}

          <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            {hasPrev ? (
              <Link
                href={`/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}/${encodeURIComponent(sessionId)}?i=${safeIndex - 1}`}
                className="btn-secondary w-full sm:w-auto"
              >
                Back
              </Link>
            ) : (
              <span className="rounded-lg border border-graysoft/30 px-4 py-2 text-center text-sm text-graysoft sm:text-left">
                Back
              </span>
            )}

            {hasNext ? (
              canAdvance ? (
                <Link
                  href={`/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}/${encodeURIComponent(sessionId)}?i=${safeIndex + 1}`}
                  className="btn-primary w-full sm:w-auto"
                >
                  Next
                </Link>
              ) : (
                <span className="rounded-lg border border-graysoft/30 px-4 py-2 text-center text-sm text-graysoft sm:text-left">
                  Select an answer to continue
                </span>
              )
            ) : (
              <form action={finalizeCategoryAttempt}>
                <input type="hidden" name="attempt_id" value={sessionId} />
                <input type="hidden" name="category_slug" value={canonicalSlug || requestedSlug} />
                <button className="btn-primary w-full sm:w-auto">
                  Submit Quiz
                </button>
              </form>
            )}
          </div>
        </section>
      </div>
    </main>
  );
}
