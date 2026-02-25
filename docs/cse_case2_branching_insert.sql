-- Exhale Academy CSE Case #2 Branching Seed (Term Infant Meconium Context)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case2_target (id uuid primary key) on commit drop;
create temporary table _case2_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-2-term-infant-meconium-transition-failure'
     or lower(coalesce(title, '')) like '%case 2%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'term-delivery-room-transition',
    case_number = 2,
    slug = 'case-2-term-infant-meconium-transition-failure',
    title = 'Case 2 -- Term Infant Transition Failure (Meconium Context)',
    intro_text = 'Term infant delivered through thick meconium-stained fluid with weak respirations and low heart rate requiring immediate priority-based stabilization.',
    description = 'Branching neonatal transition scenario emphasizing timely ventilation, reassessment, and safe disposition.',
    stem = 'Depressed term newborn requiring rapid respiratory and perfusion support in delivery room.',
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
    'term-delivery-room-transition',
    2,
    'case-2-term-infant-meconium-transition-failure',
    'Case 2 -- Term Infant Transition Failure (Meconium Context)',
    'Term infant delivered through thick meconium-stained fluid with weak respirations and low heart rate requiring immediate priority-based stabilization.',
    'Branching neonatal transition scenario emphasizing timely ventilation, reassessment, and safe disposition.',
    'Depressed term newborn requiring rapid respiratory and perfusion support in delivery room.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case2_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":84,"rr":12,"spo2":62,"bp_sys":62,"bp_dia":38}'::jsonb
where id in (select id from _case2_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case2_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case2_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case2_target)
);

delete from public.cse_steps
where case_id in (select id from _case2_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'A term male infant is delivered through thick meconium-stained fluid and is limp with weak respirations. Heart rate is 84/min and SpO2 is 62%. SELECT AS MANY AS INDICATED (MAX 4). What immediate first actions are indicated at the warmer?', 4, 'STOP' from _case2_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. Heart rate remains below 100 with weak respirations. What is your FIRST intervention now?', null, 'STOP' from _case2_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). Ventilation is not producing adequate chest rise. What corrective steps are indicated?', 3, 'STOP' from _case2_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. After effective ventilation, heart rate remains near 50. What is your NEXT action?', null, 'STOP' from _case2_target
  union all
  select id, 5, 5, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). Heart rate is now above 100 but distress persists. What ongoing management is indicated?', 3, 'STOP' from _case2_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the most appropriate disposition after initial stabilization?', null, 'STOP' from _case2_target
  returning id, step_order
)
insert into _case2_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Provide warmth, position airway, dry, and stimulate briefly', 2, 'Immediate stabilization supports transition and rapid reassessment.' from _case2_steps s where s.step_order = 1
union all select s.id, 'B', 'Quickly assess heart rate and breathing effectiveness', 2, 'Heart rate and respirations guide urgent intervention.' from _case2_steps s where s.step_order = 1
union all select s.id, 'C', 'Place right-hand pulse oximeter for trend monitoring', 1, 'Improves oxygen titration decisions.' from _case2_steps s where s.step_order = 1
union all select s.id, 'D', 'Perform routine deep tracheal suctioning before ventilation', -2, 'Routine invasive suctioning can delay effective ventilation.' from _case2_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay interventions until complete exam is finished', -2, 'Delay worsens hypoxemia and bradycardia risk.' from _case2_steps s where s.step_order = 1

union all select s.id, 'A', 'Start positive-pressure ventilation and confirm chest movement', 2, 'Best immediate treatment for poor breathing with low heart rate.' from _case2_steps s where s.step_order = 2
union all select s.id, 'B', 'Start compressions before assisted ventilation', -2, 'Ventilation correction is priority at this stage.' from _case2_steps s where s.step_order = 2
union all select s.id, 'C', 'Use blow-by oxygen only', -1, 'Insufficient for ineffective respirations.' from _case2_steps s where s.step_order = 2
union all select s.id, 'D', 'Intubate first for routine suctioning', -2, 'Adds delay before effective ventilation.' from _case2_steps s where s.step_order = 2

union all select s.id, 'A', 'Reposition head and optimize mask seal', 2, 'Commonly corrects ineffective ventilation rapidly.' from _case2_steps s where s.step_order = 3
union all select s.id, 'B', 'Briefly clear mouth and nose secretions', 1, 'Can improve airflow in obstructive secretions.' from _case2_steps s where s.step_order = 3
union all select s.id, 'C', 'Increase inspiratory pressure to obtain chest rise', 2, 'Needed when initial pressure is insufficient.' from _case2_steps s where s.step_order = 3
union all select s.id, 'D', 'Continue unchanged ineffective breaths', -2, 'Prolongs hypoventilation and bradycardia.' from _case2_steps s where s.step_order = 3
union all select s.id, 'E', 'Pause ventilation for diagnostic blood sampling', -2, 'Critical delay during active resuscitation.' from _case2_steps s where s.step_order = 3

union all select s.id, 'A', 'Begin coordinated chest compressions with ongoing ventilation support', 2, 'Appropriate escalation for persistent severe bradycardia.' from _case2_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue ventilation alone for an extended period', -1, 'Insufficient escalation for persistent severe bradycardia.' from _case2_steps s where s.step_order = 4
union all select s.id, 'C', 'Give medication before initiating compressions', -1, 'Sequence is not optimal at this point.' from _case2_steps s where s.step_order = 4
union all select s.id, 'D', 'Transfer to nursery and reassess later', -2, 'Unsafe delay during critical instability.' from _case2_steps s where s.step_order = 4

union all select s.id, 'A', 'Titrate oxygen support to target saturation trend', 2, 'Supports transition while avoiding unnecessary excess oxygen.' from _case2_steps s where s.step_order = 5
union all select s.id, 'B', 'Monitor temperature and blood glucose closely', 1, 'Prevents secondary instability.' from _case2_steps s where s.step_order = 5
union all select s.id, 'C', 'Initiate noninvasive pressure support when distress persists', 2, 'Provides needed support for ongoing work of breathing.' from _case2_steps s where s.step_order = 5
union all select s.id, 'D', 'Remove monitors once color briefly improves', -2, 'Premature de-monitoring can miss relapse.' from _case2_steps s where s.step_order = 5
union all select s.id, 'E', 'Delay respiratory support and observe', -1, 'Under-treatment can worsen fatigue and hypoxemia.' from _case2_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to monitored neonatal unit for ongoing reassessment', 2, 'Matches risk after recent instability and assisted resuscitation.' from _case2_steps s where s.step_order = 6
union all select s.id, 'B', 'Transfer immediately to routine well-baby care', -2, 'Monitoring level too low for current risk.' from _case2_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge home after brief observation', -2, 'Unsafe after depressed neonatal transition.' from _case2_steps s where s.step_order = 6
union all select s.id, 'D', 'Keep in delivery area without structured monitoring plan', -1, 'Lacks safe follow-up structure.' from _case2_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","B"]'::jsonb, s2.id,
  'Initial stabilization is efficient, but weak respirations and low heart rate persist. Ventilation support is now the priority.',
  '{"spo2": 4, "hr": -2, "rr": 2}'::jsonb
from _case2_steps s1 cross join _case2_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Time loss deepens cyanosis and lowers heart rate. Urgent ventilatory intervention is required.',
  '{"spo2": -6, "hr": -10, "rr": -3}'::jsonb
from _case2_steps s1 cross join _case2_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Assisted ventilation improves chest movement and heart rate begins to recover.',
  '{"spo2": 8, "hr": 20, "rr": 10}'::jsonb
from _case2_steps s2 cross join _case2_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate ventilatory support leads to persistent bradycardia and poor oxygenation.',
  '{"spo2": -8, "hr": -12, "rr": -2}'::jsonb
from _case2_steps s2 cross join _case2_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Corrective ventilation steps produce visible chest rise and improving perfusion.',
  '{"spo2": 6, "hr": 16, "rr": 8}'::jsonb
from _case2_steps s3 cross join _case2_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Ineffective corrections keep gas exchange poor and cardiac status fragile.',
  '{"spo2": -5, "hr": -6, "rr": -1}'::jsonb
from _case2_steps s3 cross join _case2_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Perfusion improves and heart rate rises into a safer range.',
  '{"spo2": 5, "hr": 14, "rr": 6}'::jsonb
from _case2_steps s4 cross join _case2_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Bradycardia persists with inadequate oxygenation recovery.',
  '{"spo2": -4, "hr": -8, "rr": -2}'::jsonb
from _case2_steps s4 cross join _case2_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Work of breathing eases and oxygenation trend improves with targeted support.',
  '{"spo2": 4, "hr": 8, "rr": -4}'::jsonb
from _case2_steps s5 cross join _case2_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Distress persists with inconsistent oxygenation and recurrent instability risk.',
  '{"spo2": -5, "hr": -4, "rr": 6}'::jsonb
from _case2_steps s5 cross join _case2_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: infant remains stable in monitored care with improving respiratory transition.',
  '{"spo2": 2, "hr": 4, "rr": -3}'::jsonb
from _case2_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: follow-up setting was insufficient and recurrent distress required urgent re-escalation.',
  '{"spo2": -6, "hr": -6, "rr": 8}'::jsonb
from _case2_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE2_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case2_target);

commit;
