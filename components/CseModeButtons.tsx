import Link from "next/link";

type CseModeButtonsProps = {
  tutorHref: string;
  examHref: string;
};

export default function CseModeButtons({ tutorHref, examHref }: CseModeButtonsProps) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <Link
        href={tutorHref}
        className="rounded-xl border border-primary/40 bg-background p-4 transition hover:bg-primary/5"
        aria-pressed="true"
      >
        <p className="text-sm font-semibold text-primary">Tutor Mode</p>
        <p className="mt-1 text-xs text-graysoft">Feedback as you progress through each step.</p>
      </Link>
      <Link
        href={examHref}
        className="rounded-xl border border-primary/40 bg-background p-4 transition hover:bg-primary/5"
        aria-pressed="false"
      >
        <p className="text-sm font-semibold text-primary">Exam Mode</p>
        <p className="mt-1 text-xs text-graysoft">Simulated pressure with results at the end.</p>
      </Link>
    </div>
  );
}
