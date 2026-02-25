-- Exhale Academy CSE Case #9 Branching Seed (Ventilator-Associated Sudden Deterioration)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case9_target (id uuid primary key) on commit drop;
create temporary table _case9_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-9-mechanically-ventilated-sudden-desaturation'
     or lower(coalesce(title, '')) like '%case 9%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-ventilator-associated-deterioration',
    case_number = 9,
    slug = 'case-9-mechanically-ventilated-sudden-desaturation',
    title = 'Case 9 -- Mechanically Ventilated Sudden Desaturation',
    intro_text = 'Intubated ICU patient develops abrupt hypoxemia, rising airway pressures, and hemodynamic instability requiring immediate ventilator troubleshooting.',
    description = 'Branching ventilator emergency case emphasizing bedside causes-first response and escalation safety.',
    stem = 'Acute deterioration in a ventilated adult requiring rapid structured troubleshooting.',
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
    'adult-ventilator-associated-deterioration',
    9,
    'case-9-mechanically-ventilated-sudden-desaturation',
    'Case 9 -- Mechanically Ventilated Sudden Desaturation',
    'Intubated ICU patient develops abrupt hypoxemia, rising airway pressures, and hemodynamic instability requiring immediate ventilator troubleshooting.',
    'Branching ventilator emergency case emphasizing bedside causes-first response and escalation safety.',
    'Acute deterioration in a ventilated adult requiring rapid structured troubleshooting.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case9_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":122,"rr":30,"spo2":86,"bp_sys":108,"bp_dia":66}'::jsonb
where id in (select id from _case9_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case9_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case9_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case9_target)
);

delete from public.cse_steps
where case_id in (select id from _case9_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'You are called to bedside for a 54-year-old female in the ICU on mechanical ventilation who suddenly desaturates and triggers high-pressure alarms. Current settings: AC/VC, VT 460 mL, RR 16/min, FiO2 0.60, PEEP 5 cmH2O. ABG now: pH 7.25, PaCO2 58 torr, PaO2 54 torr, HCO3 25 mEq/L. Breath sounds now seem reduced on one side and blood pressure is falling. What are your next steps? SELECT AS MANY AS INDICATED (MAX 4).', 4, 'STOP' from _case9_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. What is your FIRST maneuver now?', null, 'STOP' from _case9_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). After initial maneuver, what focused reassessment is most important?', 3, 'STOP' from _case9_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. Findings suggest acute unilateral obstructive thoracic process with hypotension. What is your NEXT action?', null, 'STOP' from _case9_target
  union all
  select id, 5, 5, 'IG', 'After immediate rescue, ventilator settings are AC/VC, VT 430 mL, RR 18/min, FiO2 0.50, PEEP 5 cmH2O. ABG repeat: pH 7.30, PaCO2 50 torr, PaO2 74 torr, HCO3 24 mEq/L. SELECT AS MANY AS INDICATED (MAX 3). What ongoing management and ventilator adjustments are indicated?', 3, 'STOP' from _case9_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the safest disposition now?', null, 'STOP' from _case9_target
  returning id, step_order
)
insert into _case9_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Increase FiO2 and call for immediate bedside support', 2, 'Buys oxygen reserve while troubleshooting.' from _case9_steps s where s.step_order = 1
union all select s.id, 'B', 'Disconnect from ventilator and assess with manual bag ventilation', 2, 'Rapidly distinguishes ventilator/circuit vs patient issue.' from _case9_steps s where s.step_order = 1
union all select s.id, 'C', 'Check tube depth, patency, and circuit integrity', 2, 'Targets common reversible causes quickly.' from _case9_steps s where s.step_order = 1
union all select s.id, 'D', 'Send for CT before bedside stabilization', -2, 'Unsafe delay during active instability.' from _case9_steps s where s.step_order = 1
union all select s.id, 'E', 'Silence alarms and observe for 10 minutes', -2, 'Misses life-threatening progression.' from _case9_steps s where s.step_order = 1

union all select s.id, 'A', 'Begin manual ventilation while troubleshooting resistance/compliance', 2, 'Best immediate control and diagnostic maneuver.' from _case9_steps s where s.step_order = 2
union all select s.id, 'B', 'Continue unchanged ventilator settings and wait', -1, 'Delays critical intervention.' from _case9_steps s where s.step_order = 2
union all select s.id, 'C', 'Extubate immediately without plan', -2, 'Dangerous and unstructured.' from _case9_steps s where s.step_order = 2
union all select s.id, 'D', 'Stop oxygen briefly to reassess baseline', -2, 'Unsafe in severe desaturation.' from _case9_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess bilateral breath sounds and chest movement urgently', 2, 'Identifies asymmetry and major cause clues.' from _case9_steps s where s.step_order = 3
union all select s.id, 'B', 'Trend BP, HR, and oxygenation continuously', 1, 'Tracks hemodynamic collapse risk.' from _case9_steps s where s.step_order = 3
union all select s.id, 'C', 'Evaluate tube patency and suction for obstruction', 2, 'Addresses common reversible ventilatory failure causes.' from _case9_steps s where s.step_order = 3
union all select s.id, 'D', 'Pause reassessment after brief saturation rise', -2, 'Can miss rebound instability.' from _case9_steps s where s.step_order = 3
union all select s.id, 'E', 'Delay action until full imaging report returns', -2, 'Dangerous in unstable ventilation and perfusion.' from _case9_steps s where s.step_order = 3

union all select s.id, 'A', 'Perform immediate decompression while preparing definitive drainage', 2, 'Treats life-threatening obstructive physiology promptly.' from _case9_steps s where s.step_order = 4
union all select s.id, 'B', 'Give fluid bolus only and observe', -1, 'Does not resolve primary cause.' from _case9_steps s where s.step_order = 4
union all select s.id, 'C', 'Obtain imaging before intervention', -2, 'Imaging-first delay can be fatal.' from _case9_steps s where s.step_order = 4
union all select s.id, 'D', 'Increase sedation without addressing cause', -2, 'Worsens instability risk.' from _case9_steps s where s.step_order = 4

union all select s.id, 'A', 'Place definitive thoracic drainage and verify ventilatory improvement', 2, 'Prevents recurrence after temporary rescue.' from _case9_steps s where s.step_order = 5
union all select s.id, 'B', 'Retitrate RR/VT for PaCO2-pH and FiO2/PEEP for PaO2 to measured response', 2, 'Matches ventilator support to objective physiology.' from _case9_steps s where s.step_order = 5
union all select s.id, 'C', 'Continue close hemodynamic and gas-exchange monitoring', 1, 'Detects relapse early.' from _case9_steps s where s.step_order = 5
union all select s.id, 'D', 'Stop monitoring after first improvement', -1, 'Premature de-escalation.' from _case9_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer to low-acuity area immediately', -2, 'Unsafe downgrade.' from _case9_steps s where s.step_order = 5

union all select s.id, 'A', 'Maintain ICU-level monitoring with structured reassessment plan', 2, 'Appropriate after critical ventilator emergency.' from _case9_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge from ICU after brief stabilization', -2, 'Unsafe disposition.' from _case9_steps s where s.step_order = 6
union all select s.id, 'C', 'Transfer to unmonitored floor', -2, 'Inadequate care level for current risk.' from _case9_steps s where s.step_order = 6
union all select s.id, 'D', 'Hold without escalation protocol', -1, 'Insufficient follow-through.' from _case9_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","B"]'::jsonb, s2.id,
  'Immediate priorities improve oxygen reserve while troubleshooting begins.',
  '{"spo2": 5, "hr": -4, "rr": -2, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case9_steps s1 cross join _case9_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Delay causes worsening hypoxemia and hemodynamic decline.',
  '{"spo2": -6, "hr": 7, "rr": 4, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case9_steps s1 cross join _case9_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Manual ventilation clarifies mechanics and improves immediate oxygenation.',
  '{"spo2": 6, "hr": -5, "rr": -3, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case9_steps s2 cross join _case9_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate action worsens ventilatory failure and perfusion.',
  '{"spo2": -5, "hr": 7, "rr": 4, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case9_steps s2 cross join _case9_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Focused reassessment identifies high-risk unilateral process promptly.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case9_steps s3 cross join _case9_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Missed signals allow progression to critical obstructive instability.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case9_steps s3 cross join _case9_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Immediate decompression improves oxygenation and blood pressure.',
  '{"spo2": 7, "hr": -7, "rr": -5, "bp_sys": 10, "bp_dia": 6}'::jsonb
from _case9_steps s4 cross join _case9_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Delayed cause treatment results in worsening shock and refractory hypoxemia.',
  '{"spo2": -8, "hr": 9, "rr": 5, "bp_sys": -10, "bp_dia": -6}'::jsonb
from _case9_steps s4 cross join _case9_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Definitive follow-through stabilizes ventilatory and hemodynamic trajectory.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case9_steps s5 cross join _case9_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Incomplete follow-through leaves high relapse risk.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case9_steps s5 cross join _case9_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable in ICU with no immediate recurrent collapse.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case9_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: low-acuity plan led to recurrent critical deterioration.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": -8, "bp_dia": -5}'::jsonb
from _case9_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE9_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case9_target);

commit;
