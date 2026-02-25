import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../../components/PracticeSwitchBar";
import CseHowItWorksClient from "../../../components/cse/CseHowItWorksClient";
import { createClient } from "../../../lib/supabase/server";

export default async function CseHowItWorksPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fhow-it-works");
  }

  return (
    <main className="page-shell">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />

      <div className="mx-auto w-full max-w-4xl space-y-6 pt-4">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <h1 className="text-3xl font-bold text-[color:var(--brand-navy)]">CSE: How It Works</h1>
          <p className="mt-3 text-sm text-slate-700">
            Understand exam mechanics before starting your first scenario.
          </p>

          <div className="mt-6 space-y-4 text-sm text-slate-700">
            <article>
              <h2 className="font-semibold text-[color:var(--brand-navy)]">IG vs DM</h2>
              <p className="mt-1">IG (Information Gathering) asks what data you should collect. DM (Decision Making) asks for the best next intervention.</p>
            </article>

            <article>
              <h2 className="font-semibold text-[color:var(--brand-navy)]">Selection Limits</h2>
              <p className="mt-1">IG steps can require multiple picks with a strict selection limit. Exceeding the limit is blocked.</p>
            </article>

            <article>
              <h2 className="font-semibold text-[color:var(--brand-navy)]">3-Window Layout</h2>
              <p className="mt-1">Every section uses three windows: Scenario on top, Options on the lower-left, and Simulation History on the lower-right.</p>
            </article>

            <article>
              <h2 className="font-semibold text-[color:var(--brand-navy)]">Section Progression</h2>
              <p className="mt-1">When finished, click Go To Next Section. A confirmation prompt appears because you cannot return once you advance.</p>
            </article>

            <article>
              <h2 className="font-semibold text-[color:var(--brand-navy)]">Scoring</h2>
              <p className="mt-1">Options are weighted as +2, +1, -1, or -2 based on decision quality and clinical priority.</p>
            </article>
          </div>
        </section>

        <CseHowItWorksClient />
      </div>
    </main>
  );
}
