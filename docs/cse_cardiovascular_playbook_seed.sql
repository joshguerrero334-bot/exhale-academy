-- Exhale Academy CSE cardiovascular disorders playbook seed
-- Captures high-yield CSE anchors for CHF/pulmonary edema, MI, shock, cor pulmonale, and PE.

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
  'adult-cardiovascular-disorders',
  'Adult Cardiovascular Disorders',
  'critical',
  'Cardiovascular CSE cases require fast recognition of CHF/cardiogenic pulmonary edema, MI/unstable angina risk, shock physiology, cor pulmonale, and sudden pulmonary embolism patterns.',
  array[
    'pink frothy secretions',
    'orthopnea',
    'sudden dyspnea with chest pain and tachycardia',
    'hemoptysis with abrupt respiratory compromise',
    'hypotension with poor perfusion signs',
    'arrhythmia instability'
  ],
  array[
    'ED cardiovascular resuscitation bay',
    'ICU hemodynamic monitoring pathway',
    'postoperative sudden-deterioration response'
  ],
  array[
    'Fluid-overloaded patient with pulmonary edema pattern and severe dyspnea',
    'Acute chest-pain patient with ischemic risk and arrhythmia concern',
    'Post-op patient with sudden dyspnea, hemoptysis, chest pain, and tachycardia'
  ],
  array[
    'Exam anchor: CHF and cardiogenic pulmonary edema go hand in hand; when pulmonary edema is present, think CHF/fluid overload',
    'Orthopnea is labored breathing while lying flat and should strongly suggest CHF/pulmonary edema',
    'Cardiogenic pulmonary edema is CHF-related; noncardiogenic pulmonary edema aligns with ARDS',
    'CHF causes include MI, CAD, ischemic heart disease, hypertension, and cardiomyopathy',
    'Unstable angina is dangerous and suggests impending failure; in CSE context, angina should trigger MI thinking when supported by other findings',
    'PE exam trigger: postoperative sudden dyspnea + hemoptysis + chest pain + tachycardia'
  ],
  array[
    'respiratory distress severity and orthopnea',
    'signs of fluid overload (JVD, edema, diaphoresis)',
    'cyanosis/anxiety/perfusion status',
    'sudden-onset pattern recognition for PE'
  ],
  array[
    'breath sounds (crackles/rhonchi/pleural rub context)',
    'blood pressure, heart rate, SpO2, and capillary perfusion',
    'hemodynamic trend for shock or right-heart strain',
    'continuous rhythm surveillance'
  ],
  array[
    'ABG for oxygenation/ventilation and acid-base trend',
    'serum electrolytes and cardiac biomarkers',
    'BNP for CHF context',
    'd-dimer for PE workup context'
  ],
  array[
    '12-lead EKG',
    'echocardiography',
    'CT/VQ/pulmonary angiography for PE confirmation',
    'chest x-ray pattern review (batwing/fluffy/Kerley B in CHF context)'
  ],
  array[
    'delaying urgent oxygenation/hemodynamic stabilization for nonurgent tests',
    'ignoring orthopnea/fluid-overload clues in pulmonary edema pattern',
    'missing sudden postoperative PE pattern',
    'defibrillating rhythms other than VFib or pulseless VT'
  ],
  array[
    'provide oxygen for hypoxemia and continuous monitoring',
    'CHF/cardiogenic edema: fluid restriction, diuretics, upright positioning, afterload/preload strategy, and NPPV when indicated',
    'MI pathway: MONA framework (Morphine, Oxygen, Nitroglycerin, Aspirin) with EKG/biomarker-guided escalation',
    'shock pathway: restore perfusion with fluids/vasopressors based on cause and ventilatory support as needed',
    'PE pathway: anticoagulation/thrombolytic strategy as indicated plus urgent diagnostic confirmation',
    'defibrillate only VFib and pulseless VT; use synchronized cardioversion for selected unstable perfusing tachyarrhythmias'
  ],
  array[
    'for PE prevention context, recommend early ambulation and anti-embolism strategies when appropriate',
    'for MI/CHF recovery planning, include cardiac rehab and smoking-cessation planning'
  ],
  array[
    'low-acuity disposition while unstable',
    'observe-only approach in acute PE/MI/shock patterns',
    'delaying D-dimer and pulmonary angiography in classic sudden postoperative PE scenario',
    'ignoring hemodynamic collapse signals'
  ],
  '[
    {"pattern":"chf_cardiogenic_edema","findings":"respiratory alkalosis with hypoxemia may appear early","action":"treat fluid-overload/cardiogenic pathway and escalate support as needed"},
    {"pattern":"mi_hypoxemia","findings":"hypoxemia with ischemic presentation","action":"initiate MI-focused oxygenation and reperfusion-support strategy"},
    {"pattern":"pe_pattern","findings":"respiratory alkalosis with hypoxemia in sudden PE context","action":"escalate PE diagnostic and treatment pathway"}
  ]'::jsonb,
  '[
    {"pattern":"chf_edema_hypoxemia","findings":"cardiogenic pulmonary edema with severe dyspnea","action":"high FiO2 and NPPV/intubation pathway based on response"},
    {"pattern":"pe_deadspace_context","findings":"ventilation-perfusion mismatch with rising deadspace concern","action":"treat as urgent PE physiology and restore perfusion strategy"}
  ]'::jsonb,
  '[
    {"pattern":"nppv_in_cardiogenic_edema","findings":"CHF/cardiogenic edema with persistent distress","action":"use CPAP/BiPAP to improve gas exchange and reduce preload"},
    {"pattern":"intubation_escalation","findings":"severe respiratory acidosis or failure despite noninvasive support","action":"intubate and use mechanical ventilation with PEEP"}
  ]'::jsonb,
  array[
    'maintain ICU-level monitoring for unstable cardiovascular respiratory presentations',
    'disposition requires sustained hemodynamic and oxygenation stability with explicit follow-up plan'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Cardiovascular lesson anchors captured: CHF <-> cardiogenic pulmonary edema linkage with fluid overload and orthopnea cue; CHF cause list (MI, CAD, ischemic heart disease, hypertension, cardiomyopathy); cardiogenic vs noncardiogenic edema distinction; unstable angina as impending-failure signal and MI trigger context; MONA reminder for MI; and postoperative sudden dyspnea + hemoptysis + chest pain + tachycardia pattern as PE trigger with mandatory D-dimer and pulmonary angiography recommendation.',
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
