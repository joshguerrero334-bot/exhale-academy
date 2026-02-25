-- Exhale Academy CSE Branching Seed (Cases 31-35)
-- Adult Cardiovascular critical cases: CHF, MI, Shock, Cor Pulmonale, PE
-- Requires docs/cse_branching_engine_migration.sql,
-- docs/cse_case_taxonomy_migration.sql, and docs/cse_outcomes_vitals_migration.sql

begin;

create temporary table _cv_seed (
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

insert into _cv_seed (
  case_number, disease_key, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(31, 'chf', 'adult-cardiovascular-critical', 'chf', 'cardiovascular-critical-chf-cardiogenic-pulmonary-edema',
 'Cardiovascular Critical (CHF Cardiogenic Pulmonary Edema)',
 'Fluid-overload CHF crisis with cardiogenic pulmonary edema and orthopnea.',
 'Critical CHF case focused on cardiogenic edema recognition, preload/afterload strategy, and escalation timing.',
 'Patient has pink frothy secretions, severe dyspnea worse when supine, and classic fluid-overload findings.',
 '{"hr":128,"rr":34,"spo2":80,"bp_sys":172,"bp_dia":102,"etco2":42}'::jsonb,
 'C', 'Adult Cardiovascular', 'Heart failure'),
(32, 'mi', 'adult-cardiovascular-critical', 'myocardial-infarction', 'cardiovascular-critical-myocardial-infarction-ischemic-crisis',
 'Cardiovascular Critical (Myocardial Infarction Ischemic Crisis)',
 'Acute ischemic presentation with chest pain, arrhythmia risk, and hemodynamic instability potential.',
 'Critical MI case focused on ischemia recognition, rhythm management, and urgent treatment sequence.',
 'Patient presents with chest pain, diaphoresis, dyspnea, and EKG findings concerning for acute infarction.',
 '{"hr":122,"rr":30,"spo2":84,"bp_sys":164,"bp_dia":98,"etco2":38}'::jsonb,
 'C', 'Adult Cardiovascular', 'Other'),
(33, 'shock', 'adult-cardiovascular-critical', 'shock', 'cardiovascular-critical-shock-perfusion-failure',
 'Cardiovascular Critical (Shock Perfusion Failure)',
 'Systemic perfusion collapse pattern with hypotension, poor capillary refill, and multiorgan risk.',
 'Critical shock case focused on oxygenation, perfusion restoration, and cause-directed intervention.',
 'Patient has hypotension, tachycardia, cold clammy skin, low urine output, and worsening oxygenation.',
 '{"hr":136,"rr":32,"spo2":82,"bp_sys":82,"bp_dia":48,"etco2":35}'::jsonb,
 'C', 'Adult Cardiovascular', 'Other'),
(34, 'cor_pulm', 'adult-cardiovascular-critical', 'cor-pulmonale', 'cardiovascular-critical-cor-pulmonale-right-heart-strain',
 'Cardiovascular Critical (Cor Pulmonale Right-Heart Strain)',
 'Right-ventricular failure pattern in chronic lung disease with pulmonary hypertension burden.',
 'Critical cor pulmonale case focused on right-heart workload reduction and respiratory support.',
 'COPD-history patient presents with dyspnea, JVD, edema, and signs of right-heart strain.',
 '{"hr":116,"rr":29,"spo2":83,"bp_sys":154,"bp_dia":92,"etco2":45}'::jsonb,
 'C', 'Adult Cardiovascular', 'Other'),
(35, 'pe', 'adult-cardiovascular-critical', 'pulmonary-embolism', 'cardiovascular-critical-pulmonary-embolism-postop-sudden-deadspace',
 'Cardiovascular Critical (Pulmonary Embolism Post-Op Sudden Deadspace)',
 'Postoperative sudden dyspnea/hemoptysis/chest-pain pattern consistent with acute PE.',
 'Critical PE case focused on sudden deadspace physiology recognition and urgent treatment pathway.',
 'Post-op patient develops sudden dyspnea, hemoptysis, chest pain, tachycardia, and oxygenation decline.',
 '{"hr":132,"rr":34,"spo2":79,"bp_sys":94,"bp_dia":58,"etco2":28}'::jsonb,
 'C', 'Adult Cardiovascular', 'Other');

create temporary table _cv_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _cv_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _cv_seed s
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
  from _cv_seed s
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
  from _cv_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _cv_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _cv_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _cv_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _cv_target)
);

delete from public.cse_attempts where case_id in (select case_id from _cv_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _cv_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _cv_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _cv_target));
delete from public.cse_steps where case_id in (select case_id from _cv_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'chf' then 'You are called to bedside for a 69-year-old female who woke suddenly with severe dyspnea, orthopnea, and frothy sputum. Focused exam is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'mi' then 'You are called to bedside for a 58-year-old male with crushing chest discomfort, diaphoresis, and worsening shortness of breath. Focused cardiovascular assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'shock' then 'You are called to bedside for a 46-year-old female with cool clammy skin, altered mentation, and progressive hypotension with tachypnea. Focused perfusion assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'cor_pulm' then 'You are called to bedside for a 64-year-old male with chronic lung disease who now has worsening edema, JVD, and increasing dyspnea. Focused cardiopulmonary assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      else 'You are called to bedside for a 55-year-old female on postoperative day 2 who suddenly develops pleuritic chest pain, dyspnea, and hemoptysis. Focused cardiopulmonary assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
    end,
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _cv_target t
  join _cv_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is the best FIRST treatment plan now?',
    null, 'STOP', '{}'::jsonb
  from _cv_target t
  union all
  select t.case_id, 3, 3, 'IG',
    'Fifteen minutes after initial treatment, SELECT AS MANY AS INDICATED (MAX 8). What reassessment findings should drive escalation NEXT?',
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _cv_target t
  union all
  select t.case_id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the safest NEXT management/disposition decision?',
    null, 'STOP', '{}'::jsonb
  from _cv_target t
  returning case_id, step_order, id
)
insert into _cv_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _cv_target t on t.case_id = i.case_id;

-- Step 1 options (IG)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Recognize syndrome-defining pattern and onset context immediately', 3, 'Core pattern recognition.' from _cv_steps st where st.step_order = 1
union all
select st.step_id, 'B',
  case s.disease_key
    when 'chf' then 'Look for orthopnea, pink frothy secretions, crackles, edema, and fluid-overload signs'
    when 'mi' then 'Assess chest pain quality with ischemic symptoms and unstable-angina risk context'
    when 'shock' then 'Assess perfusion markers: mental status, capillary refill, skin temp, urine output'
    when 'cor_pulm' then 'Assess COPD/chronic-lung history with JVD, edema, and right-heart strain signs'
    else 'Confirm sudden post-op dyspnea + hemoptysis + chest pain + tachycardia PE trigger pattern'
  end,
  3,
  'High-yield disease-specific cue set.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number
where st.step_order = 1
union all
select st.step_id, 'C', 'Obtain ABG and trend oxygenation/ventilation status', 2, 'Objective severity data.' from _cv_steps st where st.step_order = 1
union all
select st.step_id, 'D',
  case s.disease_key
    when 'chf' then 'Order CXR, BNP, EKG, biomarkers, and hemodynamic profile (PCWP/PAP) as indicated'
    when 'mi' then 'Order EKG, troponin/cardiac enzymes, and electrolyte profile (especially potassium)'
    when 'shock' then 'Define likely shock type and assess hemodynamic volume/perfusion trends'
    when 'cor_pulm' then 'Evaluate EKG/CVP profile and assess pulmonary-hypertension workload signs'
    else 'Order D-dimer and pulmonary angiography pathway (plus CT/VQ as indicated)'
  end,
  2,
  'Correct targeted diagnostics.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number
where st.step_order = 1
union all
select st.step_id, 'E', 'Delay treatment while waiting for complete diagnostic panel', -3, 'Unsafe delay.' from _cv_steps st where st.step_order = 1
union all
select st.step_id, 'F', 'Ignore hemodynamic trends if oxygen saturation briefly improves', -2, 'Can miss collapse risk.' from _cv_steps st where st.step_order = 1
union all
select st.step_id, 'G', 'Use nonurgent testing first and defer bedside stabilization', -3, 'Wrong priority in critical patient.' from _cv_steps st where st.step_order = 1
union all
select st.step_id, 'H', 'Assume no urgent issue if chest x-ray is initially nondiagnostic', -2, 'Dangerous assumption, especially for PE/MI patterns.' from _cv_steps st where st.step_order = 1;

-- Step 2 options (DM)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case s.disease_key
    when 'chf' then 'Start oxygen, upright positioning, fluid-restriction/diuretic strategy, and NPPV while monitoring hemodynamics'
    when 'mi' then 'Start oxygen and MI emergency bundle (MONA context), rhythm/BP monitoring, and ischemia-directed therapy'
    when 'shock' then 'Provide oxygen and restore perfusion with cause-directed fluids/vasopressors and ventilatory support as indicated'
    when 'cor_pulm' then 'Provide oxygen and treat underlying pulmonary cause while reducing right-ventricular workload/pulmonary pressure'
    else 'Provide oxygen and initiate urgent PE treatment pathway (anticoagulation +/- thrombolytic context) with close monitoring'
  end,
  3,
  'Best immediate treatment pathway.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number
where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen only and delay disease-specific interventions', -3, 'Incomplete and unsafe.' from _cv_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Transfer to low-acuity setting after brief improvement', -3, 'Unsafe early transfer.' from _cv_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Sedate for comfort before stabilization strategy is established', -3, 'Wrong sequence.' from _cv_steps st where st.step_order = 2
union all select st.step_id, 'E', 'Start oxygen and immediate monitoring while arranging definitive disease-specific treatment pathway', 1, 'Reasonable bridge action, but incomplete if definitive treatment is delayed.' from _cv_steps st where st.step_order = 2;

-- Step 3 options (IG reassessment)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Repeat ABG (pH/PaCO2/PaO2/HCO3) and oxygenation/hemodynamic trajectory; if intubated, document mode/VT/RR/FiO2/PEEP and adjust RR/VT/FiO2/PEEP', 2, 'Core reassessment.' from _cv_steps st where st.step_order = 3
union all
select st.step_id, 'B',
  case s.disease_key
    when 'chf' then 'Trend fluid-overload response, blood pressure, and signs of cardiogenic edema improvement'
    when 'mi' then 'Track EKG rhythm/ischemic changes and biomarker trend with perfusion status'
    when 'shock' then 'Track perfusion endpoints (MAP/urine output/cap refill) and response to fluids/pressors'
    when 'cor_pulm' then 'Trend right-heart strain signs and oxygenation with pulmonary pressure strategy'
    else 'Trend deadspace/PE indicators (PECO2 pattern, hemodynamics) and response to PE therapy'
  end,
  3,
  'Targeted reassessment by syndrome.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number
where st.step_order = 3
union all select st.step_id, 'C', 'Prepare escalation to intubation/mechanical ventilation if noninvasive strategy fails', 2, 'Appropriate escalation readiness.' from _cv_steps st where st.step_order = 3
union all select st.step_id, 'D', 'Stop close monitoring after one modest response', -3, 'Unsafe de-escalation.' from _cv_steps st where st.step_order = 3
union all select st.step_id, 'E', 'Delay reassessment until next routine cycle', -3, 'High-risk delay.' from _cv_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Ignore rhythm changes unless cardiac arrest occurs', -2, 'Misses early deterioration.' from _cv_steps st where st.step_order = 3
union all select st.step_id, 'G', 'Do not reassess perfusion after blood pressure intervention', -2, 'Inadequate shock/MI care.' from _cv_steps st where st.step_order = 3
union all select st.step_id, 'H', 'Treat diagnostics as complete and discontinue trend-based decisions', -2, 'Critical-care mismatch.' from _cv_steps st where st.step_order = 3;

-- Step 4 options (final DM/disposition)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Continue ICU-level management with structured reassessment and escalation triggers', 3, 'Safest disposition.' from _cv_steps st where st.step_order = 4
union all select st.step_id, 'B', 'Step down to low-acuity bed immediately', -3, 'Unsafe premature transfer.' from _cv_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discharge after transient stabilization', -3, 'Unsafe disposition.' from _cv_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Hold in unstructured observation without hemodynamic plan', -2, 'Inadequate plan.' from _cv_steps st where st.step_order = 4
union all select st.step_id, 'E', 'Continue monitored high-acuity care with explicit escalation triggers before transfer decisions', 1, 'Reasonable pathway but less definitive than full ICU continuity plan.' from _cv_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s2.step_id,
  'Initial assessment captures high-risk cardiovascular pattern and supports rapid treatment.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _cv_steps s1 join _cv_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Missed priorities delay stabilization and increase collapse risk.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -3, "bp_dia": -2, "etco2": 3}'::jsonb
from _cv_steps s1 join _cv_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1

union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  'Immediate treatment aligns with disease-specific life-saving priorities.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": 1, "bp_dia": 1, "etco2": -2}'::jsonb
from _cv_steps s2 join _cv_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Suboptimal treatment leaves persistent instability risk.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": -4, "bp_dia": -3, "etco2": 4}'::jsonb
from _cv_steps s2 join _cv_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2

union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  'Reassessment is complete and supports safe critical-care continuity.',
  '{"spo2": 2, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _cv_steps s3 join _cv_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Monitoring gaps create avoidable deterioration risk.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": -2, "bp_dia": -1, "etco2": 2}'::jsonb
from _cv_steps s3 join _cv_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3

union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient is stabilized with appropriate ICU-level cardiovascular critical care.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _cv_steps s4
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: unsafe de-escalation leads to recurrent cardiovascular instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _cv_steps s4
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
join _cv_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _cv_target);

commit;
