-- Exhale Academy CSE Case #8 Branching Seed (Post-Extubation Upper Airway Compromise)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case8_target (id uuid primary key) on commit drop;
create temporary table _case8_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-8-post-extubation-stridor-respiratory-risk'
     or lower(coalesce(title, '')) like '%case 8%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-post-extubation-upper-airway-risk',
    case_number = 8,
    slug = 'case-8-post-extubation-stridor-respiratory-risk',
    title = 'Case 8 -- Post-Extubation Stridor Respiratory Risk',
    intro_text = 'Recently extubated adult develops escalating noisy breathing and distress requiring immediate upper-airway rescue decisions.',
    description = 'Branching case focused on prompt post-extubation rescue strategy and timely escalation.',
    stem = 'Acute upper-airway compromise shortly after extubation.',
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
    'adult-post-extubation-upper-airway-risk',
    8,
    'case-8-post-extubation-stridor-respiratory-risk',
    'Case 8 -- Post-Extubation Stridor Respiratory Risk',
    'Recently extubated adult develops escalating noisy breathing and distress requiring immediate upper-airway rescue decisions.',
    'Branching case focused on prompt post-extubation rescue strategy and timely escalation.',
    'Acute upper-airway compromise shortly after extubation.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case8_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":118,"rr":32,"spo2":85,"bp_sys":154,"bp_dia":90}'::jsonb
where id in (select id from _case8_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case8_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case8_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case8_target)
);

delete from public.cse_steps
where case_id in (select id from _case8_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'Twenty minutes after extubation, a 58-year-old male develops inspiratory noise, increasing anxiety, and rising work of breathing. SpO2 falls to 85%. SELECT AS MANY AS INDICATED (MAX 4). What immediate actions are indicated?', 4, 'STOP' from _case8_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. What is your FIRST respiratory intervention now?', null, 'STOP' from _case8_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). After initial intervention, what reassessment and preparation actions are needed?', 3, 'STOP' from _case8_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. Distress worsens with declining oxygenation. What is the best escalation?', null, 'STOP' from _case8_target
  union all
  select id, 5, 5, 'IG', 'Ventilator is now AC/VC, VT 470 mL, RR 16/min, FiO2 0.60, PEEP 5 cmH2O. ABG after reintubation: pH 7.29, PaCO2 52 torr, PaO2 72 torr, HCO3 25 mEq/L. SELECT AS MANY AS INDICATED (MAX 3). After re-securing airway support, what ongoing management and ventilator adjustments are indicated?', 3, 'STOP' from _case8_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the safest disposition now?', null, 'STOP' from _case8_target
  returning id, step_order
)
insert into _case8_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Apply high-concentration oxygen and call for airway backup immediately', 2, 'Prioritizes oxygenation and rapid team response.' from _case8_steps s where s.step_order = 1
union all select s.id, 'B', 'Position upright and perform focused upper-airway assessment', 2, 'Can improve flow and identify progression early.' from _case8_steps s where s.step_order = 1
union all select s.id, 'C', 'Prepare difficult-airway and reintubation equipment at bedside', 2, 'Reduces rescue delay if deterioration continues.' from _case8_steps s where s.step_order = 1
union all select s.id, 'D', 'Send patient for CT to identify cause before treatment', -2, 'Transport-first delay is unsafe.' from _case8_steps s where s.step_order = 1
union all select s.id, 'E', 'Give sedative for agitation without airway plan', -2, 'Can precipitate complete obstruction.' from _case8_steps s where s.step_order = 1

union all select s.id, 'A', 'Initiate targeted post-extubation rescue therapy with close monitoring', 2, 'Best immediate attempt while preparing for failure pathway.' from _case8_steps s where s.step_order = 2
union all select s.id, 'B', 'Observe on low-flow oxygen only', -1, 'Often insufficient with escalating stridor.' from _case8_steps s where s.step_order = 2
union all select s.id, 'C', 'Remove oxygen to reassess baseline severity', -2, 'Unsafe during severe distress.' from _case8_steps s where s.step_order = 2
union all select s.id, 'D', 'Delay intervention until full diagnostic panel returns', -2, 'High-risk delay.' from _case8_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend SpO2, RR, and mental status every few minutes', 2, 'Detects impending failure early.' from _case8_steps s where s.step_order = 3
union all select s.id, 'B', 'Assess stridor intensity and speech tolerance serially', 2, 'Directly tracks airway reserve.' from _case8_steps s where s.step_order = 3
union all select s.id, 'C', 'Confirm immediate reintubation readiness and role assignments', 1, 'Shortens rescue time if decline continues.' from _case8_steps s where s.step_order = 3
union all select s.id, 'D', 'Stop monitoring once saturation briefly improves', -2, 'Misses relapse risk.' from _case8_steps s where s.step_order = 3
union all select s.id, 'E', 'Leave bedside for routine tests while unstable', -2, 'Unsafe during active airway risk.' from _case8_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed with controlled reintubation with full backup plan', 2, 'Definitive airway control is indicated with worsening failure signs.' from _case8_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue unchanged therapy despite worsening distress', -1, 'Fails to escalate.' from _case8_steps s where s.step_order = 4
union all select s.id, 'C', 'Transport patient before airway is secured', -2, 'High-risk delay.' from _case8_steps s where s.step_order = 4
union all select s.id, 'D', 'Attempt deep sedation without securing airway first', -2, 'Can cause complete collapse.' from _case8_steps s where s.step_order = 4

union all select s.id, 'A', 'Verify tube position and secure airway support parameters', 2, 'Prevents immediate recurrent instability.' from _case8_steps s where s.step_order = 5
union all select s.id, 'B', 'Continue continuous cardiorespiratory and gas-exchange reassessment', 1, 'Tracks stabilization trajectory.' from _case8_steps s where s.step_order = 5
union all select s.id, 'C', 'Adjust RR/VT for PaCO2-pH and FiO2/PEEP for PaO2 to objective response', 2, 'Targeted ventilator titration reduces secondary injury.' from _case8_steps s where s.step_order = 5
union all select s.id, 'D', 'Stop monitoring after brief normalization', -1, 'Premature de-escalation.' from _case8_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer to low-acuity unit immediately', -2, 'Unsafe downgrade.' from _case8_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to ICU for close airway and ventilatory monitoring', 2, 'Appropriate after recurrent upper-airway instability.' from _case8_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge after temporary stabilization', -2, 'Unsafe disposition.' from _case8_steps s where s.step_order = 6
union all select s.id, 'C', 'Admit to unmonitored bed', -2, 'Monitoring level is inadequate.' from _case8_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe without escalation plan', -1, 'Insufficient follow-through.' from _case8_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","B"]'::jsonb, s2.id,
  'Early actions modestly improve oxygenation, but airway risk remains high.',
  '{"spo2": 4, "hr": -4, "rr": -2, "bp_sys": -3, "bp_dia": -2}'::jsonb
from _case8_steps s1 cross join _case8_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Delay and harmful actions worsen upper-airway compromise.',
  '{"spo2": -6, "hr": 7, "rr": 4, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case8_steps s1 cross join _case8_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Initial rescue therapy temporarily improves ventilation effort and oxygenation.',
  '{"spo2": 5, "hr": -4, "rr": -3, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case8_steps s2 cross join _case8_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Insufficient treatment allows progressive fatigue and obstruction.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case8_steps s2 cross join _case8_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Focused reassessment identifies worsening trajectory in time for escalation.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case8_steps s3 cross join _case8_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Missed warning signs permit rapid respiratory decline.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case8_steps s3 cross join _case8_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Definitive airway control stabilizes gas exchange and effort.',
  '{"spo2": 7, "hr": -7, "rr": -6, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case8_steps s4 cross join _case8_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Failed escalation results in severe hypoxemia and unstable reserve.',
  '{"spo2": -8, "hr": 9, "rr": 5, "bp_sys": -8, "bp_dia": -5}'::jsonb
from _case8_steps s4 cross join _case8_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Post-airway management sustains stabilization for safe high-acuity planning.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case8_steps s5 cross join _case8_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Monitoring and titration gaps preserve high recurrence risk.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case8_steps s5 cross join _case8_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable in ICU with structured airway reassessment plan.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case8_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: low-acuity placement led to recurrent airway distress and urgent rescue.',
  '{"spo2": -6, "hr": 7, "rr": 4, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case8_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE8_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case8_target);

commit;
