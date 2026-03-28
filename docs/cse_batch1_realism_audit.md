# Exhale CSE Batch 1 Realism Audit

Batch 1 covers the first high-yield family for realism refactor:

- obstructive disease
- ventilator emergency
- neuromuscular ventilatory failure

Files reviewed:

- `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql`

Reference standard:

- `/Users/joshguerrero/exhale-academy/docs/cse_realism_review_checklist.md`

## Overall Batch Conclusion

This batch does not need a full-bank rebuild. Most of the clinical logic is usable. The major gap is realism:

- prompt tone is too authored
- options are often too bundled
- select-many sections are broader than the real CSE feel
- distractors are sometimes too obvious
- outcomes and rationales are more educational than exam-neutral

Recommended strategy:

- refactor most of these in place
- rebuild only if the case becomes cleaner to replace than to untangle

## Case 6

File:

- `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql`

Clinical theme:

- severe asthma / obstructive distress with escalation

### What is working

- strong high-acuity presentation
- clear progression from initial care to escalation
- reassessment exists
- disposition is included

### Realism issues

1. Prompt tone is still product-authored rather than NBRC-neutral.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:88`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:90`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:94`

2. Some options are broad management ideas instead of discrete simulation actions.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:111`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:127`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:133`

3. Several distractors are too obviously bad, which weakens exam realism.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:109`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:124`

4. Outcome text explains too much in an authored voice.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:140`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql:166`

### Classification

- `Heavy Refactor`

### Why

The clinical skeleton is good, but prompts, option granularity, and distractor quality all need to move closer to true CSE sequencing.

## Case 9

File:

- `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql`

Clinical theme:

- ventilator emergency with likely tension pneumothorax pattern

### What is working

- urgency is strong
- sequencing is closer to real CSE than the other files in this batch
- the manual ventilation troubleshooting move is directionally right
- the case has a meaningful rescue sequence

### Realism issues

1. The opening stem is too explanatory and front-loaded.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:88`

2. Prompt wording still sounds custom-authored.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:92`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:96`

3. Some options are still bundled beyond the usual single-step CSE feel.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:122`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:128`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:133`

4. Outcome text is still more narrative than exam-console neutral.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:140`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:166`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql:192`

### Classification

- `Rewrite In Place`

### Why

This case is the closest of the batch to a real CSE rhythm. We should keep the structure and tighten prompt phrasing, narrow option granularity, and reduce authored explanation language.

## Case 10

File:

- `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql`

Clinical theme:

- neuromuscular ventilatory failure

### What is working

- progression toward pump failure is clinically appropriate
- reassessment exists
- escalation to invasive support is present
- ICU disposition makes sense

### Realism issues

1. The wording is too instructional and exam-aware.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:107`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:110`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:134`

2. Step 1 contains too much up-front framing and one option tests classification instead of the next best simulation action.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:88`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:110`

3. The ventilator management option is far too bundled for real CSE feel.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:128`

4. Outcome text is again more authored than exam-neutral.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:141`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:167`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql:193`

### Classification

- `Heavy Refactor`

### Why

The case idea is good, but it needs significant restructuring around more discrete actions and more neutral wording. This is still salvageable without a full rebuild.

## Case 12

File:

- `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql`

Clinical theme:

- non-critical COPD exacerbation with secretion burden and transition planning

### What is working

- outpatient and transition-planning content is valuable
- secretion burden and infection-trend thinking are clinically relevant
- the case covers readiness-for-disposition well

### Realism issues

1. The case uses broad `MAX 8` selection logic repeatedly, which does not feel like the real CSE.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:90`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:109`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:129`

2. Metadata-driven reveals feel game-like rather than exam-console neutral.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:92`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:111`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:131`

3. Many answer choices are too framework-heavy or “best available” in tone.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:153`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:164`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:182`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:201`

4. The case contains too many options per phase and too much planning language in one place.
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:152`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:171`
   - `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql:189`

### Classification

- `Heavy Refactor`, with `Rebuild` as a valid fallback if simplification in place becomes messy

### Why

The subject matter is useful, but the current structure is the farthest from NBRC feel in this batch. The cleanup may be larger than a normal rewrite.

## Recommended Rewrite Order

1. `/Users/joshguerrero/exhale-academy/docs/cse_case9_branching_insert.sql`
2. `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql`
3. `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql`
4. `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql`

Reasoning:

- Case 9 is the easiest win and the best candidate to set the tone for the batch
- Case 6 gives us the obstructive-disease rewrite pattern
- Case 10 lets us apply the same standard to neuromuscular failure
- Case 12 should come last because it likely needs the biggest structural cleanup

## Batch Decision

Recommended approach for Batch 1:

- keep all four cases
- refactor the existing SQL in place for Cases 6, 9, and 10
- attempt in-place simplification for Case 12 first
- if Case 12 becomes harder to untangle than replace, rebuild that one case only

No case content was changed during this audit. This document is the review baseline before the first rewrite pass.
