"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../../../lib/supabase/server";

function toAnswer(value: FormDataEntryValue | null) {
  const upper = String(value ?? "").trim().toUpperCase();
  if (upper === "A" || upper === "B" || upper === "C" || upper === "D") return upper;
  return null;
}

export async function saveCategoryAnswer(formData: FormData) {
  const attemptId = String(formData.get("attempt_id") ?? "").trim();
  const itemId = String(formData.get("item_id") ?? "").trim();
  const slug = String(formData.get("category_slug") ?? "").trim().toLowerCase();
  const index = Number.parseInt(String(formData.get("index") ?? "0"), 10);
  const selectedAnswer = toAnswer(formData.get("selected_answer"));

  if (!attemptId || !itemId || !slug || !selectedAnswer) {
    redirect("/dashboard?error=Invalid%20answer%20submission");
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const { data: attempt, error: attemptError } = await supabase
    .from("category_quiz_attempts")
    .select("id, user_id, completed_at")
    .eq("id", attemptId)
    .single();

  if (attemptError || !attempt || attempt.user_id !== user.id) {
    redirect("/dashboard?error=Attempt%20not%20found");
  }

  if (attempt.completed_at) {
    redirect(`/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}/results`);
  }

  const { data: item, error: itemError } = await supabase
    .from("category_quiz_attempt_questions")
    .select("id, question_id")
    .eq("id", itemId)
    .eq("attempt_id", attemptId)
    .single();

  if (itemError || !item) {
    redirect(`/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}?error=Attempt%20question%20not%20found`);
  }

  const { data: question, error: questionError } = await supabase
    .from("questions")
    .select("id, correct_answer")
    .eq("id", item.question_id)
    .single();

  if (questionError || !question) {
    redirect(`/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}?error=Question%20not%20found`);
  }

  const correctAnswer = String(question.correct_answer ?? "").toUpperCase();
  const isCorrect = selectedAnswer === correctAnswer;

  const { error: updateError } = await supabase
    .from("category_quiz_attempt_questions")
    .update({
      selected_answer: selectedAnswer,
      is_correct: isCorrect,
    })
    .eq("id", itemId)
    .eq("attempt_id", attemptId);

  if (updateError) {
    redirect(
      `/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(
        `Failed to save answer. ${updateError.message}`
      )}`
    );
  }

  const safeIndex = Number.isNaN(index) ? 0 : Math.max(index, 0);
  redirect(`/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}?i=${safeIndex}`);
}

export async function finalizeCategoryAttempt(formData: FormData) {
  const attemptId = String(formData.get("attempt_id") ?? "").trim();
  const slug = String(formData.get("category_slug") ?? "").trim().toLowerCase();

  if (!attemptId || !slug) {
    redirect("/dashboard?error=Invalid%20submit%20request");
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const { data: attempt, error: attemptError } = await supabase
    .from("category_quiz_attempts")
    .select("id, user_id, completed_at")
    .eq("id", attemptId)
    .single();

  if (attemptError || !attempt || attempt.user_id !== user.id) {
    redirect("/dashboard?error=Attempt%20not%20found");
  }

  if (attempt.completed_at) {
    redirect(`/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}/results`);
  }

  const { data: itemsData, error: itemsError } = await supabase
    .from("category_quiz_attempt_questions")
    .select("selected_answer, is_correct")
    .eq("attempt_id", attemptId);

  if (itemsError) {
    redirect(
      `/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(
        `Failed to finalize quiz. ${itemsError.message}`
      )}`
    );
  }

  const items = itemsData ?? [];
  const unanswered = items.filter((row) => !row.selected_answer).length;
  if (unanswered > 0) {
    redirect(
      `/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(
        `Please answer all questions before submitting. Remaining: ${unanswered}`
      )}`
    );
  }

  const score = items.filter((row) => row.is_correct).length;

  const { error: updateError } = await supabase
    .from("category_quiz_attempts")
    .update({
      score,
      completed_at: new Date().toISOString(),
    })
    .eq("id", attemptId)
    .eq("user_id", user.id);

  if (updateError) {
    redirect(
      `/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}?error=${encodeURIComponent(
        `Failed to complete quiz. ${updateError.message}`
      )}`
    );
  }

  redirect(`/quiz/${encodeURIComponent(slug)}/${encodeURIComponent(attemptId)}/results`);
}
