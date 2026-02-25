-- Exhale Academy CSE pediatric disorders playbook seed
-- Captures croup/epiglottitis differentiation, bronchiolitis, CF, and foreign-body aspiration.

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
  'pediatric-airway-and-infectious-disorders',
  'Pediatric Airway and Infectious Disorders',
  'critical',
  'Pediatric CSE cases in this lesson emphasize rapid airway-risk triage, croup-vs-epiglottitis differentiation, RSV bronchiolitis decision logic, cystic-fibrosis chronic management priorities, and foreign-body aspiration emergencies.',
  array[
    'sudden upper-airway distress in child',
    'inspiratory stridor or severe work of breathing',
    'muffled voice/cough with high fever and rapid decline',
    'apnea or cyanosis in infant bronchiolitis',
    'unilateral wheeze suggesting foreign-body aspiration'
  ],
  array[
    'pediatric ED airway pathway',
    'PICU escalation workflow',
    'post-procedure pediatric observation'
  ],
  array[
    'Child with barking cough and inspiratory stridor over gradual onset',
    'Child with sudden toxic appearance and supraglottic airway emergency pattern',
    'Infant with RSV bronchiolitis progression and respiratory distress',
    'CF child with chronic secretion burden and recurrent infections',
    'Toddler with sudden unilateral wheeze and aspiration concern'
  ],
  array[
    'Croup is viral subglottic disease with gradual onset and barking cough/stridor pattern',
    'Epiglottitis is bacterial supraglottic emergency with sudden onset and immediate airway threat',
    'Exam anchor: epiglottitis requires immediate intubation; croup usually does not',
    'Bronchiolitis is usually RSV in infants under 2 and can progress from URI to severe distress',
    'Foreign-body aspiration in toddlers often presents with unilateral wheeze and sudden onset'
  ],
  array[
    'appearance and distress severity',
    'stridor/cough character',
    'onset timeline (gradual vs sudden)',
    'cyanosis, retractions, nasal flaring, lethargy'
  ],
  array[
    'respiratory rate/pattern and accessory muscle use',
    'unilateral vs bilateral breath-sound findings',
    'airway-protection status and secretion burden',
    'continuous SpO2 and vital-sign trend'
  ],
  array[
    'ABG when severity escalation concern exists',
    'CBC for infectious context as indicated',
    'targeted microbiology/culture context in CF or severe infection patterns'
  ],
  array[
    'lateral neck x-ray: steeple sign (croup) vs thumb sign (epiglottitis)',
    'CF: sweat chloride testing when diagnosis is suspected (> 60 mEq/L positive threshold)',
    'foreign-body aspiration imaging nuance: radiolucent organic objects may be missed on x-ray'
  ],
  array[
    'delaying airway control in suspected epiglottitis',
    'routine bronchodilator use in bronchiolitis where wheeze is edema-dominant',
    'routine corticosteroids/ribavirin/antibiotics in bronchiolitis without bacterial infection evidence',
    'delaying foreign-body removal once aspiration is strongly suspected'
  ],
  array[
    'provide oxygen for hypoxemia and close ventilatory monitoring',
    'epiglottitis: immediate intubation/mechanical ventilation with emergency surgical-airway backup if needed',
    'croup: cool aerosol environment, racemic epinephrine, and escalation if respiratory failure or airway-protection risk evolves',
    'bronchiolitis: supportive care with suction/oxygen and hospitalization for severe cases only',
    'CF: airway-clearance strategy, sequenced aerosol therapy, inhaled antibiotics as indicated, and nutrition/enzyme support',
    'foreign-body aspiration: urgent rigid bronchoscopy for removal'
  ],
  array[
    'croup nonresponse pathway can include Heliox and corticosteroid consideration',
    'post-foreign-body-removal bronchodilator/steroid may be considered if persistent wheeze/cough remains',
    'hospital bronchiolitis cases should use droplet isolation'
  ],
  array[
    'observe-only approach during rapid pediatric airway decline',
    'discharging severe bronchiolitis with apnea/cyanosis/bradycardia signs',
    'treating suspected aspiration with delay while relying only on x-ray visibility'
  ],
  '[
    {"pattern":"pediatric_upper_airway","findings":"acute alveolar hyperventilation with hypoxemia may appear in severe upper-airway disease","action":"airway-priority escalation with close trend monitoring"},
    {"pattern":"bronchiolitis_or_cf_distress","findings":"hypoxemia with respiratory distress progression","action":"supportive oxygenation and escalation by failure criteria"}
  ]'::jsonb,
  '[
    {"pattern":"severe_pediatric_hypoxemia","findings":"persistent oxygenation deficit despite initial support","action":"escalate to high-acuity airway/ventilation pathway"}
  ]'::jsonb,
  '[
    {"pattern":"epiglottitis_emergency_airway","findings":"sudden supraglottic emergency pattern","action":"immediate intubation/mechanical ventilation"},
    {"pattern":"bronchiolitis_failure","findings":"apnea, severe fatigue, or worsening gas exchange","action":"consider mechanical ventilation"},
    {"pattern":"foreign_body_obstruction","findings":"critical obstruction not relieved with initial maneuvers","action":"urgent bronchoscopy and surgical-airway backup if needed"}
  ]'::jsonb,
  array[
    'PICU/ICU monitoring for unresolved airway risk or ventilatory instability',
    'discharge only after sustained respiratory stability and caregiver-ready follow-up plan'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Pediatric lesson capture includes croup-vs-epiglottitis differentiation (gradual barking stridor/steeple vs sudden muffled emergency/thumb), bronchiolitis severity and do-not-recommend list, cystic-fibrosis IG/DM anchors including sweat chloride logic and TOBI context, and foreign-body aspiration unilateral wheeze emergency pattern with urgent bronchoscopy.',
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
