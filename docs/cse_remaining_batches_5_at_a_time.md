# Exhale CSE Remaining Rewrite Batches (5 At A Time)

This queue assumes the following cases are already rewritten to the new Exhale standard:

- Adult Chronic Airways: Cases 11-15 plus asthma noncritical replacement
- Adult Trauma: Cases 16-19
- Adult Cardiovascular: Case 7
- Adult Neurological/Neuromuscular: Case 10
- Adult Medical/Surgical: Cases 8, 9, 20, 21, 22, 23, 24

That leaves `36` cases remaining in the active 54-case pool.

## Working Principles

Every remaining batch should follow the same rules already locked in:

- pathology arc first
- Case 6 realism second
- reveal key findings only after the student chooses the right assessment
- no duplicated intro data and option data
- split bundled choices into discrete bedside actions
- use CBC / hemoglobin / hematocrit / cultures / lactate / chemistry only when the pathology calls for them
- keep prompts neutral and NBRC-like

## Batch 1: Cardiovascular Core

Goal:
- finish most of the cardiovascular family in one pass
- keep the hemodynamic and pulmonary-edema logic internally consistent

Cases:
- Case 4: `case-4-nocturnal-dyspnea-fluid-overload-crisis`
- Case 31: `cardiovascular-critical-chf-cardiogenic-pulmonary-edema`
- Case 32: `cardiovascular-critical-myocardial-infarction-ischemic-crisis`
- Case 33: `cardiovascular-critical-shock-perfusion-failure`
- Case 34: `cardiovascular-critical-cor-pulmonale-right-heart-strain`

Primary files:
- `/Users/joshguerrero/exhale-academy/docs/cse_case4_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case31_35_cardiovascular_critical_insert.sql`

## Batch 2: Cardiovascular Closeout + Acute Adult Med/Surg

Goal:
- finish the last cardiovascular case
- immediately carry that acute adult hemodynamic/airway seriousness into the most similar med-surg cases

Cases:
- Case 35: `cardiovascular-critical-pulmonary-embolism-postop-sudden-deadspace`
- Case 1: `case-1-practice-layout-audit`
- Case 3: `case-3-pacu-sudden-postop-respiratory-collapse`
- Case 48: `adult-med-surg-critical-drug-overdose-airway-protection`
- Case 52: `adult-medical-critical-thoracic-surgery-postop-complications`

Primary files:
- `/Users/joshguerrero/exhale-academy/docs/cse_case1_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case3_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case31_35_cardiovascular_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case48_56_other_adult_medical_critical_insert.sql`

## Batch 3: Adult Med/Surg Medical Triggers

Goal:
- focus on adult medical cases that depend on labs, gases, imaging, and source recognition
- use CBC / chemistries / cultures where they add realism

Cases:
- Case 49: `adult-medical-critical-sleep-apnea-polysomnography-pathway`
- Case 50: `adult-medical-critical-hypothermia-rewarming-resuscitation`
- Case 51: `adult-medical-critical-renal-diabetes-kussmaul-acidosis`
- Case 53: `adult-medical-critical-obstructive-sleep-apnea-interface-optimization`
- Case 54: `adult-medical-critical-pneumonia-consolidation-hypoxemia`

Primary files:
- `/Users/joshguerrero/exhale-academy/docs/cse_case48_56_other_adult_medical_critical_insert.sql`

## Batch 4: Adult Med/Surg Infectious / Immunologic + Neuro Start

Goal:
- close out the remaining adult medical/surgical family
- start the neuromuscular family with the highest-yield ICU pathways

Cases:
- Case 55: `adult-medical-critical-aids-opportunistic-pcp-pathway`
- Case 25: `neuromuscular-critical-myasthenia-gravis-crisis`
- Case 26: `neuromuscular-critical-guillain-barre-ascending-paralysis`
- Case 27: `neuromuscular-critical-muscular-dystrophy-hypoventilation`
- Case 28: `neuromuscular-critical-stroke-neuro-respiratory-failure`

Primary files:
- `/Users/joshguerrero/exhale-academy/docs/cse_case25_30_neuro_medsurg_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case48_56_other_adult_medical_critical_insert.sql`

## Batch 5: Neuro / Neuromuscular Closeout + Pediatric Airway Start

Goal:
- finish adult neuro
- transition into the pediatric airway cases, which share strong deterioration timing and rescue logic

Cases:
- Case 29: `neuromuscular-critical-tetanus-airway-risk`
- Case 30: `adult-neuro-critical-head-trauma-cheyne-stokes-icp`
- Case 56: `adult-neuro-critical-spinal-injury-airway-stability`
- Case 36: `pediatric-critical-croup-gradual-barking-stridor`
- Case 37: `pediatric-critical-epiglottitis-sudden-thumb-sign-emergency`

Primary files:
- `/Users/joshguerrero/exhale-academy/docs/cse_case25_30_neuro_medsurg_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case36_40_pediatric_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case48_56_other_adult_medical_critical_insert.sql`

## Batch 6: Pediatric Respiratory Cluster

Goal:
- keep all remaining pediatric disease patterns together
- differentiate upper airway, bronchiolitis, secretion burden, and foreign-body logic clearly

Cases:
- Case 38: `pediatric-critical-bronchiolitis-rsv-edema-apnea-risk`
- Case 39: `pediatric-critical-cystic-fibrosis-secretion-burden`
- Case 40: `pediatric-critical-foreign-body-aspiration-unilateral-wheeze`
- Case 2: `case-2-term-infant-meconium-transition-failure`
- Case 41: `neonatal-critical-delivery-room-apgar-resuscitation`

Primary files:
- `/Users/joshguerrero/exhale-academy/docs/cse_case2_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case36_40_pediatric_critical_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case41_47_neonatal_critical_insert.sql`

## Batch 7: Neonatal Core

Goal:
- lock in the neonatal tone and resuscitation / RDS / apnea workflow
- keep the numbers and escalation thresholds distinct from pediatric and adult cases

Cases:
- Case 42: `neonatal-critical-meconium-aspiration-vigor-intubation-threshold`
- Case 43: `neonatal-critical-apnea-of-prematurity-bradycardia-episodes`
- Case 44: `neonatal-critical-irds-surfactant-deficiency-ground-glass`
- Case 45: `neonatal-critical-congenital-heart-defect-cyanotic-shunt`
- Case 46: `neonatal-critical-bpd-chronic-oxygen-dependence`

Primary files:
- `/Users/joshguerrero/exhale-academy/docs/cse_case41_47_neonatal_critical_insert.sql`

## Batch 8: Neonatal Closeout

Goal:
- finish the last neonatal case and use the remaining capacity for QA / polish on any weak edge cases from earlier batches

Cases:
- Case 47: `neonatal-critical-cdh-surgical-emergency-mediastinal-shift`
- Plus four flex slots reserved for:
  - post-review fixes from earlier batches
  - any rebuilt cases that need a second pass
  - any taxonomy/title cleanup discovered during testing

Primary files:
- `/Users/joshguerrero/exhale-academy/docs/cse_case41_47_neonatal_critical_insert.sql`

## Recommended Execution Order

1. Batch 1: Cardiovascular Core
2. Batch 2: Cardiovascular Closeout + Acute Adult Med/Surg
3. Batch 3: Adult Med/Surg Medical Triggers
4. Batch 4: Adult Med/Surg Infectious / Immunologic + Neuro Start
5. Batch 5: Neuro / Neuromuscular Closeout + Pediatric Airway Start
6. Batch 6: Pediatric Respiratory Cluster
7. Batch 7: Neonatal Core
8. Batch 8: Neonatal Closeout + QA Buffer

## Why This Order Works

- It finishes the adult critical-care families first.
- It keeps similar physiology together wherever possible.
- It leaves neonatal for later, when the tone and number-formatting standard is fully stable.
- It reserves explicit space for cleanup, which is realistic if we are pushing for top-end quality.

## Immediate Next Batch

Start with:
- Batch 1: Cardiovascular Core

That means the next working files should be:
- `/Users/joshguerrero/exhale-academy/docs/cse_case4_branching_insert.sql`
- `/Users/joshguerrero/exhale-academy/docs/cse_case31_35_cardiovascular_critical_insert.sql`
