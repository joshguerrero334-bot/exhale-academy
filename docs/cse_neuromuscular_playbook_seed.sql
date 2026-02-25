-- Exhale Academy CSE neuromuscular disorders playbook seed
-- Captures cross-cutting guidance for MG vs GBS and ventilatory-failure surveillance.

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
  'adult-neuromuscular-disorders',
  'Adult Neuromuscular and Neuro-Respiratory Disorders',
  'critical',
  'Neuro-respiratory cases in this lesson set require early ventilatory-failure detection, rapid airway-risk recognition, and accurate syndrome differentiation, especially Myasthenia Gravis versus Guillain-Barre patterns.',
  array[
    'altered level of consciousness with hypoventilation',
    'slow and shallow respirations with aspiration risk',
    'shallow breathing with progressive weakness',
    'post-viral ascending paralysis pattern',
    'descending weakness with ptosis and bulbar symptoms',
    'loss of gag reflex or severe dysphagia',
    'wound history with lockjaw concern',
    'cheyne-stokes respiratory pattern with neurologic deficits',
    'dysphagia or weak cough with secretion burden',
    'declining spontaneous tidal volume (VT)',
    'declining vital capacity (VC)',
    'declining maximum inspiratory pressure (MIP)'
  ],
  array[
    'ED resuscitation bay',
    'stroke pathway activation unit',
    'toxicology/overdose stabilization bay',
    'ICU consult for neuromuscular respiratory decline',
    'rapid response for progressive ventilatory pump failure'
  ],
  array[
    'Adult with progressive weakness and worsening ventilatory effort requiring VT/VC/MIP trend surveillance',
    'Pattern suggests Myasthenia Gravis crisis (descending weakness)',
    'Pattern suggests Guillain-Barre progression (ascending weakness)',
    'Obtunded overdose patient with slow shallow respirations and aspiration risk',
    'Stroke patient with decreased LOC, motor/speech deficits, and abnormal respiratory pattern',
    'Tetanus concern after puncture wound with lockjaw and bulbar involvement',
    'Muscular dystrophy patient with chronic progression and sleep-related hypoventilation risk'
  ],
  array[
    'Exam-critical differentiation: Myasthenia Gravis is descending (mind to ground), Guillain-Barre is ascending (ground to brain)',
    'Any disorder in this section should trigger close ventilatory-failure surveillance with VT, VC, and MIP trending',
    'Drug overdose workflow is airway first with ventilatory support when indicated',
    'Stroke workflow emphasizes neurologic imaging and intracranial pressure-aware respiratory support',
    'Tetanus diagnosis is primarily clinical from history and exam context'
  ],
  array[
    'distribution of weakness (descending vs ascending)',
    'bulbar signs (ptosis, dysphagia, gag/cough effectiveness)',
    'fatigue pattern and work of breathing',
    'altered mental status/obtundation',
    'lockjaw and wound-exposure context',
    'speech and motor deficits with abnormal respiratory rhythm'
  ],
  array[
    'spontaneous tidal volume (VT) trend',
    'vital capacity (VC) trend',
    'maximum inspiratory pressure (MIP) trend',
    'mental-status and airway-protection trajectory',
    'breath sounds and secretion burden trend',
    'aspiration risk and gag reflex status',
    'hemodynamic trend during respiratory decline'
  ],
  array[
    'ABG to monitor ventilatory decompensation and oxygenation',
    'targeted labs/workup based on likely etiology',
    'toxicology screen, electrolytes, co-oximetry, and EKG in overdose context',
    'baseline and serial respiratory function trend in chronic neuromuscular disease'
  ],
  array[
    'MG-focused: Endrophonium (Tensilon) challenge with response monitoring',
    'MG-focused: antibody testing',
    'GBS-focused: lumbar puncture for CSF support when clinically indicated',
    'stroke-focused: CT, MRI, and cerebral angiogram',
    'muscular-dystrophy-focused: polysomnography and serial PFT comparison',
    'tetanus-focused: clinical diagnosis support (serum antitoxin > 0.01 U/mL may help rule out)'
  ],
  array[
    'deferring VT/VC/MIP measurement in progressive weakness',
    'failing to differentiate MG from GBS pattern when clues are present',
    'delaying airway control in obtunded overdose with aspiration risk',
    'assuming CPAP is adequate for sleep hypoventilation in muscular dystrophy',
    'delaying ventilatory support despite progressive pump failure'
  ],
  array[
    'trend VT, VC, and MIP serially to detect ventilatory failure early',
    'provide oxygen for hypoxemia',
    'escalate to intubation and mechanical ventilation when objective decline or airway risk progresses',
    'tailor disease-specific therapy after respiratory stabilization',
    'Myasthenia Gravis: anticholinesterase therapy (neostigmine/pyridostigmine), consider plasmapheresis or thymectomy',
    'Guillain-Barre: consider plasmapheresis in severe cases',
    'drug overdose: secure airway first, Narcan for narcotic overdose, acetylcysteine for acetaminophen overdose',
    'drug overdose oral ingestion: consider gastric lavage or activated charcoal when appropriate',
    'muscular dystrophy: airway-clearance therapy and nighttime BiPAP for sleep hypoventilation',
    'stroke: ventilatory support for respiratory failure or ICP-control goals',
    'tetanus: tetanus immunoglobulin plus antibiotic therapy'
  ],
  array[
    'structured secretion-clearance strategy with frequent reassessment',
    'high-acuity monitoring when respiratory muscle metrics are worsening',
    'MG Tensilon nonresponse/worsening can be reversed with atropine',
    'longitudinal respiratory monitoring plan in chronic progressive disorders'
  ],
  array[
    'oxygen-only strategy while objective ventilatory metrics worsen',
    'delayed escalation despite declining VT/VC/MIP',
    'premature low-acuity disposition in unresolved pump failure risk',
    'ignoring aspiration risk and airway protection failure in overdose or bulbar weakness',
    'using CPAP instead of BiPAP for hypoventilation-dominant muscular dystrophy',
    'waiting for confirmatory testing before stabilizing airway/ventilation in high-risk patients'
  ],
  '[
    {"pattern":"mg_or_gbs_early","findings":"acute alveolar hyperventilation with hypoxemia may occur early","action":"close serial reassessment for progression to ventilatory failure"},
    {"pattern":"neuromuscular_failure_progression","findings":"rising PaCO2 and worsening ventilation with declining VT/VC/MIP","action":"recommend invasive ventilatory support"},
    {"pattern":"overdose_hypoventilation","findings":"hypoventilation pattern with altered consciousness","action":"secure airway and support ventilation promptly"}
  ]'::jsonb,
  '[]'::jsonb,
  '[
    {"pattern":"metric_driven_escalation","findings":"declining VT/VC/MIP with worsening clinical effort","action":"prepare and escalate ventilatory support promptly"},
    {"pattern":"overdose_airway_risk","findings":"obtunded patient with aspiration risk and shallow respirations","action":"intubate and initiate mechanical ventilation when indicated"},
    {"pattern":"muscular_dystrophy_sleep_hypoventilation","findings":"sleep-disordered breathing with hypoventilation","action":"use nighttime BiPAP and avoid CPAP-only strategy"},
    {"pattern":"stroke_neuro_respiratory_decline","findings":"neurologic decline with respiratory compromise or elevated ICP concern","action":"support ventilation and coordinate neurocritical management"}
  ]'::jsonb,
  array[
    'ICU-level monitoring when ventilatory-failure risk is present',
    'define explicit escalation thresholds using VT/VC/MIP trend plus bedside deterioration',
    'maintain high-acuity disposition for unresolved airway-risk, ventilatory-failure, or neurocritical features'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Lesson capture expanded: (1) MG IG/DM including descending weakness, ptosis, dysphagia, VT/VC/MIP decline, Tensilon plus atropine reversal logic, antibody testing, anticholinesterase pathway, and escalation to ventilation; (2) GBS IG/DM including ascending weakness, post-viral context, gag-loss risk, lumbar puncture, plasmapheresis in severe cases, and ventilatory escalation; (3) drug overdose IG/DM including altered LOC, shallow respirations, ABG/tox/electrolytes/co-oximetry/EKG, airway-first strategy, Narcan, acetylcysteine, and oral-ingestion decontamination options; (4) muscular dystrophy IG/DM including baseline PFT trend, polysomnography, airway clearance with MIE, nighttime BiPAP and CPAP avoidance for hypoventilation pattern; (5) stroke IG/DM including CT/MRI/angiogram, elevated ICP monitoring, and ventilatory support indications; (6) tetanus IG/DM including wound history, lockjaw, clinical diagnosis focus, immunoglobulin plus antibiotics, and VT/VC/MIP-guided escalation.',
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
