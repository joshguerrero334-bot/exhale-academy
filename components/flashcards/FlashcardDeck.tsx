"use client";

import { useEffect, useMemo, useState } from "react";

type Flashcard = {
  id: string;
  front: string;
  back: string;
  section: string;
};

type Props = {
  cards: Flashcard[];
  sections: readonly string[];
};

function shuffleCards(cards: Flashcard[]) {
  const next = [...cards];
  for (let index = next.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(Math.random() * (index + 1));
    [next[index], next[swapIndex]] = [next[swapIndex], next[index]];
  }
  return next;
}

export default function FlashcardDeck({ cards, sections }: Props) {
  const [activeSection, setActiveSection] = useState<string | "All">("All");
  const [deck, setDeck] = useState(cards);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [flipped, setFlipped] = useState(false);

  const filteredCards = useMemo(() => {
    if (activeSection === "All") return deck;
    return deck.filter((card) => card.section === activeSection);
  }, [activeSection, deck]);

  const currentCard = filteredCards[currentIndex] ?? null;

  useEffect(() => {
    setCurrentIndex(0);
    setFlipped(false);
  }, [activeSection]);

  function goToCard(nextIndex: number) {
    if (filteredCards.length === 0) return;
    const bounded = (nextIndex + filteredCards.length) % filteredCards.length;
    setCurrentIndex(bounded);
    setFlipped(false);
  }

  function reshuffle() {
    setDeck(shuffleCards(cards));
    setCurrentIndex(0);
    setFlipped(false);
  }

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-6">
        <div className="flex flex-wrap items-center gap-2">
          <button
            type="button"
            onClick={() => setActiveSection("All")}
            className={`rounded-full px-4 py-2 text-sm font-semibold transition ${
              activeSection === "All"
                ? "bg-primary text-white"
                : "border border-graysoft/30 bg-background text-charcoal hover:bg-primary/5"
            }`}
          >
            All Cards
          </button>
          {sections.map((section) => (
            <button
              key={section}
              type="button"
              onClick={() => setActiveSection(section)}
              className={`rounded-full px-4 py-2 text-sm font-semibold transition ${
                activeSection === section
                  ? "bg-primary text-white"
                  : "border border-graysoft/30 bg-background text-charcoal hover:bg-primary/5"
              }`}
            >
              {section}
            </button>
          ))}
        </div>
      </section>

      <section className="grid gap-4 lg:grid-cols-[1.5fr,0.9fr]">
        <div className="rounded-[28px] border border-graysoft/30 bg-white p-4 shadow-sm sm:p-6">
          <button
            type="button"
            onClick={() => setFlipped((value) => !value)}
            className="group relative block h-[420px] w-full rounded-[24px] border border-primary/20 bg-background text-left shadow-sm transition hover:border-primary/40 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:ring-offset-2"
            aria-label={flipped ? "Show definition side" : "Show answer side"}
          >
            <div
              className={`relative h-full w-full rounded-[24px] transition-transform duration-500 [transform-style:preserve-3d] ${
                flipped ? "[transform:rotateY(180deg)]" : ""
              }`}
            >
              <div className="absolute inset-0 flex h-full w-full flex-col justify-between rounded-[24px] bg-[radial-gradient(circle_at_top_left,_rgba(103,208,204,0.18),_transparent_45%),linear-gradient(180deg,#ffffff_0%,#f7fbfb_100%)] p-6 [backface-visibility:hidden] sm:p-8">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.22em] text-primary">{currentCard?.section ?? "Deck"}</p>
                    <p className="mt-3 text-sm font-semibold uppercase tracking-[0.16em] text-slate-500">Definition / Clue</p>
                  </div>
                  <span className="rounded-full border border-primary/20 bg-white/80 px-3 py-1 text-xs font-semibold text-primary shadow-sm">
                    {filteredCards.length === 0 ? "0 / 0" : `${currentIndex + 1} / ${filteredCards.length}`}
                  </span>
                </div>
                <div className="flex flex-1 items-center justify-center py-6">
                  <h2 className="max-w-2xl text-center text-3xl font-semibold leading-tight text-charcoal sm:text-4xl">
                    {currentCard?.front ?? "No cards in this section yet."}
                  </h2>
                </div>
                <p className="text-center text-sm font-medium text-slate-500">Tap or click the card to reveal the answer</p>
              </div>

              <div className="absolute inset-0 flex h-full w-full flex-col justify-between rounded-[24px] bg-[linear-gradient(180deg,#0A1A2F_0%,#132846_100%)] p-6 text-white [backface-visibility:hidden] [transform:rotateY(180deg)] sm:p-8">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[#C9A86A]">{currentCard?.section ?? "Deck"}</p>
                    <p className="mt-3 text-sm font-semibold uppercase tracking-[0.16em] text-white/70">Answer</p>
                  </div>
                  <span className="rounded-full border border-white/15 bg-white/5 px-3 py-1 text-xs font-semibold text-white/80">
                    Flip back
                  </span>
                </div>
                <div className="flex flex-1 items-center justify-center py-6">
                  <h3 className="max-w-2xl text-center text-3xl font-semibold leading-tight text-white sm:text-4xl">
                    {currentCard?.back ?? "Choose another section."}
                  </h3>
                </div>
                <p className="text-center text-sm font-medium text-white/70">Tap or click again to study the next clue</p>
              </div>
            </div>
          </button>
        </div>

        <aside className="space-y-4">
          <section className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Deck Controls</p>
            <div className="mt-4 grid gap-3">
              <button type="button" onClick={() => goToCard(currentIndex - 1)} className="btn-secondary w-full">
                Previous Card
              </button>
              <button type="button" onClick={() => setFlipped((value) => !value)} className="btn-primary w-full">
                {flipped ? "Show Definition" : "Reveal Answer"}
              </button>
              <button type="button" onClick={() => goToCard(currentIndex + 1)} className="btn-secondary w-full">
                Next Card
              </button>
              <button type="button" onClick={reshuffle} className="rounded-xl border border-primary/30 px-4 py-3 text-sm font-semibold text-primary transition hover:bg-primary/5">
                Shuffle Deck
              </button>
            </div>
          </section>
        </aside>
      </section>
    </div>
  );
}
