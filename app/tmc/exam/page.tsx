import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../../components/PracticeSwitchBar";
import { createClient } from "../../../lib/supabase/server";
import { startMasterAttempt } from "../../master/actions";

export default async function TmcExamIntroPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Ftmc%2Fexam");
  }

  return (
    <main className="page-shell">
      <PracticeSwitchBar active="tmc" cseHref="/cse/introduction" tmcHref="/tmc" />

      <div className="mx-auto w-full max-w-4xl space-y-6 pt-4">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <h1 className="text-3xl font-bold text-[color:var(--brand-navy)]">TMC 160 Practice Exam</h1>
          <p className="mt-2 text-sm text-slate-600 sm:text-base">
            Full-length mixed exam designed to simulate high-yield TMC decision flow across all active categories.
          </p>

          <p className="mt-5 text-sm leading-relaxed text-slate-700">
            This 160-question set is built to sharpen test-day pacing, reinforce clinical reasoning, and reveal weak
            areas before your real exam. Choose Tutor Mode if you want immediate feedback and rationale while you
            practice. Choose Exam Mode if you want a strict simulation with feedback only at the end.
          </p>

          <div className="mt-6 grid gap-4 sm:grid-cols-2">
            <article className="rounded-xl border border-[color:var(--brand-gold)] bg-[color:var(--surface-soft)] p-4">
              <h2 className="text-base font-semibold text-[color:var(--brand-navy)]">Tutor Mode</h2>
              <ul className="mt-2 list-disc space-y-1 pl-5 text-sm text-slate-700">
                <li>Immediate correctness after each answer</li>
                <li>Rationale shown while progressing</li>
                <li>Best for active learning and remediation</li>
              </ul>
            </article>

            <article className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <h2 className="text-base font-semibold text-[color:var(--brand-navy)]">Exam Mode</h2>
              <ul className="mt-2 list-disc space-y-1 pl-5 text-sm text-slate-700">
                <li>No correctness shown during attempt</li>
                <li>Results and review shown at completion</li>
                <li>Best for realistic performance simulation</li>
              </ul>
            </article>
          </div>

          <div className="mt-6 flex flex-col gap-3 sm:flex-row">
            <form action={startMasterAttempt}>
              <input type="hidden" name="mode" value="tutor" />
              <button className="inline-flex items-center justify-center rounded-lg bg-[color:var(--brand-gold)] px-5 py-3 text-sm font-semibold text-[color:var(--brand-navy)] transition hover:bg-[#b5954f]">
                Start Tutor Mode
              </button>
            </form>

            <form action={startMasterAttempt}>
              <input type="hidden" name="mode" value="exam" />
              <button className="inline-flex items-center justify-center rounded-lg border border-[color:var(--brand-gold)] px-5 py-3 text-sm font-semibold text-[color:var(--brand-navy)] transition hover:bg-[color:var(--brand-gold)]/10">
                Start Exam Mode
              </button>
            </form>
          </div>
        </section>
      </div>
    </main>
  );
}
