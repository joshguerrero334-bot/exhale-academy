-- Exhale Academy CSE Branching Seed (Cases 48-56)
-- Other adult medical conditions: sleep disorders, hypothermia, pneumonia, AIDS,
-- renal failure/diabetes, thoracic surgery, head trauma, spinal injury.
-- Requires docs/cse_branching_engine_migration.sql,
-- docs/cse_case_taxonomy_migration.sql, and docs/cse_outcomes_vitals_migration.sql

begin;

create temporary table _om_seed (
  case_number int4 primary key,
  disease_key text not null,
  source text not null,
  disease_slug text not null,
  slug text not null,
  title text not null,
  intro_text text not null,
  description text not null,
  stem text not null,
  baseline_vitals jsonb not null,
  nbrc_category_code text not null,
  nbrc_category_name text not null,
  nbrc_subcategory text
) on commit drop;

insert into _om_seed (
  case_number, disease_key, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(48, 'sleep', 'adult-med-surg-critical', 'sleep-disorders', 'adult-medical-critical-sleep-apnea-polysomnography-pathway',
 'Adult Medical Critical (Sleep Apnea Polysomnography Pathway)',
 'Sleep-disordered breathing case requiring central vs obstructive differentiation and targeted noninvasive support.',
 'Adult sleep-disorder case focused on sleep study logic, AHI severity, and modality selection.',
 'Patient with obesity, loud snoring, morning headaches, and daytime fatigue has recurrent nocturnal apnea episodes.',
 '{"hr":102,"rr":22,"spo2":88,"bp_sys":152,"bp_dia":94,"etco2":48}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(49, 'hypothermia', 'adult-med-surg-critical', 'hypothermia', 'adult-medical-critical-hypothermia-rewarming-resuscitation',
 'Adult Medical Critical (Hypothermia Rewarming/Resuscitation)',
 'Severe hypothermia with cardiorespiratory depression requiring immediate stabilization and rewarming.',
 'Hypothermia case focused on ABG interpretation caveats and airway/rewarming priorities.',
 'Cold-exposure patient presents profoundly cold, confused, cyanotic, bradycardic, and bradypneic.',
 '{"hr":42,"rr":8,"spo2":79,"bp_sys":84,"bp_dia":46,"etco2":56}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(50, 'pneumonia', 'adult-med-surg-critical', 'pneumonia', 'adult-medical-critical-pneumonia-consolidation-hypoxemia',
 'Adult Medical Critical (Pneumonia Consolidation Hypoxemia)',
 'Lower-respiratory infection with consolidation, hypoxemia, and potential ventilatory decline.',
 'Pneumonia case focused on diagnostic confirmation, infection treatment, and escalation timing.',
 'Patient presents with productive cough, fever, dyspnea, crackles, and CXR consolidation pattern.',
 '{"hr":124,"rr":34,"spo2":84,"bp_sys":148,"bp_dia":88,"etco2":36}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Infectious disease'),
(51, 'aids', 'adult-med-surg-critical', 'aids', 'adult-medical-critical-aids-opportunistic-pcp-pathway',
 'Adult Medical Critical (AIDS Opportunistic PCP Pathway)',
 'Immunocompromised respiratory case with opportunistic infection concern and targeted testing needs.',
 'AIDS case focused on ELISA testing, opportunistic pulmonary infection management, and precautions.',
 'Patient with weight loss, recurrent fever, and progressive respiratory symptoms has AIDS workup concerns.',
 '{"hr":118,"rr":30,"spo2":86,"bp_sys":136,"bp_dia":82,"etco2":40}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Infectious disease'),
(52, 'renal_diabetes', 'adult-med-surg-critical', 'renal-failure-diabetes', 'adult-medical-critical-renal-diabetes-kussmaul-acidosis',
 'Adult Medical Critical (Renal/Diabetes Kussmaul Acidosis)',
 'Metabolic crisis pattern with Kussmaul breathing and risk of ventilatory fatigue.',
 'Renal/diabetes case focused on acid-base interpretation, glucose/electrolyte monitoring, and fluid strategy.',
 'Patient is lethargic with Kussmaul respirations, low urine output, and metabolic derangement concern.',
 '{"hr":116,"rr":32,"spo2":89,"bp_sys":144,"bp_dia":86,"etco2":30}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(53, 'thoracic_surgery', 'adult-med-surg-critical', 'thoracic-surgery', 'adult-medical-critical-thoracic-surgery-postop-complications',
 'Adult Medical Critical (Thoracic Surgery Post-Op Complications)',
 'Post-thoracic surgery respiratory decline with chest-tube and complication surveillance needs.',
 'Thoracic-surgery case focused on atelectasis prevention, complication recognition, and reintubation decisions.',
 'Post-op thoracic patient deteriorates after extubation with rising ventilatory risk and possible complications.',
 '{"hr":126,"rr":30,"spo2":85,"bp_sys":134,"bp_dia":78,"etco2":49}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(54, 'head_trauma', 'adult-neurocritical', 'head-trauma', 'adult-neuro-critical-head-trauma-cheyne-stokes-icp',
 'Adult Neuro Critical (Head Trauma Cheyne-Stokes/ICP)',
 'Traumatic brain injury pattern with altered consciousness, abnormal respirations, and ICP risk.',
 'Head-trauma case focused on GCS threshold actions, capnography, and ICP-protective ventilation strategy.',
 'Trauma patient has Cheyne-Stokes breathing, abnormal pupils, and worsening level of consciousness.',
 '{"hr":112,"rr":28,"spo2":86,"bp_sys":170,"bp_dia":102,"etco2":50}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(55, 'spinal_injury', 'adult-neurocritical', 'spinal-injury', 'adult-neuro-critical-spinal-injury-airway-stability',
 'Adult Neuro Critical (Spinal Injury Airway Stability)',
 'Cervical/spinal trauma with airway-risk and strict immobilization requirements.',
 'Spinal-injury case focused on stabilization-first airway management and ventilatory support decisions.',
 'Motor-vehicle trauma patient has potential cervical injury with evolving respiratory compromise.',
 '{"hr":108,"rr":24,"spo2":87,"bp_sys":122,"bp_dia":74,"etco2":45}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(56, 'sleep_obstructive', 'adult-med-surg-critical', 'sleep-disorders', 'adult-medical-critical-obstructive-sleep-apnea-interface-optimization',
 'Adult Medical Critical (Obstructive Sleep Apnea Interface Optimization)',
 'Obstructive sleep apnea management case with CPAP adherence/interface optimization decisions.',
 'OSA-focused case for practical DM sequencing and escalation safety.',
 'Patient with severe OSA has persistent nocturnal events despite poor mask tolerance.',
 '{"hr":98,"rr":20,"spo2":90,"bp_sys":148,"bp_dia":90,"etco2":46}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other');

create temporary table _om_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _om_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _om_seed s
  join public.cse_cases c on c.slug = s.slug
),
updated as (
  update public.cse_cases c
  set
    source = s.source,
    disease_slug = s.disease_slug,
    disease_track = 'critical',
    case_number = coalesce(c.case_number, s.case_number),
    slug = s.slug,
    title = s.title,
    intro_text = s.intro_text,
    description = s.description,
    stem = s.stem,
    difficulty = 'hard',
    is_active = true,
    is_published = true,
    baseline_vitals = s.baseline_vitals,
    nbrc_category_code = s.nbrc_category_code,
    nbrc_category_name = s.nbrc_category_name,
    nbrc_subcategory = s.nbrc_subcategory
  from _om_seed s
  where c.id in (select id from existing where case_number = s.case_number)
  returning s.case_number, c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty,
    is_active, is_published, baseline_vitals, nbrc_category_code, nbrc_category_name, nbrc_subcategory
  )
  select
    s.source, s.disease_slug, 'critical', s.case_number, s.slug, s.title, s.intro_text, s.description, s.stem, 'hard',
    true, true, s.baseline_vitals, s.nbrc_category_code, s.nbrc_category_name, s.nbrc_subcategory
  from _om_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _om_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _om_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _om_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _om_target)
);

delete from public.cse_attempts where case_id in (select case_id from _om_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _om_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _om_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _om_target));
delete from public.cse_steps where case_id in (select case_id from _om_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'sleep' then 'You are called to evaluate a 49-year-old male with recurrent witnessed apneas, daytime hypersomnolence, and nocturnal desaturation events. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'sleep_obstructive' then 'You are called to evaluate a 56-year-old female with loud snoring, morning headaches, and daytime fatigue with suspected nocturnal hypoventilation. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'hypothermia' then 'You are called to bedside for a 61-year-old male found after prolonged cold exposure with depressed respirations and altered mental status. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'pneumonia' then 'You are called to bedside for a 73-year-old female with fever, productive cough, pleuritic pain, and increasing dyspnea. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'aids' then 'You are called to bedside for a 41-year-old male with immunocompromised status, progressive dyspnea, fever, and hypoxemia. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'renal_diabetes' then 'You are called to bedside for a 38-year-old female with deep labored breathing, dehydration signs, and altered mentation. Focused metabolic assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'thoracic_surgery' then 'You are called to bedside for a 67-year-old male after thoracic surgery with rising dyspnea and concern for postoperative chest complications. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'head_trauma' then 'You are called to bedside for a 32-year-old female with recent head trauma, declining mental status, and abnormal breathing pattern. Focused neuro-respiratory assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      else 'You are called to bedside for a 45-year-old male with spinal trauma and progressive weakness with worsening ventilatory effort. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
    end,
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _om_target t
  join _om_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is the best FIRST treatment strategy now?',
    null, 'STOP', '{}'::jsonb
  from _om_target t
  union all
  select t.case_id, 3, 3, 'IG',
    'Fifteen minutes after initial treatment, SELECT AS MANY AS INDICATED (MAX 8). What reassessment data should drive escalation NEXT?',
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _om_target t
  union all
  select t.case_id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the safest NEXT ongoing management/disposition plan?',
    null, 'STOP', '{}'::jsonb
  from _om_target t
  returning case_id, step_order, id
)
insert into _om_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _om_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Assess immediate airway, breathing, perfusion, and mental-status risk', 3, 'Critical first priority.' from _om_steps st where st.step_order = 1
union all
select st.step_id, 'B',
  case s.disease_key
    when 'sleep' then 'Collect sleep-disorder history and order polysomnography with central-vs-obstructive differentiation'
    when 'sleep_obstructive' then 'Assess OSA severity and interface tolerance barriers with AHI-based risk context'
    when 'hypothermia' then 'Confirm core temperature and evaluate severe cold-exposure cardiorespiratory depression'
    when 'pneumonia' then 'Assess consolidation clues: cough/sputum, crackles, dull percussion, fever, and expansion/fremitus pattern'
    when 'aids' then 'Assess immunocompromised infection pattern and order ELISA-focused workup'
    when 'renal_diabetes' then 'Recognize Kussmaul pattern and assess metabolic/renal derangement context'
    when 'thoracic_surgery' then 'Assess post-op chest-tube status and common thoracic complication signs'
    when 'head_trauma' then 'Assess GCS, pupillary response, and cheyne-stokes pattern with neuro decline risk'
    else 'Assess spinal stability, neurologic deficits, and apnea/airway compromise risk'
  end,
  3,
  'Syndrome-defining findings.'
from _om_steps st join _om_seed s on s.case_number = st.case_number
where st.step_order = 1
union all select st.step_id, 'C', 'Obtain ABG and targeted labs/imaging for syndrome confirmation', 2, 'Objective diagnostic guidance.' from _om_steps st where st.step_order = 1
union all select st.step_id, 'D', 'Trend cardiorespiratory severity and identify escalation thresholds early', 2, 'Protects against delayed escalation.' from _om_steps st where st.step_order = 1
union all select st.step_id, 'E', 'Delay treatment while waiting for complete nonurgent testing', -3, 'Unsafe delay.' from _om_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Ignore mental-status decline if oxygen saturation briefly improves', -2, 'Can miss impending failure.' from _om_steps st where st.step_order = 1
union all select st.step_id, 'G', 'Use one-size-fits-all treatment without disease differentiation', -2, 'Incorrect reasoning.' from _om_steps st where st.step_order = 1
union all select st.step_id, 'H', 'Stop monitoring after first modest response', -3, 'Unsafe de-escalation.' from _om_steps st where st.step_order = 1;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case s.disease_key
    when 'sleep' then 'Use sleep-study-guided therapy: NPPV for central apnea, CPAP for obstructive apnea, plus oxygen if hypoxemic'
    when 'sleep_obstructive' then 'Optimize CPAP and interface adherence, posture/weight strategy, and oxygen if hypoxemic'
    when 'hypothermia' then 'Initiate active rewarming strategy, warm oxygen/fluids, and CPR/intubation when indicated'
    when 'pneumonia' then 'Provide oxygen, infection-directed treatment, pulmonary hygiene/hyperinflation, and escalate ventilation if failing'
    when 'aids' then 'Use ELISA-informed AIDS pathway and opportunistic pulmonary infection treatment/precautions'
    when 'renal_diabetes' then 'Correct metabolic driver while monitoring glucose/electrolytes/fluids and ventilatory fatigue'
    when 'thoracic_surgery' then 'Apply postop pulmonary hygiene, complication surveillance, and reintubate if post-extubation decline occurs'
    when 'head_trauma' then 'Provide 100% oxygen, intubate if GCS <= 8, and manage ICP-focused ventilation strategy'
    else 'Maintain spinal stabilization, secure airway with modified jaw-thrust/fiberoptic approach, and oxygenate appropriately'
  end,
  3,
  'Best immediate disease-specific strategy.'
from _om_steps st join _om_seed s on s.case_number = st.case_number
where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen alone and defer targeted management', -3, 'Incomplete and unsafe.' from _om_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Delay intubation decisions until severe collapse occurs', -3, 'High-risk delay.' from _om_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Transfer to lower-acuity care before stability is established', -3, 'Unsafe disposition.' from _om_steps st where st.step_order = 2
union all select st.step_id, 'E', 'Provide immediate oxygen and close cardiorespiratory monitoring while preparing definitive syndrome-specific therapy', 1, 'Reasonable bridge action, but incomplete if definitive treatment is delayed.' from _om_steps st where st.step_order = 2;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Repeat ABG (pH/PaCO2/PaO2/HCO3) and ventilation/oxygenation response; if intubated, document mode/VT/RR/FiO2/PEEP and adjust RR/VT/FiO2/PEEP', 2, 'Core reassessment.' from _om_steps st where st.step_order = 3
union all
select st.step_id, 'B',
  case s.disease_key
    when 'sleep' then 'Confirm sleep-disorder subtype response and pressure/interface efficacy'
    when 'sleep_obstructive' then 'Track residual events and tolerance after CPAP/interface adjustments'
    when 'hypothermia' then 'Track rewarming progress and corrected gas interpretation with hemodynamic trend'
    when 'pneumonia' then 'Track infection response, secretion burden, and pleural-effusion status'
    when 'aids' then 'Track opportunistic infection response and respiratory progression with precautions'
    when 'renal_diabetes' then 'Track acid-base correction, urine output, and fluid/electrolyte stability'
    when 'thoracic_surgery' then 'Track chest tube/drainage and postoperative complication markers'
    when 'head_trauma' then 'Track GCS/ICP/capnography and avoid hypercapnia-driven ICP worsening'
    else 'Track neurologic stability and respiratory muscle function after acute stabilization'
  end,
  3,
  'Targeted reassessment by syndrome.'
from _om_steps st join _om_seed s on s.case_number = st.case_number
where st.step_order = 3
union all select st.step_id, 'C', 'Maintain escalation readiness for invasive ventilation if objective decline appears', 2, 'Safe escalation posture.' from _om_steps st where st.step_order = 3
union all select st.step_id, 'D', 'Stop close monitoring after one slight improvement', -3, 'Unsafe de-escalation.' from _om_steps st where st.step_order = 3
union all select st.step_id, 'E', 'Delay reassessment for several hours', -3, 'High-risk delay.' from _om_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Ignore capnography/neurologic trend changes in neurotrauma', -2, 'Misses critical deterioration.' from _om_steps st where st.step_order = 3
union all select st.step_id, 'G', 'Ignore fluid and perfusion endpoints in metabolic/renal patterns', -2, 'Inadequate stabilization.' from _om_steps st where st.step_order = 3
union all select st.step_id, 'H', 'Assume diagnosis confirmation alone guarantees stability', -2, 'Management mismatch.' from _om_steps st where st.step_order = 3;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Continue ICU/high-acuity care with structured reassessment and escalation triggers', 3, 'Safest disposition.' from _om_steps st where st.step_order = 4
union all select st.step_id, 'B', 'Transfer to low-acuity care immediately', -3, 'Unsafe premature transfer.' from _om_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discharge after transient stabilization', -3, 'Unsafe disposition.' from _om_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Observe without explicit escalation thresholds', -2, 'Inadequate plan.' from _om_steps st where st.step_order = 4
union all select st.step_id, 'E', 'Continue monitored high-acuity care with explicit escalation triggers before transfer decisions', 1, 'Reasonable pathway but less protective than full ICU/high-acuity continuity plan.' from _om_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s2.step_id,
  'Initial assessment captured critical syndrome features and supported safe early management.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _om_steps s1 join _om_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Missed priorities increase risk of rapid deterioration.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -3, "bp_dia": -2, "etco2": 3}'::jsonb
from _om_steps s1 join _om_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  'Immediate treatment aligns with disease-specific critical-care priorities.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": 1, "bp_dia": 1, "etco2": -2}'::jsonb
from _om_steps s2 join _om_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Suboptimal treatment leaves avoidable instability risk.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": -4, "bp_dia": -3, "etco2": 4}'::jsonb
from _om_steps s2 join _om_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  'Reassessment is complete and supports safe ongoing management.',
  '{"spo2": 2, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _om_steps s3 join _om_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Monitoring gaps increase risk of recurrent decline.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": -2, "bp_dia": -1, "etco2": 2}'::jsonb
from _om_steps s3 join _om_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable with appropriate high-acuity management.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _om_steps s4
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: unsafe de-escalation leads to recurrent instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _om_steps s4
where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE' || t.case_number::text || '_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
  r.rule_priority,
  r.rule_type,
  r.rule_value,
  r.next_step_id,
  r.outcome_text,
  jsonb_build_object(
    'hr', coalesce((b.baseline_vitals->>'hr')::int, 0) + coalesce((r.vitals_delta->>'hr')::int, 0),
    'rr', coalesce((b.baseline_vitals->>'rr')::int, 0) + coalesce((r.vitals_delta->>'rr')::int, 0),
    'spo2', coalesce((b.baseline_vitals->>'spo2')::int, 0) + coalesce((r.vitals_delta->>'spo2')::int, 0),
    'bp_sys', coalesce((b.baseline_vitals->>'bp_sys')::int, 0) + coalesce((r.vitals_delta->>'bp_sys')::int, 0),
    'bp_dia', coalesce((b.baseline_vitals->>'bp_dia')::int, 0) + coalesce((r.vitals_delta->>'bp_dia')::int, 0),
    'etco2', coalesce((b.baseline_vitals->>'etco2')::int, 0) + coalesce((r.vitals_delta->>'etco2')::int, 0)
  )
from public.cse_rules r
join public.cse_steps s on s.id = r.step_id
join public.cse_cases b on b.id = s.case_id
join _om_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _om_target);

commit;
