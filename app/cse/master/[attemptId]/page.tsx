import { redirect } from "next/navigation";
import { createClient } from "../../../../lib/supabase/server";
import { fetchCaseSteps, parseVitalsState } from "../../../../lib/supabase/cse";

type PageProps = {
  params: Promise<{ attemptId: string }>;
};

type MasterAttemptRow = {
  id: string;
  user_id: string;
  mode: "tutor" | "exam";
  status: "in_progress" | "completed";
};

type MasterAttemptCaseRow = {
  id: string;
  attempt_id: string;
  case_id: string;
  order_index: number;
  status: "pending" | "in_progress" | "completed";
  cse_attempt_id: string | null;
  case_score: number | null;
};

function randomInt(min: number, max: number) {
  const lo = Math.ceil(min);
  const hi = Math.floor(max);
  return Math.floor(Math.random() * (hi - lo + 1)) + lo;
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

function varyBaselineVitals(vitals: Record<string, number>) {
  const next = { ...vitals };
  if (typeof next.hr === "number") next.hr = clamp(next.hr + randomInt(-4, 4), 45, 180);
  if (typeof next.rr === "number") next.rr = clamp(next.rr + randomInt(-2, 2), 8, 65);
  if (typeof next.spo2 === "number") next.spo2 = clamp(next.spo2 + randomInt(-2, 1), 65, 100);
  if (typeof next.bp_sys === "number") next.bp_sys = clamp(next.bp_sys + randomInt(-6, 6), 50, 220);
  if (typeof next.bp_dia === "number") next.bp_dia = clamp(next.bp_dia + randomInt(-4, 4), 25, 130);
  if (typeof next.etco2 === "number") next.etco2 = clamp(next.etco2 + randomInt(-3, 3), 20, 80);
  return next;
}

async function createCaseAttemptForMaster(args: {
  supabase: Awaited<ReturnType<typeof createClient>>;
  userId: string;
  mode: "tutor" | "exam";
  caseId: string;
}) {
  const { supabase, caseId, mode, userId } = args;

  const { data: caseRow, error: caseError } = await supabase
    .from("cse_cases")
    .select("id, baseline_vitals, is_active, is_published")
    .eq("id", caseId)
    .maybeSingle();

  if (caseError || !caseRow || !caseRow.is_active || !caseRow.is_published) {
    return { attemptId: null as string | null, error: "Case unavailable for master exam." };
  }

  const stepsResult = await fetchCaseSteps(supabase, caseId);
  if (stepsResult.error || stepsResult.rows.length === 0) {
    return { attemptId: null as string | null, error: stepsResult.error ?? "Case steps missing." };
  }

  const { data: created, error: attemptError } = await supabase
    .from("cse_attempts")
    .insert({
      user_id: userId,
      case_id: caseId,
      mode,
      status: "in_progress",
      current_step_id: stepsResult.rows[0].id,
      total_score: 0,
      vitals: varyBaselineVitals(parseVitalsState(caseRow.baseline_vitals)),
    })
    .select("id")
    .single();

  if (attemptError || !created) {
    return {
      attemptId: null as string | null,
      error: attemptError?.message ?? "Could not create case attempt.",
    };
  }

  return { attemptId: created.id, error: null as string | null };
}

export default async function CseMasterAttemptOrchestratorPage({ params }: PageProps) {
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
    .select("id, user_id, mode, status")
    .eq("id", attemptId)
    .maybeSingle();

  const attempt = (attemptData ?? null) as MasterAttemptRow | null;
  if (attemptError || !attempt || attempt.user_id !== user.id) {
    redirect("/cse/master?error=Master%20attempt%20not%20found");
  }

  if (attempt.status === "completed") {
    redirect(`/cse/master/${encodeURIComponent(attempt.id)}/results`);
  }

  const { data: itemData, error: itemError } = await supabase
    .from("cse_master_attempt_cases")
    .select("id, attempt_id, case_id, order_index, status, cse_attempt_id, case_score")
    .eq("attempt_id", attempt.id)
    .order("order_index", { ascending: true });

  if (itemError || !itemData || itemData.length === 0) {
    redirect("/cse/master?error=Master%20attempt%20items%20missing");
  }

  const items = itemData as MasterAttemptCaseRow[];
  if (items.length < 20) {
    const completedCases = items.filter((row) => row.status === "completed").length;
    const totalScore = items.reduce((sum, row) => sum + Number(row.case_score ?? 0), 0);
    await supabase
      .from("cse_master_attempts")
      .update({
        status: "completed",
        completed_cases: completedCases,
        total_score: totalScore,
        completed_at: new Date().toISOString(),
      })
      .eq("id", attempt.id);
    redirect(
      "/cse/master?error=This%20master%20attempt%20was%20created%20before%20the%2020-case%20update.%20Please%20start%20a%20new%20master%20attempt."
    );
  }

  // If an in-progress case attempt is already linked, route to it.
  const inProgressItem = items.find((row) => row.status === "in_progress") ?? null;
  if (inProgressItem?.cse_attempt_id) {
    const { data: linkedAttempt } = await supabase
      .from("cse_attempts")
      .select("id, status")
      .eq("id", inProgressItem.cse_attempt_id)
      .maybeSingle();

    if (linkedAttempt && linkedAttempt.status === "in_progress") {
      redirect(`/cse/attempt/${encodeURIComponent(String(linkedAttempt.id))}`);
    }
    if (linkedAttempt && linkedAttempt.status === "completed") {
      const { data: linkedScore } = await supabase
        .from("cse_attempts")
        .select("total_score")
        .eq("id", inProgressItem.cse_attempt_id)
        .maybeSingle();
      await supabase
        .from("cse_master_attempt_cases")
        .update({
          status: "completed",
          case_score: Number(linkedScore?.total_score ?? 0),
          completed_at: new Date().toISOString(),
        })
        .eq("id", inProgressItem.id);
      redirect(`/cse/master/${encodeURIComponent(attempt.id)}`);
    }
  }

  // If no active linked case, start next pending.
  const nextPending = items.find((row) => row.status === "pending") ?? null;

  if (!nextPending) {
    const completedCases = items.filter((row) => row.status === "completed").length;
    const totalScore = items.reduce((sum, row) => sum + Number(row.case_score ?? 0), 0);
    await supabase
      .from("cse_master_attempts")
      .update({
        status: "completed",
        completed_cases: completedCases,
        total_score: totalScore,
        completed_at: new Date().toISOString(),
      })
      .eq("id", attempt.id);
    redirect(`/cse/master/${encodeURIComponent(attempt.id)}/results`);
  }

  const { error: markError } = await supabase
    .from("cse_master_attempt_cases")
    .update({
      status: "in_progress",
      started_at: new Date().toISOString(),
    })
    .eq("id", nextPending.id)
    .eq("status", "pending");

  if (markError) {
    redirect(`/cse/master?error=${encodeURIComponent(markError.message)}`);
  }

  const created = await createCaseAttemptForMaster({
    supabase,
    userId: user.id,
    mode: attempt.mode,
    caseId: nextPending.case_id,
  });

  if (created.error || !created.attemptId) {
    redirect(`/cse/master?error=${encodeURIComponent(created.error ?? "Could not start case.")}`);
  }

  const { error: linkError } = await supabase
    .from("cse_master_attempt_cases")
    .update({
      cse_attempt_id: created.attemptId,
    })
    .eq("id", nextPending.id);

  if (linkError) {
    redirect(`/cse/master?error=${encodeURIComponent(`Could not link case attempt. ${linkError.message}`)}`);
  }

  redirect(`/cse/attempt/${encodeURIComponent(created.attemptId)}`);
}
