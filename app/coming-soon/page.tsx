import Link from "next/link";
import { headingFont } from "../../lib/fonts";

export default function ComingSoonPage() {
  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Coming Soon</p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>
            More tools to help you pass your boards
          </h1>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
            We are building the next wave of Exhale Academy resources so you can study smarter and show up confident
            on test day. Every new tool will stay mobile friendly for study on phones, tablets, and desktop.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <Link href="/dashboard" className="btn-primary">
              Back to Dashboard
            </Link>
            <Link href="/feedback" className="btn-secondary">
              How can we get better?
            </Link>
          </div>
        </section>

        <section className="grid gap-4 md:grid-cols-3">
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <h2 className={`${headingFont} text-xl font-semibold text-charcoal`}>Study Guides</h2>
            <p className="mt-2 text-sm text-graysoft">
              Condensed, exam-focused guides for high-yield NBRC topics with clear decision pathways.
            </p>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <h2 className={`${headingFont} text-xl font-semibold text-charcoal`}>Cheat Sheets</h2>
            <p className="mt-2 text-sm text-graysoft">
              Quick-reference one-pagers for ABGs, vent settings, pediatric/neonatal norms, and critical algorithms.
            </p>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <h2 className={`${headingFont} text-xl font-semibold text-charcoal`}>Many More Features</h2>
            <p className="mt-2 text-sm text-graysoft">
              More exam simulations, targeted weak-area drills, and faster review workflows to improve pass confidence.
            </p>
          </article>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-2xl font-semibold text-charcoal`}>Why this matters</h2>
          <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
            Board prep should feel structured, practical, and modern. We are continuing to ship resources that help
            RT students and therapists perform under pressure on that big day.
          </p>
        </section>
      </div>
    </main>
  );
}
