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

export type FocusedCsePracticeFamily = {
  slug: string;
  label: string;
  eyebrow: string;
  description: string;
  caseCount: number;
  match: {
    categoryCodes?: string[];
    includeAny?: string[];
  };
};

export const focusedCsePracticeFamilies: FocusedCsePracticeFamily[] = [
  {
    slug: "obstructive-airway",
    label: "Obstructive Airway",
    eyebrow: "COPD + Asthma",
    description: "Work through bronchospasm, air trapping, NPPV decisions, and escalation timing.",
    caseCount: 5,
    match: {
      includeAny: ["copd", "asthma", "bronchospasm", "obstructive", "noninvasive", "nppv"],
    },
  },
  {
    slug: "trauma-chest-emergencies",
    label: "Trauma + Chest Emergencies",
    eyebrow: "Air leaks + blood loss",
    description: "Practice tension pneumothorax, hemothorax, flail chest, and rapid deterioration.",
    caseCount: 4,
    match: {
      categoryCodes: ["B"],
      includeAny: ["trauma", "pneumothorax", "hemothorax", "flail", "contusion"],
    },
  },
  {
    slug: "ards-severe-hypoxemia",
    label: "ARDS + Severe Hypoxemia",
    eyebrow: "PEEP + oxygenation",
    description: "Focus on refractory hypoxemia, ARDS patterns, pneumonia, aspiration, and ventilator strategy.",
    caseCount: 5,
    match: {
      includeAny: ["ards", "hypoxemia", "pneumonia", "aspiration", "sepsis", "infectious"],
    },
  },
  {
    slug: "cardiovascular-shock",
    label: "Cardiovascular + Shock",
    eyebrow: "Perfusion + pulmonary edema",
    description: "Train CHF, pulmonary edema, shock, and hemodynamic clues that change RT priorities.",
    caseCount: 5,
    match: {
      categoryCodes: ["C"],
      includeAny: ["cardio", "heart", "chf", "shock", "pulmonary-edema", "pulmonary edema", "mi", "embolism"],
    },
  },
  {
    slug: "neuro-ventilatory-failure",
    label: "Neuro + Ventilatory Failure",
    eyebrow: "Airway protection",
    description: "Practice neuromuscular weakness, airway risk, ventilatory failure, and intubation timing.",
    caseCount: 5,
    match: {
      categoryCodes: ["D"],
      includeAny: ["neuro", "neuromuscular", "tetanus", "myasthenia", "guillain", "overdose", "head", "spinal"],
    },
  },
  {
    slug: "pediatric-airway-lower-airway",
    label: "Pediatric Airway + Lower Airway",
    eyebrow: "Kids + airway clues",
    description: "Review croup, epiglottitis, bronchiolitis, CF, foreign body, and pediatric distress patterns.",
    caseCount: 5,
    match: {
      categoryCodes: ["F"],
      includeAny: ["pediatric", "croup", "epiglottitis", "bronchiolitis", "cystic", "foreign-body", "foreign body"],
    },
  },
  {
    slug: "neonatal-delivery-room",
    label: "Neonatal + Delivery Room",
    eyebrow: "Newborn transition",
    description: "Practice Apgar logic, delivery room resuscitation, neonatal distress, IRDS, and meconium clues.",
    caseCount: 5,
    match: {
      categoryCodes: ["G"],
      includeAny: ["neonatal", "delivery", "newborn", "meconium", "prematurity", "irds", "resuscitation", "cdh"],
    },
  },
];

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

function searchableCaseText(row: CseCasePoolRow) {
  return [
    row.slug,
    row.title,
    row.disease_slug,
    row.nbrc_category_code,
    row.nbrc_subcategory,
  ]
    .map((value) => normalize(value))
    .join(" ");
}

function rowMatchesFocusedFamily(row: CseCasePoolRow, family: FocusedCsePracticeFamily) {
  const category = normalize(row.nbrc_category_code);
  const categoryMatch = (family.match.categoryCodes ?? []).some((code) => normalize(code) === category);
  const haystack = searchableCaseText(row);
  const keywordMatch = (family.match.includeAny ?? []).some((keyword) => haystack.includes(normalize(keyword)));

  return categoryMatch || keywordMatch;
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

export async function generateFocusedCseCaseSet(
  client: SupabaseServerClient,
  focusSlug: string
) {
  const family = focusedCsePracticeFamilies.find((entry) => entry.slug === focusSlug) ?? null;
  if (!family) {
    return {
      rows: [] as CseMasterBlueprintPick[],
      error: "Focused CSE practice category not found.",
      family: null,
    };
  }

  const { data, error } = await client
    .from("cse_cases")
    .select("id, slug, title, disease_slug, nbrc_category_code, nbrc_subcategory")
    .eq("is_active", true)
    .eq("is_published", true);

  if (error) {
    return {
      rows: [] as CseMasterBlueprintPick[],
      error: error.message,
      family,
    };
  }

  const pool = ((data ?? []) as CseCasePoolRow[]).filter((row) => row.id);
  const matches = shuffleArray(pool.filter((row) => rowMatchesFocusedFamily(row, family)));
  const rows = matches.slice(0, family.caseCount).map((row) => ({
    case_id: row.id,
    slug: String(row.slug ?? row.id),
    title: String(row.title ?? "Untitled case"),
    blueprint_category_code: String(row.nbrc_category_code ?? family.slug),
    blueprint_subcategory: family.label,
  }));

  if (rows.length < 2) {
    return {
      rows,
      error: `Not enough published cases are available for ${family.label} yet.`,
      family,
    };
  }

  return {
    rows,
    error: rows.length < family.caseCount ? `${family.label} currently has ${rows.length} available cases.` : null,
    family,
  };
}
