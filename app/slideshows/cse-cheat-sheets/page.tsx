import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import SlideDeckViewer from "../../../components/slideshows/SlideDeckViewer";
import { headingFont } from "../../../lib/fonts";
import { createClient } from "../../../lib/supabase/server";
import { cseCheatSheetsSlideshowDeck } from "../../../lib/slideshows";

export const metadata: Metadata = {
  title: "CSE Cheat Sheet Slideshows for Respiratory Therapy Students",
  description:
    "CSE cheat sheet slideshows for respiratory therapy students covering information gathering, decision making, emergencies, pediatrics, and disease recognition.",
};

const categories = Array.from(new Set(cseCheatSheetsSlideshowDeck.slides.map((slide) => slide.category ?? "Review")));

export default async function CseCheatSheetsSlideshowPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fslideshows%2Fcse-cheat-sheets");
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">CSE Visual Review</p>
          <div className="mt-3 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-3xl">
              <h1 className={`${headingFont} text-3xl font-semibold text-charcoal sm:text-4xl`}>
                CSE Cheat Sheet Slideshows
              </h1>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Use these visual CSE study guides to review clinical simulation structure, information gathering,
                decision making, emergency patterns, pediatric clues, and high-yield respiratory disease scenarios.
              </p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link href="/slideshows" className="btn-secondary">
                Back to Slideshows
              </Link>
              <Link href="/cse/introduction" className="btn-primary">
                Start CSE Practice
              </Link>
            </div>
          </div>
        </section>

        <section className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {categories.map((category) => {
            const count = cseCheatSheetsSlideshowDeck.slides.filter((slide) => slide.category === category).length;

            return (
              <article key={category} className="rounded-2xl border border-primary/20 bg-white p-5 shadow-sm">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Study Category</p>
                <h2 className="mt-2 text-lg font-semibold text-charcoal">{category}</h2>
                <p className="mt-2 text-sm text-graysoft">
                  {count} {count === 1 ? "slide" : "slides"}
                </p>
              </article>
            );
          })}
        </section>

        <SlideDeckViewer slides={cseCheatSheetsSlideshowDeck.slides} />

        <section className="rounded-2xl border border-primary/20 bg-white p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">How to Use These</p>
          <p className="mt-2 text-sm leading-relaxed text-graysoft">
            Start with the CSE strategy slides, then review tests and ventilation decisions before moving into disease
            patterns, emergency cases, pediatric scenarios, and neuro/systemic conditions.
          </p>
        </section>
      </div>
    </main>
  );
}
