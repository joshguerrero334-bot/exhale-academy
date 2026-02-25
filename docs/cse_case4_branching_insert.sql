-- Exhale Academy CSE Case #4 Branching Seed (Fluid Overload Respiratory Crisis)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case4_target (id uuid primary key) on commit drop;
create temporary table _case4_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-4-nocturnal-dyspnea-fluid-overload-crisis'
     or lower(coalesce(title, '')) like '%case 4%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-fluid-overload-respiratory-crisis',
    case_number = 4,
    slug = 'case-4-nocturnal-dyspnea-fluid-overload-crisis',
    title = 'Case 4 -- Nocturnal Dyspnea Fluid Overload Crisis',
    intro_text = 'Adult with abrupt nighttime breathlessness, crackles, and severe hypoxemia requiring rapid oxygenation and pressure-support decisions.',
    description = 'Branching scenario emphasizing early stabilization, preload reduction strategy, and safe disposition.',
    stem = 'Rapid respiratory deterioration with signs of intrathoracic fluid burden.',
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
    'adult-fluid-overload-respiratory-crisis',
    4,
    'case-4-nocturnal-dyspnea-fluid-overload-crisis',
    'Case 4 -- Nocturnal Dyspnea Fluid Overload Crisis',
    'Adult with abrupt nighttime breathlessness, crackles, and severe hypoxemia requiring rapid oxygenation and pressure-support decisions.',
    'Branching scenario emphasizing early stabilization, preload reduction strategy, and safe disposition.',
    'Rapid respiratory deterioration with signs of intrathoracic fluid burden.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case4_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":124,"rr":34,"spo2":78,"bp_sys":188,"bp_dia":104}'::jsonb
where id in (select id from _case4_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case4_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case4_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case4_target)
);

delete from public.cse_steps
where case_id in (select id from _case4_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'A 67-year-old female wakes with severe dyspnea, pink frothy sputum, and diffuse crackles. She is diaphoretic and using accessory muscles. SpO2 is 78% on room air. SELECT AS MANY AS INDICATED (MAX 4). What immediate bedside priorities are indicated?', 4, 'STOP' from _case4_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. What is your FIRST respiratory intervention now?', null, 'STOP' from _case4_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). After initial support, what reassessment and treatment actions are most important?', 3, 'STOP' from _case4_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. Distress remains severe despite oxygen. What is the best escalation?', null, 'STOP' from _case4_target
  union all
  select id, 5, 5, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). Following early improvement, what ongoing management is indicated?', 3, 'STOP' from _case4_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the safest disposition now?', null, 'STOP' from _case4_target
  returning id, step_order
)
insert into _case4_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Position upright and apply high-concentration oxygen', 2, 'Rapidly improves ventilation mechanics and oxygen reserve.' from _case4_steps s where s.step_order = 1
union all select s.id, 'B', 'Place continuous SpO2, ECG, and blood pressure monitoring', 1, 'Supports safe titration during unstable physiology.' from _case4_steps s where s.step_order = 1
union all select s.id, 'C', 'Establish IV access and alert provider for preload-reduction therapy', 2, 'Facilitates rapid hemodynamic treatment.' from _case4_steps s where s.step_order = 1
union all select s.id, 'D', 'Start large fluid bolus for tachycardia', -2, 'Can worsen pulmonary congestion.' from _case4_steps s where s.step_order = 1
union all select s.id, 'E', 'Send to CT before bedside stabilization', -2, 'Dangerous delay in active respiratory failure.' from _case4_steps s where s.step_order = 1

union all select s.id, 'A', 'Start noninvasive positive-pressure ventilation with close reassessment', 2, 'Best immediate support for severe hypoxemic distress with high work of breathing.' from _case4_steps s where s.step_order = 2
union all select s.id, 'B', 'Continue low-flow nasal cannula and observe', -1, 'Usually insufficient at this severity.' from _case4_steps s where s.step_order = 2
union all select s.id, 'C', 'Remove oxygen to reassess baseline saturation', -2, 'Unsafe de-escalation in critical hypoxemia.' from _case4_steps s where s.step_order = 2
union all select s.id, 'D', 'Immediate intubation without NIV trial despite preserved mentation', -1, 'May be needed later, but often premature first step.' from _case4_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend respiratory rate, mental status, and SpO2 every few minutes', 2, 'Confirms trajectory and fatigue risk.' from _case4_steps s where s.step_order = 3
union all select s.id, 'B', 'Review blood gas and response to pressure support', 1, 'Guides escalation timing and targets.' from _case4_steps s where s.step_order = 3
union all select s.id, 'C', 'Begin ordered diuretic/vasodilator strategy while monitoring blood pressure', 2, 'Treats underlying hemodynamic driver when tolerated.' from _case4_steps s where s.step_order = 3
union all select s.id, 'D', 'Stop monitoring after a brief saturation bump', -2, 'Misses rapid relapse.' from _case4_steps s where s.step_order = 3
union all select s.id, 'E', 'Delay treatment until full imaging panel returns', -2, 'Delays critical care during active failure.' from _case4_steps s where s.step_order = 3

union all select s.id, 'A', 'Increase NIV support settings and optimize synchrony', 2, 'Appropriate escalation before invasive airway when still responsive.' from _case4_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue unchanged settings despite rising fatigue', -1, 'Fails to address deterioration.' from _case4_steps s where s.step_order = 4
union all select s.id, 'C', 'Discontinue pressure support to avoid discomfort', -2, 'Likely worsens ventilation and oxygenation.' from _case4_steps s where s.step_order = 4
union all select s.id, 'D', 'Transport for imaging while unstable on minimal support', -2, 'Unsafe transfer during ongoing compromise.' from _case4_steps s where s.step_order = 4

union all select s.id, 'A', 'Titrate FiO2/pressure support to maintain target oxygenation', 2, 'Prevents over- and under-support.' from _case4_steps s where s.step_order = 5
union all select s.id, 'B', 'Track urine output and hemodynamic response to therapy', 1, 'Assesses decongestion and perfusion safety.' from _case4_steps s where s.step_order = 5
union all select s.id, 'C', 'Repeat focused lung exam and gas-exchange assessment', 2, 'Verifies sustained improvement.' from _case4_steps s where s.step_order = 5
union all select s.id, 'D', 'Maintain maximal oxygen indefinitely without reassessment', -1, 'Untargeted therapy increases risk.' from _case4_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer to unmonitored area after brief improvement', -2, 'Premature downgrade for unstable course.' from _case4_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to ICU or high-acuity monitored unit with respiratory plan', 2, 'Appropriate level after severe decompensation.' from _case4_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge home after transient symptom relief', -2, 'Unsafe disposition.' from _case4_steps s where s.step_order = 6
union all select s.id, 'C', 'Transfer to regular floor without close monitoring', -2, 'Monitoring intensity is inadequate.' from _case4_steps s where s.step_order = 6
union all select s.id, 'D', 'Keep in hallway observation without escalation plan', -1, 'Insufficient follow-through.' from _case4_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","C"]'::jsonb, s2.id,
  'Initial priorities reduce panic and slightly improve oxygenation, but severe distress remains.',
  '{"spo2": 5, "hr": -6, "rr": -3, "bp_sys": -8, "bp_dia": -4}'::jsonb
from _case4_steps s1 cross join _case4_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Delay or harmful early actions worsen pulmonary distress and hemodynamic strain.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": 10, "bp_dia": 6}'::jsonb
from _case4_steps s1 cross join _case4_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Positive-pressure support improves gas exchange and reduces visible work of breathing.',
  '{"spo2": 8, "hr": -8, "rr": -6, "bp_sys": -10, "bp_dia": -6}'::jsonb
from _case4_steps s2 cross join _case4_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Insufficient support leads to persistent hypoxemia and worsening fatigue.',
  '{"spo2": -7, "hr": 10, "rr": 5, "bp_sys": 8, "bp_dia": 4}'::jsonb
from _case4_steps s2 cross join _case4_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Targeted reassessment and treatment produce a steadier trajectory, though risk persists.',
  '{"spo2": 4, "hr": -4, "rr": -3, "bp_sys": -6, "bp_dia": -3}'::jsonb
from _case4_steps s3 cross join _case4_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring and treatment gaps allow ongoing respiratory decline.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 6, "bp_dia": 3}'::jsonb
from _case4_steps s3 cross join _case4_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Escalated noninvasive support improves oxygenation and reduces fatigue.',
  '{"spo2": 6, "hr": -6, "rr": -5, "bp_sys": -8, "bp_dia": -4}'::jsonb
from _case4_steps s4 cross join _case4_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Suboptimal escalation leads to refractory distress and high intubation risk.',
  '{"spo2": -8, "hr": 10, "rr": 6, "bp_sys": -12, "bp_dia": -8}'::jsonb
from _case4_steps s4 cross join _case4_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Ongoing titration and surveillance stabilize respiratory status for safe transition planning.',
  '{"spo2": 3, "hr": -4, "rr": -3, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case4_steps s5 cross join _case4_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Premature de-escalation leaves substantial relapse risk.',
  '{"spo2": -4, "hr": 5, "rr": 4, "bp_sys": 4, "bp_dia": 2}'::jsonb
from _case4_steps s5 cross join _case4_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: respiratory status remains stable in high-acuity monitored care.',
  '{"spo2": 2, "hr": -2, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case4_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: low-acuity disposition leads to recurrent respiratory distress and urgent return.',
  '{"spo2": -6, "hr": 8, "rr": 5, "bp_sys": -8, "bp_dia": -6}'::jsonb
from _case4_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE4_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case4_target);

commit;
