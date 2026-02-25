-- Exhale Academy CSE neonatal disorders playbook seed
-- Captures delivery room management, MAS, AOP, IRDS, CHD, BPD, and CDH.

begin;

insert into public.cse_disease_playbooks (
  disease_slug,
  disease_name,
  track,
  summary,
  emergency_cues,
  scenario_setting_templates,
  scenario_patient_summary_templates,
  scenario_history_templates,
  ig_visual_priorities,
  ig_bedside_priorities,
  ig_basic_lab_priorities,
  ig_special_test_priorities,
  ig_avoid_or_penalize,
  dm_best_actions,
  dm_reasonable_alternatives,
  dm_unsafe_actions,
  abg_patterns,
  oxygenation_patterns,
  ventilator_patterns,
  disposition_guidance,
  scoring_guidance,
  author_notes,
  source_name,
  source_revision
)
values (
  'neonatal-critical-disorders',
  'Neonatal Critical Disorders',
  'critical',
  'Neonatal CSE cases require rapid transition assessment, Apgar-driven delivery-room decisions, and syndrome-specific escalation for respiratory and cardiopulmonary emergencies.',
  array[
    'low Apgar score with poor respiratory effort',
    'cyanosis with grunting/retractions/flaring',
    'apnea with bradycardia in premature infant',
    'respiratory acidosis with worsening hypoxemia',
    'sudden severe neonatal distress requiring immediate airway/surgical planning'
  ],
  array[
    'delivery room high-risk birth response',
    'NICU respiratory deterioration pathway',
    'neonatal surgical emergency stabilization'
  ],
  array[
    'Preterm infant requiring immediate post-delivery transition assessment',
    'Meconium-stained infant with variable respiratory effort',
    'Premature infant with surfactant-deficiency distress pattern',
    'Neonate with congenital cardiopulmonary structural disease'
  ],
  array[
    'Delivery-room management is Apgar-driven and requires reassessment timing discipline',
    'Meconium aspiration intubation decision depends on infant vigor/heart rate, not stain alone',
    'IRDS is surfactant deficiency disease in prematurity and requires surfactant-focused management',
    'Congenital heart defects may cause severe neonatal cyanosis and usually require definitive surgery',
    'CDH is a surgical emergency; avoid bag-mask ventilation and decompress bowel with OG tube'
  ],
  array[
    'color/tone/cry/effort immediately after birth',
    'apnea, cyanosis, retractions, nasal flaring, grunting',
    'disease-defining visual clues (meconium staining, severe distress posture)'
  ],
  array[
    'Apgar components: appearance, pulse, grimace, activity, respiratory effort',
    'HR, RR, SpO2 trend with close continuous monitoring in unstable infant',
    'breath sounds and asymmetry pattern',
    'work of breathing and progression trajectory'
  ],
  array[
    'ABG for oxygenation/ventilation and acid-base trajectory',
    'CBC/infection workup when indicated by syndrome',
    'pre/post-ductal gas studies in congenital cardiac concern'
  ],
  array[
    'lateral neck/chest imaging and neonatal CXR pattern recognition as syndrome indicates',
    'echocardiogram as primary confirmatory test for congenital heart defects',
    'L:S ratio context for IRDS maturation assessment when provided'
  ],
  array[
    'intubating vigorous meconium-stained infant solely for stain',
    'delaying epiglottic-level airway emergencies in neonatal/pediatric overlap contexts',
    'routine bag-mask ventilation in suspected congenital diaphragmatic hernia',
    'ignoring apnea/bradycardia progression in premature infant'
  ],
  array[
    'provide oxygen for hypoxemia with neonatal target-aware titration',
    'delivery room: apply Apgar-based response (resuscitate 0-3, support 4-6, routine care 7-10)',
    'MAS: suction strategy and intubation only when poor effort/tone/HR < 100 are present',
    'AOP: continuous apnea/HR/SpO2 monitoring with caffeine and escalation support',
    'IRDS: CPAP/surfactant/thermal control and escalate to invasive ventilation when failing',
    'CHD: oxygenation support, confirm with echo, and early surgical pathway',
    'BPD: low-effective-oxygen strategy, pulmonary hygiene, and careful ventilator weaning',
    'CDH: immediate surgical pathway, OG decompression, intubation/HFOV/ECMO strategy as needed'
  ],
  array[
    'HFOV can be considered when conventional ventilation is inadequate in MAS/CDH contexts',
    'HFNC may be considered as CPAP alternative in selected IRDS support pathways'
  ],
  array[
    'observe-only approach in severe neonatal respiratory distress',
    'premature low-acuity transfer before sustained stability',
    'ignoring repeated low Apgar reassessment protocol when score remains < 7 at 5 minutes'
  ],
  '[
    {"pattern":"mas","findings":"hypoxemia with possible metabolic acidosis","action":"oxygenation support with intubation-by-vigor criteria"},
    {"pattern":"irds_or_bpd","findings":"respiratory acidosis with hypoxemia","action":"surfactant/CPAP or ventilatory escalation based on response"},
    {"pattern":"cdh","findings":"respiratory acidosis with severe oxygenation compromise","action":"urgent intubation and surgical pathway"}
  ]'::jsonb,
  '[
    {"pattern":"mas_targets","findings":"meconium aspiration support phase","action":"target PaO2 55-80 torr and SpO2 88-95%"},
    {"pattern":"irds_targets","findings":"premature surfactant-deficiency distress","action":"target PaO2 50-70 torr and SpO2 85-92%"},
    {"pattern":"bpd_targets","findings":"chronic neonatal lung disease support","action":"use lowest oxygen needed to keep SpO2 88-92%"}
  ]'::jsonb,
  '[
    {"pattern":"delivery_room_emergency","findings":"Apgar 0-3 with severe compromise","action":"resuscitation and CPR"},
    {"pattern":"mas_nonvigorous","findings":"poor tone/effort with HR < 100 in meconium context","action":"intubate and suction trachea immediately"},
    {"pattern":"irds_failure_on_cpap","findings":"pH cannot be maintained above 7.25 on CPAP","action":"intubate and initiate mechanical ventilation with PEEP"},
    {"pattern":"cdh_airway","findings":"suspected congenital diaphragmatic hernia","action":"avoid bag-mask ventilation; intubate and decompress with OG tube"}
  ]'::jsonb,
  array[
    'NICU/PICU-level monitoring for unresolved respiratory or hemodynamic instability',
    'wean/escalation plans require objective trend stability before transfer or discharge'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Neonatal lesson capture includes: delivery-room Apgar algorithm and repeat timing rules; MAS vigor-based intubation threshold; apnea-of-prematurity monitoring and caffeine support; IRDS surfactant-deficiency with CPAP/ventilation thresholds; congenital heart defect imaging/echo anchors; BPD oxygen and wean strategy; and CDH emergency management with OG decompression, intubation, and no bag-mask ventilation.',
  'Exhale Faculty',
  '2026-02-24'
)
on conflict (disease_slug, track) do update
set
  disease_name = excluded.disease_name,
  summary = excluded.summary,
  emergency_cues = excluded.emergency_cues,
  scenario_setting_templates = excluded.scenario_setting_templates,
  scenario_patient_summary_templates = excluded.scenario_patient_summary_templates,
  scenario_history_templates = excluded.scenario_history_templates,
  ig_visual_priorities = excluded.ig_visual_priorities,
  ig_bedside_priorities = excluded.ig_bedside_priorities,
  ig_basic_lab_priorities = excluded.ig_basic_lab_priorities,
  ig_special_test_priorities = excluded.ig_special_test_priorities,
  ig_avoid_or_penalize = excluded.ig_avoid_or_penalize,
  dm_best_actions = excluded.dm_best_actions,
  dm_reasonable_alternatives = excluded.dm_reasonable_alternatives,
  dm_unsafe_actions = excluded.dm_unsafe_actions,
  abg_patterns = excluded.abg_patterns,
  oxygenation_patterns = excluded.oxygenation_patterns,
  ventilator_patterns = excluded.ventilator_patterns,
  disposition_guidance = excluded.disposition_guidance,
  scoring_guidance = excluded.scoring_guidance,
  author_notes = excluded.author_notes,
  source_name = excluded.source_name,
  source_revision = excluded.source_revision;

commit;
