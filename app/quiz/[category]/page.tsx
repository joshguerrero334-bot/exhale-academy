import Link from "next/link";
import { redirect } from "next/navigation";
import { headingFont } from "../../../lib/fonts";
import { createClient } from "../../../lib/supabase/server";
import { loadQuestionsBySlug } from "../../../lib/supabase/quiz";
import { startCategoryAttempt } from "./actions";

type PageProps = {
  params: Promise<{ category: string }>;
  searchParams: Promise<{ error?: string }>;
};

export default async function QuizCategoryPage({ params, searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const [{ category: rawSlug }, query] = await Promise.all([params, searchParams]);
  const categorySlug = decodeURIComponent(rawSlug ?? "").trim().toLowerCase();

  if (!categorySlug) {
    redirect("/tmc");
  }

  const [{ data: categoryRow, error: categoryError }, questionMatch] = await Promise.all([
    supabase
      .from("categories")
      .select("name, slug")
      .eq("slug", categorySlug)
      .maybeSingle(),
    loadQuestionsBySlug(supabase, categorySlug),
  ]);

  if (categoryError) {
    throw new Error(`Failed to load category: ${categoryError.message}`);
  }

  if (!categoryRow) {
    redirect("/tmc");
  }

  if (questionMatch.error) {
    throw new Error(`Failed to load category questions: ${questionMatch.error}`);
  }

  const questionCount = questionMatch.rows.length;
  const categoryName = String(categoryRow.name ?? categorySlug).trim() || categorySlug;

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-4xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        {query.error ? (
          <section className="rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
            {query.error}
          </section>
        ) : null}

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">TMC Category Practice</p>
          <h1 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            {categoryName}
          </h1>
          <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
            Start a focused 20-question category set. Choose tutor mode if you want immediate feedback, or exam mode if
            you want a cleaner board-style run.
          </p>

          <div className="mt-6 grid gap-4 rounded-2xl border border-graysoft/25 bg-background p-5 sm:grid-cols-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">Category</p>
              <p className="mt-2 font-semibold text-charcoal">{categoryName}</p>
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">Questions Available</p>
              <p className="mt-2 font-semibold text-charcoal">{questionCount}</p>
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">Student</p>
              <p className="mt-2 truncate font-semibold text-charcoal">{user.email}</p>
            </div>
          </div>

          <div className="mt-6 flex flex-wrap gap-3">
            <form action={startCategoryAttempt}>
              <input type="hidden" name="category_slug" value={categorySlug} />
              <input type="hidden" name="mode" value="tutor" />
              <button type="submit" className="btn-primary" disabled={questionCount === 0}>
                Start Tutor Mode
              </button>
            </form>

            <form action={startCategoryAttempt}>
              <input type="hidden" name="category_slug" value={categorySlug} />
              <input type="hidden" name="mode" value="exam" />
              <button type="submit" className="btn-secondary" disabled={questionCount === 0}>
                Start Exam Mode
              </button>
            </form>

            <Link href="/tmc" className="btn-secondary">
              Back to TMC Dashboard
            </Link>
          </div>
        </section>

        {questionCount === 0 ? (
          <section className="rounded-2xl border border-amber-300 bg-amber-50 p-5 text-sm text-amber-800">
            No questions are currently mapped to this category slug. Once the category questions are seeded, this page
            will launch the correct practice set instead of sending you back to the hub.
          </section>
        ) : null}
      </div>
    </main>
  );
}
