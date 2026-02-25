import type { createClient as createServerClient } from "./server";

type SupabaseServerClient = Awaited<ReturnType<typeof createServerClient>>;

export type ActiveCategory = {
  slug: string;
  name: string;
  sort_order: number;
  is_active: boolean;
};

export type CategoryWithCount = ActiveCategory & {
  question_count: number;
};

type QuestionSlugRow = {
  category_slug: string | null;
};

export async function getActiveCategories(client: SupabaseServerClient) {
  const { data, error } = await client
    .from("categories")
    .select("slug, name, sort_order, is_active")
    .eq("is_active", true)
    .order("sort_order", { ascending: true });

  if (error) {
    return {
      rows: [] as ActiveCategory[],
      error: error.message,
    };
  }

  const rows = ((data ?? []) as ActiveCategory[]).filter(
    (row) => row.slug && row.name && row.is_active
  );

  return {
    rows,
    error: null,
  };
}

export async function getActiveCategoriesWithCounts(client: SupabaseServerClient) {
  const categoriesResult = await getActiveCategories(client);
  const categories = categoriesResult.rows;
  const slugs = categories.map((c) => c.slug.trim()).filter(Boolean);

  let questionSlugData: QuestionSlugRow[] = [];
  let questionError: string | null = null;

  if (slugs.length > 0) {
    const { data, error } = await client
      .from("questions")
      .select("category_slug")
      .in("category_slug", slugs);

    if (error) {
      questionError = error.message;
    } else {
      questionSlugData = (data ?? []) as QuestionSlugRow[];
    }
  }

  const counts = new Map<string, number>();
  for (const row of questionSlugData) {
    const slug = String(row.category_slug ?? "").trim();
    if (!slug) continue;
    counts.set(slug, (counts.get(slug) ?? 0) + 1);
  }

  const rows: CategoryWithCount[] = categories.map((row) => ({
    ...row,
    question_count: counts.get(row.slug.trim()) ?? 0,
  }));

  return {
    rows,
    error: categoriesResult.error ?? questionError,
  };
}

export async function getQuestionSlugCounts(client: SupabaseServerClient) {
  const { data, error } = await client.from("questions").select("category_slug");
  if (error) {
    return {
      total: 0,
      unassigned: 0,
      counts: new Map<string, number>(),
      error: error.message,
    };
  }

  const counts = new Map<string, number>();
  let total = 0;
  let unassigned = 0;

  for (const row of (data ?? []) as QuestionSlugRow[]) {
    total += 1;
    const slug = String(row.category_slug ?? "").trim();
    if (!slug) {
      unassigned += 1;
      continue;
    }
    counts.set(slug, (counts.get(slug) ?? 0) + 1);
  }

  return {
    total,
    unassigned,
    counts,
    error: null,
  };
}
