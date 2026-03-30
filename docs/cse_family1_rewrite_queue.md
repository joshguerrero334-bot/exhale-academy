# Exhale CSE Master Exam Rewrite Queue

## Family 1 Scope
This first rewrite family covers the chronic airways / noninvasive support / ventilatory-failure cluster in the current CSE pool.

Included scenarios:
- `/Users/joshguerrero/exhale-academy/docs/cse_case5_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case11_copd_non_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_asthma_non_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case14_15_copd_critical_insert.sql`

This family was chosen first because it is high-frequency on the real exam and currently contains some of the biggest realism gaps in the master-exam pool.

## Rubric Anchor
All recommendations below use the standards in:
- `/Users/joshguerrero/exhale-academy/docs/cse_realism_review_checklist.md`
- `/Users/joshguerrero/exhale-academy/docs/cse_full_bank_realism_audit.md`

## Decision Labels
- `Keep and tighten`: preserve the case structure, clean up wording and option granularity
- `Rewrite from concept`: keep the disease state and clinical objective, but rebuild prompts, options, reassessment cadence, and outcome text
- `Replace entirely`: retire the current scenario and build a new one from scratch

## Queue Summary

### 1. Case 6
File:
- `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql`

Current title:
- `Case 6 -- Acute Severe Bronchospasm Fatigue`

Recommendation:
- `Rewrite from concept`

Why:
- The case concept is good and high-yield for the master exam.
- The current version already uses smaller select-many limits, which makes it easier to rebuild cleanly.
- The main problems are author voice, option bundling, generalized prompts, and outcomes that still narrate teaching logic instead of reporting findings.
- This is the best first gold-standard rewrite because it lets us establish the asthma/bronchospasm pattern in the closest salvageable framework.

Main realism gaps:
- Prompt phrasing is still authored rather than NBRC-neutral.
- Reassessment steps need cleaner ABG/vital/result blocks.
- Escalation logic should be more timing-based and less generalized.
- Outcome text needs to report findings instead of summarizing meaning.

### 2. Case 5
File:
- `/Users/joshguerrero/exhale-academy/docs/cse_case5_branching_insert.sql`

Current title:
- `Case 5 -- COPD Hypercapnic Respiratory Fatigue`

Recommendation:
- `Rewrite from concept`

Why:
- The core scenario is strong for real CSE prep: controlled oxygen, hypercapnia risk, NIV timing, and safe disposition.
- The current structure is better than the noncritical COPD cases, but it still sounds like a training module.
- This case should become the master template for COPD hypercapnic failure and NIV timing.

Main realism gaps:
- Too much summary language in prompts and rationales.
- Options still read like instructional strategy labels rather than discrete clinical choices.
- ABG presentation needs to look more like the NBRC examples.
- Disposition language still includes phrases like `structured escalation path`.

### 3. Case 14
File:
- `/Users/joshguerrero/exhale-academy/docs/cse_case14_15_copd_critical_insert.sql`

Current title:
- `COPD Critical (NPPV Failure Escalation)`

Recommendation:
- `Rewrite from concept`

Why:
- This is a clinically important scenario for the master exam.
- The current case has the right big-picture arc, but the implementation is far from real-exam tone.
- Once Cases 5 and 6 are rewritten, this case can inherit their tighter prompt and reassessment standards.

Main realism gaps:
- Uses `MAX 8` repeatedly.
- Prompt voice is strongly templated: `You are called to bedside... What are your next steps?`
- Too much explicit interpretation about NPPV timing rules.
- Ventilator and ABG prompts are too dense and too explanatory.
- Disposition and handoff wording remains authored.

### 4. Case 15
File:
- `/Users/joshguerrero/exhale-academy/docs/cse_case14_15_copd_critical_insert.sql`

Current title:
- `COPD Critical (High-Risk Airway Pathway)`

Recommendation:
- `Rewrite from concept`

Why:
- The contraindication-to-NPPV pathway is worth keeping in the pool because it teaches the exact prioritization the CSE likes.
- The current version is realistic in theme but not in voice or decision granularity.
- This one should follow the Case 14 rewrite so the two critical COPD pathways feel like deliberate companion scenarios instead of two unrelated authored cases.

Main realism gaps:
- Repeated `MAX 8` sections.
- Prompt voice remains templated and too broad.
- Intubation/post-intubation management is too bundled.
- Uses phrases like `structured handoff planning` and `escalation readiness`.
- Transition planning section feels like curriculum writing, not exam writing.

### 5. Case 11
File:
- `/Users/joshguerrero/exhale-academy/docs/cse_case11_copd_non_critical_insert.sql`

Current title:
- `COPD Non-Critical (Emphysema-Predominant Flare)`

Recommendation:
- `Rewrite from concept`

Why:
- The clinical theme is worth preserving, but the current build is too synthetic and checklist-driven.
- This case should eventually become a cleaner outpatient/ED-to-discharge COPD scenario with better CSE-style select-many discipline.

Main realism gaps:
- Repeated `MAX 8` sections.
- `You are called to bedside` stem template.
- Too much discharge-planning and prevention language in authored phrasing.
- Reassessment and disposition sections feel educational rather than exam-neutral.

### 6. Case 12
File:
- `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql`

Current title:
- `COPD Non-Critical (Chronic Bronchitis-Predominant Flare)`

Recommendation:
- `Rewrite from concept`

Why:
- The secretion-burden phenotype adds useful variety to the pool.
- The current version is still too broad, too templated, and too explain-y.
- It should be rebuilt after Case 11 so both noncritical COPD pathways use the same tighter rhythm.

Main realism gaps:
- Repeated `MAX 8` structure.
- Broad multi-goal prompts.
- Transition-planning voice is too authored.
- Distractors are not subtle enough.

### 7. Asthma noncritical case
File:
- `/Users/joshguerrero/exhale-academy/docs/cse_asthma_non_critical_insert.sql`

Current title:
- `COPD Non-Critical (Asthma Triggered Exacerbation)`

Recommendation:
- `Replace entirely`

Why:
- This case is mislabeled at the taxonomy/title level and should not remain dressed as a COPD scenario.
- It should be replaced with a properly named asthma case built from scratch using the new rubric.
- Rewriting around the current framing would create unnecessary cleanup work and keep the wrong classification logic alive.

Main realism gaps:
- Wrong disease identity in the current seed.
- Repeated `MAX 8` structure.
- Templated authored stem.
- Outpatient planning language is too curricular.
- Current framing risks confusing the final master exam pool if left in place.

## Recommended Rewrite Order
1. `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql`
2. `/Users/joshguerrero/exhale-academy/docs/cse_case5_branching_insert.sql`
3. `/Users/joshguerrero/exhale-academy/docs/cse_case14_15_copd_critical_insert.sql` (Case 14)
4. `/Users/joshguerrero/exhale-academy/docs/cse_case14_15_copd_critical_insert.sql` (Case 15)
5. `/Users/joshguerrero/exhale-academy/docs/cse_case11_copd_non_critical_insert.sql`
6. `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql`
7. `/Users/joshguerrero/exhale-academy/docs/cse_asthma_non_critical_insert.sql` (replace with a new asthma case)

## Why This Order Works
- Case 6 is the best first rewrite because it has the cleanest salvageable skeleton and the highest value for establishing the new voice.
- Case 5 then locks the COPD hypercapnic/NIV pattern.
- Cases 14 and 15 can inherit the same critical-care rhythm once the two earlier anchor cases are done.
- Cases 11 and 12 should come later because the noncritical/disposition-heavy cases benefit from already having a stable rewrite pattern.
- The asthma noncritical case should be rebuilt last, once the new naming, tone, and taxonomy rules are settled.

## Implementation Rules For This Family
As we rewrite this family, every updated case should follow these rules:
- Prefer `max 2` to `max 4` for select-many sections unless there is a strong clinical reason to exceed that.
- Present oxygen/device context, then vitals, then ABG or imaging in clean blocks.
- Use objective findings in outcome text instead of interpreted summaries.
- Keep single-choice options to one move whenever possible.
- Remove `structured`, `best available`, `escalation readiness`, `core` teaching language.
- Make distractors plausible-but-mistimed rather than obviously reckless.
- Keep explanations short and scoring-focused.

## Immediate Next Step
Rewrite `/Users/joshguerrero/exhale-academy/docs/cse_case6_branching_insert.sql` as the family model case.
