import type { createClient as createServerClient } from "./server";

type SupabaseServerClient = Awaited<ReturnType<typeof createServerClient>>;

type CseCasePoolRow = {
  id: string;
  slug: string | null;
  title: string | null;
  disease_slug: string | null;
  nbrc_category_code: string | null;
  nbrc_subcategory: string | null;
};

export type CseMasterBlueprintPick = {
  case_id: string;
  slug: string;
  title: string;
  blueprint_category_code: string;
  blueprint_subcategory: string | null;
};

function shuffleArray<T>(rows: T[]) {
  const copy = [...rows];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

function normalize(value: string | null | undefined) {
  return String(value ?? "").trim().toLowerCase();
}

function subcategoryMatches(row: CseCasePoolRow, target: string) {
  const needle = normalize(target);
  const sub = normalize(row.nbrc_subcategory);
  const disease = normalize(row.disease_slug);
  const title = normalize(row.title);

  if (!needle) return false;
  if (sub === needle) return true;

  // Blueprint-alias handling where historical data may be normalized differently.
  if (needle === "asthma") {
    return disease.includes("asthma") || title.includes("asthma");
  }
  if (needle.includes("cystic fibrosis")) {
    return (
      disease.includes("cystic-fibrosis") ||
      disease.includes("bronchiectasis") ||
      sub.includes("cystic fibrosis") ||
      sub.includes("bronchiectasis")
    );
  }
  if (needle === "respiratory distress syndrome") {
    return sub.includes("respiratory distress syndrome") || disease.includes("irds");
  }

  return false;
}

type CategoryBlueprint = {
  code: string;
  total: number;
  subcategoryTargets?: Array<{ subcategory: string; count: number }>;
};

const CSE_TEST_DAY_BLUEPRINT: CategoryBlueprint[] = [
  {
    code: "A",
    total: 7,
    subcategoryTargets: [
      { subcategory: "Intubation and mechanical ventilation", count: 2 },
      { subcategory: "Noninvasive management", count: 2 },
      { subcategory: "Outpatient management of COPD", count: 1 },
      { subcategory: "Outpatient management of asthma", count: 1 },
      { subcategory: "Diagnosis", count: 1 },
    ],
  },
  { code: "B", total: 1 },
  {
    code: "C",
    total: 2,
    subcategoryTargets: [
      { subcategory: "Heart failure", count: 1 },
      { subcategory: "Other", count: 1 },
    ],
  },
  { code: "D", total: 1 },
  {
    code: "E",
    total: 5,
    subcategoryTargets: [
      { subcategory: "Cystic fibrosis or non-cystic fibrosis bronchiectasis", count: 1 },
      { subcategory: "Infectious disease", count: 1 },
      { subcategory: "Acute respiratory distress syndrome", count: 1 },
      { subcategory: "Other", count: 2 },
    ],
  },
  {
    code: "F",
    total: 2,
    subcategoryTargets: [
      { subcategory: "Asthma", count: 1 },
      { subcategory: "Other", count: 1 },
    ],
  },
  {
    code: "G",
    total: 2,
    subcategoryTargets: [
      { subcategory: "Respiratory distress syndrome", count: 1 },
      { subcategory: "Resuscitation", count: 1 },
    ],
  },
];

export async function generateCseMasterCaseBlueprint(
  client: SupabaseServerClient,
  desiredTotal = 20
) {
  const { data, error } = await client
    .from("cse_cases")
    .select("id, slug, title, disease_slug, nbrc_category_code, nbrc_subcategory")
    .eq("is_active", true)
    .eq("is_published", true)
    .not("nbrc_category_code", "is", null);

  if (error) {
    return {
      rows: [] as CseMasterBlueprintPick[],
      error: error.message,
    };
  }

  const pool = ((data ?? []) as CseCasePoolRow[]).filter(
    (row) => row.id && normalize(row.nbrc_category_code)
  );

  const usedCaseIds = new Set<string>();
  const selected: CseMasterBlueprintPick[] = [];
  const deficits: string[] = [];

  for (const categoryPlan of CSE_TEST_DAY_BLUEPRINT) {
    const categoryPool = shuffleArray(
      pool.filter((row) => normalize(row.nbrc_category_code) === normalize(categoryPlan.code))
    );

    let categorySelected = 0;

    for (const target of categoryPlan.subcategoryTargets ?? []) {
      const matches = categoryPool.filter(
        (row) => !usedCaseIds.has(row.id) && subcategoryMatches(row, target.subcategory)
      );
      const chosen = matches.slice(0, target.count);

      for (const row of chosen) {
        usedCaseIds.add(row.id);
        selected.push({
          case_id: row.id,
          slug: String(row.slug ?? row.id),
          title: String(row.title ?? "Untitled case"),
          blueprint_category_code: categoryPlan.code,
          blueprint_subcategory: target.subcategory,
        });
        categorySelected += 1;
      }

      if (chosen.length < target.count) {
        deficits.push(
          `${categoryPlan.code}/${target.subcategory}: needed ${target.count}, found ${chosen.length}`
        );
      }
    }

    const needRemainder = Math.max(categoryPlan.total - categorySelected, 0);
    if (needRemainder > 0) {
      const fallback = categoryPool.filter((row) => !usedCaseIds.has(row.id)).slice(0, needRemainder);
      for (const row of fallback) {
        usedCaseIds.add(row.id);
        selected.push({
          case_id: row.id,
          slug: String(row.slug ?? row.id),
          title: String(row.title ?? "Untitled case"),
          blueprint_category_code: categoryPlan.code,
          blueprint_subcategory: row.nbrc_subcategory ?? null,
        });
      }
      if (fallback.length < needRemainder) {
        deficits.push(`${categoryPlan.code}/fallback: needed ${needRemainder}, found ${fallback.length}`);
      }
    }
  }

  const targetCount = Math.min(desiredTotal, 20);
  if (selected.length < targetCount) {
    const neededGlobal = targetCount - selected.length;
    const globalFallback = shuffleArray(pool.filter((row) => !usedCaseIds.has(row.id))).slice(
      0,
      neededGlobal
    );
    for (const row of globalFallback) {
      usedCaseIds.add(row.id);
      selected.push({
        case_id: row.id,
        slug: String(row.slug ?? row.id),
        title: String(row.title ?? "Untitled case"),
        blueprint_category_code: String(row.nbrc_category_code ?? "?"),
        blueprint_subcategory: row.nbrc_subcategory ?? null,
      });
    }
    if (globalFallback.length < neededGlobal) {
      deficits.push(`global_fallback: needed ${neededGlobal}, found ${globalFallback.length}`);
    }
  }

  const rows = shuffleArray(selected).slice(0, targetCount);

  if (rows.length < targetCount) {
    return {
      rows,
      error: `Insufficient unique published CSE cases to build 20-case master exam. Deficits: ${deficits.join(
        " | "
      )}`,
    };
  }

  return {
    rows,
    error: deficits.length > 0 ? `Partial subcategory fallback applied: ${deficits.join(" | ")}` : null,
  };
}
