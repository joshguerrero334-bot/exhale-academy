import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import SlideDeckViewer from "../../../components/slideshows/SlideDeckViewer";
import { copdSlideshowDeck } from "../../../lib/slideshows";
import { headingFont } from "../../../lib/fonts";
import { createClient } from "../../../lib/supabase/server";

export const metadata: Metadata = {
  title: "COPD Slideshow for Respiratory Therapy Students",
  description:
    "COPD visual slideshow for TMC and CSE prep covering symptoms, causes, diagnostics, interventions, and board exam reminders.",
};

export default async function CopdSlideshowPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fslideshows%2Fcopd");
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Respiratory Disease Slideshow</p>
          <div className="mt-3 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-3xl">
              <h1 className={`${headingFont} text-3xl font-semibold text-charcoal sm:text-4xl`}>
                COPD Visual Slideshow
              </h1>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Review COPD as a board-style disease pattern: chronic airflow limitation, smoking history, air trapping,
                obstructive PFT clues, and respiratory therapy interventions.
              </p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link href="/slideshows" className="btn-secondary">
                Back to Slideshows
              </Link>
              <Link href="/flashcards/respiratory-disease-patterns" className="btn-primary">
                Study Disease Flashcards
              </Link>
            </div>
          </div>
        </section>

        <SlideDeckViewer slides={copdSlideshowDeck.slides} />

        <section className="rounded-2xl border border-primary/20 bg-white p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Board Prep Reminder</p>
          <p className="mt-2 text-sm leading-relaxed text-graysoft">
            For COPD questions, look for smoking history, chronic cough or sputum, decreased FEV1/FVC, increased RV and
            TLC, flattened diaphragm, and cautious oxygen titration when CO2 retention is a concern.
          </p>
        </section>
      </div>
    </main>
  );
}
