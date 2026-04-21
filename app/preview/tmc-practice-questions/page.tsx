import type { Metadata } from "next";
import Link from "next/link";
import { headingFont } from "../../../lib/fonts";
import { previewQuestions } from "../../../lib/preview/free-preview-content";

export const metadata: Metadata = {
  title: "Free TMC Practice Questions | Exhale Academy",
  description:
    "Try 10 free TMC practice questions from Exhale Academy. Preview respiratory therapy exam prep before subscribing.",
  alternates: { canonical: "/preview/tmc-practice-questions" },
};

type PageProps = {
  searchParams: Promise<{ q?: string; answer?: string }>;
};

function getIndex(raw: string | undefined) {
  const parsed = Number.parseInt(String(raw ?? "0"), 10);
  if (Number.isNaN(parsed)) return 0;
  return Math.max(0, Math.min(previewQuestions.length - 1, parsed));
}

export default async function FreeTmcPracticeQuestionsPage({ searchParams }: PageProps) {
  const query = await searchParams;
  const index = getIndex(query.q);
  const selected = String(query.answer ?? "").toUpperCase();
  const question = previewQuestions[index];
  const hasAnswer = selected === "A" || selected === "B" || selected === "C" || selected === "D";
  const isCorrect = hasAnswer && selected === question.correct;
  const nextIndex = Math.min(index + 1, previewQuestions.length - 1);
  const prevIndex = Math.max(index - 1, 0);

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Free TMC Preview</p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>
            10 Free TMC Practice Questions
          </h1>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
            Preview Exhale Academy&apos;s respiratory therapy test prep with the same 10 free TMC practice questions every time. The full membership unlocks the complete TMC question bank, category drills, and full-length practice exams.
          </p>
          <div className="mt-5 flex flex-wrap gap-3">
            <Link href="/signup" className="btn-primary">Unlock Full Access</Link>
            <Link href="/" className="btn-secondary">Back to Home</Link>
          </div>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">{question.category}</p>
              <p className="mt-1 text-sm text-graysoft">Question {index + 1} of {previewQuestions.length}</p>
            </div>
            <span className="rounded-full border border-primary/20 bg-primary/5 px-3 py-1 text-xs font-semibold text-primary">
              Fixed free preview
            </span>
          </div>

          <h2 className={`${headingFont} mt-5 text-xl font-semibold leading-relaxed text-charcoal sm:text-2xl`}>
            {question.stem}
          </h2>

          <form method="get" className="mt-5 space-y-3">
            <input type="hidden" name="q" value={index} />
            {(["A", "B", "C", "D"] as const).map((label) => {
              const isSelected = selected === label;
              const isRight = question.correct === label;
              const showCorrect = hasAnswer && isRight;
              const showWrong = hasAnswer && isSelected && !isRight;
              return (
                <label
                  key={label}
                  className={`block cursor-pointer rounded-xl border p-4 text-sm transition ${
                    showCorrect
                      ? "border-emerald-400 bg-emerald-50"
                      : showWrong
                        ? "border-red-400 bg-red-50"
                        : isSelected
                          ? "border-primary bg-primary/5"
                          : "border-graysoft/30 bg-white hover:border-primary"
                  }`}
                >
                  <input className="mr-3" type="radio" name="answer" value={label} defaultChecked={isSelected} />
                  <span className="font-semibold">{label}.</span> {question.options[label]}
                </label>
              );
            })}
            <button type="submit" className="btn-primary">Reveal Answer</button>
          </form>

          {hasAnswer ? (
            <div className={`mt-5 rounded-xl border p-4 text-sm ${isCorrect ? "border-emerald-300 bg-emerald-50 text-emerald-800" : "border-amber-300 bg-amber-50 text-amber-900"}`}>
              <p className="font-semibold">{isCorrect ? "Correct." : `Not quite. Correct answer: ${question.correct}.`}</p>
              <p className="mt-1 leading-relaxed">{question.rationale}</p>
            </div>
          ) : null}

          <div className="mt-6 flex flex-wrap gap-3">
            <Link href={`/preview/tmc-practice-questions?q=${prevIndex}`} className="btn-secondary">Previous</Link>
            <Link href={`/preview/tmc-practice-questions?q=${nextIndex}`} className="btn-secondary">Next Question</Link>
            <Link href="/signup" className="btn-primary">Get the Full Question Bank</Link>
          </div>
        </section>
      </div>
    </main>
  );
}
