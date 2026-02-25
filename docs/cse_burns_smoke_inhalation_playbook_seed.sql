-- Exhale Academy CSE burns + smoke inhalation playbook seed

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
  'burns-smoke-inhalation',
  'Burns and Smoke Inhalation',
  'critical',
  'Critical burns and smoke inhalation cases emphasize rapid airway-risk recognition, progression to complete obstruction risk, and immediate escalation for inhalation injury and carbon monoxide poisoning.',
  array[
    'smoke inhalation exposure',
    'tachypnea',
    'black/sooty secretions',
    'progressive respiratory distress with airway obstruction risk',
    'cherry red appearance suggesting carbon monoxide poisoning'
  ],
  array['ED resuscitation bay', 'burn center transfer pathway', 'fire-scene smoke exposure handoff'],
  array[
    'Fire victim with inhalation injury concern',
    'Firefighter after heavy smoke exposure',
    'Patient with significant car-exhaust inhalation and hypoxemia symptoms'
  ],
  array[
    'Smoke inhalation and burns can progress to complete airway obstruction and require urgent RT-focused management',
    'High-risk exposure contexts include fire victims, firefighters, and car-exhaust inhalation',
    'On CSE, cherry red appearance should trigger suspicion for carbon monoxide poisoning'
  ],
  array[
    'respiratory distress severity',
    'burn/smoke exposure context',
    'appearance cues including cherry red finding when present'
  ],
  array[
    'black/sooty secretions',
    'tachypnea trend',
    'work of breathing and evolving airway compromise signs'
  ],
  array[
    'co-oximetry with COHb measurement when carbon monoxide poisoning is suspected',
    'serial oxygenation/ventilation trend monitoring'
  ],
  array[
    'do not rely on standard ABG analyzer alone to diagnose CO poisoning',
    'confirm carbon monoxide burden with co-oximeter COHb measurement'
  ],
  array[
    'delaying airway-focused intervention in progressive smoke inhalation injury',
    'assuming normal ABG analysis excludes carbon monoxide poisoning'
  ],
  array[
    'prioritize airway-risk management in smoke inhalation injury',
    'obtain COHb by co-oximeter when CO poisoning is suspected',
    'recommend hyperbaric oxygen therapy for carbon monoxide poisoning when available'
  ],
  array[
    'continuous reassessment for worsening obstruction risk and gas-exchange decline'
  ],
  array[
    'deferring COHb confirmation to standard ABG analyzer only',
    'ignoring cherry red clue in smoke-exposure scenario'
  ],
  '[]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb,
  array[
    'ICU or burn-center level monitoring for unstable inhalation injury',
    'maintain escalation readiness due to airway-obstruction progression risk'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Captured lesson set: burns and smoke inhalation focus for RT/CSE. Key IG cues saved: black sooty secretions and tachypnea. Exam hints saved: cherry red appearance suggests carbon monoxide poisoning; use co-oximeter COHb (not standard ABG analyzer) and recommend hyperbaric oxygen therapy when available.',
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
