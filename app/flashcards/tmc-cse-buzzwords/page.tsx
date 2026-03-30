import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import FlashcardDeck from "../../../components/flashcards/FlashcardDeck";
import { headingFont } from "../../../lib/fonts";
import { createClient } from "../../../lib/supabase/server";
import { buzzwordSections, tmcCseBuzzwordCards } from "../../../lib/flashcards/tmc-cse-buzzwords";

export const metadata: Metadata = {
  title: "TMC + CSE Buzzwords Flashcards | Exhale Academy",
  description: "Flip-style TMC and CSE buzzword flashcards for Exhale Academy students.",
};

export default async function TmcCseBuzzwordsFlashcardsPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fflashcards%2Ftmc-cse-buzzwords");
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-8 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Flashcards</p>
          <div className="mt-3 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-3xl">
              <h1 className={`${headingFont} text-3xl font-semibold text-charcoal sm:text-4xl`}>
                TMC + CSE Buzzwords
              </h1>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Start with the clue, answer it in your head, then flip the card to confirm. Use the subcategory
                filters to drill disease recognition, diagnostic buzzwords, or ventilator management one group at a time.
              </p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link href="/flashcards" className="btn-secondary">
                Back to Flashcards
              </Link>
              <Link href="/dashboard" className="btn-primary">
                Back to Dashboard
              </Link>
            </div>
          </div>
        </section>

        <FlashcardDeck cards={tmcCseBuzzwordCards} sections={buzzwordSections} />
      </div>
    </main>
  );
}
