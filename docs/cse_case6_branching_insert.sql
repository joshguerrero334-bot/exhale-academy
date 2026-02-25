-- Exhale Academy CSE Case #6 Branching Seed (Acute Severe Bronchospasm)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case6_target (id uuid primary key) on commit drop;
create temporary table _case6_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-6-acute-severe-bronchospasm-fatigue'
     or lower(coalesce(title, '')) like '%case 6%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-acute-severe-bronchospasm',
    case_number = 6,
    slug = 'case-6-acute-severe-bronchospasm-fatigue',
    title = 'Case 6 -- Acute Severe Bronchospasm Fatigue',
    intro_text = 'Adult presents with escalating wheeze, chest tightness, and increasing exhaustion despite home inhaler use.',
    description = 'Branching case emphasizing early bronchodilator strategy, reassessment, and timely escalation.',
    stem = 'Rapidly worsening lower-airway obstruction with risk of ventilatory failure.',
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
    'adult-acute-severe-bronchospasm',
    6,
    'case-6-acute-severe-bronchospasm-fatigue',
    'Case 6 -- Acute Severe Bronchospasm Fatigue',
    'Adult presents with escalating wheeze, chest tightness, and increasing exhaustion despite home inhaler use.',
    'Branching case emphasizing early bronchodilator strategy, reassessment, and timely escalation.',
    'Rapidly worsening lower-airway obstruction with risk of ventilatory failure.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case6_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":128,"rr":36,"spo2":82,"bp_sys":168,"bp_dia":96}'::jsonb
where id in (select id from _case6_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case6_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case6_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case6_target)
);

delete from public.cse_steps
where case_id in (select id from _case6_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'A 29-year-old female presents with severe wheezing and chest tightness after two days of worsening symptoms. She can only speak 2-3 words per breath and appears exhausted. SpO2 is 82% on room air. SELECT AS MANY AS INDICATED (MAX 4). What immediate actions are indicated?', 4, 'STOP' from _case6_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. What is your FIRST respiratory treatment approach now?', null, 'STOP' from _case6_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). 30 minutes after initial treatment, what reassessment should direct next steps?', 3, 'STOP' from _case6_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. Work of breathing remains extreme and speech declines. What is the best escalation?', null, 'STOP' from _case6_target
  union all
  select id, 5, 5, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). Following escalation, what ongoing management is indicated?', 3, 'STOP' from _case6_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the most appropriate disposition after initial stabilization?', null, 'STOP' from _case6_target
  returning id, step_order
)
insert into _case6_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Apply oxygen and continuous monitoring immediately', 2, 'Critical first step in severe hypoxemia.' from _case6_steps s where s.step_order = 1
union all select s.id, 'B', 'Initiate repeated bronchodilator delivery promptly', 2, 'Targets reversible airflow obstruction early.' from _case6_steps s where s.step_order = 1
union all select s.id, 'C', 'Establish IV access for adjunct therapy readiness', 1, 'Supports timely escalation.' from _case6_steps s where s.step_order = 1
union all select s.id, 'D', 'Delay treatment until chest imaging is completed', -2, 'Unsafe delay during severe distress.' from _case6_steps s where s.step_order = 1
union all select s.id, 'E', 'Sedate patient to reduce tachypnea before stabilization', -2, 'Can worsen respiratory failure.' from _case6_steps s where s.step_order = 1

union all select s.id, 'A', 'Use aggressive bronchodilator protocol with oxygen titration', 2, 'Best immediate approach for severe bronchospasm with hypoxemia.' from _case6_steps s where s.step_order = 2
union all select s.id, 'B', 'Use low-dose therapy and wait 45 minutes', -1, 'Undertreats severity and delays response.' from _case6_steps s where s.step_order = 2
union all select s.id, 'C', 'Stop oxygen to measure baseline progression', -2, 'Dangerous de-escalation.' from _case6_steps s where s.step_order = 2
union all select s.id, 'D', 'Immediate intubation without trial of maximal medical therapy', -1, 'May be required later, but can be premature if airway still protectable.' from _case6_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend respiratory rate, pulse, and SpO2 every few minutes', 2, 'Shows treatment trajectory and failure signals.' from _case6_steps s where s.step_order = 3
union all select s.id, 'B', 'Assess ability to speak and accessory muscle burden', 2, 'Detects impending fatigue and collapse.' from _case6_steps s where s.step_order = 3
union all select s.id, 'C', 'Obtain objective airflow/gas-exchange reassessment', 1, 'Guides escalation timing.' from _case6_steps s where s.step_order = 3
union all select s.id, 'D', 'Stop reassessment once wheeze softens briefly', -2, 'Can miss silent-chest deterioration.' from _case6_steps s where s.step_order = 3
union all select s.id, 'E', 'Send for CT while still unstable', -2, 'Transport-first delay is unsafe.' from _case6_steps s where s.step_order = 3

union all select s.id, 'A', 'Start noninvasive ventilatory support while continuing bronchodilator strategy', 2, 'Appropriate escalation for worsening fatigue with ongoing obstruction.' from _case6_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue unchanged treatment despite obvious fatigue', -1, 'Fails to escalate in time.' from _case6_steps s where s.step_order = 4
union all select s.id, 'C', 'Give sedative and observe response without support change', -2, 'Risky in evolving ventilatory failure.' from _case6_steps s where s.step_order = 4
union all select s.id, 'D', 'Discontinue bronchodilators because response is slow', -2, 'Removes essential therapy prematurely.' from _case6_steps s where s.step_order = 4

union all select s.id, 'A', 'Titrate support to objective response and fatigue trend', 2, 'Matches dynamic physiology and prevents over/under-support.' from _case6_steps s where s.step_order = 5
union all select s.id, 'B', 'Continue close cardiorespiratory monitoring and repeat reassessment', 1, 'Essential for early relapse detection.' from _case6_steps s where s.step_order = 5
union all select s.id, 'C', 'Continue anti-inflammatory and bronchodilator plan per response', 2, 'Sustains recovery trajectory.' from _case6_steps s where s.step_order = 5
union all select s.id, 'D', 'Stop monitoring after first normal saturation reading', -2, 'High relapse risk remains.' from _case6_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer to low-acuity care immediately', -2, 'Premature downgrade.' from _case6_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to monitored unit with clear escalation thresholds', 2, 'Safest path after severe near-failure presentation.' from _case6_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge from ED after transient improvement', -2, 'Unsafe for current risk profile.' from _case6_steps s where s.step_order = 6
union all select s.id, 'C', 'Admit to unmonitored floor without respiratory plan', -2, 'Care level insufficient.' from _case6_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe in hallway pending bed availability without protocol', -1, 'Inadequate contingency planning.' from _case6_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","B"]'::jsonb, s2.id,
  'Immediate care slightly improves oxygenation, but severe obstruction persists.',
  '{"spo2": 5, "hr": -6, "rr": -3, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case6_steps s1 cross join _case6_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Delay and harmful actions worsen fatigue and hypoxemia rapidly.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case6_steps s1 cross join _case6_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Airflow improves modestly with better oxygenation and reduced panic.',
  '{"spo2": 6, "hr": -6, "rr": -4, "bp_sys": -3, "bp_dia": -2}'::jsonb
from _case6_steps s2 cross join _case6_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Insufficient therapy leaves persistent severe obstruction and rising fatigue.',
  '{"spo2": -5, "hr": 7, "rr": 4, "bp_sys": 4, "bp_dia": 2}'::jsonb
from _case6_steps s2 cross join _case6_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Focused reassessment catches ongoing high-risk work before collapse.',
  '{"spo2": 2, "hr": -2, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case6_steps s3 cross join _case6_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Missed warning signs allow progression toward ventilatory failure.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case6_steps s3 cross join _case6_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Escalated support improves gas exchange and reduces fatigue trajectory.',
  '{"spo2": 6, "hr": -7, "rr": -5, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case6_steps s4 cross join _case6_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Inadequate escalation leads to worsening exhaustion and unstable oxygenation.',
  '{"spo2": -7, "hr": 8, "rr": 5, "bp_sys": 5, "bp_dia": 3}'::jsonb
from _case6_steps s4 cross join _case6_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Consistent reassessment and titration stabilize trajectory for safe next-level care.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case6_steps s5 cross join _case6_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Ongoing management gaps preserve high relapse and decompensation risk.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case6_steps s5 cross join _case6_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable in monitored care with clear contingency thresholds.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case6_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: insufficient care setting leads to recurrent severe distress.',
  '{"spo2": -6, "hr": 7, "rr": 4, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case6_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE6_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case6_target);

commit;
