import type { Metadata } from "next";
import Link from "next/link";
import { headingFont } from "../../../lib/fonts";
import { previewCseCases } from "../../../lib/preview/free-preview-content";

export const metadata: Metadata = {
  title: "Free CSE Clinical Simulation Preview | Exhale Academy",
  description:
    "Try two free fixed CSE clinical simulation scenarios from Exhale Academy before subscribing to the full respiratory therapy exam prep platform.",
  alternates: { canonical: "/preview/cse-scenarios" },
};

type FreeCseScenariosPageProps = {
  searchParams: Promise<{ error?: string }>;
};

export default async function FreeCseScenariosPage({ searchParams }: FreeCseScenariosPageProps) {
  const query = await searchParams;

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Free CSE Preview</p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>
            Try 2 Real CSE Clinical Simulations
          </h1>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-graysoft sm:text-base">
            These are fixed free CSE previews using real Exhale Academy clinical simulation cases. They show the same branching decision style students get inside the paid Master CSE, without exposing the full case bank.
          </p>
          <div className="mt-5 flex flex-wrap gap-3">
            <Link href="/signup" className="btn-primary">Unlock Full CSE Prep</Link>
            <Link href="/" className="btn-secondary">Back to Home</Link>
          </div>
          {query.error ? (
            <div className="mt-4 rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900">
              {query.error}
            </div>
          ) : null}
        </section>

        <section className="grid gap-4 md:grid-cols-2">
          {previewCseCases.map((previewCase) => (
            <article key={previewCase.slug} className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Fixed Preview Case</p>
              <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>{previewCase.label}</h2>
              <p className="mt-3 text-sm leading-relaxed text-graysoft">{previewCase.description}</p>
              <Link href={`/preview/cse-scenarios/${previewCase.slug}`} className="btn-primary mt-5">
                Start Free Case
              </Link>
            </article>
          ))}
        </section>
      </div>
    </main>
  );
}
