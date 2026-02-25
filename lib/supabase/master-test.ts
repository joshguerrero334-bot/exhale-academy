import type { createClient as createServerClient } from "./server";
import { getActiveCategoriesWithCounts } from "./taxonomy";

type SupabaseServerClient = Awaited<ReturnType<typeof createServerClient>>;

export type MasterTestQuestion = {
  id: string | number;
  category_slug: string;
  stem: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  correct_answer: "A" | "B" | "C" | "D";
  rationale_correct: string;
};

function shuffleArray<T>(list: T[]) {
  const next = [...list];
  for (let i = next.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [next[i], next[j]] = [next[j], next[i]];
  }
  return next;
}

function buildAllocation(
  availableBySlug: Map<string, number>,
  desiredTotal: number,
  minimumPerCategory: number
) {
  const entries = Array.from(availableBySlug.entries()).filter(([, n]) => n > 0);
  const totalAvailable = entries.reduce((sum, [, n]) => sum + n, 0);
  const total = Math.min(desiredTotal, totalAvailable);
  const eligibleCount = entries.length;

  if (eligibleCount === 0 || total === 0) {
    return new Map<string, number>();
  }

  const allocation = new Map<string, number>();
  const minTarget =
    total >= minimumPerCategory * eligibleCount
      ? minimumPerCategory
      : Math.floor(total / eligibleCount);

  let used = 0;
  for (const [slug, available] of entries) {
    const base = Math.min(available, minTarget);
    allocation.set(slug, base);
    used += base;
  }

  let remaining = total - used;
  if (remaining <= 0) {
    return allocation;
  }

  const capacity = new Map<string, number>();
  for (const [slug, available] of entries) {
    capacity.set(slug, Math.max(available - (allocation.get(slug) ?? 0), 0));
  }

  while (remaining > 0) {
    const availableEntries = Array.from(capacity.entries()).filter(([, cap]) => cap > 0);
    if (availableEntries.length === 0) break;

    const sumCap = availableEntries.reduce((sum, [, cap]) => sum + cap, 0);
    const updates = new Map<string, number>();

    for (const [slug, cap] of availableEntries) {
      const share = Math.floor((remaining * cap) / sumCap);
      if (share > 0) updates.set(slug, share);
    }

    if (updates.size === 0) {
      const [slug] = availableEntries[0];
      updates.set(slug, 1);
    }

    for (const [slug, add] of updates.entries()) {
      if (remaining <= 0) break;
      const cap = capacity.get(slug) ?? 0;
      if (cap <= 0) continue;
      const increment = Math.min(add, cap, remaining);
      allocation.set(slug, (allocation.get(slug) ?? 0) + increment);
      capacity.set(slug, cap - increment);
      remaining -= increment;
    }
  }

  return allocation;
}

export async function generateMasterTestQuestions(
  client: SupabaseServerClient,
  desiredTotal = 160
) {
  const categoriesResult = await getActiveCategoriesWithCounts(client);
  if (categoriesResult.error) {
    return {
      rows: [] as MasterTestQuestion[],
      error: categoriesResult.error,
    };
  }

  const activeSlugs = categoriesResult.rows.map((row) => row.slug).filter(Boolean);
  if (activeSlugs.length === 0) {
    return {
      rows: [] as MasterTestQuestion[],
      error: "No active categories found.",
    };
  }

  const { data, error } = await client
    .from("questions")
    .select(
      "id, category_slug, stem, option_a, option_b, option_c, option_d, correct_answer, rationale_correct"
    )
    .in("category_slug", activeSlugs);

  if (error) {
    return {
      rows: [] as MasterTestQuestion[],
      error: error.message,
    };
  }

  const allQuestions = ((data ?? []) as Record<string, unknown>[])
    .map((row) => {
      const id = row.id as string | number | null | undefined;
      const categorySlug = String(row.category_slug ?? "").trim();
      const stem = String(row.stem ?? "").trim();
      const optionA = String(row.option_a ?? "").trim();
      const optionB = String(row.option_b ?? "").trim();
      const optionC = String(row.option_c ?? "").trim();
      const optionD = String(row.option_d ?? "").trim();
      const correctAnswer = String(row.correct_answer ?? "").trim().toUpperCase();
      if (!id || !categorySlug || !stem || !optionA || !optionB || !optionC || !optionD) return null;
      if (!["A", "B", "C", "D"].includes(correctAnswer)) return null;
      return {
        id,
        category_slug: categorySlug,
        stem,
        option_a: optionA,
        option_b: optionB,
        option_c: optionC,
        option_d: optionD,
        correct_answer: correctAnswer as "A" | "B" | "C" | "D",
        rationale_correct: String(row.rationale_correct ?? "No rationale available."),
      } as MasterTestQuestion;
    })
    .filter(Boolean) as MasterTestQuestion[];

  const grouped = new Map<string, MasterTestQuestion[]>();
  for (const question of allQuestions) {
    const slug = question.category_slug;
    if (!grouped.has(slug)) grouped.set(slug, []);
    grouped.get(slug)!.push(question);
  }

  const availableBySlug = new Map<string, number>();
  for (const slug of activeSlugs) {
    availableBySlug.set(slug, grouped.get(slug)?.length ?? 0);
  }

  const allocation = buildAllocation(availableBySlug, desiredTotal, 8);
  const selected: MasterTestQuestion[] = [];
  const selectedIds = new Set<string>();

  for (const [slug, count] of allocation.entries()) {
    const bucket = shuffleArray(grouped.get(slug) ?? []);
    for (const question of bucket.slice(0, count)) {
      const key = String(question.id);
      if (selectedIds.has(key)) continue;
      selected.push(question);
      selectedIds.add(key);
    }
  }

  const maxTotal = Math.min(desiredTotal, allQuestions.length);
  if (selected.length < maxTotal) {
    const leftovers = shuffleArray(
      allQuestions.filter((q) => !selectedIds.has(String(q.id)))
    );
    for (const question of leftovers) {
      if (selected.length >= maxTotal) break;
      selected.push(question);
      selectedIds.add(String(question.id));
    }
  }

  return {
    rows: shuffleArray(selected),
    error: null,
  };
}
