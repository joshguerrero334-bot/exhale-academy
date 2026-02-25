# Exhale CSE Case Validator Checklist (Pre-DB)

Use this checklist before seeding any new or updated case into the database.

## How to use
1. Run this checklist per case.
2. Mark each line as `PASS` or `FAIL`.
3. Any `FAIL` in Blocker sections must be fixed before DB update.

## Section A: Structure (Blocker)
- [ ] Case has exactly 6 steps with IG/DM progression.
- [ ] Step 1 includes age, sex, setting, and presenting picture.
- [ ] Step 1 does not reveal diagnosis.
- [ ] IG prompts are multi-select with clear max.
- [ ] DM prompts are single-select unless explicitly justified.

## Section B: Clinical Logic (Blocker)
- [ ] Case aligns with `/Users/joshguerrero/exhale-academy/docs/cse_category_algorithms.md`.
- [ ] Options match the actual moment in the scenario (no time-jumps).
- [ ] No option requires unrevealed data.
- [ ] Escalation triggers are objective and coherent.
- [ ] Disposition is appropriate for the final stability level.

## Section C: Option Quality (Blocker)
- [ ] Each DM step has one clearly best available option.
- [ ] Distractors are plausible but wrong for this patient state.
- [ ] At least one unsafe or harmful option exists where clinically relevant.
- [ ] Rationales explain why correct/incorrect based on current findings.
- [ ] No duplicate options with different wording but same intent.

## Section D: Vent/ABG Integrity (Blocker for intubation cases)
- [ ] Intubation path includes vent mode and settings.
- [ ] ABG quartet present where needed: `pH, PaCO2, PaO2, HCO3`.
- [ ] Vent-adjustment options are tied to ABG/oxygenation.
- [ ] Post-intubation reassessment includes oxygenation + ventilation + complication checks.

## Section E: Data/Rules Integrity (Blocker)
- [ ] Every step has rule coverage including `DEFAULT`.
- [ ] Rule priorities reflect safer logic before fallback.
- [ ] `vitals_override` trends are clinically believable.
- [ ] No broken next-step references.
- [ ] Negative-score actions correctly map to worse outcomes.

## Section F: Language/UX Quality (Important)
- [ ] Prompts are readable and bedside-realistic (not robotic).
- [ ] No banned phrase patterns:
  - [ ] "`... suspected.`" in Step 1 diagnosis-giveaway style
  - [ ] "`Opening monitor data is available now.`"
  - [ ] explicit contraindication reveal before student discovery
- [ ] Terminology is consistent with lesson plan wording.
- [ ] Student is required to infer diagnosis from clues, not labels.

## Section G: Category Mapping (Blocker)
- [ ] `nbrc_category_code` assigned correctly.
- [ ] `nbrc_category_name` assigned correctly.
- [ ] `nbrc_subcategory` assigned correctly when required.
- [ ] Mapping file updated (`/Users/joshguerrero/exhale-academy/docs/cse_nbrc_case_category_seed.sql`).

## Final Release Gate
- [ ] SQL seed is idempotent.
- [ ] Case appears in correct CSE category in UI.
- [ ] Step 1 prompt displayed in UI matches expected narrative.
- [ ] At least one end-to-end branch was manually sanity-checked in app.

## Suggested scoring for review
- `PASS_ALL_BLOCKERS`: ready to seed.
- `PASS_WITH_WARNINGS`: seed only if warnings are language-only and scheduled for fix.
- `FAIL`: do not seed.
