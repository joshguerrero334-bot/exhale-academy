-- Exhale Academy CSE Branching Seed (Neuromuscular Ventilatory Failure)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case10_target (id uuid primary key) on commit drop;
create temporary table _case10_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-10-neuromuscular-ventilatory-failure-pattern'
     or lower(coalesce(title, '')) like '%case 10%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-neuromuscular-ventilatory-failure',
    case_number = 10,
    slug = 'case-10-neuromuscular-ventilatory-failure-pattern',
    title = 'Case 10 -- Neuromuscular Ventilatory Failure Pattern',
    intro_text = 'Adult with progressive generalized weakness presents with shallow breathing, poor cough, and rising CO2 risk requiring timely ventilatory support decisions.',
    description = 'Branching scenario focused on early recognition of ventilatory pump failure, reassessment, and escalation timing.',
    stem = 'Progressive ventilatory pump failure with impending hypercapnic decompensation.',
    difficulty = 'medium',
    is_active = true,
    is_published = true
  where c.id in (select id from existing)
  returning c.id
),
created as (
  insert into public.cse_cases (
    source, case_number, slug, title, intro_text, description, stem, difficulty, is_active, is_published
  )
  select
    'adult-neuromuscular-ventilatory-failure',
    10,
    'case-10-neuromuscular-ventilatory-failure-pattern',
    'Case 10 -- Neuromuscular Ventilatory Failure Pattern',
    'Adult with progressive generalized weakness presents with shallow breathing, poor cough, and rising CO2 risk requiring timely ventilatory support decisions.',
    'Branching scenario focused on early recognition of ventilatory pump failure, reassessment, and escalation timing.',
    'Progressive ventilatory pump failure with impending hypercapnic decompensation.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case10_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":108,"rr":28,"spo2":89,"bp_sys":142,"bp_dia":86}'::jsonb
where id in (select id from _case10_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case10_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case10_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case10_target)
);

delete from public.cse_attempts where case_id in (select id from _case10_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case10_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case10_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case10_target));
delete from public.cse_steps where case_id in (select id from _case10_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 41-year-old woman with progressive generalized weakness comes to the emergency department because of increasing dyspnea and weak cough.

While breathing room air, the following are noted:
HR 108/min
RR 28/min
BP 142/86 mm Hg
SpO2 89%

She is speaking softly and taking shallow breaths.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case10_target
  union all
  select id, 2, 2, 'DM',
    'Cough is weak, and inspiratory effort remains poor. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case10_target
  union all
  select id, 3, 3, 'IG',
    'After initial support, the patient remains tachypneic.

While receiving O2 by nasal cannula at 2 L/min, the following are noted:
HR 104/min
RR 30/min
BP 138/84 mm Hg
SpO2 91%

ABG analysis reveals:
pH 7.34
PaCO2 52 torr
PaO2 64 torr
HCO3- 27 mEq/L

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case10_target
  union all
  select id, 4, 4, 'DM',
    'PaCO2 rises further, and inspiratory effort weakens. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case10_target
  union all
  select id, 5, 5, 'IG',
    'After escalation, the patient is receiving mechanical ventilation with improved oxygenation. Which of the following should be evaluated or managed now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case10_target
  union all
  select id, 6, 6, 'DM',
    'The patient remains at risk for recurrent ventilatory failure. Which of the following should be recommended postadmission?',
    null, 'STOP', '{}'::jsonb from _case10_target
  returning id, step_order
)
insert into _case10_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Cough strength and ability to clear secretions', 2, 'This is indicated in the initial assessment.' from _case10_steps s where s.step_order = 1
union all select s.id, 'B', 'Vital signs, pulse oximetry, and breathing pattern', 2, 'This helps assess severity and trend.' from _case10_steps s where s.step_order = 1
union all select s.id, 'C', 'Vital capacity, inspiratory force, and ABG analysis', 2, 'These data are indicated when ventilatory pump failure is suspected.' from _case10_steps s where s.step_order = 1
union all select s.id, 'D', 'Routine imaging before stabilization', -3, 'This delays urgent care.' from _case10_steps s where s.step_order = 1
union all select s.id, 'E', 'Sedation before a ventilation plan is established', -3, 'This may worsen respiratory failure.' from _case10_steps s where s.step_order = 1

union all select s.id, 'A', 'Begin noninvasive ventilatory support with close reassessment', 3, 'This is the best first support strategy when airway protection is still present.' from _case10_steps s where s.step_order = 2
union all select s.id, 'B', 'Use oxygen alone and reassess much later', -3, 'This does not address ventilatory insufficiency.' from _case10_steps s where s.step_order = 2
union all select s.id, 'C', 'Remove oxygen to assess baseline status', -3, 'This is unsafe.' from _case10_steps s where s.step_order = 2
union all select s.id, 'D', 'Proceed directly to intubation without further reassessment', -2, 'This may be required later, but it is not the best first step now.' from _case10_steps s where s.step_order = 2

union all select s.id, 'A', 'Mental status and breathing pattern', 2, 'This helps assess progression toward ventilatory failure.' from _case10_steps s where s.step_order = 3
union all select s.id, 'B', 'ABG trend and repeat ventilatory mechanics', 2, 'This is indicated to assess worsening hypercapnia.' from _case10_steps s where s.step_order = 3
union all select s.id, 'C', 'Secretion burden and cough effectiveness', 2, 'This helps determine airway-protection risk.' from _case10_steps s where s.step_order = 3
union all select s.id, 'D', 'Routine discharge planning', -3, 'This is premature.' from _case10_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop monitoring after brief subjective improvement', -3, 'This is unsafe.' from _case10_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed with controlled endotracheal intubation and mechanical ventilation', 3, 'This is indicated with worsening ventilatory failure.' from _case10_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue the same noninvasive support despite worsening CO2 retention', -3, 'This delays definitive care.' from _case10_steps s where s.step_order = 4
union all select s.id, 'C', 'Stop support and observe spontaneous effort', -3, 'This is unsafe.' from _case10_steps s where s.step_order = 4
union all select s.id, 'D', 'Transport for diagnostics before securing ventilation', -3, 'This delays indicated care.' from _case10_steps s where s.step_order = 4

union all select s.id, 'A', 'Ventilator settings and ABG response', 2, 'This is indicated after intubation.' from _case10_steps s where s.step_order = 5
union all select s.id, 'B', 'Secretion-clearance effectiveness and airway patency', 2, 'This is important in neuromuscular weakness.' from _case10_steps s where s.step_order = 5
union all select s.id, 'C', 'Continuous oxygenation and hemodynamic monitoring', 2, 'This is indicated during early stabilization.' from _case10_steps s where s.step_order = 5
union all select s.id, 'D', 'Stop close monitoring after the first improved ABG', -3, 'This is unsafe.' from _case10_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer immediately to a low-acuity unit', -3, 'This is not appropriate.' from _case10_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to the ICU for continued ventilatory support and reassessment', 3, 'This is the safest disposition in this situation.' from _case10_steps s where s.step_order = 6
union all select s.id, 'B', 'Transfer to an unmonitored floor bed', -3, 'This is not an appropriate level of care.' from _case10_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge after temporary improvement', -3, 'This is unsafe.' from _case10_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe without a defined escalation plan', -3, 'This is not an appropriate disposition.' from _case10_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Shallow breathing and weak cough persist, and ventilatory weakness remains present.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case10_steps s1 cross join _case10_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Ventilatory weakness worsens.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case10_steps s1 cross join _case10_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Oxygenation improves slightly, but shallow breathing persists.',
  '{"spo2": 5, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case10_steps s2 cross join _case10_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Hypercapnic ventilatory failure progresses.',
  '{"spo2": -4, "hr": 6, "rr": 4, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case10_steps s2 cross join _case10_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'PaCO2 rises, and inspiratory effort remains weak.',
  '{"spo2": -1, "hr": 1, "rr": 1, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case10_steps s3 cross join _case10_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and ventilatory failure worsens.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case10_steps s3 cross join _case10_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'The airway is secured, and gas exchange improves.',
  '{"spo2": 8, "hr": -6, "rr": -6, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case10_steps s4 cross join _case10_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Definitive ventilatory support is delayed, and instability increases.',
  '{"spo2": -7, "hr": 7, "rr": 4, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case10_steps s4 cross join _case10_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'Early ventilatory stabilization is maintained with close monitoring.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case10_steps s5 cross join _case10_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Management gaps leave recurrent ventilatory deterioration risk.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case10_steps s5 cross join _case10_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is admitted to the ICU for continued ventilatory support and reassessment.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case10_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: the level of care is inadequate, and recurrent ventilatory failure occurs.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case10_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE10_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
    'bp_dia', coalesce((b.baseline_vitals->>'bp_dia')::int, 0) + coalesce((r.vitals_delta->>'bp_dia')::int, 0)
  )
from public.cse_rules r
join public.cse_steps s on s.id = r.step_id
join public.cse_cases b on b.id = s.case_id
where s.case_id in (select id from _case10_target);

commit;
