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
    description = 'Branching ventilator emergency case focused on sudden desaturation, unilateral breath sounds, and bedside treatment of acute obstructive thoracic deterioration.',
    stem = 'Abrupt deterioration in a mechanically ventilated adult requiring immediate bedside assessment and intervention.',
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
    'Branching ventilator emergency case focused on sudden desaturation, unilateral breath sounds, and bedside treatment of acute obstructive thoracic deterioration.',
    'Abrupt deterioration in a mechanically ventilated adult requiring immediate bedside assessment and intervention.',
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

delete from public.cse_attempt_events
where attempt_id in (
  select a.id
  from public.cse_attempts a
  where a.case_id in (select id from _case9_target)
)
or step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case9_target)
)
or outcome_id in (
  select o.id
  from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case9_target)
);

delete from public.cse_attempts
where case_id in (select id from _case9_target);

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
  select id, 1, 1, 'IG', 'A 54-year-old woman in the ICU is receiving AC/VC ventilation with VT 460 mL, rate 16/min, FIO2 0.60, and PEEP 5 cm H2O. The high-pressure alarm sounds and SpO2 falls to 86%. Blood pressure is decreasing, and breath sounds are reduced on the right. Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).', 3, 'STOP' from _case9_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. Which of the following should be done FIRST?', null, 'STOP' from _case9_target
  union all
  select id, 3, 3, 'IG', 'Manual ventilation is difficult. Right breath sounds remain markedly decreased, and blood pressure continues to fall. Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).', 3, 'STOP' from _case9_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. Which of the following should be recommended now?', null, 'STOP' from _case9_target
  union all
  select id, 5, 5, 'IG', 'After decompression, ventilator settings are AC/VC, VT 430 mL, rate 18/min, FIO2 0.50, and PEEP 5 cm H2O. ABG analysis reveals pH 7.30, PaCO2 50 torr, PaO2 74 torr, and HCO3 24 mEq/L. Which of the following should be recommended now? SELECT AS MANY AS INDICATED (MAX 3).', 3, 'STOP' from _case9_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. Which of the following is the most appropriate disposition?', null, 'STOP' from _case9_target
  returning id, step_order
)
insert into _case9_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Assess endotracheal tube position, patency, and circuit connections', 2, 'This evaluates common reversible causes of high-pressure alarms.' from _case9_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess bilateral breath sounds and chest movement', 2, 'This helps identify unilateral thoracic abnormalities.' from _case9_steps s where s.step_order = 1
union all select s.id, 'C', 'Assess blood pressure, heart rate, and oxygen saturation continuously', 2, 'This measures the severity of the deterioration.' from _case9_steps s where s.step_order = 1
union all select s.id, 'D', 'Obtain a CT scan before bedside intervention', -2, 'This delays treatment during hemodynamic instability.' from _case9_steps s where s.step_order = 1
union all select s.id, 'E', 'Wait for the next ventilator alarm cycle before reassessing', -2, 'This delays recognition of a life-threatening problem.' from _case9_steps s where s.step_order = 1

union all select s.id, 'A', 'Disconnect from the ventilator and ventilate manually with 100% oxygen', 2, 'This is the best immediate maneuver during sudden ventilator deterioration.' from _case9_steps s where s.step_order = 2
union all select s.id, 'B', 'Increase PEEP and observe the response', -1, 'This does not address the likely cause of the instability.' from _case9_steps s where s.step_order = 2
union all select s.id, 'C', 'Continue the current ventilator settings and wait for repeat ABG results', -2, 'This delays urgent bedside intervention.' from _case9_steps s where s.step_order = 2
union all select s.id, 'D', 'Extubate the patient immediately', -2, 'This is not indicated in an unstable intubated patient.' from _case9_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess right and left breath sounds', 2, 'This confirms persistent unilateral findings.' from _case9_steps s where s.step_order = 3
union all select s.id, 'B', 'Reassess tube patency and pass a suction catheter', 2, 'This helps exclude endotracheal tube obstruction.' from _case9_steps s where s.step_order = 3
union all select s.id, 'C', 'Reassess blood pressure, heart rate, and oxygen saturation', 2, 'This identifies worsening hemodynamic compromise.' from _case9_steps s where s.step_order = 3
union all select s.id, 'D', 'Wait for a portable chest radiograph before further action', -2, 'This delays treatment of a likely tension pneumothorax.' from _case9_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop manual ventilation after the saturation rises briefly', -2, 'This can worsen deterioration before the cause is treated.' from _case9_steps s where s.step_order = 3

union all select s.id, 'A', 'Perform immediate pleural decompression', 2, 'This is indicated for suspected tension pneumothorax with hypotension.' from _case9_steps s where s.step_order = 4
union all select s.id, 'B', 'Obtain a chest radiograph before intervention', -2, 'This delays definitive treatment.' from _case9_steps s where s.step_order = 4
union all select s.id, 'C', 'Administer a fluid bolus and continue observation', -1, 'This does not treat the primary cause of the instability.' from _case9_steps s where s.step_order = 4
union all select s.id, 'D', 'Increase sedation and continue mechanical ventilation', -2, 'This does not relieve the obstructive process.' from _case9_steps s where s.step_order = 4

union all select s.id, 'A', 'Insert a thoracostomy tube', 2, 'This provides definitive treatment after emergency decompression.' from _case9_steps s where s.step_order = 5
union all select s.id, 'B', 'Decrease FIO2 as tolerated to maintain adequate oxygenation', 2, 'This is appropriate after oxygenation improves.' from _case9_steps s where s.step_order = 5
union all select s.id, 'C', 'Continue close hemodynamic and oxygenation monitoring', 1, 'This is indicated after a critical ventilator emergency.' from _case9_steps s where s.step_order = 5
union all select s.id, 'D', 'Transfer to a low-acuity area once the blood pressure improves', -2, 'This is premature after recent decompensation.' from _case9_steps s where s.step_order = 5
union all select s.id, 'E', 'Stop reassessment after the first improved ABG', -1, 'This can miss recurrent deterioration.' from _case9_steps s where s.step_order = 5

union all select s.id, 'A', 'Continue ICU monitoring', 2, 'This is the most appropriate disposition after a ventilator emergency.' from _case9_steps s where s.step_order = 6
union all select s.id, 'B', 'Transfer to an unmonitored floor bed', -2, 'This level of care is insufficient.' from _case9_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge from the ICU after brief stabilization', -2, 'This is unsafe after recent critical deterioration.' from _case9_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe without a defined monitoring plan', -1, 'This does not provide adequate follow-through.' from _case9_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","B"]'::jsonb, s2.id,
  'Right breath sounds remain decreased, and blood pressure continues to fall.',
  '{"spo2": 5, "hr": -4, "rr": -2, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case9_steps s1 cross join _case9_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'SpO2 falls further, and hypotension worsens.',
  '{"spo2": -6, "hr": 7, "rr": 4, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case9_steps s1 cross join _case9_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Manual ventilation is difficult, but oxygenation improves briefly.',
  '{"spo2": 6, "hr": -5, "rr": -3, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case9_steps s2 cross join _case9_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Manual ventilation remains difficult, and hypotension worsens.',
  '{"spo2": -5, "hr": 7, "rr": 4, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case9_steps s2 cross join _case9_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Manual ventilation remains difficult. Right breath sounds are absent, and blood pressure continues to fall.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case9_steps s3 cross join _case9_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Right breath sounds remain absent. SpO2 remains low, and hypotension worsens.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case9_steps s3 cross join _case9_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Right breath sounds improve, and blood pressure increases.',
  '{"spo2": 7, "hr": -7, "rr": -5, "bp_sys": 10, "bp_dia": 6}'::jsonb
from _case9_steps s4 cross join _case9_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'SpO2 falls further, and blood pressure continues to drop.',
  '{"spo2": -8, "hr": 9, "rr": 5, "bp_sys": -10, "bp_dia": -6}'::jsonb
from _case9_steps s4 cross join _case9_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Chest tube placement is followed by improved oxygenation and hemodynamic stability.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case9_steps s5 cross join _case9_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Oxygenation worsens again, and hypotension recurs.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case9_steps s5 cross join _case9_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'The patient remains stable in the ICU without recurrent hemodynamic collapse.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case9_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'The patient develops recurrent hypoxemia and hypotension.',
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
