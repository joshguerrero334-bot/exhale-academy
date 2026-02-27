import { headingFont } from "../../lib/fonts";

export default function AboutPage() {
  return (
    <main className="min-h-screen bg-background text-charcoal">
      <section className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">About Us</p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>
            Why Exhale Academy exists
          </h1>
          <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
            Exhale Academy was built to give respiratory therapy students a modern, realistic, and efficient way to
            prepare for the TMC and CSE exams. We focus on clinical reasoning, not memorization, and we remove the
            clutter that makes studying harder than it should be.
          </p>
        </div>

        <div className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-2xl font-semibold text-charcoal`}>What makes us different</h2>
          <ul className="mt-4 space-y-2 text-sm text-charcoal sm:text-base">
            <li>• Evidence-based, exam-aligned RT prep</li>
            <li>• Realistic branching CSE scenarios with IG/DM flow</li>
            <li>• Structured TMC categories plus full 160-question exams</li>
            <li>• Tutor mode and exam mode for different study goals</li>
            <li>• Mobile-friendly access from anywhere</li>
          </ul>
        </div>

        <div className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-2xl font-semibold text-charcoal`}>Our mission</h2>
          <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
            We want every RT student to feel prepared, confident, and clinically sharp on test day and beyond. Exhale
            Academy is built by people who understand the pressure and want to raise the standard for RT education.
          </p>
        </div>
      </section>
    </main>
  );
}

