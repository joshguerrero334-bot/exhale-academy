import { createClient } from "../lib/supabase/server";
import { headingFont } from "../lib/fonts";

export default async function Home() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const startHref = user ? "/billing" : "/login?next=%2Fbilling";

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <section className="mx-auto w-full max-w-5xl px-4 pb-10 pt-10 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-8 shadow-sm sm:p-12">
          <p className="text-xs font-semibold uppercase tracking-[0.24em] text-primary">Exhale Academy</p>
          <h1 className={`${headingFont} mt-4 text-4xl font-semibold leading-tight text-charcoal sm:text-5xl`}>
            Welcome to Exhale Academy
          </h1>
          <p className="mt-4 max-w-3xl text-base leading-relaxed text-graysoft sm:text-lg">
            At Exhale Academy, we believe every respiratory therapist deserves the confidence, clarity, and mastery
            required to succeed, not only on the TMC and CSE examinations, but throughout an entire healthcare career.
          </p>
          <p className="mt-4 max-w-3xl text-base leading-relaxed text-graysoft sm:text-lg">
            We built this platform to solve a problem every RT student and working therapist has faced:
            information overload, outdated study materials, inconsistent teaching, and a lack of truly realistic exam
            preparation. Exhale Academy is fully mobile friendly so you can study anywhere.
          </p>
          <p className="mt-4 text-base font-semibold text-charcoal">We are here to change that.</p>

          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <a href={startHref} className="btn-primary px-6 py-3">
              Start Practicing
            </a>
            <a href="/billing" className="btn-primary px-6 py-3">
              Subscribe Now
            </a>
            <a href="/login" className="btn-secondary px-6 py-3">
              Log In
            </a>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-5xl px-4 pb-10 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-2xl font-semibold text-charcoal`}>Why We Created Exhale Academy</h2>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            Respiratory therapy is a profession built on precision, critical thinking, and calm under pressure. Yet
            the path to becoming a confident, competent therapist often feels overwhelming and unnecessarily
            complicated.
          </p>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            Exhale Academy was created to give students a clean, modern, distraction-free learning experience backed
            by:
          </p>
          <ul className="mt-4 space-y-2 text-sm text-charcoal sm:text-base">
            <li>• High-quality, evidence-based exam prep</li>
            <li>• Realistic TMC &amp; CSE simulations that mirror the NBRC blueprint</li>
            <li>• Scenario-based training that teaches not just memorization, but clinical reasoning</li>
            <li>• Tutor-mode and exam-mode options for every learning style</li>
            <li>• A structured, stress-free approach to RT mastery</li>
          </ul>
          <p className="mt-4 text-sm font-medium text-charcoal sm:text-base">
            No ads. No clutter. No wasted time. Just the material you actually need.
          </p>
        </div>
      </section>

      <section className="mx-auto w-full max-w-5xl px-4 pb-10 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-2xl font-semibold text-charcoal`}>What You&apos;ll Find Inside</h2>

          <div className="mt-6 grid gap-4 md:grid-cols-3">
            <article className="rounded-xl border border-graysoft/30 bg-background p-5">
              <h3 className="text-lg font-semibold text-charcoal">TMC Practice System</h3>
              <ul className="mt-3 space-y-1 text-sm text-graysoft">
                <li>• 500 high-quality questions</li>
                <li>• Category-based organization</li>
                <li>• Full 160-question TMC-style exam</li>
                <li>• Tutor Mode with rationales</li>
                <li>• Exam Mode with realistic pressure</li>
              </ul>
            </article>

            <article className="rounded-xl border border-graysoft/30 bg-background p-5">
              <h3 className="text-lg font-semibold text-charcoal">CSE Clinical Simulation Training</h3>
              <ul className="mt-3 space-y-1 text-sm text-graysoft">
                <li>• Multi-step branching scenarios</li>
                <li>• NBRC-style IG &amp; DM structure</li>
                <li>• Dynamic vitals based on decisions</li>
                <li>• Feedback for clinical reasoning</li>
                <li>• Neonatal, pediatric, trauma, airway, and critical care cases</li>
              </ul>
            </article>

            <article className="rounded-xl border border-graysoft/30 bg-background p-5">
              <h3 className="text-lg font-semibold text-charcoal">Clean, Professional UX</h3>
              <ul className="mt-3 space-y-1 text-sm text-graysoft">
                <li>• Designed to reduce stress and decision fatigue</li>
                <li>• Simple navigation and clear pathways</li>
                <li>• Mobile-friendly for study anywhere</li>
                <li>• Built with modern tools for speed and reliability</li>
              </ul>
            </article>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-5xl px-4 pb-10 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-2xl font-semibold text-charcoal`}>Our Mission</h2>
          <ul className="mt-4 space-y-2 text-sm text-charcoal sm:text-base">
            <li>• Breathe easier during exam prep</li>
            <li>• Understand the “why” behind the answer</li>
            <li>• Develop real-world confidence, not just test-taking habits</li>
            <li>• Step into the profession ready to think, lead, and save lives</li>
          </ul>
          <p className="mt-5 text-sm font-medium text-charcoal sm:text-base">
            We&apos;re not here to be another RT website. We&apos;re here to raise the standard.
          </p>
        </div>
      </section>

      <section className="mx-auto w-full max-w-5xl px-4 pb-10 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-2xl font-semibold text-charcoal`}>Who We Are</h2>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            We are a team of healthcare professionals, educators, and developers who understand the journey.
            We&apos;ve lived the long shifts, the burnout, the anxiety before big exams, and the drive to build a better
            future.
          </p>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            Exhale Academy was built from clinical experience, educational gaps we wished someone fixed, and a deep
            commitment to helping the next generation of RTs succeed.
          </p>
          <p className="mt-4 text-sm font-medium text-charcoal sm:text-base">
            No corporate backing. No hidden agenda. Just purpose-built RT training.
          </p>
        </div>
      </section>

      <section className="mx-auto w-full max-w-5xl px-4 pb-14 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-8 text-center shadow-sm">
          <h2 className={`${headingFont} text-2xl font-semibold text-charcoal sm:text-3xl`}>Our Promise</h2>
          <ul className="mx-auto mt-4 max-w-2xl space-y-2 text-sm text-charcoal sm:text-base">
            <li>• Accurate</li>
            <li>• Modern</li>
            <li>• Evidence-based</li>
            <li>• Affordable</li>
            <li>• Free of distractions</li>
            <li>• Built for your success</li>
          </ul>
          <p className="mx-auto mt-4 max-w-2xl text-sm text-graysoft sm:text-base">
            Your only job here is to learn, grow, and breathe easy. We&apos;ll take care of the rest.
          </p>
          <a href="/billing" className="btn-primary mt-6 px-6 py-3">
            Subscribe and Start
          </a>
        </div>
      </section>

      <footer className="border-t border-graysoft/30 bg-white px-4 py-8 sm:px-6">
        <div className="mx-auto flex w-full max-w-5xl flex-col items-center justify-between gap-4 sm:flex-row">
          <nav className="flex flex-wrap items-center justify-center gap-x-5 gap-y-2 text-sm text-graysoft">
            <a href="/login" className="hover:text-primary">Login</a>
            <a href="/signup" className="hover:text-primary">Sign Up</a>
            <a href="/coming-soon" className="hover:text-primary">Coming Soon</a>
            <a href="/feedback" className="hover:text-primary">How can we get better?</a>
            <a href="/privacy" className="hover:text-primary">Privacy</a>
            <a href="/terms" className="hover:text-primary">Terms</a>
          </nav>
          <p className="text-xs text-graysoft">© Exhale Academy</p>
        </div>
      </footer>
    </main>
  );
}
