import Link from "next/link";
import { createClient } from "../lib/supabase/server";
import { headingFont } from "../lib/fonts";

export default async function Home() {
  let isLoggedIn = false;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    isLoggedIn = !!user;
  } catch {
    isLoggedIn = false;
  }
  const primaryCtaHref = isLoggedIn ? "/dashboard" : "/signup";

  return (
    <main className="min-h-screen overflow-x-hidden bg-background text-charcoal">
      <section className="mx-auto grid w-full max-w-[1460px] lg:min-h-[calc(100vh-68px)] lg:grid-cols-[600px_1fr]">
        <div className="flex items-center justify-center bg-white px-4 py-5 sm:px-10 sm:py-8 lg:border-r lg:border-graysoft/30">
          <div className="w-full max-w-[430px] rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
            <p className="text-[11px] font-semibold uppercase tracking-[0.24em] text-primary">Exhale Academy</p>
            <h1
              className={`${headingFont} mt-2.5 text-[1.85rem] font-semibold leading-[1.15] text-charcoal sm:text-[2.15rem] lg:text-[2.3rem]`}
            >
              Start your Exhale journey
            </h1>
            <p className="mt-2.5 text-sm leading-relaxed text-graysoft">
              New here? Create your account, subscribe, and start practicing in minutes.
            </p>
            <p className="mt-1 text-sm leading-relaxed text-graysoft">
              Already subscribed? Log in to jump back into your dashboard.
            </p>

            <div className="mt-6 space-y-2.5">
              <Link href={primaryCtaHref} className="btn-primary w-full px-6 py-3 text-center text-sm">
                Create Account
              </Link>
              <Link href="/login" className="btn-secondary w-full px-6 py-3 text-center text-sm">
                Log In
              </Link>
            </div>

            <p className="mt-5 text-xs leading-relaxed text-graysoft">
              Don&apos;t spend hundreds on test prep. Don&apos;t sit in boring lectures.
              <br />
              Study smarter, anywhere.
            </p>
          </div>
        </div>

        <div className="flex items-center bg-gradient-to-br from-primary/28 via-primary/12 to-background px-4 py-8 sm:px-12 sm:py-10 lg:px-20">
          <div className="mx-auto w-full max-w-[760px] text-center lg:text-left">
            <h2
              className={`${headingFont} text-[2rem] font-semibold leading-[1.12] text-charcoal sm:text-[2.6rem] lg:text-[3.15rem]`}
            >
              Modern RT prep for TMC + CSE
            </h2>
            <p className="mx-auto mt-5 max-w-2xl text-[1.03rem] leading-[1.7] text-charcoal/90 sm:text-[1.15rem] lg:mx-0">
              Exhale Academy gives you realistic exam-style practice without outdated content, lecture fatigue, or
              overpriced prep programs. One subscription, built for today&apos;s RT students.
            </p>
            <div className="mt-6 flex justify-center lg:justify-start">
              <Link href={primaryCtaHref} className="btn-primary w-full px-6 py-3 text-center sm:w-auto">
                Start studying now
              </Link>
            </div>

            <div className="mt-8 grid gap-3.5 sm:grid-cols-2">
              <div className="rounded-xl border border-graysoft/30 bg-white/90 p-4 text-left shadow-sm">
                <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">Save More</p>
                <p className="mt-1 text-sm leading-relaxed text-charcoal">
                  No expensive bundles or $600 seminars. One affordable subscription for everything you need.
                </p>
              </div>
              <div className="rounded-xl border border-graysoft/30 bg-white/90 p-4 text-left shadow-sm">
                <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">Study Anywhere</p>
                <p className="mt-1 text-sm leading-relaxed text-charcoal">
                  Phone, tablet, laptop, or desktop friendly. Pick up where you left off from any device.
                </p>
              </div>
              <div className="rounded-xl border border-graysoft/30 bg-white/90 p-4 text-left shadow-sm">
                <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">TMC + CSE</p>
                <p className="mt-1 text-sm leading-relaxed text-charcoal">
                  500+ TMC-style questions and 20+ clinical simulations, all under one account.
                </p>
              </div>
              <div className="rounded-xl border border-graysoft/30 bg-white/90 p-4 text-left shadow-sm">
                <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">Not Outdated</p>
                <p className="mt-1 text-sm leading-relaxed text-charcoal">
                  Fresh, structured RT prep aligned with current NBRC content and real bedside practice.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 py-10 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <h3 className={`${headingFont} text-2xl font-semibold text-charcoal sm:text-3xl`}>What&apos;s inside your membership</h3>
          <p className="mt-2 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
            Everything is designed to feel like the real exam, without the noise.
          </p>
          <div className="mt-6 grid gap-4 md:grid-cols-3">
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-base font-semibold text-charcoal">TMC Question Bank</p>
              <p className="mt-2 text-sm leading-relaxed text-graysoft">
                500+ NBRC-style questions with detailed rationales. Practice by category or take mixed exams to mimic
                the real TMC.
              </p>
            </article>
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-base font-semibold text-charcoal">CSE Clinical Simulations</p>
              <p className="mt-2 text-sm leading-relaxed text-graysoft">
                20+ branching cases that walk you through information-gathering and decision-making just like the CSE.
                See how each choice helps, hurts, or delays patient care.
              </p>
            </article>
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-base font-semibold text-charcoal">Tutor &amp; Exam Modes</p>
              <p className="mt-2 text-sm leading-relaxed text-graysoft">
                Use Tutor Mode to see rationales as you go, or Exam Mode to simulate test day timing and pressure.
                Build confidence first, then pressure-test your knowledge.
              </p>
            </article>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-10 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <h3 className={`${headingFont} text-2xl font-semibold text-charcoal sm:text-3xl`}>What students are saying</h3>
          <p className="mt-2 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
            Early users are already telling us Exhale feels different from the usual RT prep.
          </p>
          <div className="mt-6 grid gap-4 md:grid-cols-3">
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm leading-relaxed text-charcoal">
                &ldquo;These cases feel exactly like what my preceptor talks about. Way better than just reading
                notes.&rdquo;
              </p>
              <p className="mt-3 text-xs font-semibold uppercase tracking-[0.14em] text-primary">CSE Candidate</p>
            </article>
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm leading-relaxed text-charcoal">
                &ldquo;I love being able to drill oxygenation one day and then take a full mixed test the
                next.&rdquo;
              </p>
              <p className="mt-3 text-xs font-semibold uppercase tracking-[0.14em] text-primary">TMC Student</p>
            </article>
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm leading-relaxed text-charcoal">
                &ldquo;Clean, simple, and not overwhelming. I actually want to log in and practice.&rdquo;
              </p>
              <p className="mt-3 text-xs font-semibold uppercase tracking-[0.14em] text-primary">New Grad RT</p>
            </article>
          </div>
        </div>
      </section>

      <section className="border-y border-graysoft/30 bg-primary/12">
        <div className="mx-auto w-full max-w-[1460px] px-4 py-6 text-center sm:px-10 lg:px-20">
          <p className={`${headingFont} text-lg font-semibold text-charcoal sm:text-xl`}>
            Built by working respiratory therapists, not a generic test-prep company.
          </p>
          <p className="mt-2 text-sm text-graysoft sm:text-base">
            Exhale Academy was created by RTs who wanted modern, honest, and affordable prep for the TMC and CSE.
          </p>
        </div>
      </section>
    </main>
  );
}
