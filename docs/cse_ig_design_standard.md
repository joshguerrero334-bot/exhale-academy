# Exhale Academy CSE Information Gathering (IG) Design Standard

This standard applies to all CSE Information Gathering (IG) steps.

## Purpose
IG steps must test whether the learner can gather only the right data at the right time, then act on revealed findings.

## Required IG structure
1. Each IG step must include 15-20 selectable parameters.
2. Prompt must include `SELECT AS MANY AS INDICATED`.
3. Prompt must not include any numeric selection hint (`MAX`, `up to`, explicit count guidance).
4. Parameter design must include a mix of:
- clearly indicated selections
- optional but reasonable selections
- unnecessary selections
- unsafe or delay-causing selections (when clinically appropriate)

## Selection progression logic (authoring order)
Design IG options so the learner can work through this sequence:
1. Visual findings
- Things seen immediately: general appearance, color, posture, respiratory pattern/work, sensorium.
2. Bedside assessments
- Fast bedside checks: pulse, RR, BP, auscultation, percussion, tracheal position, SpO2, EtCO2, temperature when relevant.
3. Basic lab/imaging tests
- ABG, CBC, electrolytes, EKG, chest x-ray, and other common tests when indicated.
4. Special tests
- Higher-specificity tests (CT, bronchoscopy, ICP, hemodynamics, specialized diagnostics) only when case-justified.

## Emergency inference rule
- Do not ask the learner directly whether the case is an emergency.
- Build findings so urgency is inferred from the data.
- In critical cases, delayed diagnostics before stabilization must be penalized.

## Scoring standard
Use only allowed scores: `+3`, `+2`, `+1`, `0`, `-1`, `-2`, `-3`.

Meaning:
- `+3`: critical/mandatory now; omission creates meaningful patient harm risk.
- `+2`: strongly indicated now, high clinical value, time-appropriate.
- `+1`: useful/supportive, reasonable for current phase.
- `0`: neutral (rare; avoid overuse).
- `-1`: low-yield, unnecessary now, or premature.
- `-2`: very counterproductive; likely to delay or complicate care.
- `-3`: dangerous/detrimental; material risk of direct patient harm.

## Reference-values anchoring
- Correctness and rationale must be aligned to `public.cse_reference_values`.
- Use source-tagged normals/ranges (for example RTZ entries) to justify why a selection is relevant or irrelevant.
- If a value is abnormal in-case, abnormality should be interpretable against stored normals.

## Immediate reveal behavior (IG UX contract)
- When a learner selects an IG option, show the resulting parameter value immediately.
- Revealed values should remain visible for ongoing interpretation before advancing.
- History should retain full parameter names and values, not letter keys.

## "Usually high-value" items
When appropriate for the case, these are commonly high-yield and should be considered early:
- General appearance/color
- Respiratory rate/pattern
- Heart rate
- SpO2
- Blood pressure for cardiovascular concern
- Level of consciousness/sensorium
- Breath sounds
- Focused history of present illness

These are not universal mandates. Relevance is case-dependent.

## Guardrails for over-ordering
- Do not reward broad "order everything" behavior.
- Penalize non-indicated special tests.
- Treat urinalysis as non-indicated by default unless the scenario specifically makes urinary/renal etiology clinically relevant.

## Authoring checklist (per IG step)
- 15-20 options present.
- Visual -> Bedside -> Basic -> Special progression is possible.
- At least one clear unnecessary choice exists.
- At least one clear harmful/delay trap exists in urgent cases.
- Rationales reference clinical priorities and normal-range logic.
