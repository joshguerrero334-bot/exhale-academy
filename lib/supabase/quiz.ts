import type { createClient as createServerClient } from "./server";

export type SupabaseServerClient = Awaited<ReturnType<typeof createServerClient>>;

export type QuizMode = "tutor" | "exam";

export type QuestionRow = {
  id: string | number;
  category_slug: string | null;
  stem: string | null;
  option_a: string | null;
  option_b: string | null;
  option_c: string | null;
  option_d: string | null;
  correct_answer: "A" | "B" | "C" | "D" | null;
  rationale_correct: string | null;
  rationale_why_others_wrong: Record<string, string> | string | null;
};

export const QUESTION_FIELDS =
  "id, category_slug, stem, option_a, option_b, option_c, option_d, correct_answer, rationale_correct, rationale_why_others_wrong";

export const QUESTION_FIELDS_FALLBACK =
  "id, category_slug, stem, option_a, option_b, option_c, option_d, correct_answer, rationale_correct";

export function toQuizMode(value: string | null): QuizMode {
  return value === "exam" ? "exam" : "tutor";
}

export function shuffleArray<T>(list: T[]) {
  const next = [...list];
  for (let i = next.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [next[i], next[j]] = [next[j], next[i]];
  }
  return next;
}

export function clampIndex(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}

export async function loadQuestionsBySlug(
  client: SupabaseServerClient,
  categorySlug: string
) {
  const primary = await client
    .from("questions")
    .select(QUESTION_FIELDS)
    .eq("category_slug", categorySlug);

  if (!primary.error) {
    return {
      rows: (primary.data ?? []) as QuestionRow[],
      compatibilityMode: false,
      error: null as string | null,
    };
  }

  const fallback = await client
    .from("questions")
    .select(QUESTION_FIELDS_FALLBACK)
    .eq("category_slug", categorySlug);

  if (fallback.error) {
    return {
      rows: [] as QuestionRow[],
      compatibilityMode: false,
      error: fallback.error.message,
    };
  }

  return {
    rows: (fallback.data ?? []) as QuestionRow[],
    compatibilityMode: true,
    error: null as string | null,
  };
}

export function normalizeRationaleWhyOthers(value: QuestionRow["rationale_why_others_wrong"]) {
  if (!value) return null;
  if (typeof value === "string") return value;

  const lines = ["A", "B", "C", "D"]
    .map((key) => {
      const text = String(value[key] ?? "").trim();
      return text ? `${key}: ${text}` : "";
    })
    .filter(Boolean);

  return lines.length > 0 ? lines.join("\n") : null;
}
