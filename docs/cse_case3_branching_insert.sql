-- Exhale Academy CSE Case #3 Branching Seed (PACU Sudden Deterioration)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case3_target (id uuid primary key) on commit drop;
create temporary table _case3_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-3-pacu-sudden-postop-respiratory-collapse'
     or lower(coalesce(title, '')) like '%case 3%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'pacu-postop-respiratory-emergency',
    case_number = 3,
    slug = 'case-3-pacu-sudden-postop-respiratory-collapse',
    title = 'Case 3 -- PACU Sudden Postoperative Respiratory Collapse',
    intro_text = 'Adult in PACU with abrupt respiratory deterioration, worsening oxygenation, and evolving hemodynamic instability requiring rapid pattern recognition and intervention.',
    description = 'Branching PACU airway and breathing emergency simulation with high-risk delay traps.',
    stem = 'Post-op respiratory collapse requiring immediate bedside stabilization and definitive escalation.',
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
    'pacu-postop-respiratory-emergency',
    3,
    'case-3-pacu-sudden-postop-respiratory-collapse',
    'Case 3 -- PACU Sudden Postoperative Respiratory Collapse',
    'Adult in PACU with abrupt respiratory deterioration, worsening oxygenation, and evolving hemodynamic instability requiring rapid pattern recognition and intervention.',
    'Branching PACU airway and breathing emergency simulation with high-risk delay traps.',
    'Post-op respiratory collapse requiring immediate bedside stabilization and definitive escalation.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case3_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":118,"rr":30,"spo2":83,"bp_sys":146,"bp_dia":84}'::jsonb
where id in (select id from _case3_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case3_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case3_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case3_target)
);

delete from public.cse_steps
where case_id in (select id from _case3_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'A 61-year-old male in PACU after abdominal surgery becomes abruptly restless, then drowsy with noisy breathing. SpO2 is 83% and work of breathing rises quickly. SELECT AS MANY AS INDICATED (MAX 4). What immediate bedside actions are indicated?', 4, 'STOP' from _case3_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. Obstruction persists with poor ventilation. What is your FIRST intervention now?', null, 'STOP' from _case3_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). What focused reassessment should be performed immediately after assisted ventilation begins?', 3, 'STOP' from _case3_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. With sudden hypotension and absent right breath sounds, what is your NEXT intervention now?', null, 'STOP' from _case3_target
  union all
  select id, 5, 5, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). After initial decompression response, what ongoing actions are indicated?', 3, 'STOP' from _case3_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the most appropriate disposition after stabilization?', null, 'STOP' from _case3_target
  returning id, step_order
)
insert into _case3_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Call for immediate airway assistance and assign team roles', 2, 'Early coordination reduces delays in rapidly changing emergencies.' from _case3_steps s where s.step_order = 1
union all select s.id, 'B', 'Perform airway repositioning and jaw thrust', 2, 'Often improves obstructive airflow rapidly.' from _case3_steps s where s.step_order = 1
union all select s.id, 'C', 'Apply high-concentration oxygen with continuous monitoring', 2, 'Supports oxygenation while underlying cause is addressed.' from _case3_steps s where s.step_order = 1
union all select s.id, 'D', 'Send for CT before bedside stabilization', -2, 'Transport-first approach causes dangerous delay.' from _case3_steps s where s.step_order = 1
union all select s.id, 'E', 'Give additional opioid for agitation', -2, 'May worsen ventilatory drive and obstruction.' from _case3_steps s where s.step_order = 1

union all select s.id, 'A', 'Insert airway adjunct and provide assisted bag-mask ventilation', 2, 'Directly addresses airflow and ventilation failure.' from _case3_steps s where s.step_order = 2
union all select s.id, 'B', 'Continue oxygen mask only and observe', -1, 'Oxygen alone may not correct inadequate ventilation.' from _case3_steps s where s.step_order = 2
union all select s.id, 'C', 'Transfer to ward for routine observation', -2, 'Unsafe during active respiratory compromise.' from _case3_steps s where s.step_order = 2
union all select s.id, 'D', 'Give sedative before ventilation is controlled', -2, 'Sedation can precipitate arrest without airway control.' from _case3_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend capnography and pulse oximetry continuously', 1, 'Confirms true ventilation and oxygenation response.' from _case3_steps s where s.step_order = 3
union all select s.id, 'B', 'Recheck bilateral breath sounds and chest expansion', 2, 'Finds dangerous asymmetry requiring urgent action.' from _case3_steps s where s.step_order = 3
union all select s.id, 'C', 'Review sedative and opioid timing', 2, 'Medication effects can contribute to decline.' from _case3_steps s where s.step_order = 3
union all select s.id, 'D', 'Silence monitors to reduce alarm burden', -2, 'Removes critical warning data during instability.' from _case3_steps s where s.step_order = 3
union all select s.id, 'E', 'Pause reassessment for 20 minutes to observe', -2, 'Delays recognition of abrupt deterioration.' from _case3_steps s where s.step_order = 3

union all select s.id, 'A', 'Perform immediate right-sided decompression while preparing definitive drainage', 2, 'Treats obstructive physiology without delay.' from _case3_steps s where s.step_order = 4
union all select s.id, 'B', 'Obtain imaging before intervention', -2, 'Imaging-first approach delays lifesaving treatment.' from _case3_steps s where s.step_order = 4
union all select s.id, 'C', 'Increase opioid infusion and observe', -2, 'Does not correct cause and may worsen ventilation.' from _case3_steps s where s.step_order = 4
union all select s.id, 'D', 'Give fluid bolus only then reassess', -1, 'Does not resolve primary obstructive mechanism.' from _case3_steps s where s.step_order = 4

union all select s.id, 'A', 'Prepare and place definitive chest drainage', 2, 'Definitive step prevents recurrence after temporary decompression.' from _case3_steps s where s.step_order = 5
union all select s.id, 'B', 'Trend blood gas and continuous hemodynamic monitoring', 1, 'Tracks response and detects relapse early.' from _case3_steps s where s.step_order = 5
union all select s.id, 'C', 'Titrate oxygen and ventilation to measured response', 2, 'Maintains gas exchange with targeted support.' from _case3_steps s where s.step_order = 5
union all select s.id, 'D', 'Stop continuous monitoring after brief normalization', -1, 'Premature de-escalation misses recurrent instability.' from _case3_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer to floor before definitive drainage', -2, 'Premature transfer increases sudden relapse risk.' from _case3_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to ICU for close respiratory and hemodynamic monitoring', 2, 'Appropriate for high relapse risk after critical decompensation.' from _case3_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge from PACU after brief improvement', -2, 'Unsafe after recent critical deterioration.' from _case3_steps s where s.step_order = 6
union all select s.id, 'C', 'Transfer to unmonitored unit', -2, 'Monitoring level does not match acuity.' from _case3_steps s where s.step_order = 6
union all select s.id, 'D', 'Remain in PACU without escalation plan', -1, 'Lacks structured high-acuity follow-up.' from _case3_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","B"]'::jsonb, s2.id,
  'Airflow improves modestly and saturation rises, but instability persists and escalation is still required.',
  '{"spo2": 6, "hr": -6, "rr": -4, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case3_steps s1 cross join _case3_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Hypoxemia deepens and mental status declines with impending respiratory failure.',
  '{"spo2": -7, "hr": 8, "rr": 4, "bp_sys": 8, "bp_dia": 6}'::jsonb
from _case3_steps s1 cross join _case3_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Ventilation improves and oxygenation rises, allowing clearer reassessment.',
  '{"spo2": 5, "hr": -6, "rr": -6, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case3_steps s2 cross join _case3_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Ventilation remains inadequate with early hemodynamic decline.',
  '{"spo2": -8, "hr": 10, "rr": -10, "bp_sys": -18, "bp_dia": -10}'::jsonb
from _case3_steps s2 cross join _case3_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Focused reassessment reveals a dangerous asymmetric breathing pattern requiring immediate intervention.',
  '{"spo2": -2, "hr": 6, "rr": 4, "bp_sys": -8, "bp_dia": -6}'::jsonb
from _case3_steps s3 cross join _case3_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Missed reassessment opportunities allow rapid progression to critical instability.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": -14, "bp_dia": -8}'::jsonb
from _case3_steps s3 cross join _case3_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Hemodynamics and oxygenation improve rapidly after decompression.',
  '{"spo2": 8, "hr": -8, "rr": -6, "bp_sys": 14, "bp_dia": 8}'::jsonb
from _case3_steps s4 cross join _case3_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Obstructive physiology worsens with escalating shock and refractory hypoxemia.',
  '{"spo2": -10, "hr": 10, "rr": -2, "bp_sys": -20, "bp_dia": -12}'::jsonb
from _case3_steps s4 cross join _case3_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Definitive follow-through stabilizes respiratory and hemodynamic trajectory.',
  '{"spo2": 4, "hr": -6, "rr": -4, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case3_steps s5 cross join _case3_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Incomplete follow-through leads to recurrent instability and relapse risk.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case3_steps s5 cross join _case3_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable in ICU with no immediate recurrent collapse.',
  '{"spo2": 2, "hr": -3, "rr": -2, "bp_sys": 2, "bp_dia": 2}'::jsonb
from _case3_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: low-acuity disposition led to recurrent collapse and urgent re-escalation.',
  '{"spo2": -7, "hr": 8, "rr": 4, "bp_sys": -8, "bp_dia": -6}'::jsonb
from _case3_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE3_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case3_target);

commit;
