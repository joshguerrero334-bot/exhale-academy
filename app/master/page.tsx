import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { headingFont } from "../../lib/fonts";
import { startMasterAttempt } from "./actions";

type PageProps = {
  searchParams: Promise<{ error?: string }>;
};

type AttemptRow = {
  id: string;
  mode: "tutor" | "exam";
  created_at: string;
  completed_at: string | null;
  total: number;
};

export default async function MasterStartPage({ searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const { data: attemptData, error: attemptError } = await supabase
    .from("master_test_attempts")
    .select("*")
    .eq("user_id", user.id)
    .is("completed_at", null)
    .order("created_at", { ascending: false })
    .limit(1);

  const rawInProgress = ((attemptData ?? [])[0] ?? null) as AttemptRow | null;
  let inProgress: AttemptRow | null = rawInProgress;

  if (rawInProgress) {
    const { count: itemCount } = await supabase
      .from("master_test_attempt_questions")
      .select("id", { count: "exact", head: true })
      .eq("attempt_id", rawInProgress.id);

    if (!itemCount || itemCount === 0) {
      inProgress = null;
    }
  }
  const query = await searchParams;

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-5xl space-y-5 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Master Test
          </p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>
            160-Question TMC Practice Exam
          </h1>
          <p className="mt-3 text-sm text-graysoft">
            Select Tutor Mode for immediate feedback or Exam Mode for no feedback until results.
          </p>

          {query.error ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              {query.error}
            </div>
          ) : null}

          {attemptError ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              Could not load current attempt: {attemptError.message}
            </div>
          ) : null}

          {inProgress ? (
            <div className="mt-5 rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm font-semibold text-charcoal">
                In-progress attempt found ({inProgress.mode === "tutor" ? "Tutor" : "Exam"} Mode)
              </p>
              <p className="mt-1 text-xs text-graysoft">
                Created: {new Date(inProgress.created_at).toLocaleString()} · {inProgress.total} questions
              </p>
              <div className="mt-4 flex flex-col gap-3 sm:flex-row">
                <Link
                  href={`/master/${encodeURIComponent(inProgress.id)}`}
                  className="btn-primary"
                >
                  Resume Attempt
                </Link>
                <form action={startMasterAttempt}>
                  <input type="hidden" name="mode" value={inProgress.mode} />
                  <button
                    type="submit"
                    className="btn-secondary"
                  >
                    Start New Attempt
                  </button>
                </form>
              </div>
            </div>
          ) : (
            <form action={startMasterAttempt} className="mt-5 space-y-3">
              <div className="grid gap-3 sm:grid-cols-2">
                <button
                  type="submit"
                  name="mode"
                  value="tutor"
                  className="rounded-xl border border-primary/40 bg-background p-4 text-left transition hover:bg-primary/5"
                  aria-pressed="true"
                >
                  <p className="text-sm font-semibold text-primary">Tutor Mode</p>
                  <p className="mt-1 text-xs text-graysoft">Immediate correctness + rationale after each answer</p>
                </button>
                <button
                  type="submit"
                  name="mode"
                  value="exam"
                  className="rounded-xl border border-primary/40 bg-background p-4 text-left transition hover:bg-primary/5"
                  aria-pressed="false"
                >
                  <p className="text-sm font-semibold text-primary">Exam Mode</p>
                  <p className="mt-1 text-xs text-graysoft">No correctness shown until final results</p>
                </button>
              </div>
            </form>
          )}
        </section>
      </div>
    </main>
  );
}
