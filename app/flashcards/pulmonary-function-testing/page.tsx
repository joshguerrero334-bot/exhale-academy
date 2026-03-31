import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import FlashcardDeck from "../../../components/flashcards/FlashcardDeck";
import { headingFont } from "../../../lib/fonts";
import {
  pulmonaryFunctionTestingCards,
  pulmonaryFunctionTestingSections,
} from "../../../lib/flashcards/pulmonary-function-testing";
import { createClient } from "../../../lib/supabase/server";

export const metadata: Metadata = {
  title: "PFT Flashcards | Exhale Academy",
  description:
    "Board-focused pulmonary function testing flashcards for Exhale Academy students studying for the TMC and CSE.",
};

const suggestedStudyOrder = [
  "Key Terms",
  "Interpretation Flow",
  "Patterns",
  "Flow-Volume Loops",
  "Buzzwords, Traps, and Memory",
] as const;

export default async function PulmonaryFunctionTestingFlashcardsPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fflashcards%2Fpulmonary-function-testing");
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-8 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Flashcards</p>
          <div className="mt-3 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-3xl">
              <h1 className={`${headingFont} text-3xl font-semibold text-charcoal sm:text-4xl`}>
                Pulmonary Function Testing (PFTs)
              </h1>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Drill PFT interpretation the way it shows up on boards: ratio first, then volume, then TLC, then DLCO.
                Use the deck for rapid recall and the quick-reference tables below when you want the big picture.
              </p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link href="/flashcards" className="btn-secondary">
                Back to Flashcards
              </Link>
              <Link href="/dashboard" className="btn-primary">
                Back to Exhale Hub
              </Link>
            </div>
          </div>
        </section>

        <FlashcardDeck cards={pulmonaryFunctionTestingCards} sections={pulmonaryFunctionTestingSections} />

        <section className="grid gap-4 lg:grid-cols-[1.05fr,0.95fr]">
          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Normal Values</p>
            <h2 className="mt-2 text-2xl font-semibold text-charcoal">Quick Reference Table</h2>
            <div className="mt-5 overflow-hidden rounded-2xl border border-graysoft/30">
              <table className="min-w-full divide-y divide-graysoft/20 text-sm">
                <thead className="bg-background">
                  <tr>
                    <th className="px-4 py-3 text-left font-semibold text-charcoal">Measure</th>
                    <th className="px-4 py-3 text-left font-semibold text-charcoal">Approximate Normal</th>
                    <th className="px-4 py-3 text-left font-semibold text-charcoal">Why It Matters</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-graysoft/20 bg-white">
                  <tr>
                    <td className="px-4 py-3 font-semibold">FEV1</td>
                    <td className="px-4 py-3">80% predicted or higher</td>
                    <td className="px-4 py-3">Shows how fast air can be exhaled</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">FVC</td>
                    <td className="px-4 py-3">80% predicted or higher</td>
                    <td className="px-4 py-3">Helps flag low total exhaled volume</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">FEV1/FVC</td>
                    <td className="px-4 py-3">About 70% or higher</td>
                    <td className="px-4 py-3">The first split between obstructive and non-obstructive patterns</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">TLC</td>
                    <td className="px-4 py-3">80% to 120% predicted</td>
                    <td className="px-4 py-3">Confirms whether the lungs are truly restricted</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">DLCO</td>
                    <td className="px-4 py-3">80% to 120% predicted</td>
                    <td className="px-4 py-3">Adds the gas-exchange clue boards like to test</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Interpretation Flow</p>
            <h2 className="mt-2 text-2xl font-semibold text-charcoal">Read PFTs in This Order</h2>
            <ol className="mt-5 space-y-4 text-sm leading-relaxed text-graysoft sm:text-base">
              <li>
                <span className="font-semibold text-charcoal">1. Check the ratio first.</span> If the FEV1/FVC is low,
                think obstructive.
              </li>
              <li>
                <span className="font-semibold text-charcoal">2. Check the FVC next.</span> If the ratio is normal or
                high, a low FVC raises suspicion for restriction.
              </li>
              <li>
                <span className="font-semibold text-charcoal">3. Use TLC to confirm.</span> A low TLC seals the
                restrictive diagnosis.
              </li>
              <li>
                <span className="font-semibold text-charcoal">4. Look at DLCO last.</span> This helps sort out
                emphysema, fibrosis, and other gas-exchange problems.
              </li>
            </ol>
          </article>
        </section>

        <section className="grid gap-4 lg:grid-cols-3">
          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Loop Clue</p>
            <h2 className="mt-2 text-xl font-semibold text-charcoal">Normal</h2>
            <ul className="mt-4 space-y-2 text-sm leading-relaxed text-graysoft sm:text-base">
              <li>Rounded peak</li>
              <li>Smooth descending limb</li>
              <li>Full, balanced shape</li>
            </ul>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Loop Clue</p>
            <h2 className="mt-2 text-xl font-semibold text-charcoal">Obstructive</h2>
            <ul className="mt-4 space-y-2 text-sm leading-relaxed text-graysoft sm:text-base">
              <li>Scooped or coved expiratory limb</li>
              <li>Peak flow often reduced</li>
              <li>Think COPD or asthma</li>
            </ul>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Loop Clue</p>
            <h2 className="mt-2 text-xl font-semibold text-charcoal">Restrictive</h2>
            <ul className="mt-4 space-y-2 text-sm leading-relaxed text-graysoft sm:text-base">
              <li>Tall, narrow shape</li>
              <li>Low total volume</li>
              <li>Think fibrosis, ARDS, or neuromuscular weakness</li>
            </ul>
          </article>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Suggested Study Order</p>
          <h2 className="mt-2 text-2xl font-semibold text-charcoal">Best Way to Review This Deck</h2>
          <ol className="mt-5 grid gap-3 text-sm leading-relaxed text-graysoft sm:grid-cols-2 sm:text-base lg:grid-cols-5">
            {suggestedStudyOrder.map((step, index) => (
              <li key={step} className="rounded-2xl border border-graysoft/25 bg-background px-4 py-4">
                <span className="block text-xs font-semibold uppercase tracking-[0.16em] text-primary">Step {index + 1}</span>
                <span className="mt-2 block font-semibold text-charcoal">{step}</span>
              </li>
            ))}
          </ol>
        </section>
      </div>
    </main>
  );
}
