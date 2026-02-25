import { createClient } from "./server";

export type QuestionRow = {
  id: string | number;
  category: string;
  sub_concept: string | null;
  difficulty: string | null;
  cognitive_level: string | null;
  exam_priority: string | null;
  stem: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  correct_answer: "A" | "B" | "C" | "D";
  rationale_correct: string | null;
  rationale_why_others_wrong: Record<string, string> | string | null;
  keywords_to_notice: string[] | string | null;
  common_trap: string | null;
  exam_logic: string | null;
  qa_summary: string | null;
};

export async function getCategories() {
  const supabase = await createClient();

  // For small dataset, simplest is: fetch all categories and uniq in JS
  const { data, error } = await supabase
    .from("questions")
    .select("category");

  if (error) throw new Error(error.message);

  const uniq = Array.from(new Set((data ?? []).map((r) => r.category))).sort();
  return uniq;
}

export async function getQuestionsByCategory(category: string) {
  const supabase = await createClient();

  // 100 questions total — ordering random is fine for MVP
  const { data, error } = await supabase
    .from("questions")
    .select("*")
    .eq("category", category)
    .order("id", { ascending: true });

  if (error) throw new Error(error.message);
  return (data ?? []) as QuestionRow[];
}
