import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import SlideDeckViewer from "../../../components/slideshows/SlideDeckViewer";
import { asthmaSlideshowDeck } from "../../../lib/slideshows";
import { headingFont } from "../../../lib/fonts";
import { createClient } from "../../../lib/supabase/server";

export const metadata: Metadata = {
  title: "Asthma Slideshow for Respiratory Therapy Students",
  description:
    "Asthma visual slideshow for TMC and CSE prep covering symptoms, triggers, diagnostics, interventions, and board exam reminders.",
};

export default async function AsthmaSlideshowPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fslideshows%2Fasthma");
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Respiratory Disease Slideshow</p>
          <div className="mt-3 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-3xl">
              <h1 className={`${headingFont} text-3xl font-semibold text-charcoal sm:text-4xl`}>
                Asthma Visual Slideshow
              </h1>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Review asthma as a board-style disease pattern: reversible bronchoconstriction, classic triggers,
                diagnostic clues, and respiratory therapy interventions.
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

        <SlideDeckViewer slides={asthmaSlideshowDeck.slides} />

        <section className="rounded-2xl border border-primary/20 bg-white p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Board Prep Reminder</p>
          <p className="mt-2 text-sm leading-relaxed text-graysoft">
            For asthma questions, look for reversible bronchoconstriction, wheezing, decreased peak flow, normal DLCO,
            and improvement after bronchodilator therapy.
          </p>
        </section>
      </div>
    </main>
  );
}
