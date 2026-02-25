# Exhale CSE Guardrails Contract

This document defines the required guardrails for all future Exhale CSE case generation.

## 1) Data Model Guardrails
- All CSE content must follow the branching schema:
  - `public.cse_cases`
  - `public.cse_steps`
  - `public.cse_options`
  - `public.cse_rules`
  - `public.cse_outcomes`
- Cases must use supported rule logic only (`INCLUDES_ALL`, `INCLUDES_ANY`, `SCORE_AT_LEAST`, `SCORE_AT_MOST`, `DEFAULT`).
- Every step must have a safe terminal fallback path (`DEFAULT` rule/outcome).

## 2) Idempotency Guardrails
- Seed scripts must be re-runnable.
- Case scripts must update-or-insert by stable case slug and rebuild only targeted case content.
- Scripts must not perform global destructive deletes unrelated to targeted case IDs.

## 3) Step Design Guardrails
- Each case must follow explicit CSE-style IG/DM flow.
- Prompt language must clearly state selection mode:
  - `SELECT AS MANY AS INDICATED (MAX N)` for IG.
  - `CHOOSE ONLY ONE` for DM.
- Cases must include clinically unsafe distractors with negative scoring.

## 4) Scoring Guardrails
- Standardized score scale:
  - `critical_best = 3`
  - `strong = 2`
  - `helpful = 1`
  - `neutral = 0`
  - `counterproductive = -1`
  - `very_counterproductive = -2`
  - `dangerous = -3`
- Rule priorities must enforce best-practice branching before fallback/default.

## 5) Clinical Content Guardrails
- Cases must be built from approved lesson content.
- Include:
  - Information Gathering findings
  - Decision Making actions
  - escalation thresholds
  - contraindications / do-not-recommend traps
- High-yield exam hints must be encoded into branching logic, not only prose.

## 6) Taxonomy Guardrails
- Each case must be mapped to NBRC category fields in `public.cse_cases`:
  - `nbrc_category_code`
  - `nbrc_category_name`
  - `nbrc_subcategory`
- Category mapping seed must include all newly introduced slugs.

## 7) Quality Guardrails
- Baseline vitals must be present per case.
- Outcomes must produce valid `vitals_override` values.
- Case visibility requires:
  - `is_active = true`
  - `is_published = true`
- Cases should be verified in UI by category filter after SQL execution.

## 8) Workflow Guardrails
- Build order for each lesson:
  1. Extract and structure lesson content
  2. Save/refresh disease playbook seed
  3. Generate case seed files
  4. Update NBRC mapping seed
  5. Run SQL and verify rows/UI
- Do not execute unapproved lesson interpretations into production DB.

## 9) File Conventions
- Use deterministic file naming:
  - `docs/cse_<topic>_playbook_seed.sql`
  - `docs/cse_caseNN_MM_<topic>_critical_insert.sql`
  - `docs/cse_nbrc_case_category_seed.sql`
- Keep scripts self-contained with `begin; ... commit;`.

## 10) Acceptance Criteria
A lesson-to-case build is complete when all are true:
- Playbook seed exists and upserts successfully.
- Case seeds insert/update expected case count.
- NBRC mapping returns expected category assignment.
- Cases appear in Exhale CSE UI under intended NBRC category.
