import type { Metadata } from "next";
import Link from "next/link";
import SlideDeckViewer from "../../components/slideshows/SlideDeckViewer";
import { headingFont } from "../../lib/fonts";
import { cseCheatSheetsSlideshowDeck } from "../../lib/slideshows";

export const metadata: Metadata = {
  title: "Free CSE Slideshows for Respiratory Therapy Students | Exhale Academy",
  description:
    "Study free CSE slideshow guides for respiratory therapy exam prep, then unlock Exhale Academy for full CSE clinical simulations, TMC practice questions, and flashcards.",
  keywords: [
    "free CSE slideshows",
    "CSE prep",
    "CSE exam prep",
    "CSE clinical simulations",
    "respiratory therapy test prep",
    "respiratory therapy exam prep",
    "TMC prep",
    "TMC practice questions",
    "respiratory therapy study guides",
  ],
  alternates: {
    canonical: "/free-cse-slideshows",
  },
};

const categories = Array.from(new Set(cseCheatSheetsSlideshowDeck.slides.map((slide) => slide.category ?? "Review")));

export default function FreeCseSlideshowsPage() {
  return (
    <main className="min-h-screen overflow-x-hidden bg-background text-charcoal">
      <section className="relative border-b border-primary/20 bg-[radial-gradient(circle_at_top_left,_rgba(103,208,204,0.28),_transparent_38%),linear-gradient(135deg,#ffffff_0%,#f6fbfb_58%,#eef8f7_100%)]">
        <div className="mx-auto grid w-full max-w-[1460px] gap-8 px-4 py-10 sm:px-10 lg:grid-cols-[1.05fr,0.95fr] lg:px-20 lg:py-16">
          <div className="flex flex-col justify-center">
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-primary">
              Free CSE Slideshow Preview
            </p>
            <h1
              className={`${headingFont} mt-3 text-4xl font-semibold leading-[1.05] text-charcoal sm:text-5xl lg:text-6xl`}
            >
              Free CSE study slides for respiratory therapy students
            </h1>
            <p className="mt-5 max-w-2xl text-base leading-relaxed text-charcoal/85 sm:text-lg">
              Review visual CSE cheat sheets for information gathering, decision making, emergency patterns,
              pediatric clues, disease recognition, and board-style respiratory therapy exam prep.
            </p>
            <p className="mt-3 max-w-2xl text-sm leading-relaxed text-graysoft sm:text-base">
              These slides help you recognize the patterns. The full Exhale Academy subscription lets you practice them
              with realistic CSE clinical simulations, TMC practice questions, flashcards, and full exam tools.
            </p>
            <div className="mt-7 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
              <Link href="#free-slides" className="btn-primary px-6 py-3 text-center">
                Start Free Slides
              </Link>
              <Link href="/signup" className="btn-secondary px-6 py-3 text-center">
                Create Account
              </Link>
              <Link href="/preview/cse-scenarios" className="btn-secondary px-6 py-3 text-center">
                Try 2 Free CSE Cases
              </Link>
            </div>
          </div>

          <div className="rounded-[28px] border border-graysoft/30 bg-white/90 p-5 shadow-sm sm:p-7">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">What You Get Free</p>
            <div className="mt-4 grid gap-3">
              <article className="rounded-2xl border border-graysoft/25 bg-background p-4">
                <p className="text-3xl font-semibold text-charcoal">{cseCheatSheetsSlideshowDeck.slideCount}</p>
                <p className="mt-1 text-sm font-semibold text-charcoal">Visual CSE study slides</p>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">
                  Organized into strategy, disease patterns, emergency care, pediatrics, and neuro/systemic review.
                </p>
              </article>
              <article className="rounded-2xl border border-primary/25 bg-primary/10 p-4">
                <p className="text-sm font-semibold text-charcoal">Free preview, focused access</p>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">
                  This page gives students the slideshows only. Full TMC prep, CSE practice, and flashcards stay inside
                  the membership.
                </p>
              </article>
              <article className="rounded-2xl border border-amber-200 bg-amber-50 p-4">
                <p className="text-sm font-semibold text-amber-900">Do not stop at recognition</p>
                <p className="mt-2 text-sm leading-relaxed text-amber-900/80">
                  The CSE rewards correct decisions under pressure. Use the slides, then practice the full cases before
                  exam day sneaks up on you.
                </p>
              </article>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 py-8 sm:px-10 lg:px-20">
        <div className="grid gap-4 md:grid-cols-3">
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Step 1</p>
            <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>Review the slides</h2>
            <p className="mt-2 text-sm leading-relaxed text-graysoft">
              Build fast CSE pattern recognition before you jump into full simulations.
            </p>
          </article>
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Step 2</p>
            <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>Try free cases</h2>
            <p className="mt-2 text-sm leading-relaxed text-graysoft">
              See how the Exhale CSE engine feels with two fixed clinical simulation previews.
            </p>
          </article>
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Step 3</p>
            <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>Unlock full prep</h2>
            <p className="mt-2 text-sm leading-relaxed text-graysoft">
              Practice TMC questions, full CSE simulations, flashcards, and board-focused review in one place.
            </p>
          </article>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-8 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Organized For CSE Prep</p>
          <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            Pick a category, then review the slide deck
          </h2>
          <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {categories.map((category) => {
              const count = cseCheatSheetsSlideshowDeck.slides.filter((slide) => slide.category === category).length;

              return (
                <article key={category} className="rounded-xl border border-primary/20 bg-background p-4">
                  <p className="text-sm font-semibold text-charcoal">{category}</p>
                  <p className="mt-1 text-xs font-semibold uppercase tracking-[0.14em] text-primary">
                    {count} {count === 1 ? "slide" : "slides"}
                  </p>
                </article>
              );
            })}
          </div>
        </div>
      </section>

      <section id="free-slides" className="mx-auto w-full max-w-[1460px] px-4 pb-8 sm:px-10 lg:px-20">
        <SlideDeckViewer slides={cseCheatSheetsSlideshowDeck.slides} />
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-10 sm:px-10 lg:px-20">
        <div className="overflow-hidden rounded-[28px] border border-primary/25 bg-[linear-gradient(135deg,#ffffff_0%,#f6fbfb_50%,#e8f7f6_100%)] p-6 shadow-sm sm:p-8">
          <div className="grid gap-6 lg:grid-cols-[1fr,0.9fr] lg:items-center">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">
                Ready For The Full Engine?
              </p>
              <h2 className={`${headingFont} mt-2 text-3xl font-semibold leading-tight text-charcoal sm:text-4xl`}>
                The slides teach the clues. The full site trains the decisions.
              </h2>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Exhale Academy gives respiratory therapy students TMC prep, TMC practice questions, CSE exam prep,
                realistic CSE clinical simulations, and high-yield flashcards built for board review.
              </p>
            </div>
            <div className="flex flex-col gap-3">
              <Link href="/signup" className="btn-primary px-6 py-3 text-center">
                Create Account and Subscribe
              </Link>
              <Link href="/preview/tmc-practice-questions" className="btn-secondary px-6 py-3 text-center">
                Try 10 Free TMC Questions
              </Link>
              <Link href="/preview/flashcards" className="btn-secondary px-6 py-3 text-center">
                Try Free Flashcards
              </Link>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
