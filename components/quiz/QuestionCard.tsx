"use client";

type QuestionCardProps = {
  stem: string;
  options: Array<{ label: "A" | "B" | "C" | "D"; text: string }>;
  selectedAnswer: "A" | "B" | "C" | "D" | null;
  correctAnswer: "A" | "B" | "C" | "D";
  locked: boolean;
  onSelect: (label: "A" | "B" | "C" | "D") => void;
};

export default function QuestionCard({
  stem,
  options,
  selectedAnswer,
  correctAnswer,
  locked,
  onSelect,
}: QuestionCardProps) {
  return (
    <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm sm:p-8">
      <h2 className="text-lg font-semibold leading-relaxed text-[color:var(--text)] sm:text-xl">{stem}</h2>

      <div className="mt-5 space-y-3">
        {options.map((option) => {
          const isSelected = selectedAnswer === option.label;
          const isCorrect = correctAnswer === option.label;

          let style =
            "border-[color:var(--border)] bg-[color:var(--surface)] hover:border-[color:var(--brand-gold)]";
          if (locked && isCorrect) {
            style = "border-emerald-500 bg-emerald-50";
          } else if (locked && isSelected && !isCorrect) {
            style = "border-red-500 bg-red-50";
          } else if (isSelected) {
            style = "border-[color:var(--brand-navy)] bg-slate-50";
          }

          return (
            <button
              key={option.label}
              type="button"
              onClick={() => onSelect(option.label)}
              disabled={locked}
              className={`w-full rounded-xl border px-4 py-4 text-left text-sm transition-all duration-200 ${style} ${locked ? "cursor-default" : "cursor-pointer"}`}
            >
              <span className="mr-2 font-semibold text-[color:var(--brand-navy)]">{option.label}.</span>
              <span className="text-[color:var(--text)]">{option.text}</span>
            </button>
          );
        })}
      </div>
    </section>
  );
}
