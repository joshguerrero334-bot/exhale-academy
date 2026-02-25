import Link from "next/link";
import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../../../components/PracticeSwitchBar";
import { createClient } from "../../../../lib/supabase/server";
import { fetchCaseSteps } from "../../../../lib/supabase/cse";
import { createCseAttempt } from "./actions";
import { headingFont } from "../../../../lib/fonts";

type PageProps = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ error?: string; preview?: string }>;
};

type AttemptRow = {
  id: string;
  mode: "tutor" | "exam";
  created_at: string;
};

export default async function CseCaseStartBySlugPage({ params, searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fcases");
  }

  const { slug } = await params;
  const query = await searchParams;
  const previewMode = query.preview === "1";

  const baseSelect = "id, slug, source, title, intro_text, stem, is_active, is_published";
  let cseCase: {
    id: string;
    slug: string | null;
    source: string | null;
    title: string;
    intro_text: string | null;
    stem: string | null;
    is_active: boolean | null;
    is_published: boolean | null;
  } | null = null;
  let caseError: { message?: string } | null = null;

  const bySlug = await supabase.from("cse_cases").select(baseSelect).eq("slug", slug).maybeSingle();
  cseCase = bySlug.data ?? null;
  caseError = bySlug.error;

  // Backward compatibility for routes that may still pass a case UUID.
  if (!cseCase && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(slug)) {
    const byId = await supabase.from("cse_cases").select(baseSelect).eq("id", slug).maybeSingle();
    cseCase = byId.data ?? null;
    caseError = byId.error;
  }

  if (caseError || !cseCase || !cseCase.is_active || (!cseCase.is_published && !previewMode)) {
    redirect("/cse/cases?error=Case%20not%20found");
  }
  const caseRef = cseCase.slug && cseCase.slug.trim().length > 0 ? cseCase.slug : cseCase.id;

  const [stepsResult, attemptResult] = await Promise.all([
    fetchCaseSteps(supabase, cseCase.id),
    supabase
      .from("cse_attempts")
      .select("id, mode, created_at")
      .eq("user_id", user.id)
      .eq("case_id", cseCase.id)
      .eq("status", "in_progress")
      .order("created_at", { ascending: false })
      .limit(1),
  ]);

  const inProgress = ((attemptResult.data ?? [])[0] ?? null) as AttemptRow | null;

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />
      <div className="mx-auto w-full max-w-5xl space-y-5 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            {cseCase.source ?? "cse"}
          </p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>{cseCase.title}</h1>
          <p className="mt-3 text-sm text-graysoft">{cseCase.intro_text ?? cseCase.stem ?? "Clinical simulation scenario."}</p>

          {query.error ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">{query.error}</div>
          ) : null}

          {stepsResult.error ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              Could not load case steps: {stepsResult.error}
            </div>
          ) : null}

          {inProgress ? (
            <div className="mt-5 rounded-xl border border-graysoft/30 bg-background p-4">
              <p className="text-sm font-semibold text-charcoal">
                In-progress attempt ({inProgress.mode === "tutor" ? "Tutor" : "Exam"} Mode)
              </p>
              <p className="mt-1 text-xs text-graysoft">Created: {new Date(inProgress.created_at).toLocaleString()}</p>
              <div className="mt-4 flex flex-wrap gap-3">
                <Link href={`/cse/attempt/${encodeURIComponent(inProgress.id)}`} className="btn-primary">
                  Resume Attempt
                </Link>
                <form action={createCseAttempt}>
                  <input type="hidden" name="case_id" value={cseCase.id} />
                  <input type="hidden" name="slug" value={caseRef} />
                  <input type="hidden" name="mode" value={inProgress.mode} />
                  <input type="hidden" name="preview" value={previewMode ? "1" : "0"} />
                  <button className="btn-secondary">
                    Start New Attempt
                  </button>
                </form>
              </div>
            </div>
          ) : (
            <form action={createCseAttempt} className="mt-5 space-y-3">
              <input type="hidden" name="case_id" value={cseCase.id} />
              <input type="hidden" name="slug" value={caseRef} />
              <input type="hidden" name="preview" value={previewMode ? "1" : "0"} />
              <div className="grid gap-3 sm:grid-cols-2">
                <button type="submit" name="mode" value="tutor" className="rounded-xl border border-primary/40 bg-background p-4 text-left transition hover:bg-primary/5" aria-pressed="true">
                  <p className="text-sm font-semibold text-primary">Tutor Mode</p>
                  <p className="mt-1 text-xs text-graysoft">Show rationale and scoring after each step</p>
                </button>
                <button type="submit" name="mode" value="exam" className="rounded-xl border border-primary/40 bg-background p-4 text-left transition hover:bg-primary/5" aria-pressed="false">
                  <p className="text-sm font-semibold text-primary">Exam Mode</p>
                  <p className="mt-1 text-xs text-graysoft">Hide rationale and scores until completion</p>
                </button>
              </div>
            </form>
          )}

          <div className="mt-5">
            <Link href="/cse/cases" className="btn-secondary">
              Back to Cases
            </Link>
          </div>
        </section>
      </div>
    </main>
  );
}
