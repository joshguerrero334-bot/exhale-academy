-- Exhale Academy CSE other adult medical conditions playbook seed
-- Covers sleep disorders, hypothermia, pneumonia, AIDS, renal failure/diabetes,
-- thoracic surgery, head trauma, and spinal injury.

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
  'adult-other-medical-conditions',
  'Adult Other Medical Conditions',
  'critical',
  'Adult medical/surgical and neurocritical CSE cases in this lesson set emphasize syndrome recognition, airway-first escalation, and targeted diagnostics for sleep disorders, hypothermia, pneumonia, AIDS, renal/diabetic crises, thoracic surgery complications, head trauma, and spinal injury.',
  array[
    'severe hypothermia with no signs of life',
    'ventilatory failure with altered mental status',
    'postoperative respiratory deterioration after extubation',
    'head trauma with cheyne-stokes and GCS <= 8',
    'spinal injury with apnea or airway compromise'
  ],
  array[
    'ED resuscitation bay',
    'ICU respiratory decline pathway',
    'post-op rapid response setting',
    'neurocritical trauma pathway'
  ],
  array[
    'Adult with chronic sleep apnea symptoms and daytime sequelae',
    'Cold-exposure patient with bradycardia/bradypnea and altered mentation',
    'Infectious pulmonary process with consolidation and hypoxemia',
    'Immunocompromised patient with recurrent fever and opportunistic infection concern',
    'Trauma/surgical patient with escalating ventilatory risk'
  ],
  array[
    'Sleep apnea workup should always include polysomnography and central-vs-obstructive differentiation',
    'Kussmaul breathing should strongly trigger renal failure/metabolic acidosis concern',
    'Cheyne-stokes pattern should trigger head trauma/neuro concern in this section context',
    'Thoracic surgery prevention includes pre/post-op hyperinflation therapy to reduce atelectasis risk'
  ],
  array[
    'work of breathing and mental status',
    'color/perfusion pattern',
    'syndrome-specific appearance cues (cold exposure, trauma pattern, postoperative decline)'
  ],
  array[
    'vital signs and oxygenation trend',
    'airway patency and aspiration risk',
    'breath sounds and expansion/percussion findings when pulmonary process is suspected'
  ],
  array[
    'ABG for oxygenation/ventilation and acid-base trend',
    'electrolytes and glucose when renal/diabetic disorder suspected',
    'CBC and infection markers in pneumonia/infectious contexts'
  ],
  array[
    'polysomnography for sleep apnea',
    'GCS and capnography in head trauma',
    'CT/MRI in spinal injury evaluation',
    'ELISA testing for HIV/AIDS context'
  ],
  array[
    'delaying stabilization while waiting for nonurgent diagnostics',
    'ignoring airway risk in obtunded or high-trauma patients',
    'using non-heated humidification strategy in severe hypothermia ventilatory support',
    'missing VAP-protocol considerations when ventilating pneumonia cases'
  ],
  array[
    'provide oxygen for hypoxemia and continuously monitor cardiorespiratory status',
    'intubate and mechanically ventilate for ventilatory failure based on objective decline',
    'treat underlying cause after immediate stabilization',
    'use targeted treatment pathways by syndrome (sleep apnea mode selection, infection treatment, trauma-neuro ICP/airway goals)'
  ],
  array[
    'sleep apnea: optimize interface and positioning strategy for obstructive disease',
    'pneumonia: hyperinflation plus pulmonary hygiene alongside infection-directed therapy',
    'spinal injury: airway techniques that maintain cervical stability'
  ],
  array[
    'observe-only strategy in unstable respiratory failure',
    'premature de-escalation after one minor improvement',
    'failing to protect spine/neck when spinal injury is still possible',
    'failing to secure airway when GCS is at severe threshold'
  ],
  '[
    {"pattern":"pneumonia","findings":"respiratory alkalosis with hypoxemia","action":"oxygenation support and infection-directed care"},
    {"pattern":"hypothermia_or_neuro_decline","findings":"respiratory acidosis with hypoxemia can emerge with ventilatory failure","action":"airway/ventilation escalation and targeted rewarming/neuro strategy"},
    {"pattern":"renal_diabetic","findings":"metabolic acidosis pattern","action":"correct metabolic driver and monitor ventilatory fatigue"}
  ]'::jsonb,
  '[
    {"pattern":"sleep_or_chronic_failure","findings":"chronic ventilatory-failure trend may coexist with hypoxemia","action":"select appropriate noninvasive support and monitor response"},
    {"pattern":"severe_acute_hypoxemia","findings":"persistent oxygen deficit despite initial therapy","action":"escalate ventilatory support"}
  ]'::jsonb,
  '[
    {"pattern":"osa","findings":"obstructive sleep apnea pattern","action":"CPAP with interface optimization"},
    {"pattern":"csa","findings":"central sleep apnea pattern","action":"NPPV support strategy"},
    {"pattern":"thoracic_postop_decline","findings":"post-extubation deterioration after thoracic surgery","action":"re-intubate and resume mechanical ventilation"},
    {"pattern":"head_trauma","findings":"GCS <= 8 or worsening neuro-respiratory status","action":"immediate intubation and mechanical ventilation"},
    {"pattern":"spinal_injury_airway","findings":"airway compromise with cervical injury risk","action":"modified jaw-thrust/fiberoptic-assisted intubation strategy"}
  ]'::jsonb,
  array[
    'maintain ICU/high-acuity management until sustained stabilization',
    'transition plans should include complication surveillance and explicit escalation triggers'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Lesson capture includes: sleep apnea diagnostics and AHI framework; hypothermia ABG correction caveat and warming strategy; pneumonia diagnostics/treatment with VAP considerations; AIDS ELISA and opportunistic infection guidance; renal/diabetes Kussmaul and metabolic-acidosis surveillance; thoracic surgery complication prevention; head trauma GCS/ICP/capnography strategy; and spinal injury airway stabilization technique.',
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
