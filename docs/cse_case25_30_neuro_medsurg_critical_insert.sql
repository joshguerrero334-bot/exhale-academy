-- Exhale Academy CSE Branching Seed (Cases 25-30)
-- Adult Neuro + Adult Med/Surg lesson-derived critical cases
-- Requires docs/cse_branching_engine_migration.sql,
-- docs/cse_case_taxonomy_migration.sql, and docs/cse_outcomes_vitals_migration.sql

begin;

create temporary table _nm_seed (
  case_number int4 primary key,
  profile text not null,
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

insert into _nm_seed (
  case_number, profile, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(25, 'neuro', 'adult-neuromuscular-critical', 'myasthenia-gravis', 'neuromuscular-critical-myasthenia-gravis-crisis',
 'Neuromuscular Critical (Myasthenia Gravis Crisis)',
 'Descending weakness with bulbar signs and worsening ventilatory muscle fatigue.',
 'Critical MG case focused on ventilatory-failure detection and timely escalation.',
 'Patient with ptosis, dysphagia, shallow breathing, and declining respiratory strength metrics.',
 '{"hr":118,"rr":32,"spo2":84,"bp_sys":146,"bp_dia":88,"etco2":52}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(26, 'neuro', 'adult-neuromuscular-critical', 'guillain-barre', 'neuromuscular-critical-guillain-barre-ascending-paralysis',
 'Neuromuscular Critical (Guillain-Barre Ascending Paralysis)',
 'Ascending weakness after febrile illness with progressive respiratory compromise.',
 'Critical GBS case focused on airway protection, respiratory muscle trend, and escalation timing.',
 'Post-viral patient with ascending weakness, dysphagia risk, shallow respirations, and declining volumes.',
 '{"hr":114,"rr":30,"spo2":85,"bp_sys":142,"bp_dia":86,"etco2":50}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(27, 'medsurg', 'adult-med-surg-critical', 'drug-overdose', 'adult-med-surg-critical-drug-overdose-airway-protection',
 'Adult Med/Surg Critical (Drug Overdose Airway Protection)',
 'Toxic ingestion with altered consciousness and high aspiration risk requiring airway-first decisions.',
 'Critical overdose case focused on airway protection, antidote selection, and ventilatory support.',
 'Obtunded patient with slow shallow respirations and likely toxic ingestion pattern.',
 '{"hr":104,"rr":10,"spo2":82,"bp_sys":96,"bp_dia":58,"etco2":60}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(28, 'neuro', 'adult-neuromuscular-critical', 'muscular-dystrophy', 'neuromuscular-critical-muscular-dystrophy-hypoventilation',
 'Neuromuscular Critical (Muscular Dystrophy Hypoventilation)',
 'Progressive neuromuscular disease with sleep-related hypoventilation and ventilatory decline.',
 'Critical muscular-dystrophy case focused on chronic trend recognition and escalation triggers.',
 'Patient with chronic muscle weakness now presents with worsening hypoventilation signs.',
 '{"hr":108,"rr":26,"spo2":86,"bp_sys":138,"bp_dia":82,"etco2":54}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(29, 'neuro', 'adult-neuromuscular-critical', 'stroke', 'neuromuscular-critical-stroke-neuro-respiratory-failure',
 'Neuromuscular Critical (Stroke Neuro-Respiratory Failure)',
 'Acute neurologic deficit with respiratory pattern changes and airway-risk progression.',
 'Critical stroke case focused on neuro-imaging priorities, airway risk, and ventilatory escalation.',
 'Patient with acute speech/motor deficits, decreased consciousness, and abnormal respiratory rhythm.',
 '{"hr":112,"rr":28,"spo2":87,"bp_sys":168,"bp_dia":96,"etco2":49}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(30, 'neuro', 'adult-neuromuscular-critical', 'tetanus', 'neuromuscular-critical-tetanus-airway-risk',
 'Neuromuscular Critical (Tetanus Airway Risk)',
 'Wound-related tetanus pattern with lockjaw, bulbar dysfunction, and respiratory failure risk.',
 'Critical tetanus case focused on clinical recognition and airway-protection escalation.',
 'Patient with puncture-wound history, trismus, dysphagia, and declining ventilatory strength.',
 '{"hr":120,"rr":29,"spo2":85,"bp_sys":152,"bp_dia":90,"etco2":51}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null);

create temporary table _nm_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _nm_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _nm_seed s
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
  from _nm_seed s
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
  from _nm_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _nm_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _nm_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _nm_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _nm_target)
);

delete from public.cse_attempts where case_id in (select case_id from _nm_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _nm_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _nm_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _nm_target));
delete from public.cse_steps where case_id in (select case_id from _nm_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case t.case_number
      when 25 then 'You are called to bedside for a 34-year-old female with double vision, drooping eyelids, and worsening shallow breathing late in the day. Focused neuromuscular assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 26 then 'You are called to bedside for a 51-year-old male with progressive leg weakness after a recent viral illness who now reports weak cough and increasing dyspnea. Focused neuromuscular assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 27 then 'You are called to bedside for a 39-year-old female found somnolent with slow shallow respirations after suspected pill ingestion. Focused tox/airway assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 28 then 'You are called to bedside for a 45-year-old male with chronic progressive muscle weakness who now has nighttime hypoventilation symptoms and ineffective secretion clearance. Focused respiratory-muscle assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 29 then 'You are called to bedside for a 72-year-old female with sudden speech change, unilateral weakness, and irregular breathing pattern. Focused neuro-respiratory assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      else 'You are called to bedside for a 43-year-old male with painful muscle rigidity, dysphagia, and worsening ventilation after a recent puncture wound. Focused airway and neuromuscular assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
    end,
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _nm_target t
  join _nm_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    case when s.profile = 'medsurg'
      then 'CHOOSE ONLY ONE. What is the best FIRST airway and treatment action now?'
      else 'CHOOSE ONLY ONE. What is the best FIRST treatment strategy now?'
    end,
    null, 'STOP', '{}'::jsonb
  from _nm_target t
  join _nm_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 3, 3, 'IG',
    case when s.profile = 'medsurg'
      then 'Fifteen minutes after initial stabilization, SELECT AS MANY AS INDICATED (MAX 8). What reassessment data should guide escalation NEXT?'
      else 'Fifteen minutes after initial support, SELECT AS MANY AS INDICATED (MAX 8). What reassessment confirms improvement or failure NEXT?'
    end,
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _nm_target t
  join _nm_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the safest NEXT management/disposition decision?',
    null, 'STOP', '{}'::jsonb
  from _nm_target t
  returning case_id, step_order, id
)
insert into _nm_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _nm_target t on t.case_id = i.case_id;

-- Step 1 options (IG)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Assess immediate airway protection risk and level of consciousness', 3, 'Top safety priority.' from _nm_steps st where st.step_order = 1
union all select st.step_id, 'B', 'Obtain full respiratory severity assessment including work of breathing and breath sounds', 2, 'Core bedside assessment.' from _nm_steps st where st.step_order = 1
union all select st.step_id, 'C', 'Obtain ABG to evaluate oxygenation/ventilation and acid-base status', 2, 'Objective gas-exchange severity.' from _nm_steps st where st.step_order = 1
union all select st.step_id, 'D', 'Trend spontaneous VT, VC, and MIP for ventilatory-failure surveillance', case when s.profile='neuro' then 3 else 1 end, 'High-yield respiratory muscle trend, especially in neuromuscular cases.' from _nm_steps st join _nm_seed s on s.case_number = st.case_number where st.step_order = 1
union all select st.step_id, 'E', 'Identify syndrome-specific diagnostic clues (e.g., MG vs GBS pattern, overdose context, stroke/tetanus clues)', 2, 'Improves pathway accuracy.' from _nm_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Delay treatment until all nonurgent testing is complete', -3, 'Unsafe delay.' from _nm_steps st where st.step_order = 1
union all select st.step_id, 'G', 'Ignore airway status while focusing only on long-term planning', -3, 'Misses immediate life threat.' from _nm_steps st where st.step_order = 1
union all select st.step_id, 'H', 'Assume brief subjective improvement means no reassessment is needed', -2, 'False reassurance risk.' from _nm_steps st where st.step_order = 1;

-- Step 2 options (DM)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case when s.profile='medsurg'
    then 'Secure airway first (intubate if obtunded/aspiration risk), provide oxygen, and initiate targeted overdose pathway'
    else 'Provide oxygen, monitor VT/VC/MIP closely, and escalate to ventilatory support when failure criteria emerge'
  end,
  3,
  'Best immediate strategy.'
from _nm_steps st join _nm_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen alone and postpone escalation decisions', -3, 'Inadequate for high-risk trajectory.' from _nm_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Defer syndrome-directed therapy until next shift reassessment', -3, 'Unsafe delay.' from _nm_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Sedate first before establishing airway/ventilation strategy', -3, 'Dangerous sequence.' from _nm_steps st where st.step_order = 2
union all select st.step_id, 'E', 'Start oxygen and immediate monitoring while preparing definitive syndrome-specific treatment pathway', 1, 'Reasonable bridge action, but incomplete if definitive therapy is delayed.' from _nm_steps st where st.step_order = 2;

-- Step 3 options (IG reassessment)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Repeat ABG (pH/PaCO2/PaO2/HCO3) and clinical trajectory after intervention; if intubated, document mode/VT/RR/FiO2/PEEP and adjust RR/VT/FiO2/PEEP', 2, 'Confirms response and direction.' from _nm_steps st where st.step_order = 3
union all select st.step_id, 'B', 'Recheck VT, VC, and MIP to detect improvement or decompensation', case when s.profile='neuro' then 3 else 1 end, 'Critical neuromuscular monitoring.' from _nm_steps st join _nm_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'C', 'Reassess airway protection, secretion burden, and aspiration risk', 2, 'Airway safety determinant.' from _nm_steps st where st.step_order = 3
union all select st.step_id, 'D', 'Apply disease-specific follow-up checks (e.g., LP/Tensilon/tox studies/neuro imaging as indicated)', 2, 'Right diagnostics after stabilization.' from _nm_steps st where st.step_order = 3
union all select st.step_id, 'E', 'Stop monitoring after one modest improvement', -3, 'Unsafe de-escalation.' from _nm_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Delay reassessment for several hours', -3, 'High-risk delay.' from _nm_steps st where st.step_order = 3
union all select st.step_id, 'G', 'Ignore objective respiratory metrics if pulse ox briefly rises', -2, 'Can miss ventilatory failure.' from _nm_steps st where st.step_order = 3
union all select st.step_id, 'H', 'Skip complication surveillance', -2, 'Misses deterioration causes.' from _nm_steps st where st.step_order = 3;

-- Step 4 options (final DM/disposition)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Continue ICU-level care with structured reassessment and escalation readiness', 3, 'Safest disposition.' from _nm_steps st where st.step_order = 4
union all select st.step_id, 'B', 'Transfer to low-acuity floor now', -3, 'Unsafe premature transfer.' from _nm_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discharge after temporary improvement', -3, 'Unsafe disposition.' from _nm_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Observe without explicit escalation triggers', -2, 'Inadequate safety plan.' from _nm_steps st where st.step_order = 4
union all select st.step_id, 'E', 'Continue monitored high-acuity care with explicit escalation triggers before transfer decisions', 1, 'Reasonable pathway but less protective than full ICU continuity plan.' from _nm_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s2.step_id,
  'Initial information gathering captures high-risk features and supports timely treatment.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _nm_steps s1 join _nm_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Missed priorities increase risk of respiratory deterioration.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -2, "bp_dia": -2, "etco2": 3}'::jsonb
from _nm_steps s1 join _nm_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1

union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  'Immediate management aligns with life-saving priorities.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": 1, "bp_dia": 1, "etco2": -3}'::jsonb
from _nm_steps s2 join _nm_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Suboptimal treatment leaves continued instability risk.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": -3, "bp_dia": -2, "etco2": 4}'::jsonb
from _nm_steps s2 join _nm_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2

union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  'Reassessment is strong and supports safe continuation.',
  '{"spo2": 2, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _nm_steps s3 join _nm_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Monitoring gaps allow avoidable setback.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": -2, "bp_dia": -1, "etco2": 2}'::jsonb
from _nm_steps s3 join _nm_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3

union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable with ICU-level continuity and clear escalation criteria.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _nm_steps s4
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: unsafe de-escalation leads to recurrent critical instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _nm_steps s4
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
join _nm_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _nm_target);

commit;
