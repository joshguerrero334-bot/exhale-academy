import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import FlashcardDeck from "../../components/flashcards/FlashcardDeck";
import { headingFont } from "../../lib/fonts";
import { createClient } from "../../lib/supabase/server";
import { buzzwordSections, tmcCseBuzzwordCards } from "../../lib/flashcards/tmc-cse-buzzwords";

export const metadata: Metadata = {
  title: "Flashcards | Exhale Academy",
  description: "Quizlet-style TMC and CSE flashcards for Exhale Academy students.",
};

export default async function FlashcardsPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fflashcards");
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-8 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Exhale Flashcards</p>
          <div className="mt-3 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-3xl">
              <h1 className={`${headingFont} text-3xl font-semibold text-charcoal sm:text-4xl`}>
                TMC + CSE buzzwords, built like fast board-prep reps
              </h1>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Start with the clue, make the diagnosis or concept in your head, then flip to confirm. This first deck
                is built from your TMC and CSE buzzwords PDF and tuned for desktop, tablet, and phone.
              </p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link href="/dashboard" className="btn-secondary">
                Back to Dashboard
              </Link>
              <Link href="/tmc" className="btn-primary">
                Go to TMC Practice
              </Link>
            </div>
          </div>
        </section>

        <section className="grid gap-4 md:grid-cols-3">
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Format</p>
            <h2 className="mt-2 text-lg font-semibold text-charcoal">Flip-to-reveal cards</h2>
            <p className="mt-2 text-sm text-graysoft">Read the clue, commit to an answer, then tap or click to flip the card.</p>
          </article>
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Source</p>
            <h2 className="mt-2 text-lg font-semibold text-charcoal">Your buzzwords PDF</h2>
            <p className="mt-2 text-sm text-graysoft">Disease recognition, diagnostics, ventilator clues, and quick TMC/CSE exam tips.</p>
          </article>
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Access</p>
            <h2 className="mt-2 text-lg font-semibold text-charcoal">Desktop to phone</h2>
            <p className="mt-2 text-sm text-graysoft">Designed for mouse click, tablet tap, and phone tap without losing readability.</p>
          </article>
        </section>

        <FlashcardDeck cards={tmcCseBuzzwordCards} sections={buzzwordSections} />
      </div>
    </main>
  );
}
