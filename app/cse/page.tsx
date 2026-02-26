import Link from "next/link";
import PracticeSwitchBar from "../../components/PracticeSwitchBar";
import { headingFont } from "../../lib/fonts";

export default function CsePage() {
  return (
    <main className="min-h-screen bg-background text-charcoal">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h1 className={`${headingFont} text-3xl font-semibold text-charcoal`}>Clinical Simulation Exam (CSE)</h1>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            Exhale Academy CSE is built to train clinical judgment, not memorization. Each scenario progresses in a
            true branching flow where your information-gathering and decision-making choices directly change the
            patient response and next step.
          </p>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            Use Tutor Mode to see step-level rationale and score feedback, or Exam Mode to simulate test pressure with
            delayed scoring details at the end. Every case follows NBRC-style STOP progression with realistic patient
            reactions.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <Link href="/dashboard" className="btn-secondary">
              Start Practicing
            </Link>
            <Link href="/billing" className="btn-primary">
              Unlock Full Access
            </Link>
            <Link href="/cse/master" className="btn-primary">
              Start Master CSE
            </Link>
            <Link href="/cse/cases" className="btn-secondary">
              Browse Cases
            </Link>
            <Link href="/feedback" className="btn-secondary">
              How can we get better?
            </Link>
          </div>
        </section>
      </div>
    </main>
  );
}
