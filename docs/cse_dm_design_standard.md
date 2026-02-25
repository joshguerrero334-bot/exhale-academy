# Exhale Academy CSE Decision Making (DM) Design Standard

This standard applies to all CSE Decision Making (DM) steps.

## Purpose
After IG data is revealed, DM steps must test whether the learner can choose the best available treatment or management action for the current clinical state.

## Required DM structure
1. DM prompt must include `CHOOSE ONLY ONE` unless a case explicitly requires multi-select.
2. Each DM step must provide 4-5 options.
3. Options must be clinically distinct (avoid duplicate wording with same intent).
4. Each option must include a score and rationale tied to current findings.

## Option design pattern (required)
Every DM option set should include:
- one best available option for current data state (`+3` or `+2` based on urgency/criticality),
- one acceptable but less optimal alternative (`+1`),
- one low-yield/premature option (`-1`),
- one unsafe or delay-causing option (`-2` or `-3`).

When 5 options are used, include another plausible distractor or second unsafe branch depending on case complexity.

## Best-available logic
- Do not assume ideal therapy is always listed.
- If ideal action is missing, highest-score option must represent the safest and most effective available choice.
- "Physician disagrees" flow should be modeled as iterative clinical negotiation, not automatic learner failure.
- A reasonable second-best option can be suboptimal (`+1` or `-1`) without being treated as catastrophic.

## Scoring standard
Allowed scores: `+3`, `+2`, `+1`, `0`, `-1`, `-2`, `-3`.

Meaning:
- `+3`: best available and essential now; failure to choose creates significant harm risk.
- `+2`: best available, time-appropriate, strong expected benefit.
- `+1`: reasonable and potentially helpful but not most appropriate.
- `0`: neutral impact (use rarely).
- `-1`: weak, unnecessary, premature, or misses priority.
- `-2`: very counterproductive; likely to worsen course or delay key care.
- `-3`: dangerous/detrimental; likely to cause direct harm or severe deterioration.

## Reference-values anchoring
- Rationales and scoring must align with `public.cse_reference_values`.
- Abnormal findings used in DM must be interpretable against seeded normals/ranges.
- DM actions that depend on ABG, hemodynamics, labs, or ventilatory metrics must reflect those reference thresholds.

## Clinical pattern guardrails
Use these patterns when data supports them:
- Bronchospasm wheeze -> bronchodilator-focused action.
- CHF/pulmonary edema pattern (for example frothy secretions) -> fluid/offloading support (for example diuretics, noninvasive support when indicated).
- Foreign body pattern -> airway visualization/removal pathway (for example bronchoscopy consult).
- Stridor/upper-airway swelling pattern -> urgent upper-airway stabilization actions.
- Secretion retention pattern (for example rhonchi/weak cough) -> bronchial hygiene/suction strategy.
- ABG acute ventilatory failure pattern (low pH, high PaCO2 without metabolic compensation) -> escalate ventilatory support.
- Severe refractory hypoxemia pattern despite higher FiO2 -> consider PEEP/CPAP escalation and underlying-cause treatment.

These are pattern guides, not hardcoded answer keys; case context still governs scoring.

## DM progression and feedback
- After submit, outcome text should describe physiologic response and readiness for next section.
- Responses must support iterative IG/DM cycling across the case (typically 4-5 cycles).
- Outcome text should stay concise and clinically actionable.

## Authoring checklist (per DM step)
- 4-5 options present.
- Single best available action is clearly defensible from current data.
- At least one unsafe/delay option exists when clinically relevant.
- Rationale for each option references current findings and normal-range context.
- Next-step progression (improve/partial/worsen) is clinically coherent.
