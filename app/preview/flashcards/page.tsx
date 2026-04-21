import type { Metadata } from "next";
import Link from "next/link";
import FlashcardDeck from "../../../components/flashcards/FlashcardDeck";
import { headingFont } from "../../../lib/fonts";
import { previewFlashcards } from "../../../lib/preview/free-preview-content";

export const metadata: Metadata = {
  title: "Free Respiratory Therapy Flashcards | Exhale Academy",
  description:
    "Try 10 free respiratory therapy flashcards for TMC and CSE prep. Preview Exhale Academy flashcards before subscribing.",
  alternates: { canonical: "/preview/flashcards" },
};

const sections = Array.from(new Set(previewFlashcards.map((card) => card.section)));

export default function FreeFlashcardsPreviewPage() {
  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-8 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Free Flashcard Preview</p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>
            10 Free Respiratory Therapy Flashcards
          </h1>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
            Try the Exhale flashcard experience with 10 fixed TMC and CSE flashcards. The full membership unlocks every respiratory therapy flashcard deck, including normal values, ventilators, pharmacology, PFTs, and disease patterns.
          </p>
          <div className="mt-5 flex flex-wrap gap-3">
            <Link href="/signup" className="btn-primary">Unlock All Flashcards</Link>
            <Link href="/" className="btn-secondary">Back to Home</Link>
          </div>
        </section>

        <FlashcardDeck cards={previewFlashcards} sections={sections} />
      </div>
    </main>
  );
}
