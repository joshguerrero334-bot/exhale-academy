import Link from "next/link";

export default function BlogCTA() {
  return (
    <section className="rounded-[2rem] border border-[color:var(--brand-gold)]/30 bg-[linear-gradient(135deg,rgba(113,201,194,0.12),rgba(255,255,255,0.95))] p-6 shadow-sm sm:p-8">
      <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Study Smarter</p>
      <h2 className="mt-3 text-2xl font-semibold text-[color:var(--brand-navy)] sm:text-3xl">
        Want more than free articles? Unlock premium questions, cases, and strategy inside Exhale.
      </h2>
      <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-700 sm:text-base">
        Ready to study smarter? Try Exhale TMC Prep and CSE practice to turn free strategy into test-day execution.
      </p>
      <div className="mt-6 flex flex-wrap gap-3">
        <Link href="/signup" className="btn-primary">Start Exhale</Link>
        <Link href="/billing" className="btn-secondary">View Subscription</Link>
      </div>
    </section>
  );
}
