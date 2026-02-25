# Adult Trauma Refactor Blueprint (Pilot)

This file shows exactly how the new workflow was applied to Adult Trauma cases (16-19).

## Scope
- Case 16: `trauma-critical-tension-pneumothorax`
- Case 17: `trauma-critical-hemothorax`
- Case 18: `trauma-critical-flail-chest-contusion`
- Case 19: `trauma-critical-ventilator-pneumothorax`

## Step-intent matrix used
- Step 1 (IG): scene + exam priorities, no diagnosis reveal.
- Step 2 (DM): immediate life-saving decision.
- Step 3 (IG): reassessment and objective trend confirmation.
- Step 4 (DM): ongoing management/disposition under risk.

## Concrete refactor changes made
1. Prompt realism
- Preserved narrative bedside setup with age/sex/context.
- Removed diagnosis-leading reveal text in case 18 metadata.
  - Replaced with objective imaging finding language.

2. Option quality rebalance
- Added one plausible-but-incomplete (`+1`) DM choice in each trauma case Step 2 and Step 4.
- Kept one clear best option (`+3`) as the safe trajectory.
- Retained unsafe options (`-2/-3`) for exam-level discrimination.

3. Decision clarity
- Ensured immediate pleural emergencies prioritize decompression/drainage.
- Reinforced high-acuity monitoring and explicit reassessment trajectory at disposition.

4. Vent/ABG integration
- Preserved ABG quartet and vent-setting adjustment logic in case 19.
- Preserved post-intervention trend checks in all four cases.

## Files updated
- `/Users/joshguerrero/exhale-academy/docs/cse_case16_17_trauma_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case18_19_trauma_critical_insert.sql`

## Why this helps
- Better student realism: scenario feels like bedside care, not a diagnosis label.
- Better psychometrics: distractors are plausible and step-appropriate.
- Better learning signal: students are pushed to use trend data and escalation logic.

## Next repeatable workflow for all categories
1. Load category algorithm from `cse_category_algorithms.md`.
2. Apply 6-step (or current case-step) workflow contract.
3. Rebalance DM options to include: best, plausible second-best, and unsafe distractors.
4. Validate against `cse_case_validator_checklist.md`.
5. Run seed + UI verification.
