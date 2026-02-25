-- Exhale Academy CSE Case #5 Branching Seed (COPD Hypercapnic Exacerbation)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case5_target (id uuid primary key) on commit drop;
create temporary table _case5_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-5-copd-hypercapnic-respiratory-fatigue'
     or lower(coalesce(title, '')) like '%case 5%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-copd-hypercapnic-exacerbation',
    disease_slug = 'copd',
    disease_track = 'critical',
    case_number = 5,
    slug = 'case-5-copd-hypercapnic-respiratory-fatigue',
    title = 'Case 5 -- COPD Hypercapnic Respiratory Fatigue',
    intro_text = 'Adult with chronic lung disease history presents with worsening dyspnea, somnolence, and rising ventilatory fatigue.',
    description = 'Branching case on oxygen titration, ventilatory support, and escalation safety in hypercapnic risk.',
    stem = 'Progressive ventilatory failure requiring targeted oxygen and support strategy.',
    difficulty = 'medium',
    is_active = true,
    is_published = true
  where c.id in (select id from existing)
  returning c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty, is_active, is_published
  )
  select
    'adult-copd-hypercapnic-exacerbation',
    'copd',
    'critical',
    5,
    'case-5-copd-hypercapnic-respiratory-fatigue',
    'Case 5 -- COPD Hypercapnic Respiratory Fatigue',
    'Adult with chronic lung disease history presents with worsening dyspnea, somnolence, and rising ventilatory fatigue.',
    'Branching case on oxygen titration, ventilatory support, and escalation safety in hypercapnic risk.',
    'Progressive ventilatory failure requiring targeted oxygen and support strategy.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case5_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":112,"rr":32,"spo2":84,"bp_sys":156,"bp_dia":92}'::jsonb
where id in (select id from _case5_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case5_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case5_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case5_target)
);

delete from public.cse_steps
where case_id in (select id from _case5_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'A 63-year-old female with longstanding obstructive lung disease has two days of worsening dyspnea and productive cough. She is drowsy, tachypneic, and speaking short phrases. SpO2 is 84% on room air. SELECT AS MANY AS INDICATED (MAX 4). What immediate priorities are indicated?', 4, 'STOP' from _case5_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. What is the best initial oxygen strategy?', null, 'STOP' from _case5_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). Which reassessment actions should guide next intervention?', 3, 'STOP' from _case5_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. CO2 rises and fatigue worsens. What is the best escalation now?', null, 'STOP' from _case5_target
  union all
  select id, 5, 5, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). After escalation, what ongoing management is indicated?', 3, 'STOP' from _case5_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the safest disposition?', null, 'STOP' from _case5_target
  returning id, step_order
)
insert into _case5_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Apply controlled oxygen and target a measured saturation range', 2, 'Balances hypoxemia correction with hypercapnia risk.' from _case5_steps s where s.step_order = 1
union all select s.id, 'B', 'Start continuous cardiorespiratory and oximetry monitoring', 1, 'Captures rapid deterioration early.' from _case5_steps s where s.step_order = 1
union all select s.id, 'C', 'Obtain focused respiratory exam and baseline blood gas promptly', 2, 'Defines severity and supports escalation decisions.' from _case5_steps s where s.step_order = 1
union all select s.id, 'D', 'Give 100% oxygen without reassessment plan', -2, 'Untargeted high oxygen can worsen CO2 retention risk.' from _case5_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay treatment until chest imaging is complete', -2, 'Critical delay in unstable ventilation.' from _case5_steps s where s.step_order = 1

union all select s.id, 'A', 'Use controlled oxygen delivery with frequent titration', 2, 'Appropriate first-line strategy in this pattern.' from _case5_steps s where s.step_order = 2
union all select s.id, 'B', 'Use no oxygen to avoid CO2 rise', -2, 'Withholding oxygen in hypoxemia is unsafe.' from _case5_steps s where s.step_order = 2
union all select s.id, 'C', 'Use maximal oxygen continuously without targets', -2, 'Over-treatment may worsen ventilation mismatch.' from _case5_steps s where s.step_order = 2
union all select s.id, 'D', 'Observe without oxygen while awaiting labs', -2, 'Unsafe delay with critical hypoxemia.' from _case5_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend mental status, respiratory rate, and accessory muscle use', 2, 'Identifies impending ventilatory failure.' from _case5_steps s where s.step_order = 3
union all select s.id, 'B', 'Repeat blood gas after initial stabilization interval', 1, 'Measures response and CO2 trajectory.' from _case5_steps s where s.step_order = 3
union all select s.id, 'C', 'Assess secretion burden and airway clearance ability', 1, 'Important for support strategy and tolerance.' from _case5_steps s where s.step_order = 3
union all select s.id, 'D', 'Stop monitoring once saturation briefly reaches target', -2, 'Misses rebound hypercapnia and fatigue.' from _case5_steps s where s.step_order = 3
union all select s.id, 'E', 'Give sedative for anxiety before ventilation is supported', -2, 'Can suppress respiratory drive during decompensation.' from _case5_steps s where s.step_order = 3

union all select s.id, 'A', 'Initiate noninvasive ventilation with close tolerance checks', 2, 'Appropriate escalation for hypercapnic fatigue with preserved airway reflexes.' from _case5_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue oxygen only despite rising CO2 and fatigue', -1, 'Fails to address inadequate ventilation.' from _case5_steps s where s.step_order = 4
union all select s.id, 'C', 'Delay support and repeat labs later', -2, 'Dangerous delay in worsening ventilatory failure.' from _case5_steps s where s.step_order = 4
union all select s.id, 'D', 'Immediate intubation without NIV trial when stable enough for NIV', -1, 'May be needed later, but can be premature first escalation.' from _case5_steps s where s.step_order = 4

union all select s.id, 'A', 'Adjust interface/settings to optimize synchrony and tidal response', 2, 'Improves NIV success and comfort.' from _case5_steps s where s.step_order = 5
union all select s.id, 'B', 'Continue bronchodilator and secretion management plan', 1, 'Addresses reversible obstruction contributors.' from _case5_steps s where s.step_order = 5
union all select s.id, 'C', 'Reassess blood gas and work of breathing after adjustments', 2, 'Confirms objective response.' from _case5_steps s where s.step_order = 5
union all select s.id, 'D', 'Set fixed oxygen and stop reassessing once improved', -1, 'Untargeted continuation risks relapse.' from _case5_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer out of monitored care immediately', -2, 'Premature downgrade.' from _case5_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to monitored high-acuity unit with respiratory reassessment plan', 2, 'Safest for ongoing ventilatory risk.' from _case5_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge after transient gas-exchange improvement', -2, 'Unsafe after recent instability.' from _case5_steps s where s.step_order = 6
union all select s.id, 'C', 'Transfer to unmonitored floor', -2, 'Monitoring level too low.' from _case5_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe in ED hallway without structured escalation path', -1, 'Insufficient follow-through for risk level.' from _case5_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","C"]'::jsonb, s2.id,
  'Early targeted actions modestly improve oxygenation and reduce immediate panic.',
  '{"spo2": 4, "hr": -4, "rr": -2, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case5_steps s1 cross join _case5_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Over-oxygenation or delay worsens gas-exchange mismatch and fatigue.',
  '{"spo2": -4, "hr": 6, "rr": 3, "bp_sys": 4, "bp_dia": 2}'::jsonb
from _case5_steps s1 cross join _case5_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Controlled oxygen strategy improves saturation with less ventilatory strain.',
  '{"spo2": 5, "hr": -5, "rr": -3, "bp_sys": -3, "bp_dia": -2}'::jsonb
from _case5_steps s2 cross join _case5_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate oxygen strategy leaves persistent hypoxemia and fatigue.',
  '{"spo2": -5, "hr": 7, "rr": 4, "bp_sys": 4, "bp_dia": 2}'::jsonb
from _case5_steps s2 cross join _case5_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Focused reassessment identifies worsening ventilation before collapse.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case5_steps s3 cross join _case5_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Missed reassessment delays escalation and accelerates respiratory fatigue.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case5_steps s3 cross join _case5_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'NIV support improves ventilation and eases work of breathing.',
  '{"spo2": 6, "hr": -6, "rr": -5, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case5_steps s4 cross join _case5_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Ventilatory failure progresses with worsening hypercapnic burden.',
  '{"spo2": -7, "hr": 8, "rr": 5, "bp_sys": 5, "bp_dia": 3}'::jsonb
from _case5_steps s4 cross join _case5_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Targeted follow-through sustains improvement and reduces relapse risk.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case5_steps s5 cross join _case5_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Management gaps leave unstable reserve and recurrent deterioration risk.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case5_steps s5 cross join _case5_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable in monitored care with continued respiratory reassessment.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case5_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: low-acuity disposition leads to rapid recurrence of respiratory failure signs.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case5_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE5_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case5_target);

commit;
