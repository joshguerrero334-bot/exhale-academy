import Link from "next/link";
import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../../../../components/PracticeSwitchBar";
import { createClient } from "../../../../../lib/supabase/server";
import { headingFont } from "../../../../../lib/fonts";

type PageProps = {
  params: Promise<{ attemptId: string }>;
};

type MasterAttemptRow = {
  id: string;
  user_id: string;
  mode: "tutor" | "exam";
  status: "in_progress" | "completed";
  total_cases: number;
  completed_cases: number;
  total_score: number;
  created_at: string;
  completed_at: string | null;
};

type MasterItemRow = {
  id: string;
  case_id: string;
  order_index: number;
  blueprint_category_code: string;
  blueprint_subcategory: string | null;
  status: "pending" | "in_progress" | "completed";
  case_score: number | null;
};

export default async function CseMasterAttemptResultsPage({ params }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fmaster");
  }

  const { attemptId } = await params;

  const { data: attemptData, error: attemptError } = await supabase
    .from("cse_master_attempts")
    .select("id, user_id, mode, status, total_cases, completed_cases, total_score, created_at, completed_at")
    .eq("id", attemptId)
    .maybeSingle();

  const attempt = (attemptData ?? null) as MasterAttemptRow | null;
  if (attemptError || !attempt || attempt.user_id !== user.id) {
    redirect("/cse/master?error=Master%20attempt%20not%20found");
  }

  const { data: itemData, error: itemError } = await supabase
    .from("cse_master_attempt_cases")
    .select("id, case_id, order_index, blueprint_category_code, blueprint_subcategory, status, case_score")
    .eq("attempt_id", attempt.id)
    .order("order_index", { ascending: true });

  if (itemError || !itemData) {
    redirect("/cse/master?error=Master%20attempt%20items%20missing");
  }

  const items = itemData as MasterItemRow[];
  const pending = items.find((row) => row.status !== "completed");
  if (pending) {
    redirect(`/cse/master/${encodeURIComponent(attempt.id)}`);
  }

  const byCategory = new Map<string, { count: number; score: number }>();
  for (const item of items) {
    const key = item.blueprint_category_code || "?";
    const current = byCategory.get(key) ?? { count: 0, score: 0 };
    current.count += 1;
    current.score += Number(item.case_score ?? 0);
    byCategory.set(key, current);
  }

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />
      <div className="mx-auto w-full max-w-5xl space-y-5 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Master CSE Results</p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal`}>20-Case Exam Summary</h1>
          <p className="mt-2 text-sm text-graysoft">
            Mode: {attempt.mode === "tutor" ? "Tutor" : "Exam"} · Completed {attempt.completed_cases}/{attempt.total_cases}
          </p>
          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            <div className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Total Score</p>
              <p className="mt-1 text-2xl font-bold text-charcoal">{attempt.total_score}</p>
            </div>
            <div className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Started</p>
              <p className="mt-1 text-sm font-semibold text-charcoal">{new Date(attempt.created_at).toLocaleString()}</p>
            </div>
            <div className="rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Completed</p>
              <p className="mt-1 text-sm font-semibold text-charcoal">
                {attempt.completed_at ? new Date(attempt.completed_at).toLocaleString() : "In progress"}
              </p>
            </div>
          </div>
          <div className="mt-5 flex gap-3">
            <Link href="/cse/master" className="btn-primary">
              Start New Master Attempt
            </Link>
            <Link href="/cse/cases" className="btn-secondary">
              Browse Case Library
            </Link>
          </div>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
          <h2 className={`${headingFont} text-lg font-semibold text-charcoal`}>Blueprint Category Breakdown</h2>
          <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {Array.from(byCategory.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([code, stats]) => (
                <div key={code} className="rounded-xl border border-graysoft/30 bg-background p-3">
                  <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Category {code}</p>
                  <p className="mt-1 text-sm font-semibold text-charcoal">{stats.count} cases</p>
                  <p className="text-xs text-slate-600">Score: {stats.score}</p>
                </div>
              ))}
          </div>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm">
          <h2 className={`${headingFont} text-lg font-semibold text-charcoal`}>Case-by-Case Results</h2>
          <div className="mt-3 space-y-2">
            {items.map((item) => (
              <div key={item.id} className="rounded-xl border border-graysoft/30 bg-background p-3">
                <p className="text-sm font-semibold text-charcoal">
                  Case {item.order_index + 1}
                </p>
                <p className="mt-1 text-xs text-slate-600">
                  Category {item.blueprint_category_code}
                  {item.blueprint_subcategory ? ` · ${item.blueprint_subcategory}` : ""}
                  {" · "}Score {Number(item.case_score ?? 0)}
                </p>
              </div>
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}
