import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { headingFont } from "../../lib/fonts";
import { createClient } from "../../lib/supabase/server";
import { slideshowDecks } from "../../lib/slideshows";

export const metadata: Metadata = {
  title: "Visual Slideshows for Respiratory Therapy Students",
  description:
    "Visual respiratory therapy slideshows and slide-based study guides for TMC and CSE board exam prep.",
};

export default async function SlideshowsPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fslideshows");
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-6xl space-y-8 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Visual Slideshows</p>
          <div className="mt-3 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-3xl">
              <h1 className={`${headingFont} text-3xl font-semibold text-charcoal sm:text-4xl`}>
                Slide-based study guides for visual learners
              </h1>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Review high-yield respiratory therapy concepts with clean PowerPoint-style visuals built for quick TMC
                and CSE pattern recognition.
              </p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link href="/dashboard" className="btn-secondary">
                Back to Exhale Hub
              </Link>
              <Link href="/flashcards" className="btn-primary">
                Open Flashcards
              </Link>
            </div>
          </div>
        </section>

        <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {slideshowDecks.map((deck) => (
            <article key={deck.slug} className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:border-primary/60 hover:shadow-md">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">{deck.eyebrow}</p>
              <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>{deck.title}</h2>
              <p className="mt-3 text-sm leading-relaxed text-graysoft">{deck.description}</p>
              <p className="mt-4 text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">
                {deck.slideCount} visual slides
              </p>
              <Link href={deck.route} className="btn-primary mt-5">
                Open Slide Deck
              </Link>
            </article>
          ))}
        </section>
      </div>
    </main>
  );
}
