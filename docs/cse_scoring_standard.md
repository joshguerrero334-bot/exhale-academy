# Exhale Academy CSE Scoring Standard

This document defines the scoring model for CSE authoring, engine behavior, and exam analytics.

## Exam blueprint
- Total scored problems per exam form: 22.
- Categories represented: 8.
- Pretest scenarios: 2, committee-judged and tracked separately.
- Each exam form has its own `minimum_passing_score` set by form/version.

## Passing interpretation
- Final pass/fail is determined by form-specific minimum passing score.
- Prep guidance target can use approximately 72% equivalent performance as directional coaching only.
- Do not hardcode 72% as universal pass logic.

## Point scale
Allowed selection scores:
- `+3`, `+2`, `+1`, `0`, `-1`, `-2`, `-3`

Meaning:
- `+3`: best available and essential action/information; omission risks harm.
- `+2`: very important and strongly indicated.
- `+1`: helpful and clinically reasonable.
- `0`: neutral (neither clearly helpful nor harmful).
- `-1`: counterproductive or unnecessary now.
- `-2`: very counterproductive and likely to worsen care timing/quality.
- `-3`: detrimental and potentially harmful.

## IG vs DM weighting guardrail
- IG should contribute more than half of total available points in a complete case set.
- Scoring distribution should reinforce clinical prioritization and selective data gathering.

## Authoring constraints
- Scores must be assigned only from the allowed point scale.
- Rationales must explain scoring with reference to clinical context and `public.cse_reference_values`.
- Dangerous or delay-prone actions should receive stronger penalties (`-2` or `-3`) when justified.
- Critical time-sensitive actions can receive `+3` when omission would create substantial risk.

## Engine and reporting behavior
- Attempt totals are cumulative sums of scored selections.
- Tutor mode shows per-step and running score.
- Exam mode hides scoring until final summary.
- Pretest scenario results must be stored and reportable separately from operational cut-score logic.
