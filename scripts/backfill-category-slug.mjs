#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";

const CATEGORY_MAP = new Map([
  ["oxygenation", "oxygenation"],
  ["ventilation", "ventilation"],
  ["airway management", "airway-management"],
  ["abg & acid-base", "abg-acid-base"],
  ["abg and acid-base", "abg-acid-base"],
  ["abg acid base", "abg-acid-base"],
  ["acid-base", "abg-acid-base"],
  ["mechanical ventilation", "mechanical-ventilation"],
  ["pharmacology", "pharmacology"],
  ["patient assessment", "patient-assessment"],
  ["pulmonary function testing", "pulmonary-function-testing"],
  ["neonatal & pediatrics", "neonatal-peds"],
  ["neonatal and pediatrics", "neonatal-peds"],
  ["neonatal/peds", "neonatal-peds"],
  ["infection control & safety", "infection-control-safety"],
  ["infection control and safety", "infection-control-safety"],
]);

function normalize(value) {
  return String(value ?? "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let value = "";
  let inQuotes = false;

  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    const next = text[i + 1];

    if (ch === '"' && inQuotes && next === '"') {
      value += '"';
      i += 1;
      continue;
    }

    if (ch === '"') {
      inQuotes = !inQuotes;
      continue;
    }

    if (ch === "," && !inQuotes) {
      row.push(value);
      value = "";
      continue;
    }

    if ((ch === "\n" || ch === "\r") && !inQuotes) {
      if (ch === "\r" && next === "\n") i += 1;
      row.push(value);
      rows.push(row);
      row = [];
      value = "";
      continue;
    }

    value += ch;
  }

  if (value.length > 0 || row.length > 0) {
    row.push(value);
    rows.push(row);
  }

  return rows;
}

function toCsv(rows) {
  return rows
    .map((row) =>
      row
        .map((cell) => {
          const value = String(cell ?? "");
          if (/[",\n\r]/.test(value)) {
            return `"${value.replaceAll('"', '""')}"`;
          }
          return value;
        })
        .join(",")
    )
    .join("\n");
}

function resolveSlugFromRow(row, headers, unknownCounts) {
  const indexCategorySlug = headers.indexOf("category_slug");
  const existingSlug = indexCategorySlug >= 0 ? String(row[indexCategorySlug] ?? "").trim() : "";
  if (existingSlug) return existingSlug;

  const indexCategory = headers.indexOf("category");
  const rawCategory = indexCategory >= 0 ? String(row[indexCategory] ?? "").trim() : "";
  const normalized = normalize(rawCategory);

  if (!normalized) return "";
  const mapped = CATEGORY_MAP.get(normalized);
  if (mapped) return mapped;

  const key = rawCategory || "(blank)";
  unknownCounts.set(key, (unknownCounts.get(key) ?? 0) + 1);
  return "";
}

async function main() {
  const [, , inputArg, outputArg] = process.argv;
  if (!inputArg || !outputArg) {
    console.error("Usage: node scripts/backfill-category-slug.mjs <input.csv> <output.csv>");
    process.exit(1);
  }

  const inputPath = path.resolve(process.cwd(), inputArg);
  const outputPath = path.resolve(process.cwd(), outputArg);

  const source = await fs.readFile(inputPath, "utf8");
  const rows = parseCsv(source);
  if (rows.length === 0) {
    throw new Error("Input CSV is empty.");
  }

  const headers = rows[0].map((h) => String(h).trim());
  let categorySlugIndex = headers.indexOf("category_slug");

  if (categorySlugIndex === -1) {
    headers.push("category_slug");
    categorySlugIndex = headers.length - 1;
  }

  const unknownCategoryCounts = new Map();
  const outputRows = [headers];

  for (let i = 1; i < rows.length; i += 1) {
    const row = [...rows[i]];
    while (row.length < headers.length) row.push("");
    const slug = resolveSlugFromRow(row, headers, unknownCategoryCounts);
    row[categorySlugIndex] = slug;
    outputRows.push(row);
  }

  await fs.writeFile(outputPath, toCsv(outputRows), "utf8");

  console.log(`Wrote ${outputRows.length - 1} rows to ${outputPath}`);
  if (unknownCategoryCounts.size > 0) {
    console.warn("Unknown categories (left blank):");
    for (const [category, count] of unknownCategoryCounts.entries()) {
      console.warn(`- ${category}: ${count}`);
    }
  } else {
    console.log("All categories were mapped.");
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
