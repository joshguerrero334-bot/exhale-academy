import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import { headingFont } from "../../../lib/fonts";
import { focusedCsePracticeFamilies } from "../../../lib/supabase/cse-master";
import { startCseMasterAttempt, startFocusedCseAttempt } from "./actions";

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
    const expectedTotal = Number(inProgress.total_cases ?? 0);
    if (!count || count === 0) {
      inProgress = null;
    } else if (expectedTotal <= 0 || count < expectedTotal) {
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
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Master CSE
          </p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>
            20-Case Test-Day Simulation
          </h1>
          <p className="mt-3 text-sm text-graysoft">
            Built to feel like one complete CSE sitting. Each new attempt pulls from the active case pool and assembles
            a balanced 20-case simulation designed for realistic test-day pressure.
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
              A previous in-progress CSE attempt had an incomplete case set and was closed. Start a new attempt to use
              the current format.
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
                In-progress {inProgress.total_cases >= 20 ? "master exam" : "focused practice"} (
                {inProgress.mode === "tutor" ? "Tutor" : "Exam"} Mode)
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
                  Resume Attempt
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

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Focused CSE Practice
          </p>
          <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            Target one pathology family at a time
          </h2>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-graysoft">
            Use these shorter sets when students need reps on a specific pattern before jumping back into the full
            Master CSE. Each set uses the same real case engine, but limits the pull to one high-yield family.
          </p>

          <div className="mt-6 grid gap-4 md:grid-cols-2">
            {focusedCsePracticeFamilies.map((family) => (
              <article
                key={family.slug}
                className="rounded-2xl border border-primary/20 bg-background p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-md"
              >
                <p className="text-[0.68rem] font-semibold uppercase tracking-[0.18em] text-primary">
                  {family.eyebrow}
                </p>
                <h3 className={`${headingFont} mt-2 text-xl font-semibold text-charcoal`}>
                  {family.label}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">{family.description}</p>
                <p className="mt-3 text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">
                  {family.caseCount} case target
                </p>
                <div className="mt-4 grid gap-2 sm:grid-cols-2">
                  <form action={startFocusedCseAttempt}>
                    <input type="hidden" name="focus_slug" value={family.slug} />
                    <input type="hidden" name="mode" value="tutor" />
                    <button type="submit" className="w-full rounded-xl bg-primary px-4 py-3 text-sm font-semibold text-white transition hover:bg-primary/90">
                      Tutor Mode
                    </button>
                  </form>
                  <form action={startFocusedCseAttempt}>
                    <input type="hidden" name="focus_slug" value={family.slug} />
                    <input type="hidden" name="mode" value="exam" />
                    <button type="submit" className="w-full rounded-xl border border-primary/40 bg-white px-4 py-3 text-sm font-semibold text-primary transition hover:bg-primary/5">
                      Exam Mode
                    </button>
                  </form>
                </div>
              </article>
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}
