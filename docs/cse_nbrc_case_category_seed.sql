-- Exhale Academy CSE NBRC case-category mapping seed
-- Maps existing created CSE cases into NBRC A-G buckets.

begin;

-- A. Adult Chronic Airways Disease
update public.cse_cases
set
  nbrc_category_code = 'A',
  nbrc_category_name = 'Adult Chronic Airways Disease',
  nbrc_subcategory = 'Intubation and mechanical ventilation'
where slug in (
  'copd-critical-nppv-contraindication-pathway'
);

update public.cse_cases
set
  nbrc_category_code = 'A',
  nbrc_category_name = 'Adult Chronic Airways Disease',
  nbrc_subcategory = 'Noninvasive management'
where slug in (
  'copd-critical-nppv-failure-escalation'
);

update public.cse_cases
set
  nbrc_category_code = 'A',
  nbrc_category_name = 'Adult Chronic Airways Disease',
  nbrc_subcategory = 'Outpatient management of asthma'
where slug in (
  'copd-non-critical-asthma-triggered-exacerbation'
);

update public.cse_cases
set
  nbrc_category_code = 'A',
  nbrc_category_name = 'Adult Chronic Airways Disease',
  nbrc_subcategory = 'Diagnosis'
where slug in (
  'copd-non-critical-emphysema-phenotype',
  'copd-non-critical-chronic-bronchitis-phenotype'
);

-- B. Adult Trauma
update public.cse_cases
set
  nbrc_category_code = 'B',
  nbrc_category_name = 'Adult Trauma',
  nbrc_subcategory = null
where slug in (
  'trauma-critical-tension-pneumothorax',
  'trauma-critical-hemothorax',
  'trauma-critical-flail-chest-contusion',
  'trauma-critical-ventilator-pneumothorax'
);

-- C. Adult Cardiovascular
update public.cse_cases
set
  nbrc_category_code = 'C',
  nbrc_category_name = 'Adult Cardiovascular',
  nbrc_subcategory = 'Heart failure'
where slug in (
  'case-4-nocturnal-dyspnea-fluid-overload-crisis',
  'cardiovascular-critical-chf-cardiogenic-pulmonary-edema'
);

update public.cse_cases
set
  nbrc_category_code = 'C',
  nbrc_category_name = 'Adult Cardiovascular',
  nbrc_subcategory = 'Other'
where slug in (
  'case-7-sudden-hypoxemia-hemodynamic-strain-pattern',
  'cardiovascular-critical-myocardial-infarction-ischemic-crisis',
  'cardiovascular-critical-shock-perfusion-failure',
  'cardiovascular-critical-cor-pulmonale-right-heart-strain',
  'cardiovascular-critical-pulmonary-embolism-postop-sudden-deadspace'
);

-- D. Adult Neurological or Neuromuscular
update public.cse_cases
set
  nbrc_category_code = 'D',
  nbrc_category_name = 'Adult Neurological or Neuromuscular',
  nbrc_subcategory = null
where slug in (
  'case-10-neuromuscular-ventilatory-failure-pattern',
  'neuromuscular-critical-myasthenia-gravis-crisis',
  'neuromuscular-critical-guillain-barre-ascending-paralysis',
  'neuromuscular-critical-muscular-dystrophy-hypoventilation',
  'neuromuscular-critical-stroke-neuro-respiratory-failure',
  'neuromuscular-critical-tetanus-airway-risk',
  'adult-neuro-critical-head-trauma-cheyne-stokes-icp',
  'adult-neuro-critical-spinal-injury-airway-stability'
);

-- E. Adult Medical or Surgical
update public.cse_cases
set
  nbrc_category_code = 'E',
  nbrc_category_name = 'Adult Medical or Surgical',
  nbrc_subcategory = 'Other'
where slug in (
  'case-1-practice-layout-audit',
  'case-3-pacu-sudden-postop-respiratory-collapse',
  'case-8-post-extubation-stridor-respiratory-risk',
  'adult-med-surg-critical-drug-overdose-airway-protection',
  'adult-medical-critical-sleep-apnea-polysomnography-pathway',
  'adult-medical-critical-hypothermia-rewarming-resuscitation',
  'adult-medical-critical-renal-diabetes-kussmaul-acidosis',
  'adult-medical-critical-thoracic-surgery-postop-complications',
  'adult-medical-critical-obstructive-sleep-apnea-interface-optimization'
);

update public.cse_cases
set
  nbrc_category_code = 'E',
  nbrc_category_name = 'Adult Medical or Surgical',
  nbrc_subcategory = 'Infectious disease'
where slug in (
  'adult-medical-critical-pneumonia-consolidation-hypoxemia',
  'adult-medical-critical-aids-opportunistic-pcp-pathway'
);

update public.cse_cases
set
  nbrc_category_code = 'E',
  nbrc_category_name = 'Adult Medical or Surgical',
  nbrc_subcategory = 'Acute respiratory distress syndrome'
where slug in (
  'case-9-mechanically-ventilated-sudden-desaturation',
  'ards-critical-pneumonia-refractory-hypoxemia',
  'ards-critical-sepsis-lung-protective-ventilation',
  'ards-critical-aspiration-acute-whiteout-pattern',
  'ards-critical-pancreatitis-prone-position-pathway',
  'ards-critical-shock-inhalational-injury-mixed-trigger'
);

-- F. Pediatric
update public.cse_cases
set
  nbrc_category_code = 'F',
  nbrc_category_name = 'Pediatric',
  nbrc_subcategory = 'Other'
where slug in (
  'pediatric-critical-croup-gradual-barking-stridor',
  'pediatric-critical-epiglottitis-sudden-thumb-sign-emergency',
  'pediatric-critical-bronchiolitis-rsv-edema-apnea-risk',
  'pediatric-critical-cystic-fibrosis-secretion-burden',
  'pediatric-critical-foreign-body-aspiration-unilateral-wheeze'
);

-- G. Neonatal
update public.cse_cases
set
  nbrc_category_code = 'G',
  nbrc_category_name = 'Neonatal',
  nbrc_subcategory = 'Resuscitation'
where slug in (
  'case-2-term-infant-meconium-transition-failure',
  'neonatal-critical-delivery-room-apgar-resuscitation'
);

update public.cse_cases
set
  nbrc_category_code = 'G',
  nbrc_category_name = 'Neonatal',
  nbrc_subcategory = 'Respiratory distress syndrome'
where slug in (
  'neonatal-critical-meconium-aspiration-vigor-intubation-threshold',
  'neonatal-critical-apnea-of-prematurity-bradycardia-episodes',
  'neonatal-critical-irds-surfactant-deficiency-ground-glass',
  'neonatal-critical-congenital-heart-defect-cyanotic-shunt',
  'neonatal-critical-bpd-chronic-oxygen-dependence',
  'neonatal-critical-cdh-surgical-emergency-mediastinal-shift'
);

commit;
