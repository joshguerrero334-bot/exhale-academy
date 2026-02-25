-- Exhale Academy CSE ARDS playbook seed
-- Captures ARDS lesson guidance for case generation.

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
  'ards',
  'Acute Respiratory Distress Syndrome (ARDS)',
  'critical',
  'ARDS is a severe acute respiratory disorder characterized by noncardiogenic pulmonary edema, refractory hypoxemia, and reduced lung compliance requiring lung-protective ventilation and cause-directed management.',
  array[
    'acute respiratory distress with rapid worsening',
    'refractory hypoxemia',
    'bilateral infiltrates/ground-glass appearance',
    'decreased lung compliance',
    'P/F ratio below 300 on PEEP >= 5'
  ],
  array['ED resuscitation bay', 'ICU escalation', 'post-infectious deterioration pathway'],
  array[
    'Patient with worsening respiratory failure after pneumonia or sepsis',
    'Acute bilateral pulmonary process with severe oxygenation failure',
    'Noncardiogenic pulmonary edema pattern requiring ARDSNet strategy'
  ],
  array[
    'ARDS causes include pneumonia, trauma, aspiration, sepsis, drug overdose, fluid overload, inhalation of toxins, shock, burns, and pancreatitis',
    'Onset is acute within 1 week with worsening respiratory symptoms',
    'Pulmonary edema should be noncardiogenic (not heart-failure driven)',
    'Treat the underlying cause that triggered ARDS'
  ],
  array[
    'tachypnea',
    'intercostal retractions',
    'diaphoresis',
    'cyanosis'
  ],
  array[
    'auscultation: bronchial breath sounds or crackles',
    'tachycardia and hypertension trend',
    'severe hypoxemia pattern'
  ],
  array[
    'ABG for PaO2, P/F ratio, and acid-base balance',
    'sputum culture when infection is suspected',
    'hemodynamic monitoring: elevated PAP with normal PCWP trend in ARDS profile'
  ],
  array[
    'chest x-ray with bilateral infiltrates/radiopacity (whiteout) and ground-glass pattern'
  ],
  array[
    'delaying oxygen/PEEP escalation in refractory hypoxemia',
    'treating ARDS without addressing underlying etiology'
  ],
  array[
    'oxygen therapy with FiO2 up to 60% then add PEEP, wean FiO2 below 60% before reducing PEEP when improving',
    'ARDSNet lung-protective ventilation: tidal volume 6 mL/kg IBW, plateau pressure < 30 cmH2O',
    'permissive hypercapnia acceptable when pH >= 7.20',
    'diuretics to reduce fluid overload risk',
    'close hemodynamic monitoring',
    'prone positioning up to 16 hours to improve oxygenation',
    'consider HFOV, IRV, and APRV in selected severe trajectories',
    'rescue pulmonary vasodilator option: inhaled nitric oxide',
    'treat the underlying trigger (e.g., pneumonia -> antibiotics)'
  ],
  array[
    'antibiotics when infection source is identified',
    'serial reassessment of oxygenation and ventilatory mechanics'
  ],
  array[
    'beta agonists as ARDS therapy',
    'corticosteroids as routine ARDS therapy',
    'N-acetylcysteine as ARDS therapy',
    'surfactant therapy for routine ARDS treatment',
    'pulmonary artery catheter use as routine ARDS treatment'
  ],
  '[
    {"pattern":"refractory_hypoxemia","findings":"severe oxygenation failure despite increasing FiO2","action":"add/optimize PEEP and continue lung-protective strategy"},
    {"pattern":"permissive_hypercapnia","findings":"rising PaCO2 with acceptable pH >= 7.20","action":"continue ARDSNet strategy while monitoring for decompensation"}
  ]'::jsonb,
  '[
    {"pattern":"moderate_to_severe_ards","findings":"P/F < 300 on PEEP >= 5","action":"intensify oxygenation strategy and prone consideration"}
  ]'::jsonb,
  '[
    {"pattern":"ardsnet_core","findings":"ARDS with low compliance","action":"TV 6 mL/kg IBW, plateau pressure < 30, permissive hypercapnia threshold pH >= 7.20"},
    {"pattern":"rescue_ventilation_options","findings":"persistent severe hypoxemia despite standard strategy","action":"consider APRV/IRV/HFOV and rescue therapies"}
  ]'::jsonb,
  array[
    'ICU-level management with structured reassessment',
    'maintain escalation readiness with refractory hypoxemia trajectories'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Captured ARDS lesson: definition, causes, IG findings (distress signs, crackles/bronchial breath sounds, ABG/CXR/hemodynamics), core treatment sequence, ARDSNet settings, and ineffective-therapy exclusions.',
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
