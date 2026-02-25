#!/usr/bin/env node

import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const CATEGORY_SLUG_MAP = new Map([
  ["oxygenation", "oxygenation"],
  ["ventilation", "ventilation"],
  ["pharmacology", "pharmacology"],
  ["airway management", "airway-management"],
  ["abg & acid-base", "abg-acid-base"],
  ["abg and acid-base", "abg-acid-base"],
  ["abg acid-base", "abg-acid-base"],
  ["abg acid base", "abg-acid-base"],
  ["mechanical ventilation", "mechanical-ventilation"],
  ["patient assessment", "patient-assessment"],
  ["pulmonary function testing", "pulmonary-function-testing"],
  ["neonatal & pediatrics", "neonatal-peds"],
  ["neonatal and pediatrics", "neonatal-peds"],
  ["infection control & safety", "infection-control-safety"],
  ["infection control and safety", "infection-control-safety"],
]);

function normalizeCategory(value) {
  return String(value ?? "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");
}

async function main() {
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    console.error(
      "Missing env vars. Required: NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY"
    );
    process.exit(1);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: rows, error: fetchError } = await supabase
    .from("questions")
    .select("id, category")
    .is("category_slug", null);

  if (fetchError) {
    console.error(`Failed to fetch NULL category_slug rows: ${fetchError.message}`);
    process.exit(1);
  }

  const nullRows = rows ?? [];
  if (nullRows.length === 0) {
    console.log("No rows found where category_slug IS NULL.");
    return;
  }

  const idsBySlug = new Map();
  const unmatchedCounts = new Map();

  for (const row of nullRows) {
    const id = row.id;
    const rawCategory = String(row.category ?? "").trim();
    const normalized = normalizeCategory(rawCategory);
    const slug = CATEGORY_SLUG_MAP.get(normalized);

    if (!slug) {
      const key = rawCategory || "(blank)";
      unmatchedCounts.set(key, (unmatchedCounts.get(key) ?? 0) + 1);
      continue;
    }

    if (!idsBySlug.has(slug)) idsBySlug.set(slug, []);
    idsBySlug.get(slug).push(id);
  }

  let updatedRows = 0;
  for (const [slug, ids] of idsBySlug.entries()) {
    if (ids.length === 0) continue;

    const { data: updated, error: updateError } = await supabase
      .from("questions")
      .update({ category_slug: slug })
      .in("id", ids)
      .is("category_slug", null)
      .select("id");

    if (updateError) {
      console.error(`Failed updating slug "${slug}": ${updateError.message}`);
      continue;
    }

    updatedRows += (updated ?? []).length;
  }

  console.log(`Rows updated: ${updatedRows}`);

  if (unmatchedCounts.size === 0) {
    console.log("Unmatched categories: none");
    return;
  }

  console.log("Unmatched categories:");
  for (const [value, count] of unmatchedCounts.entries()) {
    console.log(`- ${value}: ${count}`);
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});

