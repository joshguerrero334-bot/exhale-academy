-- Exhale Academy CSE trauma playbook seed
-- Stores chest trauma critical-track guidance captured from lesson notes.

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
  'chest-trauma',
  'Chest Trauma (Flail Chest, Pneumothorax, Hemothorax)',
  'critical',
  'Critical chest trauma cases focus on rapid recognition of pneumothorax and hemothorax patterns, immediate stabilization decisions, and escalation timing when ventilatory failure or instability appears.',
  array[
    'sudden respiratory distress',
    'severe chest pain',
    'paradoxical chest movement (flail chest)',
    'tracheal or mediastinal shift away from affected side',
    'absent/diminished unilateral breath sounds',
    'signs of tension pneumothorax with instability',
    'worsening hypoxemia',
    'possible blood-loss physiology'
  ],
  array['ED trauma bay', 'resuscitation room', 'ICU handoff after tube thoracostomy'],
  array[
    'Blunt or penetrating chest trauma patient in acute distress',
    'Patient with likely unilateral pleural process (air or blood) and worsening gas exchange',
    'Ventilated patient with sudden pressure/volume alarm changes suggesting new pneumothorax'
  ],
  array[
    'Trauma mechanism may include penetrating injury (knife or gunshot wound) or severe blunt injury',
    'Flail chest is classically >= 3 adjacent rib fractures with paradoxical movement',
    'Pneumothorax can be traumatic or spontaneous',
    'Hemothorax is blood accumulation in pleural space from chest injury',
    'Pulmonary contusion patients require close reassessment due to hypoxemia/ARDS risk'
  ],
  array[
    'bruising over injured side',
    'increased work of breathing',
    'paradoxical chest movement',
    'decreased chest expansion on affected side',
    'possible cyanosis',
    'tracheal/mediastinal shift away from affected side'
  ],
  array[
    'tachypnea',
    'heart-rate and blood-pressure trend by severity',
    'chest percussion: hyperresonant (pneumothorax) vs dull/flat (hemothorax)',
    'breath sounds diminished or absent on affected side',
    'tactile/vocal fremitus decrease on affected side',
    'hemoptysis when present',
    'if ventilated: sudden increase in airway pressure or fall in tidal volume can indicate pneumothorax'
  ],
  array[
    'ABG to classify severity and failure pattern',
    'CBC including RBC/Hb/Hct when blood loss is possible',
    'monitor for worsening hypoxemia and ARDS risk in pulmonary contusion'
  ],
  array[
    'chest x-ray is generally recommended in chest trauma',
    'if clear tension pneumothorax signs with instability are present, treat immediately before chest x-ray',
    'PFT may show reduced volumes/capacities but is not a first-line acute priority'
  ],
  array[
    'delay emergency decompression in unstable tension pneumothorax while waiting for imaging',
    'observe-only while unilateral breath sounds are absent and instability is progressing',
    'nonurgent testing before stabilization'
  ],
  array[
    'give 100% oxygen for hypoxemia',
    'tension pneumothorax with instability: immediate needle decompression or emergent thoracostomy/chest tube, then chest x-ray',
    'pneumothorax treatment: chest tube thoracostomy',
    'hemothorax treatment: thoracentesis or chest tube to drain blood',
    'for ventilatory failure/apnea/profound shock/compromised airway: mechanical ventilation with PEEP',
    'if on ventilator and pneumothorax develops: reduce peak pressure strategy (lower PIP/lower tidal volume as indicated)',
    'provide analgesia for pain control',
    'recommend bronchopulmonary hygiene',
    'recommend hyperinflation therapy after chest tube placement to reduce secondary pulmonary complications',
    'severe flail-chest patterns may require surgical stabilization'
  ],
  array[
    'repeat reassessment after intervention to confirm improved oxygenation and hemodynamics',
    'use chest x-ray after immediate lifesaving decompression to confirm tube position/lung status'
  ],
  array[
    'delaying definitive pleural decompression in unstable tension physiology',
    'ignoring unilateral absent breath sounds with matching percussion findings',
    'premature de-escalation despite persistent hypoxemia'
  ],
  '[
    {"pattern":"small_pneumothorax","findings":"acute alveolar hyperventilation with hypoxemia","action":"oxygen and close reassessment with pleural management"},
    {"pattern":"large_pneumothorax","findings":"acute ventilatory failure with hypoxemia","action":"urgent decompression/chest tube and escalation to ventilation if needed"},
    {"pattern":"hemothorax_or_contusion_failure","findings":"progressive hypoxemia with worsening respiratory load","action":"drain pleural blood when indicated and escalate support"}
  ]'::jsonb,
  '[
    {"pattern":"refractory_hypoxemia_trauma","findings":"persistent low oxygenation despite initial support","action":"escalate pleural intervention and ventilatory support"}
  ]'::jsonb,
  '[
    {"pattern":"vented_new_pneumothorax","findings":"sudden rise in airway pressure or drop in tidal volume","action":"treat pneumothorax and adjust pressure strategy"},
    {"pattern":"trauma_ventilatory_failure","findings":"apnea, profound shock, ventilatory failure, or compromised airway","action":"mechanical ventilation with PEEP"}
  ]'::jsonb,
  array[
    'ICU-level monitoring for unstable chest trauma or post-procedural high-risk patients',
    'maintain escalation readiness due to recurrent pneumothorax/hemothorax and ARDS risk'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Captured lesson set: chest trauma, flail chest, pneumothorax, and hemothorax. Exam anchor retained: chest trauma cases commonly test pneumothorax or hemothorax pattern recognition and urgent treatment timing. Chest x-ray is usually recommended except when unstable tension physiology requires immediate decompression first.',
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
