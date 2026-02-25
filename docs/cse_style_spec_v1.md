# Exhale CSE Style Spec v1

This is the required writing and flow standard for all Exhale CSE cases.

## 1) Case framing standard
- Open with a concise bedside vignette:
  - age
  - sex
  - setting
  - presenting complaint
  - objective baseline severity cues
- Do not name the diagnosis in Step 1.
- Step 1 should force inference from clues, not label recognition.

## 2) Prompt language standard
- Information Gathering prompts should ask what to **assess/evaluate now**.
- Decision Making prompts must include priority language:
  - `FIRST`
  - `NEXT`
  - `best immediate`
  - `most appropriate now`
- Avoid vague prompts such as "What do you do?" without timing context.

## 3) Timeline progression standard
- Each case must include explicit time progression across steps:
  - for example `5 minutes later`, `30 minutes later`, `2 hours later`.
- New data at each checkpoint must reflect prior branch quality.
- Reassessment prompts must be stage-specific, not generic repeats.

## 4) IG/DM structure standard
- Use alternating IG/DM flow unless a justified exception is documented.
- IG: multi-select with clear max.
- DM: single best choice by default.
- DM wrong-choice handling:
  - for critical decisions, use retry behavior (`make another selection`) when appropriate.

## 5) Option-set quality standard
- Every DM set should contain:
  - 1 best choice
  - 1 plausible but incomplete choice
  - 1-2 unsafe or delay-causing distractors
- Distractors must be clinically plausible for the scenario, not absurd.
- No option may require data not yet revealed.

## 6) Explanation standard
- Each option rationale must be:
  - concise
  - data-anchored
  - timing-aware (`why this now` / `why not now`)
- Use physiologic language (oxygenation, ventilation, perfusion, airway risk) rather than generic wording.

## 7) State-transition feedback standard
- After key decisions, include a short acknowledgment signal:
  - `Noted.`
  - `The physician agrees.`
  - `Make another selection.`
  - `End of the problem.`
- Keep acknowledgment separate from clinical explanation.

## 8) Ventilation and ABG standard
- Any intubation-required pathway must include:
  - explicit ventilator settings
  - ABG quartet (`pH`, `PaCO2`, `PaO2`, `HCO3`)
  - settings-adjustment choices linked to ABG/oxygenation findings

## 9) Final-section standard
- Final section should test execution quality, not only diagnosis.
- Good branches should finish with stable vitals in expected normal range.
- Bad branches should preserve instability to reinforce consequence logic.

## 10) Category labeling standard
- Case header/content should align with NBRC category and subtype.
- Maintain strict mapping in `cse_cases.nbrc_*` fields.

## 11) Do-not-use language
- `Opening monitor data is available now.`
- `... suspected.` diagnosis giveaway in Step 1.
- Explanations that simply restate the option without physiologic reason.

## 12) Definition of done
- Passes `cse_case_validator_checklist.md`.
- Prompt intent includes FIRST/NEXT where appropriate.
- Timeline checkpoints are explicit.
- Options/rationales are coherent and clinically defensible.
