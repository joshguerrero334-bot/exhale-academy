import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "../../../../../lib/supabase/server";
import { headingFont } from "../../../../../lib/fonts";
import {
  QUESTION_FIELDS,
  QUESTION_FIELDS_FALLBACK,
  normalizeRationaleWhyOthers,
  type QuestionRow,
} from "../../../../../lib/supabase/quiz";

type PageProps = {
  params: Promise<{ category: string; sessionId: string }>;
};

type AttemptRow = {
  id: string;
  user_id: string;
  category_slug: string;
  mode: "tutor" | "exam";
  total: number;
  score: number;
  completed_at: string | null;
};

type ItemRow = {
  question_id: string | number;
  selected_answer: "A" | "B" | "C" | "D" | null;
  is_correct: boolean | null;
};

export default async function CategoryResultsPage({ params }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const { category: rawSlug, sessionId } = await params;
  const requestedSlug = decodeURIComponent(rawSlug ?? "").trim().toLowerCase();

  if (!sessionId || !requestedSlug) {
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
  if (!attempt.completed_at) {
    redirect(`/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}/${encodeURIComponent(sessionId)}`);
  }

  const { data: itemsData, error: itemsError } = await supabase
    .from("category_quiz_attempt_questions")
    .select("question_id, selected_answer, is_correct")
    .eq("attempt_id", sessionId)
    .order("order_index", { ascending: true });

  if (itemsError) {
    redirect(
      `/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}?error=${encodeURIComponent(
        `Failed to load results. ${itemsError.message}`
      )}`
    );
  }

  const items = (itemsData ?? []) as ItemRow[];
  const questionIds = items.map((row) => row.question_id);

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
          `Failed loading question details. ${fallback.error.message}`
        )}`
      );
    }

    questions = (fallback.data ?? []) as QuestionRow[];
  } else {
    questions = (primary.data ?? []) as QuestionRow[];
  }

  const questionMap = new Map(questions.map((row) => [String(row.id), row]));

  const total = attempt.total || items.length;
  const correct = Number(attempt.score ?? 0);
  const percent = total > 0 ? Math.round((correct / total) * 100) : 0;

  const breakdown = new Map<string, { total: number; correct: number }>();
  const missed: Array<{
    category_slug: string;
    stem: string;
    selected_answer: string;
    correct_answer: string;
    rationale_correct: string;
    rationale_why_others_wrong: string | null;
  }> = [];

  for (const item of items) {
    const question = questionMap.get(String(item.question_id));
    if (!question) continue;

    const slug = String(question.category_slug ?? canonicalSlug ?? "unknown").trim() || "unknown";
    if (!breakdown.has(slug)) breakdown.set(slug, { total: 0, correct: 0 });
    const row = breakdown.get(slug)!;
    row.total += 1;
    if (item.is_correct) row.correct += 1;

    if (item.selected_answer && !item.is_correct) {
      missed.push({
        category_slug: slug,
        stem: String(question.stem ?? "Question unavailable"),
        selected_answer: item.selected_answer,
        correct_answer: String(question.correct_answer ?? "Unknown"),
        rationale_correct: String(question.rationale_correct ?? "No rationale available."),
        rationale_why_others_wrong: normalizeRationaleWhyOthers(question.rationale_why_others_wrong),
      });
    }
  }

  missed.sort((a, b) => a.category_slug.localeCompare(b.category_slug));

  const breakdownRows = Array.from(breakdown.entries())
    .map(([slug, row]) => ({ slug, ...row }))
    .sort((a, b) => a.slug.localeCompare(b.slug));

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Category Quiz Results
          </p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal`}>Attempt Summary</h1>
          <p className="mt-2 text-sm text-graysoft">
            Category: {canonicalSlug || requestedSlug} · Mode: {attempt.mode === "tutor" ? "Tutor" : "Exam"}
          </p>

          <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
            <div className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-xs uppercase tracking-[0.14em] text-slate-500">Correct</p>
              <p className="mt-1 text-xl font-semibold text-charcoal">{correct}</p>
            </div>
            <div className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-xs uppercase tracking-[0.14em] text-slate-500">Total</p>
              <p className="mt-1 text-xl font-semibold text-charcoal">{total}</p>
            </div>
            <div className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-xs uppercase tracking-[0.14em] text-slate-500">Percent</p>
              <p className="mt-1 text-xl font-semibold text-charcoal">{percent}%</p>
            </div>
            <div className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-xs uppercase tracking-[0.14em] text-slate-500">Missed</p>
              <p className="mt-1 text-xl font-semibold text-charcoal">{Math.max(total - correct, 0)}</p>
            </div>
          </div>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-xl font-semibold text-charcoal`}>Breakdown by Category</h2>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {breakdownRows.map((row) => (
              <div key={row.slug} className="rounded-xl border border-graysoft/30 bg-background p-4">
                <p className="text-sm font-semibold text-charcoal">{row.slug}</p>
                <p className="mt-1 text-sm text-slate-700">
                  {row.correct}/{row.total}
                </p>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-xl font-semibold text-charcoal`}>Missed Questions (Review)</h2>
          {missed.length === 0 ? (
            <p className="mt-3 text-sm text-slate-700">No missed questions.</p>
          ) : (
            <div className="mt-4 space-y-3">
              {missed.map((row, idx) => (
                <article key={`${row.category_slug}-${idx}`} className="rounded-xl border border-graysoft/30 bg-background p-4">
                  <p className="text-xs uppercase tracking-[0.14em] text-slate-500">{row.category_slug}</p>
                  <p className="mt-2 text-sm font-semibold text-[color:var(--text)]">{row.stem}</p>
                  <p className="mt-2 text-sm text-slate-700">Your answer: <span className="font-semibold">{row.selected_answer}</span></p>
                  <p className="text-sm text-slate-700">Correct answer: <span className="font-semibold">{row.correct_answer}</span></p>
                  <p className="mt-2 text-sm text-slate-700">{row.rationale_correct}</p>
                  {row.rationale_why_others_wrong ? (
                    <pre className="mt-2 whitespace-pre-wrap text-xs text-slate-600">{row.rationale_why_others_wrong}</pre>
                  ) : null}
                </article>
              ))}
            </div>
          )}
        </section>

        <div className="flex flex-wrap gap-3">
          <Link href={`/quiz/${encodeURIComponent(canonicalSlug || requestedSlug)}`} className="btn-primary">
            Start New Quiz
          </Link>
          <Link href="/dashboard" className="btn-secondary">
            Back to Dashboard
          </Link>
        </div>
      </div>
    </main>
  );
}
