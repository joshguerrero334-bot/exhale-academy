import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { headingFont } from "../../lib/fonts";
import { createClient } from "../../lib/supabase/server";

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
                Flashcards built for fast repetition and better recall
              </h1>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Choose a flashcard category, then drill the subcategories inside that deck. Start with the front clue,
                answer it in your head, and flip the card to confirm.
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

        <section className="grid gap-4 lg:grid-cols-2 xl:grid-cols-3">
          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Flashcard Category</p>
            <h2 className="mt-2 text-2xl font-semibold text-charcoal">TMC + CSE Buzzwords</h2>
            <p className="mt-3 text-sm leading-relaxed text-graysoft">
              Study disease recognition, diagnostic buzzwords, and ventilator management in one focused deck with
              section filters once you enter.
            </p>
            <div className="mt-5">
              <Link href="/flashcards/tmc-cse-buzzwords" className="btn-primary">
                Open Buzzwords Deck
              </Link>
            </div>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Flashcard Category</p>
            <h2 className="mt-2 text-2xl font-semibold text-charcoal">Respiratory Disease Patterns</h2>
            <p className="mt-3 text-sm leading-relaxed text-graysoft">
              Review asthma, COPD, ARDS, pneumonia, PE, fibrosis, and more with short disease-pattern cards built for
              quick board-style recall.
            </p>
            <div className="mt-5">
              <Link href="/flashcards/respiratory-disease-patterns" className="btn-primary">
                Open Disease Deck
              </Link>
            </div>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Flashcard Category</p>
            <h2 className="mt-2 text-2xl font-semibold text-charcoal">BiPAP, CPAP, and Oxygen Devices</h2>
            <p className="mt-3 text-sm leading-relaxed text-graysoft">
              Study pressure support choices and oxygen delivery devices with concise cards built for board-style recall.
            </p>
            <div className="mt-5">
              <Link href="/flashcards/airway-pressure-and-oxygen-devices" className="btn-primary">
                Open Devices Deck
              </Link>
            </div>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Flashcard Category</p>
            <h2 className="mt-2 text-2xl font-semibold text-charcoal">Pulmonary Function Testing (PFTs)</h2>
            <p className="mt-3 text-sm leading-relaxed text-graysoft">
              Review normal values, obstructive vs restrictive patterns, DLCO clues, and flow-volume loop recognition in
              one focused PFT deck.
            </p>
            <div className="mt-5">
              <Link href="/flashcards/pulmonary-function-testing" className="btn-primary">
                Open PFT Deck
              </Link>
            </div>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Flashcard Category</p>
            <h2 className="mt-2 text-2xl font-semibold text-charcoal">Flow-Volume Loops</h2>
            <p className="mt-3 text-sm leading-relaxed text-graysoft">
              Practice pure loop recognition with image-based cards that help students identify normal, obstructive, and
              restrictive loop patterns fast.
            </p>
            <div className="mt-5">
              <Link href="/flashcards/flow-volume-loops" className="btn-primary">
                Open Loop Deck
              </Link>
            </div>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Flashcard Category</p>
            <h2 className="mt-2 text-2xl font-semibold text-charcoal">Mechanical Ventilation</h2>
            <p className="mt-3 text-sm leading-relaxed text-graysoft">
              Drill support modes, waveform pattern recognition, and high-yield ventilator concepts with grouped cards
              built for TMC and CSE review.
            </p>
            <div className="mt-5">
              <Link href="/flashcards/mechanical-ventilation" className="btn-primary">
                Open Ventilation Deck
              </Link>
            </div>
          </article>
        </section>
      </div>
    </main>
  );
}
