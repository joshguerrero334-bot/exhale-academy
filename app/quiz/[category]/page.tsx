import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import { headingFont } from "../../../lib/fonts";
import { startCategoryAttempt } from "./actions";

type PageProps = {
  params: Promise<{ category: string }>;
  searchParams: Promise<{ error?: string }>;
};

type AttemptRow = {
  id: string;
  mode: "tutor" | "exam";
  created_at: string;
};

export default async function QuizStartPage({ params, searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const { category: rawSlug } = await params;
  const slug = decodeURIComponent(rawSlug ?? "").trim().toLowerCase();
  if (!slug) {
    redirect("/dashboard");
  }

  const [categoryRes, questionRes, inProgressRes, query] = await Promise.all([
    supabase.from("categories").select("slug, name").eq("slug", slug).maybeSingle(),
    supabase.from("questions").select("id").eq("category_slug", slug),
    supabase
      .from("category_quiz_attempts")
      .select("*")
      .eq("user_id", user.id)
      .eq("category_slug", slug)
      .is("completed_at", null)
      .order("created_at", { ascending: false })
      .limit(1),
    searchParams,
  ]);

  const categoryName = String(
    ((categoryRes.data ?? null) as { name?: string } | null)?.name ?? slug
  );

  const questionCount = (questionRes.data ?? []).length;
  const rawInProgress = ((inProgressRes.data ?? [])[0] ?? null) as AttemptRow | null;
  let inProgress: AttemptRow | null = rawInProgress;

  if (rawInProgress) {
    const { count: itemCount } = await supabase
      .from("category_quiz_attempt_questions")
      .select("id", { count: "exact", head: true })
      .eq("attempt_id", rawInProgress.id);

    if (!itemCount || itemCount === 0) {
      inProgress = null;
    }
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Category Quiz
          </p>
          <h1 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>{categoryName}</h1>
          <p className="mt-3 text-sm text-graysoft">Randomized quiz from this category.</p>

          {query.error ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              {query.error}
            </div>
          ) : null}

          {questionCount === 0 ? (
            <div className="mt-5 rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-800">
              No questions found. category_slug may not be filled yet.
            </div>
          ) : inProgress ? (
            <div className="mt-5 rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm font-semibold text-charcoal">
                In-progress attempt found ({inProgress.mode === "tutor" ? "Tutor" : "Exam"} Mode)
              </p>
              <p className="mt-1 text-xs text-graysoft">
                Created: {new Date(inProgress.created_at).toLocaleString()}
              </p>
              <div className="mt-4 flex flex-col gap-3 sm:flex-row">
                <Link
                  href={`/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(inProgress.id)}`}
                  className="btn-primary"
                >
                  Resume Attempt
                </Link>
              </div>
            </div>
          ) : (
            <form action={startCategoryAttempt} className="mt-5 space-y-3">
              <input type="hidden" name="category_slug" value={slug} />
              <div className="grid gap-3 sm:grid-cols-2">
                <button
                  type="submit"
                  name="mode"
                  value="tutor"
                  className="rounded-xl border border-primary/40 bg-background p-4 text-left transition hover:bg-primary/5"
                >
                  <p className="text-sm font-semibold text-primary">Tutor Mode</p>
                  <p className="mt-1 text-xs text-graysoft">Immediate correctness + rationale after each answer</p>
                </button>
                <button
                  type="submit"
                  name="mode"
                  value="exam"
                  className="rounded-xl border border-primary/40 bg-background p-4 text-left transition hover:bg-primary/5"
                >
                  <p className="text-sm font-semibold text-primary">Exam Mode</p>
                  <p className="mt-1 text-xs text-graysoft">No correctness shown until final results</p>
                </button>
              </div>
            </form>
          )}

          <div className="mt-5">
            <Link
              href="/dashboard"
              className="btn-secondary"
            >
              Back to Dashboard
            </Link>
          </div>
        </section>
      </div>
    </main>
  );
}
