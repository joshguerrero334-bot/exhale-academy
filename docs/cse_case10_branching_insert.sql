-- Exhale Academy CSE Case #10 Branching Seed (Neuromuscular Ventilatory Failure)
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
    description = 'Branching scenario focused on early recognition of pump failure, airway clearance strategy, and escalation timing.',
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
    'Branching scenario focused on early recognition of pump failure, airway clearance strategy, and escalation timing.',
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

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case10_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case10_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case10_target)
);

delete from public.cse_steps
where case_id in (select id from _case10_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'A 41-year-old female with progressive weakness reports increasing shortness of breath, weak cough, and difficulty clearing secretions. Breathing is shallow and speech is soft. SpO2 is 89% on room air. SELECT AS MANY AS INDICATED (MAX 4). What immediate priorities are indicated?', 4, 'STOP' from _case10_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. What is your FIRST respiratory support approach now?', null, 'STOP' from _case10_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). After initial support, what reassessment should guide escalation?', 3, 'STOP' from _case10_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. CO2 rises and inspiratory effort weakens further. What is your NEXT step?', null, 'STOP' from _case10_target
  union all
  select id, 5, 5, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). Following escalation, what ongoing management is indicated?', 3, 'STOP' from _case10_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the most appropriate disposition?', null, 'STOP' from _case10_target
  returning id, step_order
)
insert into _case10_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Apply controlled supplemental oxygen and continuous monitoring', 2, 'Stabilizes oxygenation while tracking progression.' from _case10_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess cough strength and secretion clearance ability', 2, 'Critical in neuromuscular respiratory risk.' from _case10_steps s where s.step_order = 1
union all select s.id, 'C', 'Obtain VT, VC, and MIP plus blood gas promptly', 2, 'Core ventilatory-failure surveillance metrics in neuromuscular disorders.' from _case10_steps s where s.step_order = 1
union all select s.id, 'D', 'Delay intervention pending complete imaging workup', -2, 'Dangerous delay in evolving ventilatory failure.' from _case10_steps s where s.step_order = 1
union all select s.id, 'E', 'Sedate for anxiety before ventilation plan is established', -2, 'May worsen respiratory drive and airway protection.' from _case10_steps s where s.step_order = 1
union all select s.id, 'F', 'Differentiate descending vs ascending weakness pattern (MG vs GBS)', 2, 'High-yield exam distinction that improves pathway accuracy.' from _case10_steps s where s.step_order = 1

union all select s.id, 'A', 'Initiate noninvasive ventilatory support with close tolerance checks', 2, 'Appropriate first escalation for pump weakness with preserved airway reflexes.' from _case10_steps s where s.step_order = 2
union all select s.id, 'B', 'Use oxygen alone and reassess much later', -1, 'Fails to address ventilatory insufficiency.' from _case10_steps s where s.step_order = 2
union all select s.id, 'C', 'Remove oxygen to assess true baseline', -2, 'Unsafe during active compromise.' from _case10_steps s where s.step_order = 2
union all select s.id, 'D', 'Intubate immediately without assessing NIV feasibility', -1, 'May be needed later but can be premature initially.' from _case10_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend mental status, respiratory pattern, and accessory muscle use', 2, 'Detects impending failure early.' from _case10_steps s where s.step_order = 3
union all select s.id, 'B', 'Repeat ABG and trend VT, VC, and MIP after support initiation', 2, 'Tracks objective progression toward or away from ventilatory failure.' from _case10_steps s where s.step_order = 3
union all select s.id, 'C', 'Reassess secretion burden and airway clearance effectiveness', 2, 'Guides need for airway protection escalation.' from _case10_steps s where s.step_order = 3
union all select s.id, 'D', 'Stop monitoring after brief subjective relief', -2, 'Misses rapid decline risk.' from _case10_steps s where s.step_order = 3
union all select s.id, 'E', 'Delay reassessment until next routine interval', -2, 'Unsafe in unstable progression.' from _case10_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed to controlled invasive airway support with full preparation', 2, 'Indicated when ventilatory failure progresses despite NIV.' from _case10_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue unchanged NIV despite worsening effort and CO2 rise', -1, 'Delays definitive care.' from _case10_steps s where s.step_order = 4
union all select s.id, 'C', 'Stop support and observe spontaneous effort', -2, 'Unsafe de-escalation.' from _case10_steps s where s.step_order = 4
union all select s.id, 'D', 'Transport to diagnostics before securing ventilation', -2, 'High-risk delay during deterioration.' from _case10_steps s where s.step_order = 4

union all select s.id, 'A', 'Set ventilator mode/settings (e.g., AC/VC VT 6-8 mL/kg IBW, RR 14-18, FiO2/PEEP titrated) and adjust RR/VT/FiO2/PEEP from ABG (pH/PaCO2/PaO2/HCO3) and oxygenation response', 2, 'Reduces risk of over/under-ventilation.' from _case10_steps s where s.step_order = 5
union all select s.id, 'B', 'Implement secretion-clearance strategy with frequent reassessment', 2, 'Essential in neuromuscular weakness.' from _case10_steps s where s.step_order = 5
union all select s.id, 'C', 'Continue continuous hemodynamic and oxygenation monitoring', 1, 'Tracks stability and relapse.' from _case10_steps s where s.step_order = 5
union all select s.id, 'D', 'Reduce monitoring after first normal blood gas', -1, 'Premature de-escalation.' from _case10_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer to low-acuity setting immediately', -2, 'Unsafe for current risk.' from _case10_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to ICU/high-acuity unit with structured respiratory plan', 2, 'Appropriate after progressive ventilatory failure.' from _case10_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge after temporary improvement', -2, 'Unsafe disposition.' from _case10_steps s where s.step_order = 6
union all select s.id, 'C', 'Transfer to unmonitored floor', -2, 'Insufficient monitoring intensity.' from _case10_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe without defined escalation thresholds', -1, 'Inadequate follow-through.' from _case10_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","B"]'::jsonb, s2.id,
  'Early priorities improve safety and clarify risk, but ventilatory weakness persists.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case10_steps s1 cross join _case10_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Delayed or harmful actions accelerate fatigue and CO2 retention risk.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 2}'::jsonb
from _case10_steps s1 cross join _case10_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Support improves ventilatory mechanics and oxygenation trend.',
  '{"spo2": 5, "hr": -4, "rr": -3, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case10_steps s2 cross join _case10_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate support leaves worsening hypercapnic trajectory.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case10_steps s2 cross join _case10_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Focused reassessment identifies failure progression in time for escalation.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case10_steps s3 cross join _case10_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Missed signs allow progression to critical ventilatory failure.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case10_steps s3 cross join _case10_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Definitive airway support stabilizes gas exchange and effort.',
  '{"spo2": 7, "hr": -6, "rr": -6, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case10_steps s4 cross join _case10_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Delayed definitive support leads to severe instability and exhaustion.',
  '{"spo2": -8, "hr": 8, "rr": 5, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case10_steps s4 cross join _case10_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Ongoing management sustains stability and reduces recurrence risk.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case10_steps s5 cross join _case10_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Management gaps keep relapse risk high.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case10_steps s5 cross join _case10_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable in monitored high-acuity care.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case10_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: low-acuity disposition led to recurrent ventilatory deterioration.',
  '{"spo2": -6, "hr": 7, "rr": 4, "bp_sys": -6, "bp_dia": -4}'::jsonb
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
