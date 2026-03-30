-- Exhale Academy CSE Branching Seed (Post-Extubation Upper Airway Compromise)
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
    description = 'Branching case focused on rapid recognition of post-extubation upper-airway compromise and timely escalation.',
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
    'Branching case focused on rapid recognition of post-extubation upper-airway compromise and timely escalation.',
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

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case8_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case8_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case8_target)
);

delete from public.cse_attempts where case_id in (select id from _case8_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case8_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case8_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case8_target));
delete from public.cse_steps where case_id in (select id from _case8_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'Twenty minutes after extubation, a 58-year-old man develops inspiratory stridor and increasing respiratory distress.

While receiving O2 by aerosol mask at an FIO2 of 0.40, the following are noted:
HR 118/min
RR 32/min
BP 154/90 mm Hg
SpO2 85%

He is anxious and using accessory muscles.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case8_target
  union all
  select id, 2, 2, 'DM',
    'Inspiratory stridor persists, and work of breathing is increasing. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case8_target
  union all
  select id, 3, 3, 'IG',
    'After initial therapy, stridor improves briefly but returns.

While receiving O2 by aerosol mask at an FIO2 of 0.50, the following are noted:
HR 122/min
RR 34/min
BP 150/88 mm Hg
SpO2 87%

The patient is able to speak only single words.

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case8_target
  union all
  select id, 4, 4, 'DM',
    'Respiratory distress worsens, and oxygenation continues to fall. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case8_target
  union all
  select id, 5, 5, 'IG',
    'After reintubation, the airway is secured and oxygenation improves.

While receiving mechanical ventilation with an FIO2 of 0.60 and PEEP of 5 cm H2O, ABG analysis reveals:
pH 7.29
PaCO2 52 torr
PaO2 72 torr
HCO3- 25 mEq/L

Which of the following should be evaluated or adjusted now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case8_target
  union all
  select id, 6, 6, 'DM',
    'The patient remains at risk for recurrent airway compromise. Which of the following should be recommended postadmission?',
    null, 'STOP', '{}'::jsonb from _case8_target
  returning id, step_order
)
insert into _case8_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Upper-airway sounds and ability to speak', 2, 'This is indicated in the initial assessment.' from _case8_steps s where s.step_order = 1
union all select s.id, 'B', 'Work of breathing, pulse oximetry, and vital signs', 2, 'This helps assess severity and trend.' from _case8_steps s where s.step_order = 1
union all select s.id, 'C', 'Immediate availability of airway equipment and backup personnel', 2, 'This is indicated with worsening post-extubation distress.' from _case8_steps s where s.step_order = 1
union all select s.id, 'D', 'Transport for CT imaging before treatment', -3, 'This delays urgent care.' from _case8_steps s where s.step_order = 1
union all select s.id, 'E', 'Sedation without an airway plan', -3, 'This may worsen airway compromise.' from _case8_steps s where s.step_order = 1

union all select s.id, 'A', 'Administer upper-airway rescue therapy while preparing for reintubation if needed', 3, 'This is the best first intervention in this situation.' from _case8_steps s where s.step_order = 2
union all select s.id, 'B', 'Observe on low-flow oxygen only', -3, 'This delays indicated treatment.' from _case8_steps s where s.step_order = 2
union all select s.id, 'C', 'Remove oxygen to assess baseline severity', -3, 'This is unsafe.' from _case8_steps s where s.step_order = 2
union all select s.id, 'D', 'Delay intervention until a full diagnostic panel is completed', -3, 'This delays indicated care.' from _case8_steps s where s.step_order = 2

union all select s.id, 'A', 'Speech tolerance and stridor intensity', 2, 'This helps assess airway reserve.' from _case8_steps s where s.step_order = 3
union all select s.id, 'B', 'Oxygen saturation and work of breathing trend', 2, 'This is indicated to assess worsening distress.' from _case8_steps s where s.step_order = 3
union all select s.id, 'C', 'Immediate readiness for reintubation', 2, 'This is indicated if deterioration continues.' from _case8_steps s where s.step_order = 3
union all select s.id, 'D', 'Routine discharge paperwork', -3, 'This is premature.' from _case8_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop monitoring after brief improvement', -3, 'This is unsafe.' from _case8_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed with controlled reintubation with full airway backup', 3, 'This is indicated with worsening post-extubation airway failure.' from _case8_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue the same therapy and reassess later', -3, 'This delays definitive airway management.' from _case8_steps s where s.step_order = 4
union all select s.id, 'C', 'Transport the patient before securing the airway', -3, 'This is unsafe.' from _case8_steps s where s.step_order = 4
union all select s.id, 'D', 'Deeply sedate the patient without securing the airway', -3, 'This may cause complete obstruction.' from _case8_steps s where s.step_order = 4

union all select s.id, 'A', 'Verify tube position and secure the airway', 2, 'This is indicated immediately after reintubation.' from _case8_steps s where s.step_order = 5
union all select s.id, 'B', 'Adjust ventilator settings to improve gas exchange', 2, 'This is indicated based on the ABG.' from _case8_steps s where s.step_order = 5
union all select s.id, 'C', 'Continue close cardiorespiratory reassessment', 2, 'This is indicated after airway rescue.' from _case8_steps s where s.step_order = 5
union all select s.id, 'D', 'Stop monitoring after the first improved saturation reading', -3, 'This is unsafe.' from _case8_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer immediately to a low-acuity unit', -3, 'This is not appropriate.' from _case8_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to the ICU for continued airway and ventilatory monitoring', 3, 'This is the safest disposition after recurrent airway compromise.' from _case8_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge after temporary stabilization', -3, 'This is unsafe.' from _case8_steps s where s.step_order = 6
union all select s.id, 'C', 'Admit to an unmonitored bed', -3, 'This is not an appropriate level of care.' from _case8_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe without a defined escalation plan', -3, 'This is not an appropriate disposition.' from _case8_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Stridor persists, and upper-airway distress remains present.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case8_steps s1 cross join _case8_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Respiratory distress worsens, and oxygenation falls.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case8_steps s1 cross join _case8_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Stridor improves briefly, but airway risk remains high.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case8_steps s2 cross join _case8_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Upper-airway obstruction worsens, and respiratory fatigue increases.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case8_steps s2 cross join _case8_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Speech tolerance worsens, and stridor remains severe.',
  '{"spo2": -1, "hr": 2, "rr": 1, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case8_steps s3 cross join _case8_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and airway compromise worsens rapidly.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case8_steps s3 cross join _case8_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'The airway is secured, and oxygenation improves.',
  '{"spo2": 8, "hr": -6, "rr": -6, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case8_steps s4 cross join _case8_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Upper-airway obstruction causes severe hypoxemia and worsening instability.',
  '{"spo2": -8, "hr": 8, "rr": 5, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case8_steps s4 cross join _case8_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'Post-intubation stabilization is maintained with close monitoring.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case8_steps s5 cross join _case8_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Monitoring and ventilator-management gaps leave recurrent instability risk.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case8_steps s5 cross join _case8_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is admitted to the ICU for continued airway and ventilatory management.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case8_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: the level of care is inadequate, and recurrent airway distress occurs.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": -5, "bp_dia": -3}'::jsonb
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
