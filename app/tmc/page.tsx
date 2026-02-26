import Link from "next/link";
import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../components/PracticeSwitchBar";
import { createClient } from "../../lib/supabase/server";
import { headingFont } from "../../lib/fonts";
import { getActiveCategoriesWithCounts } from "../../lib/supabase/taxonomy";
import { isAdminUser } from "../../lib/auth/admin";

type TmcPageProps = {
  searchParams: Promise<{ error?: string }>;
};

export default async function TmcPage({ searchParams }: TmcPageProps) {
  const supabase = await createClient();

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Ftmc");
  }

  const canAccessAdminTools = isAdminUser({ id: user.id, email: user.email ?? null });

  const [categoriesResult, query] = await Promise.all([
    getActiveCategoriesWithCounts(supabase),
    searchParams,
  ]);

  const categoryCards = categoriesResult.rows.map((row) => ({
    slug: row.slug.trim(),
    name: row.name.trim(),
  }));

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <PracticeSwitchBar active="tmc" cseHref="/cse/introduction" tmcHref="/tmc" />

      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            TMC Practice
          </p>
          <h1 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            Categories + Full-Length Exam
          </h1>
          <p className="mt-3 text-sm text-graysoft sm:text-base">
            Drill by category or start a 160-question mixed exam. Signed in as{" "}
            <span className="font-semibold text-charcoal">{user.email}</span>
          </p>

          <div className="mt-6 flex flex-wrap gap-3">
            <Link href="/master" className="btn-primary">
              Start 160-Question TMC Practice Exam
            </Link>
            <Link href="/billing" className="btn-primary">
              Unlock Full Access
            </Link>
            <Link href="/tmc/exam" className="btn-secondary">
              Review Tutor vs Exam Modes
            </Link>
            <Link href="/feedback" className="btn-secondary">
              How can we get better?
            </Link>
          </div>
        </section>

        {query.error ? (
          <section className="rounded-2xl border border-red-300 bg-red-50 p-4 text-sm text-red-700">
            {query.error}
          </section>
        ) : null}

        {categoriesResult.error ? (
          <section className="rounded-2xl border border-red-300 bg-red-50 p-5 text-sm text-red-700">
            <p className="font-semibold">Category taxonomy setup is incomplete.</p>
            <p className="mt-2 text-xs">categories error: {categoriesResult.error ?? "none"}</p>
            {canAccessAdminTools ? (
              <Link href="/admin/tools" className="btn-primary mt-3">
                Open Admin Tools
              </Link>
            ) : null}
          </section>
        ) : null}

        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className={`${headingFont} text-xl font-semibold text-charcoal`}>Practice Categories</h2>
            {canAccessAdminTools ? (
              <Link href="/admin/tools" className="text-sm font-semibold text-primary underline">
                Admin Tools
              </Link>
            ) : null}
          </div>

          {categoryCards.length === 0 ? (
            <div className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 text-sm text-slate-600 shadow-sm">
              <p>No active categories found in `categories` table.</p>
            </div>
          ) : (
            <div className="grid gap-4 md:grid-cols-2">
              {categoryCards.map((row) => (
                <article
                  key={row.slug}
                  className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-primary hover:shadow-md"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <h3 className="text-xl font-semibold text-charcoal">{row.name}</h3>
                    </div>
                  </div>

                  <div className="mt-5 border-t border-graysoft/30 pt-4">
                    <Link
                      href={`/quiz/${encodeURIComponent(row.slug)}`}
                      className="btn-primary w-full"
                    >
                      Start Practice Test
                    </Link>
                  </div>
                </article>
              ))}
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
