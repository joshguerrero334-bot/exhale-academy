import Link from "next/link";
import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../../components/PracticeSwitchBar";
import { createClient } from "../../../lib/supabase/server";
import { headingFont } from "../../../lib/fonts";
import { startCseMasterAttempt } from "./actions";

type PageProps = {
  searchParams: Promise<{ error?: string; warning?: string }>;
};

type MasterAttemptRow = {
  id: string;
  mode: "tutor" | "exam";
  status: "in_progress" | "completed";
  created_at: string;
  total_cases: number;
  completed_cases: number;
};

export default async function CseMasterStartPage({ searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fmaster");
  }

  const { data: rawAttempts, error: attemptsError } = await supabase
    .from("cse_master_attempts")
    .select("id, mode, status, created_at, total_cases, completed_cases")
    .eq("user_id", user.id)
    .eq("status", "in_progress")
    .order("created_at", { ascending: false })
    .limit(1);

  let inProgress = ((rawAttempts ?? [])[0] ?? null) as MasterAttemptRow | null;
  let legacyShortAttemptDetected = false;

  if (inProgress) {
    const { count } = await supabase
      .from("cse_master_attempt_cases")
      .select("id", { count: "exact", head: true })
      .eq("attempt_id", inProgress.id);
    if (!count || count === 0) {
      inProgress = null;
    } else if (count < 20 || Number(inProgress.total_cases ?? 0) < 20) {
      legacyShortAttemptDetected = true;
      await supabase
        .from("cse_master_attempts")
        .update({
          status: "completed",
          completed_at: new Date().toISOString(),
        })
        .eq("id", inProgress.id);
      inProgress = null;
    }
  }

  const query = await searchParams;

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Master CSE
          </p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>
            20-Case Test-Day Simulation
          </h1>
          <p className="mt-3 text-sm text-graysoft">
            Built to mirror NBRC test form composition across A-G categories. Each new attempt randomizes case
            selection from the eligible pool while preserving blueprint counts.
          </p>

          {query.error ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              {query.error}
            </div>
          ) : null}
          {query.warning ? (
            <div className="mt-4 rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm text-amber-800">
              {query.warning}
            </div>
          ) : null}
          {legacyShortAttemptDetected ? (
            <div className="mt-4 rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm text-amber-800">
              A previous in-progress master attempt had fewer than 20 cases and was closed. Start a new master attempt
              to use the full 20-case format.
            </div>
          ) : null}
          {attemptsError ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              Could not load in-progress attempts: {attemptsError.message}
            </div>
          ) : null}

          {inProgress ? (
            <div className="mt-5 rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm font-semibold text-charcoal">
                In-progress master attempt ({inProgress.mode === "tutor" ? "Tutor" : "Exam"} Mode)
              </p>
              <p className="mt-1 text-xs text-graysoft">
                Created: {new Date(inProgress.created_at).toLocaleString()} · Completed{" "}
                {inProgress.completed_cases}/{inProgress.total_cases} cases
              </p>
              <div className="mt-4 flex flex-wrap gap-3">
                <Link
                  href={`/cse/master/${encodeURIComponent(inProgress.id)}`}
                  className="btn-primary"
                >
                  Resume Master Exam
                </Link>
                <form action={startCseMasterAttempt}>
                  <input type="hidden" name="mode" value={inProgress.mode} />
                  <button
                    type="submit"
                    className="btn-secondary"
                  >
                    Start New Master Attempt
                  </button>
                </form>
              </div>
            </div>
          ) : (
            <form action={startCseMasterAttempt} className="mt-5 space-y-3">
              <div className="grid gap-3 sm:grid-cols-2">
                <button
                  type="submit"
                  name="mode"
                  value="tutor"
                  className="rounded-xl border border-primary/40 bg-background p-4 text-left transition hover:bg-primary/5"
                  aria-pressed="true"
                >
                  <p className="text-sm font-semibold text-primary">Tutor Mode</p>
                  <p className="mt-1 text-xs text-graysoft">Step-level coaching and rationale visibility</p>
                </button>
                <button
                  type="submit"
                  name="mode"
                  value="exam"
                  className="rounded-xl border border-primary/40 bg-background p-4 text-left transition hover:bg-primary/5"
                  aria-pressed="false"
                >
                  <p className="text-sm font-semibold text-primary">Exam Mode</p>
                  <p className="mt-1 text-xs text-graysoft">Realistic pressure with delayed score emphasis</p>
                </button>
              </div>
            </form>
          )}
        </section>
      </div>
    </main>
  );
}
