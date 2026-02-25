import Link from "next/link";
import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../../components/PracticeSwitchBar";
import { createClient } from "../../../lib/supabase/server";
import { headingFont } from "../../../lib/fonts";

type CseAttemptRow = {
  mode: string | null;
  created_at: string | null;
  total_score?: number | null;
  score?: number | null;
  total?: number | null;
};

export default async function CseIntroductionPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fintroduction");
  }

  let latestAttempt: CseAttemptRow | null = null;
  let performanceError: string | null = null;

  const primary = await supabase
    .from("cse_attempts")
    .select("mode, created_at, total_score")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(1);

  if (primary.error) {
    const fallback = await supabase
      .from("cse_attempts")
      .select("mode, created_at, score, total")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(1);

    if (fallback.error) {
      performanceError = fallback.error.message;
    } else {
      latestAttempt = ((fallback.data ?? [])[0] ?? null) as CseAttemptRow | null;
    }
  } else {
    latestAttempt = ((primary.data ?? [])[0] ?? null) as CseAttemptRow | null;
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />

      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h1 className={`${headingFont} text-3xl font-semibold text-charcoal`}>Clinical Simulation Exam (CSE)</h1>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            The NBRC Clinical Simulation Examination is not a memorization test. It evaluates how you think.
            Success on the CSE requires more than knowing normal values or recalling algorithms. You must
            interpret incomplete information, recognize subtle patterns, prioritize interventions, and avoid
            decisions that could harm outcomes.
          </p>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            Inside Exhale Academy&apos;s CSE experience, you&apos;ll work through structured clinical scenarios that
            reflect the blueprint and decision-making style of the real exam. Each case starts with a focused
            patient presentation and progresses through information-gathering and decision-making steps. You&apos;ll
            see how each decision impacts the scenario and get clear rationales so you learn the &quot;why,&quot; not just
            the answer.
          </p>
          <p className="mt-4 text-sm leading-relaxed text-graysoft sm:text-base">
            Use Tutor Mode to learn with feedback as you go, and Exam Mode to simulate real pressure with results
            at the end. This section is designed to convert knowledge into clinical judgment, exactly what the CSE
            measures. Let&apos;s begin.
          </p>

          <div className="mt-6 flex flex-wrap gap-3">
            <Link href="/cse/how-it-works" className="btn-secondary">
              How it Works
            </Link>
            <Link href="/cse/cases" className="btn-primary">
              Browse Cases
            </Link>
          </div>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-xl font-semibold text-charcoal`}>CSE Performance</h2>
          {latestAttempt ? (
            <div className="mt-4 rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm text-slate-700">
                Last attempt: {latestAttempt.created_at ? new Date(latestAttempt.created_at).toLocaleString() : "n/a"}
              </p>
              <p className="mt-1 text-sm text-slate-700">Mode: {latestAttempt.mode ?? "n/a"}</p>
              <p className="mt-1 text-sm text-slate-700">
                Score: {latestAttempt.total_score ?? latestAttempt.score ?? 0}
              </p>
            </div>
          ) : (
            <div className="mt-4 rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm text-slate-700">No attempts yet.</p>
              <p className="mt-1 text-xs text-slate-500">
                Performance tracking will appear here after your first attempt.
              </p>
              {performanceError ? (
                <p className="mt-2 text-xs text-slate-500">Preview unavailable: {performanceError}</p>
              ) : null}
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
