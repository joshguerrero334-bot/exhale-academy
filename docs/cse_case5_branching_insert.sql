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
    intro_text = 'Adult with severe COPD exacerbation presents with hypoxemia, somnolence, and rising ventilatory fatigue.',
    description = 'Branching case focused on controlled oxygen, recognition of hypercapnic ventilatory failure, and timely initiation of noninvasive ventilation.',
    stem = 'Acute COPD exacerbation with hypercapnia, fatigue, and need for ventilatory support.',
    difficulty = 'hard',
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
    'Adult with severe COPD exacerbation presents with hypoxemia, somnolence, and rising ventilatory fatigue.',
    'Branching case focused on controlled oxygen, recognition of hypercapnic ventilatory failure, and timely initiation of noninvasive ventilation.',
    'Acute COPD exacerbation with hypercapnia, fatigue, and need for ventilatory support.',
    'hard',
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

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case5_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case5_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case5_target)
);

delete from public.cse_attempts where case_id in (select id from _case5_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case5_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case5_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case5_target));
delete from public.cse_steps where case_id in (select id from _case5_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG',
    'A 63-year-old woman with severe COPD comes to the emergency department because of worsening dyspnea and productive cough for 2 days.

While breathing room air, the following are noted:
HR 112/min
RR 32/min
BP 156/92 mm Hg
SpO2 84%

She is drowsy and speaks in short phrases.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3,
    'STOP'
  from _case5_target
  union all
  select id, 2, 2, 'DM',
    'Breath sounds reveal diffuse rhonchi and diminished breath sounds bilaterally. Which of the following should be recommended FIRST?',
    null,
    'STOP'
  from _case5_target
  union all
  select id, 3, 3, 'IG',
    'Thirty minutes after controlled oxygen and bronchodilator therapy are started, the patient remains drowsy.

While receiving O2 by Venturi mask at an FIO2 of 0.28, the following are noted:
HR 108/min
RR 30/min
BP 150/88 mm Hg
SpO2 88%

ABG analysis reveals:
pH 7.28
PaCO2 68 torr
PaO2 56 torr
HCO3- 31 mEq/L

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3,
    'STOP'
  from _case5_target
  union all
  select id, 4, 4, 'DM',
    'The patient becomes more somnolent and continues to use accessory muscles. Which of the following should be recommended now?',
    null,
    'STOP'
  from _case5_target
  union all
  select id, 5, 5, 'IG',
    'One hour after bilevel positive airway pressure is started, the patient is receiving IPAP 14 cm H2O, EPAP 6 cm H2O, and FIO2 0.30.

The following are noted:
HR 102/min
RR 26/min
BP 146/84 mm Hg
SpO2 91%

ABG analysis reveals:
pH 7.31
PaCO2 60 torr
PaO2 62 torr
HCO3- 30 mEq/L

Which of the following should be evaluated or adjusted now? SELECT AS MANY AS INDICATED (MAX 3).',
    3,
    'STOP'
  from _case5_target
  union all
  select id, 6, 6, 'DM',
    'The patient is more alert and synchronizing with bilevel positive airway pressure. Which of the following should be recommended postadmission?',
    null,
    'STOP'
  from _case5_target
  returning id, step_order
)
insert into _case5_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Mental status and ability to protect the airway', 2, 'This is indicated to assess ventilatory failure severity.' from _case5_steps s where s.step_order = 1
union all select s.id, 'B', 'Breath sounds and work of breathing', 2, 'This helps assess severity of obstruction and fatigue.' from _case5_steps s where s.step_order = 1
union all select s.id, 'C', 'Pulse oximetry and vital signs', 2, 'This is indicated to assess current severity and trend.' from _case5_steps s where s.step_order = 1
union all select s.id, 'D', 'Complete pulmonary function testing', -3, 'This is not indicated in the current condition.' from _case5_steps s where s.step_order = 1
union all select s.id, 'E', 'Exercise oximetry', -3, 'This delays urgent care.' from _case5_steps s where s.step_order = 1

union all select s.id, 'A', 'Administer controlled oxygen by Venturi mask', 3, 'This is the best first step in severe hypoxemia with COPD.' from _case5_steps s where s.step_order = 2
union all select s.id, 'B', 'Administer 100% oxygen by nonrebreathing mask', -2, 'This may worsen hypercapnia and is not the best first choice.' from _case5_steps s where s.step_order = 2
union all select s.id, 'C', 'Withhold oxygen because of chronic CO2 retention', -3, 'This is not appropriate in severe hypoxemia.' from _case5_steps s where s.step_order = 2
union all select s.id, 'D', 'Proceed directly to endotracheal intubation', -1, 'This may become necessary later, but controlled oxygen should be started immediately.' from _case5_steps s where s.step_order = 2

union all select s.id, 'A', 'Mental status', 2, 'This is indicated to detect worsening ventilatory fatigue.' from _case5_steps s where s.step_order = 3
union all select s.id, 'B', 'ABG trend', 2, 'This is indicated to assess worsening hypercapnia and acidosis.' from _case5_steps s where s.step_order = 3
union all select s.id, 'C', 'Secretion burden and cough effectiveness', 2, 'This affects tolerance of noninvasive ventilation.' from _case5_steps s where s.step_order = 3
union all select s.id, 'D', 'Cardiopulmonary exercise testing', -3, 'This is not indicated in the current condition.' from _case5_steps s where s.step_order = 3
union all select s.id, 'E', 'Discharge planning', -3, 'This is clearly premature.' from _case5_steps s where s.step_order = 3

union all select s.id, 'A', 'Begin bilevel positive airway pressure', 3, 'This is indicated for hypercapnic ventilatory failure with worsening fatigue.' from _case5_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue the same treatment and repeat the ABG later', -3, 'This delays indicated ventilatory support.' from _case5_steps s where s.step_order = 4
union all select s.id, 'C', 'Discontinue oxygen and observe', -3, 'This is not appropriate.' from _case5_steps s where s.step_order = 4
union all select s.id, 'D', 'Proceed directly to intubation', -1, 'This may be required if noninvasive ventilation fails, but it is not the best next step yet.' from _case5_steps s where s.step_order = 4

union all select s.id, 'A', 'Repeat ABG analysis', 2, 'This is indicated to assess ventilatory response.' from _case5_steps s where s.step_order = 5
union all select s.id, 'B', 'Adjust IPAP or backup rate if PaCO2 remains elevated', 2, 'This helps improve ventilation.' from _case5_steps s where s.step_order = 5
union all select s.id, 'C', 'Check mask fit and patient synchrony', 2, 'This is important for noninvasive ventilation success.' from _case5_steps s where s.step_order = 5
union all select s.id, 'D', 'Discontinue bilevel positive airway pressure because SpO2 improved', -3, 'This is premature.' from _case5_steps s where s.step_order = 5
union all select s.id, 'E', 'Reduce oxygen to room air immediately', -2, 'This is not indicated.' from _case5_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to the ICU for continued noninvasive ventilatory management and reassessment', 3, 'This is the appropriate level of care after severe hypercapnic respiratory failure.' from _case5_steps s where s.step_order = 6
union all select s.id, 'B', 'Transfer to an unmonitored medical floor', -3, 'This is not the appropriate level of care.' from _case5_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge home after the next ABG', -3, 'This is unsafe.' from _case5_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe in the emergency department without admission', -3, 'This is not the appropriate disposition.' from _case5_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Breath sounds remain diminished, and the patient remains drowsy with persistent hypoxemia.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case5_steps s1 cross join _case5_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. The patient becomes more fatigued, and hypoxemia persists.',
  '{"spo2": -2, "hr": 4, "rr": 2, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case5_steps s1 cross join _case5_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Oxygenation improves slightly, but dyspnea and somnolence persist.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case5_steps s2 cross join _case5_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Gas exchange remains unstable, and the patient becomes more somnolent.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case5_steps s2 cross join _case5_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'PaCO2 remains elevated, and work of breathing continues to increase.',
  '{"spo2": -1, "hr": 2, "rr": 1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case5_steps s3 cross join _case5_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed. Somnolence and hypercapnia worsen.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case5_steps s3 cross join _case5_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'The patient becomes more synchronous with ventilatory support, and oxygenation improves.',
  '{"spo2": 5, "hr": -5, "rr": -4, "bp_sys": -3, "bp_dia": -2}'::jsonb
from _case5_steps s4 cross join _case5_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Ventilatory failure worsens, and the patient becomes more difficult to arouse.',
  '{"spo2": -6, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case5_steps s4 cross join _case5_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'pH and PaCO2 begin to improve, and the patient is more alert.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case5_steps s5 cross join _case5_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Gas exchange remains unstable, and close monitoring is still required.',
  '{"spo2": -3, "hr": 4, "rr": 2, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case5_steps s5 cross join _case5_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is admitted for ongoing noninvasive ventilatory support and reassessment.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case5_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: inadequate level of care leads to recurrent hypercapnic respiratory failure.',
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
