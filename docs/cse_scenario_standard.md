# Exhale Academy CSE Scenario Standard

This is the required format for all future CSE scenarios in Exhale Academy.

## Core rule
Use strict NBRC-style progression with explicit physiologic consequences after each submitted decision set.

## Clinical framing rule (required)
- Student should be able to classify the scenario early as:
  - emergency requiring immediate intervention, or
  - non-emergency requiring focused information gathering first.
- Scenario authoring must reinforce this decision gate in early steps.
- Wrong prioritization (for example: diagnostics before stabilization in emergencies) must produce clear negative progression.

## Required flow
1. Scene narrative (no diagnosis label)
2. IG step (multi-select)
3. STOP barrier
4. Data Reveal with positive/negative progression paths
5. DM step (single best answer)
6. STOP barrier
7. Follow-up Data Reveal
8. Repeat IG/DM blocks if needed
9. Final outcome summary

## Step requirements
- IG step:
  - Prompt must include: `SELECT AS MANY AS INDICATED`
  - Prompt must not include any count hint (`MAX`, `up to`, numeric selection guidance).
  - Must include `15-20` selectable parameters.
  - Parameter sets must support this progression: Visual -> Bedside -> Basic Labs -> Special Tests.
  - Selection scoring/rationales must align with `public.cse_reference_values`.
  - `step_kind = 'ig'`
  - `min_selections = 1`
  - `max_selections = X`
- DM step:
  - Prompt must include: `CHOOSE ONLY ONE`
  - Must include `4-5` decision options.
  - Must include a defensible "best available" option for current case data, even when ideal therapy is not listed.
  - Decision scoring/rationales must align with `public.cse_reference_values`.
  - `step_kind = 'dm'`
  - `min_selections = 1`
  - `max_selections = 1`
- STOP behavior:
  - Must lock progression until submission (`is_locked` in attempt step state)
  - Reveal appears only after submit

## Scoring model
Every choice must include:
- `score_value` from `{3, 2, 1, 0, -1, -2, -3}`
- `rationale_text` explaining physiologic reasoning

Meaning:
- `+3` critical/mandatory best action
- `+2` strongly indicated
- `+1` helpful/moderately indicated
- `0` neutral
- `-1` unnecessary/insufficient/premature
- `-2` very counterproductive
- `-3` dangerous/detrimental

## Content style
- Guide the learner through decision consequences.
- Show both favorable and unfavorable progression states.
- Keep realism high and wording concise.
- Do not over-explain.
- Do not name the diagnosis if inference is intended.
- In early sections, make priority recognition testable: immediate action vs gather-more-data pathway.

## Database mapping
- Scenario container: `public.cse_cases`
- Steps: `public.cse_steps`
- Options: `public.cse_options`
- Branch rules: `public.cse_rules`
- Attempt state: `public.cse_attempts`
- Attempt events: `public.cse_attempt_events`

## Seed script expectations
- Idempotent and re-runnable
- Repairs/aligns older schema columns when needed
- Removes and recreates step/option/rule payload for target case
- Includes `DEFAULT` fallback rule for every step
- No static `If student did X...` paragraphs in prompts

## Current reference implementation
- `docs/cse_branching_engine_migration.sql`
- `docs/cse_case3_branching_insert.sql`
- `docs/cse_ig_design_standard.md`
- `docs/cse_dm_design_standard.md`

## Legacy static SQL
Legacy static-flow SQL files were moved to:
- `docs/legacy_static_cse/`

Do not run legacy files for the branching engine path.
