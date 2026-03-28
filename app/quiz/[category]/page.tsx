import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "../../../lib/supabase/server";

export default async function QuizCategoryPage({
  params,
}: {
  params: { category: string };
}) {
  const supabase = await createClient();

  // Auth guard
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const category = decodeURIComponent(params.category ?? "");

  if (!category) {
    redirect("/dashboard");
  }

  const { data: questions, error } = await supabase
    .from("questions")
    .select(
      "id, category, stem, option_a, option_b, option_c, option_d, correct_answer, rationale_correct"
    )
    .eq("category", category)
    .order("id", { ascending: true })
    .limit(50);

  if (error) {
    throw new Error(`Failed to load questions: ${error.message}`);
  }

  const count = questions?.length ?? 0;

  return (
    <main className="min-h-screen bg-black px-6 py-12 text-white">
      <div className="mx-auto max-w-2xl">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm uppercase tracking-widest text-white/70">
              Exhale Academy
            </p>
            <h1 className="mt-2 text-2xl font-bold">{category}</h1>
            <p className="mt-1 text-sm text-white/60">
              {count} question{count === 1 ? "" : "s"} loaded
            </p>
          </div>

          <Link
            href="/dashboard"
            className="rounded-lg border border-white/20 px-4 py-2 text-sm font-semibold hover:border-white/40"
          >
            Back
          </Link>
        </div>

        {count === 0 ? (
          <div className="mt-8 rounded-xl border border-white/10 bg-white/5 p-4 text-sm text-white/60">
            No questions found for{" "}
            <span className="text-white/80">{category}</span>.
            <div className="mt-3 text-xs text-white/50">
              Most common causes: category text mismatch (extra spaces), or your
              data didn’t actually import into the <code>questions</code> table.
            </div>
          </div>
        ) : (
          <div className="mt-8 space-y-4">
            {questions!.map((q, idx) => (
              <div
                key={q.id}
                className="rounded-xl border border-white/10 bg-white/5 p-5"
              >
                <div className="text-xs text-white/50">Q{idx + 1}</div>
                <div className="mt-2 font-semibold">{q.stem}</div>

                <div className="mt-4 space-y-2 text-sm">
                  <div className="rounded-lg border border-white/10 p-3">
                    <b>A.</b> {q.option_a}
                  </div>
                  <div className="rounded-lg border border-white/10 p-3">
                    <b>B.</b> {q.option_b}
                  </div>
                  <div className="rounded-lg border border-white/10 p-3">
                    <b>C.</b> {q.option_c}
                  </div>
                  <div className="rounded-lg border border-white/10 p-3">
                    <b>D.</b> {q.option_d}
                  </div>
                </div>

                <div className="mt-4 text-xs text-white/60">
                  <span className="text-white/80">Answer:</span> {q.correct_answer}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}