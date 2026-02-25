"use client";

import { useState } from "react";
import QuestionCard from "./QuestionCard";

export type QuizQuestion = {
  id: string;
  stem: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  correct_answer: "A" | "B" | "C" | "D";
  rationale_correct: string;
};

type QuizEngineProps = {
  category: string;
  questions: QuizQuestion[];
};

function shuffleQuestions(list: QuizQuestion[]) {
  const next = [...list];
  for (let i = next.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [next[i], next[j]] = [next[j], next[i]];
  }
  return next;
}

export default function QuizEngine({ category, questions }: QuizEngineProps) {
  const [randomizedQuestions, setRandomizedQuestions] = useState(questions);
  const [index, setIndex] = useState(0);
  const [selectedByQuestion, setSelectedByQuestion] = useState<Record<string, "A" | "B" | "C" | "D">>({});
  const [isComplete, setIsComplete] = useState(false);

  const total = randomizedQuestions.length;
  const current = randomizedQuestions[index];
  const selectedAnswer = selectedByQuestion[current.id] ?? null;

  const progressPercent = Math.round(((index + 1) / total) * 100);
  const isLocked = selectedAnswer !== null;
  const score = randomizedQuestions.reduce((sum, question) => {
    const selected = selectedByQuestion[question.id];
    if (selected && selected === question.correct_answer) return sum + 1;
    return sum;
  }, 0);
  const percentage = total > 0 ? Math.round((score / total) * 100) : 0;

  function pickAnswer(label: "A" | "B" | "C" | "D") {
    if (isLocked) return;
    setSelectedByQuestion((prev) => ({ ...prev, [current.id]: label }));
  }

  function goNext() {
    if (!isLocked) return;
    if (index >= total - 1) {
      setIsComplete(true);
      return;
    }
    setIndex((prev) => prev + 1);
  }

  function goBack() {
    if (index <= 0) return;
    setIndex((prev) => prev - 1);
  }

  function retakeQuiz() {
    setRandomizedQuestions(shuffleQuestions(questions));
    setIndex(0);
    setSelectedByQuestion({});
    setIsComplete(false);
  }

  if (isComplete) {
    const missed = randomizedQuestions.filter((question) => {
      const selected = selectedByQuestion[question.id];
      return selected && selected !== question.correct_answer;
    });

    return (
      <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">
          Quiz Complete
        </p>
        <h2 className="mt-3 text-2xl font-bold text-[color:var(--brand-navy)]">{category}</h2>

        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
            <p className="text-xs uppercase tracking-[0.15em] text-slate-500">Score</p>
            <p className="mt-2 text-2xl font-semibold text-[color:var(--brand-navy)]">
              {score} / {total}
            </p>
          </div>
          <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
            <p className="text-xs uppercase tracking-[0.15em] text-slate-500">Percentage</p>
            <p className="mt-2 text-2xl font-semibold text-[color:var(--brand-navy)]">{percentage}%</p>
          </div>
        </div>

        <div className="mt-6 flex flex-col gap-3 sm:flex-row">
          <button
            onClick={retakeQuiz}
            className="rounded-lg bg-[color:var(--brand-navy)] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[color:var(--brand-navy-strong)]"
          >
            Retake Quiz
          </button>
          <a
            href="/dashboard"
            className="rounded-lg border border-[color:var(--brand-gold)] px-4 py-3 text-center text-sm font-semibold text-[color:var(--brand-navy)] transition hover:bg-[color:var(--brand-gold)]/15"
          >
            Return to Dashboard
          </a>
        </div>

        <div className="mt-8">
          <h3 className="text-lg font-semibold text-[color:var(--brand-navy)]">Missed Questions Review</h3>
          {missed.length === 0 ? (
            <p className="mt-3 rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4 text-sm text-slate-700">
              Excellent work. No missed questions in this set.
            </p>
          ) : (
            <div className="mt-3 space-y-3">
              {missed.map((question, idx) => (
                <article
                  key={question.id}
                  className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4"
                >
                  <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">Missed #{idx + 1}</p>
                  <p className="mt-2 text-sm font-semibold text-[color:var(--text)]">{question.stem}</p>
                  <p className="mt-2 text-sm text-slate-700">
                    Your answer: <span className="font-semibold">{selectedByQuestion[question.id]}</span>
                  </p>
                  <p className="text-sm text-slate-700">
                    Correct answer: <span className="font-semibold">{question.correct_answer}</span>
                  </p>
                  <p className="mt-2 text-sm text-slate-600">{question.rationale_correct}</p>
                </article>
              ))}
            </div>
          )}
        </div>
      </section>
    );
  }

  return (
    <section>
      <div className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm sm:p-8">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">{category}</p>
            <p className="mt-1 text-sm text-slate-600">
              Question {index + 1} of {total}
            </p>
          </div>
          <p className="text-sm font-semibold text-[color:var(--brand-navy)]">
            Score: {score}/{Object.keys(selectedByQuestion).length}
          </p>
        </div>

        <div className="mt-4 h-2 overflow-hidden rounded-full bg-[color:var(--cool-gray)]">
          <div
            className="h-full rounded-full bg-[color:var(--brand-navy)] transition-all duration-300"
            style={{ width: `${progressPercent}%` }}
          />
        </div>
      </div>

      <div className="mt-5">
        <QuestionCard
          stem={current.stem}
          options={[
            { label: "A", text: current.option_a },
            { label: "B", text: current.option_b },
            { label: "C", text: current.option_c },
            { label: "D", text: current.option_d },
          ]}
          selectedAnswer={selectedAnswer}
          correctAnswer={current.correct_answer}
          locked={isLocked}
          onSelect={pickAnswer}
        />
      </div>

      {isLocked ? (
        <div className="mt-5 rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
          <p
            className={`text-sm font-semibold ${
              selectedAnswer === current.correct_answer ? "text-emerald-700" : "text-red-700"
            }`}
          >
            {selectedAnswer === current.correct_answer ? "Correct answer selected" : "Incorrect answer selected"}
          </p>
          <p className="mt-2 text-sm text-slate-700">
            Correct answer: <span className="font-semibold">{current.correct_answer}</span>
          </p>

          <details className="mt-3 rounded-lg border border-[color:var(--border)] bg-white p-3">
            <summary className="cursor-pointer text-sm font-semibold text-[color:var(--brand-navy)]">
              View Rationale
            </summary>
            <p className="mt-2 text-sm leading-relaxed text-slate-700">{current.rationale_correct}</p>
          </details>
        </div>
      ) : null}

      <div className="mt-6 flex justify-end">
        <div className="flex w-full items-center justify-between gap-3">
          <button
            type="button"
            onClick={goBack}
            disabled={index === 0}
            className="rounded-lg border border-[color:var(--cool-gray)] px-5 py-3 text-sm font-semibold text-[color:var(--brand-navy)] transition hover:border-[color:var(--brand-gold)] disabled:cursor-not-allowed disabled:text-slate-400"
          >
            Back
          </button>
          <button
            type="button"
            onClick={goNext}
            disabled={!isLocked}
            className="rounded-lg bg-[color:var(--brand-gold)] px-5 py-3 text-sm font-semibold text-[color:var(--brand-navy)] transition hover:bg-[#b5954f] disabled:cursor-not-allowed disabled:bg-slate-300 disabled:text-slate-500"
          >
            {index === total - 1 ? "Finish Quiz" : "Next Question"}
          </button>
        </div>
      </div>
    </section>
  );
}
