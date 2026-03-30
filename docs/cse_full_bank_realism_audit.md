# Exhale CSE Full-Bank Realism Audit

This document compares the current Exhale 54-scenario CSE pool against the tone, sequencing, phrasing, numeric style, and option construction seen in the NBRC self-assessment response reports reviewed from:

- `/Users/joshguerrero/Downloads/cse version b .pdf`
- `/Users/joshguerrero/Downloads/CSE08-07.pdf.pdf`

This is not a clinical-correctness audit. It is a realism audit.

## Current Pool Size

Based on the seeded taxonomy map in `/Users/joshguerrero/exhale-academy/docs/cse_nbrc_case_category_seed.sql`, the repo currently supports:

- `54` unique CSE case slugs

The master exam builder pulls from active, published cases with an NBRC category code. See:

- `/Users/joshguerrero/exhale-academy/lib/supabase/cse-master.ts`

## What The NBRC PDFs Do Consistently

Across both PDFs, the CSE style is highly consistent.

### 1. Prompts are short, neutral, and operational

The exam usually asks:

- `Which of the following should be evaluated initially?`
- `Which of the following should be recommended?`
- `Which of the following should be evaluated postadmission?`
- `Which of the following should be recommended FIRST?`

The exam does not sound like an instructor. It sounds like a clinical simulation console.

### 2. Vitals and ABGs are presented in clean lists

NBRC style usually presents physiology like this:

- oxygen context first
- then vitals as a block
- then ABGs as a block when needed

Examples from the PDFs:

- `While receiving O2 by nasal cannula at 3 L/min, vital signs are:`
- `While the patient is receiving an FIO2 of 0.24, physiologic data obtained are:`
- `ABG analysis while receiving an FIO2 of 0.50 reveals:`

This matters because it keeps the simulation feeling structured and test-like.

### 3. The exam reports findings, not interpretations

The PDFs say things like:

- `Breath sounds are reduced on the left side`
- `A chest radiograph reveals ribs 2 through 7 are fractured`
- `The tracheostomy tube is patent`
- `SpO2 is 86% while receiving O2 by nasal cannula at 6 L/min`

The exam usually does not say:

- `This supports a unilateral obstructive process`
- `This reflects a best-available escalation pathway`

The student is expected to infer the meaning.

### 4. Single-best-answer items are usually one move

The correct recommendation is usually a single next action:

- `Initiate HHFNC at 50 L/min with an FIO2 of 1.0.`
- `Insert a left chest tube.`
- `Increase to an FIO2 of 0.30 by tracheostomy mask.`
- `Insert a cuffed tracheostomy tube, and initiate mechanical ventilation.`

The real exam does not usually make one option carry an entire protocol unless it is a final recommendation.

### 5. Select-many sections are selective, not broad

The PDFs consistently use focused information-gathering sections with small, high-yield sets. The current Exhale bank often behaves more like a long checklist exercise than a true CSE decision gate.

### 6. Explanations are brief and mechanistic

NBRC explanations usually sound like:

- `This is necessary to judge severity...`
- `This is indicated after a high-speed trauma...`
- `This level of O2 therapy should increase the FIO2 enough...`

They explain scoring logic briefly. They do not teach broadly.

## Current Exhale Bank: Recurring Realism Gaps

The major issues are consistent across the bank.

### 1. Overuse of broad select-many sections

Repo scan results:

- `73` instances of `MAX 8`
- `103` instances of `SELECT AS MANY AS INDICATED`

The strongest mismatch is the repeated use of:

- `SELECT AS MANY AS INDICATED (MAX 8)`

That feels more like an authored study product than the real CSE.

High-concentration files include:

- `/Users/joshguerrero/exhale-academy/docs/cse_case48_56_other_adult_medical_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case41_47_neonatal_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case25_30_neuro_medsurg_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case20_24_ards_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case31_35_cardiovascular_critical_insert.sql`

### 2. Prompt stems are too authored and too similar

Many Exhale stems follow this pattern:

- `You are called to bedside for...`
- `Focused assessment is pending.`
- `What are your next steps?`

This creates repetition and sounds custom-authored. The PDFs vary setting, oxygen context, and initial data more naturally.

### 3. Too much interpretive wording

The bank still contains language like:

- `structured reassessment`
- `structured plan`
- `structured handoff planning`
- `escalation readiness`
- `core ventilatory-failure surveillance metrics`
- `high-yield exam distinction`

These phrases are educational-product language, not NBRC simulation language.

Repo scan results:

- `31` uses of `structured`
- `1` use of `Core ventilatory-failure surveillance`
- `1` use of `High-yield exam distinction`

### 4. Numeric presentation is less NBRC-like than it should be

The PDFs usually:

- give oxygen context first
- present vitals as a vertical list
- present ABG values as a clean block
- avoid crowding too many numbers into one sentence

The current bank often embeds settings, ABGs, reassessment, and decision framing in one long prompt. That makes the sim feel denser than the real test.

### 5. ABG framing needs standardization

The PDFs use clear constructions such as:

- `ABG analysis while receiving an FIO2 of 0.50 reveals:`
- `While receiving O2 by nasal cannula at 4 L/min, ABG analysis reveals:`

Current Exhale cases often mix:

- ventilator settings
- an ABG block
- an instruction prompt
- a management question

inside one line. The data is present, but the presentation is less exam-authentic.

### 6. Options are still too bundled in several families

The biggest bundle problems remain in:

- COPD critical cases
- neuromuscular ventilatory failure
- ARDS critical

Examples include options that ask students to choose:

- a ventilator mode
- VT
- RR
- FiO2/PEEP logic
- ongoing titration approach

all in one answer. The NBRC usually isolates the next move.

## What Needs To Change Across The 54 Scenarios

## A. Prompt Framework

### Replace repetitive stems

Current style:

- `You are called to bedside for a 61-year-old male... Focused assessment is pending. What are your next steps?`

Preferred style:

- state the setting
- state oxygen/device context
- state a focused symptom cluster
- state the current physiologic block
- ask a short neutral question

Target patterns:

- `While receiving O2 by nasal cannula at 4 L/min, vital signs are:`
- `Which of the following should be evaluated initially?`
- `Which of the following should be recommended?`
- `Which of the following should be evaluated postadmission?`
- `Which of the following should be recommended FIRST?`

## B. Vitals Formatting

Use NBRC-like data blocks instead of long in-sentence physiology when possible.

Preferred pattern:

- device / FIO2 or flow context
- vertical vitals
- then the question

Example model:

- `While receiving O2 by nasal cannula at 2 L/min, vital signs are:`
- `Temperature`
- `HR`
- `RR`
- `BP`
- `SpO2`

This should become the default for initial scenario setup.

## C. ABG Formatting

ABGs should be introduced with the oxygen or ventilator context first.

Preferred pattern:

- `ABG analysis while receiving an FIO2 of 0.50 reveals:`
- then list:
  - `pH`
  - `PCO2`
  - `PO2`
  - `HCO3-`
  - `BE`
  - `SO2 (calc)` where appropriate

Avoid compressing all of this into one long sentence unless the UI forces it.

## D. Option Construction

### Single-choice

Default to one action per option.

Good:

- `Insert a chest tube.`
- `Initiate mechanical ventilation.`
- `Increase to an FIO2 of 0.30 by tracheostomy mask.`

Use multi-part options only when the real exam would realistically recommend a compound final action.

### Select-many

Reduce most `MAX 8` sections to:

- `MAX 3`
- `MAX 4`

Use `MAX 5` only when the scenario truly justifies it.

## E. Outcome Text

Outcome text should describe what happened, not summarize the diagnosis.

Good:

- `Breath sounds are absent on the right, and blood pressure continues to fall.`
- `SpO2 increases to 95%.`
- `The tracheostomy tube is patent.`

Bad:

- `This supports a unilateral obstructive thoracic process.`
- `This confirms the best-available escalation pathway.`

## F. Rationales

Shorten rationales across the bank.

Preferred style:

- why this option is indicated now
- why it changes the next decision
- why a distractor delays or fails care

Avoid textbook mini-lessons.

## G. Population-Specific Voice

The PDFs show that adult trauma, COPD, pediatric, and neonatal cases all share the same neutral exam voice but use different clinical vocabulary.

This means our rewrite should preserve:

- trauma-specific language for trauma
- neonatal workflow language for neonatal
- outpatient-management language for chronic airway and sleep-disordered breathing
- secretion and airway-clearance language for CF/bronchiectasis

The tone should stay uniform even as vocabulary changes.

## Highest-Priority Full-Bank Improvements

### Priority 1

Reduce `MAX 8` select-many sections across the entire bank.

Why:

- this is the single most obvious structural mismatch to the real CSE feel

### Priority 2

Standardize vitals and ABG presentation to NBRC-style blocks.

Why:

- this changes how the exam feels immediately
- it reduces the “custom case” feeling

### Priority 3

Remove interpretive / educational phrasing from prompts, options, outcomes, and rationales.

Why:

- this is the second-biggest tone mismatch after selection breadth

### Priority 4

Break bundled options into discrete next-step options.

Why:

- this improves judgment realism and priority testing

### Priority 5

Rewrite disposition and follow-up language to be more concrete and less “plan-oriented.”

Why:

- several current cases still sound like authored curriculum at the end instead of simulation

## Family-Level Rewrite Recommendations

### 1. COPD / asthma / chronic airways

Main issues:

- too many broad select-many prompts
- disposition language too “structured”
- more educational than operational

Priority files:

- `/Users/joshguerrero/exhale-academy/docs/cse_asthma_non_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case11_copd_non_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case12_copd_non_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case14_copd_critical_nppv_failure_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case15_copd_critical_nppv_contraindication_insert.sql`

### 2. Trauma

Main issues:

- over-broad select-many structure
- some prompts sound too templated
- strong clinical content, but not enough NBRC-style restraint

Priority files:

- `/Users/joshguerrero/exhale-academy/docs/cse_case16_17_trauma_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case18_19_trauma_critical_insert.sql`

### 3. ARDS / ventilator / adult medical critical

Main issues:

- ABG and vent data too embedded
- some options still too bundled
- should become more settings-context -> ABG block -> one recommendation

Priority files:

- `/Users/joshguerrero/exhale-academy/docs/cse_case20_24_ards_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case48_56_other_adult_medical_critical_insert.sql`

### 4. Neuro / neuromuscular

Main issues:

- exam-aware language
- overinterpretive options
- some ventilatory management bundles

Priority files:

- `/Users/joshguerrero/exhale-academy/docs/cse_case10_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case25_30_neuro_medsurg_critical_insert.sql`

### 5. Pediatric / neonatal

Main issues:

- very templated step-one stems
- broad select-many
- outcomes/disposition language too authored

Priority files:

- `/Users/joshguerrero/exhale-academy/docs/cse_case36_40_pediatric_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case41_47_neonatal_critical_insert.sql`

## Recommended Rewrite Program For The 54 Scenarios

Do not rewrite randomly. Rewrite in this order:

1. COPD / asthma / noninvasive / ventilatory failure
2. Trauma and ventilator emergencies
3. ARDS and other adult medical critical
4. Neuro / neuromuscular
5. Pediatric
6. Neonatal

For each family:

1. reduce `MAX 8`
2. standardize opening vitals format
3. standardize ABG format
4. tighten prompt phrasing
5. split bundled options
6. replace interpretive outcomes with bedside findings
7. shorten rationales

## Bottom Line

The Exhale case bank already has enough clinical coverage to support a strong master exam. The main gap is not content count. The main gap is realism:

- too many broad select-many sections
- too much authored language
- too much bundled decision-making
- physiology presentation that is less NBRC-like than it could be

The good news is that this is fixable without deleting the whole bank. Most of the 54 scenarios can be improved through controlled refactors using the rubric from:

- `/Users/joshguerrero/exhale-academy/docs/cse_realism_review_checklist.md`

The most important bank-wide shift is this:

- report findings
- ask for the next move
- keep the wording neutral
- make the student infer the meaning

That is what the NBRC PDFs do repeatedly, and that is the standard Exhale should match.
