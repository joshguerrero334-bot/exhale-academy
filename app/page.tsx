import type { Metadata } from "next";
import Link from "next/link";
import { createClient } from "../lib/supabase/server";
import { headingFont } from "../lib/fonts";

export const metadata: Metadata = {
  title: "Respiratory Therapy Test Prep for TMC and CSE",
  description:
    "Exhale Academy is a respiratory therapy test prep platform with TMC prep, TMC practice exams, TMC practice questions, CSE exam prep, CSE clinical simulations, TMC flashcards, and respiratory therapy flashcards.",
  keywords: [
    "respiratory therapy test prep",
    "respiratory therapy exam prep",
    "TMC prep",
    "TMC exam prep",
    "TMC practice exam",
    "TMC practice questions",
    "TMC question bank",
    "CSE prep",
    "CSE exam prep",
    "CSE clinical simulations",
    "TMC flashcards",
    "respiratory therapy flashcards",
    "free TMC practice questions",
    "free CSE clinical simulation preview",
    "free respiratory therapy flashcards",
  ],
  alternates: {
    canonical: "/",
  },
};

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
              Respiratory therapy test prep built for TMC and CSE success
            </h1>
            <p className="mt-2.5 text-sm leading-relaxed text-graysoft">
              New here? Create your account, subscribe, and start your respiratory therapy exam prep in minutes.
            </p>
            <p className="mt-1 text-sm leading-relaxed text-graysoft">
              Already subscribed? Log in to jump back into your Exhale Hub, TMC prep, CSE prep, and flashcards.
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
              Modern respiratory therapy exam prep for TMC + CSE
            </h2>
            <p className="mx-auto mt-5 max-w-2xl text-[1.03rem] leading-[1.7] text-charcoal/90 sm:text-[1.15rem] lg:mx-0">
              Exhale Academy gives you respiratory therapy test prep that feels modern, realistic, and useful. Build
              confidence with TMC prep, TMC practice questions, a focused TMC question bank, CSE prep, and realistic
              CSE clinical simulations in one place.
            </p>
            <div className="mt-6 flex flex-col justify-center gap-3 sm:flex-row lg:justify-start">
              <Link href={primaryCtaHref} className="btn-primary w-full px-6 py-3 text-center sm:w-auto">
                Start studying now
              </Link>
              <Link href="/blog" className="btn-secondary w-full px-6 py-3 text-center sm:w-auto">
                Read the Free Blog
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
                  TMC exam prep with 500+ TMC practice questions plus CSE exam prep with 20+ clinical simulations.
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
        <div className="overflow-hidden rounded-[28px] border border-primary/25 bg-[radial-gradient(circle_at_top_left,_rgba(103,208,204,0.24),_transparent_42%),linear-gradient(135deg,#ffffff_0%,#f6fbfb_55%,#eef8f7_100%)] p-5 shadow-sm sm:p-8">
          <div className="grid gap-6 lg:grid-cols-[1.05fr,1fr] lg:items-center">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-primary">Try Exhale For Free</p>
              <h3 className={`${headingFont} mt-2 text-3xl font-semibold leading-tight text-charcoal sm:text-4xl`}>
                Preview the inside before you subscribe
              </h3>
              <p className="mt-3 max-w-2xl text-sm leading-relaxed text-graysoft sm:text-base">
                Try a fixed free sample of Exhale Academy&apos;s respiratory therapy exam prep: 10 free TMC practice
                questions, 2 real CSE clinical simulation previews, and 10 free respiratory therapy flashcards.
                The preview stays the same every time, so students can see the product without exposing the full
                TMC question bank, Master CSE case pool, or flashcard library.
              </p>
              <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
                <Link href="/preview/tmc-practice-questions" className="btn-primary px-6 py-3 text-center">
                  Try 10 Free TMC Questions
                </Link>
                <Link href="/preview/cse-scenarios" className="btn-secondary px-6 py-3 text-center">
                  Preview 2 CSE Cases
                </Link>
                <Link href="/preview/flashcards" className="btn-secondary px-6 py-3 text-center">
                  Try 10 Free Flashcards
                </Link>
                <Link href="/free-cse-pdf-guides" className="btn-secondary px-6 py-3 text-center">
                  Download Free CSE PDFs
                </Link>
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-3 lg:grid-cols-1">
              <article className="rounded-2xl border border-graysoft/25 bg-white/90 p-4 shadow-sm">
                <p className="text-2xl font-semibold text-charcoal">10</p>
                <p className="mt-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary">Free TMC Questions</p>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">
                  Board-style questions with answer reveal and rationale.
                </p>
              </article>
              <article className="rounded-2xl border border-graysoft/25 bg-white/90 p-4 shadow-sm">
                <p className="text-2xl font-semibold text-charcoal">2</p>
                <p className="mt-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary">Real CSE Cases</p>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">
                  Fixed full-case previews using the same branching case content.
                </p>
              </article>
              <article className="rounded-2xl border border-graysoft/25 bg-white/90 p-4 shadow-sm">
                <p className="text-2xl font-semibold text-charcoal">10</p>
                <p className="mt-1 text-xs font-semibold uppercase tracking-[0.16em] text-primary">Free Flashcards</p>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">
                  One-click cards for fast respiratory therapy board review.
                </p>
              </article>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 py-10 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <h3 className={`${headingFont} text-2xl font-semibold text-charcoal sm:text-3xl`}>What&apos;s inside your membership</h3>
          <p className="mt-2 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
            Everything is designed to support respiratory therapy exam prep with realistic practice, quick review, and
            clean study tools.
          </p>
          <div className="mt-6 grid gap-4 md:grid-cols-3">
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-base font-semibold text-charcoal">TMC Question Bank</p>
              <p className="mt-2 text-sm leading-relaxed text-graysoft">
                500+ NBRC-style questions with detailed rationales. Use the TMC question bank for category drills, TMC
                practice questions, and full TMC practice exam sessions.
              </p>
            </article>
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-base font-semibold text-charcoal">CSE Clinical Simulations</p>
              <p className="mt-2 text-sm leading-relaxed text-graysoft">
                CSE prep built around realistic branching cases. Practice CSE clinical simulations that train
                information-gathering, decision-making, and bedside logic.
              </p>
            </article>
            <article className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-base font-semibold text-charcoal">TMC Flashcards + RT Flashcards</p>
              <p className="mt-2 text-sm leading-relaxed text-graysoft">
                Review TMC flashcards and respiratory therapy flashcards for disease patterns, oxygen devices, PFTs,
                and fast board-style recall on any device.
              </p>
            </article>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-10 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div className="max-w-3xl">
              <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">Why Students Choose Exhale</p>
              <h3 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
                TMC prep, CSE prep, and flashcards that work together
              </h3>
              <p className="mt-2 text-sm leading-relaxed text-graysoft sm:text-base">
                Most respiratory therapy test prep platforms force students to bounce between scattered tools. Exhale
                keeps everything connected, so you can move from TMC practice questions to CSE clinical simulations to
                respiratory therapy flashcards without losing momentum.
              </p>
            </div>
            <div className="grid w-full gap-3 sm:grid-cols-2 lg:max-w-[420px]">
              <Link href="/tmc" className="rounded-xl border border-graysoft/30 bg-background px-4 py-4 text-sm font-semibold text-charcoal transition hover:border-primary hover:bg-primary/5">
                Explore TMC Prep
              </Link>
              <Link href="/cse/master" className="rounded-xl border border-graysoft/30 bg-background px-4 py-4 text-sm font-semibold text-charcoal transition hover:border-primary hover:bg-primary/5">
                Explore CSE Prep
              </Link>
              <Link href="/flashcards" className="rounded-xl border border-graysoft/30 bg-background px-4 py-4 text-sm font-semibold text-charcoal transition hover:border-primary hover:bg-primary/5">
                Study TMC Flashcards
              </Link>
              <Link href="/blog" className="rounded-xl border border-graysoft/30 bg-background px-4 py-4 text-sm font-semibold text-charcoal transition hover:border-primary hover:bg-primary/5">
                Read Free RT Articles
              </Link>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-10 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">Free Education</p>
              <h3 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>Start with the Exhale blog</h3>
              <p className="mt-2 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
                Read free articles on TMC prep, TMC exam prep, CSE prep, ABGs, ventilator management, and bedside
                reasoning before you ever subscribe.
              </p>
            </div>
            <Link href="/blog" className="btn-secondary w-full px-6 py-3 text-center md:w-auto">
              Explore the Blog
            </Link>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-10 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <h3 className={`${headingFont} text-2xl font-semibold text-charcoal sm:text-3xl`}>What students are saying</h3>
          <p className="mt-2 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
            Early users are already telling us Exhale feels different from the usual respiratory therapy exam prep.
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
            Exhale Academy was created by RTs who wanted modern, honest, and affordable respiratory therapy test prep
            for the TMC and CSE.
          </p>
        </div>
      </section>
    </main>
  );
}
