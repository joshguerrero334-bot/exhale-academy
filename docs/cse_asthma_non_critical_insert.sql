-- Exhale Academy CSE Branching Seed (Asthma Non-Critical - Triggered Exacerbation)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _asthma_non_critical_target (id uuid primary key) on commit drop;
create temporary table _asthma_non_critical_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-13-asthma-conservative-triggered-exacerbation',
    'asthma-conservative-triggered-exacerbation',
    'case-13-copd-non-critical-asthma-triggered-exacerbation',
    'copd-non-critical-asthma-triggered-exacerbation',
    'asthma-non-critical-triggered-exacerbation'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'asthma-non-critical',
    disease_slug = 'asthma',
    disease_track = 'non_critical',
    case_number = coalesce(c.case_number, 13),
    slug = 'asthma-non-critical-triggered-exacerbation',
    title = 'Asthma Non-Critical (Triggered Exacerbation)',
    intro_text = 'Noncritical asthma exacerbation after trigger exposure requiring acute bronchodilator treatment, reassessment, and safe discharge planning.',
    description = 'Branching case focused on asthma trigger recognition, acute treatment, reassessment, and discharge with an asthma action plan.',
    stem = 'Triggered asthma exacerbation with wheezing, moderate hypoxemia, and no immediate ventilatory-failure signs.',
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
    'asthma-non-critical',
    'asthma',
    'non_critical',
    13,
    'asthma-non-critical-triggered-exacerbation',
    'Asthma Non-Critical (Triggered Exacerbation)',
    'Noncritical asthma exacerbation after trigger exposure requiring acute bronchodilator treatment, reassessment, and safe discharge planning.',
    'Branching case focused on asthma trigger recognition, acute treatment, reassessment, and discharge with an asthma action plan.',
    'Triggered asthma exacerbation with wheezing, moderate hypoxemia, and no immediate ventilatory-failure signs.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _asthma_non_critical_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":118,"rr":32,"spo2":89,"bp_sys":146,"bp_dia":88,"etco2":49}'::jsonb
where id in (select id from _asthma_non_critical_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _asthma_non_critical_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _asthma_non_critical_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _asthma_non_critical_target)
);

delete from public.cse_attempts where case_id in (select id from _asthma_non_critical_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _asthma_non_critical_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _asthma_non_critical_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _asthma_non_critical_target));
delete from public.cse_steps where case_id in (select id from _asthma_non_critical_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 43-year-old man comes to the emergency department because of dyspnea, chest tightness, and wheezing after cleaning a dusty attic.

While breathing room air, the following are noted:
HR 118/min
RR 32/min
BP 146/88 mm Hg
SpO2 89%

He has accessory-muscle use and difficulty speaking full sentences.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _asthma_non_critical_target
  union all
  select id, 2, 2, 'DM',
    'Breath sounds reveal diffuse expiratory wheezing. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _asthma_non_critical_target
  union all
  select id, 3, 3, 'IG',
    'Thirty minutes after oxygen, bronchodilator therapy, and systemic corticosteroids are started, the patient is breathing more comfortably but still wheezing.

While receiving O2 by aerosol mask at an FIO2 of 0.35, the following are noted:
HR 108/min
RR 28/min
BP 140/84 mm Hg
SpO2 93%

ABG analysis reveals:
pH 7.45
PaCO2 34 torr
PaO2 68 torr
HCO3- 23 mEq/L

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _asthma_non_critical_target
  union all
  select id, 4, 4, 'DM',
    'Wheezing persists, but the patient remains alert and is speaking in longer phrases. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _asthma_non_critical_target
  union all
  select id, 5, 5, 'IG',
    'After additional treatment, the patient is breathing more comfortably. Which of the following should be evaluated before disposition? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _asthma_non_critical_target
  union all
  select id, 6, 6, 'DM',
    'Symptoms remain improved and oxygenation is stable. Which of the following should be recommended postdischarge?',
    null, 'STOP', '{}'::jsonb from _asthma_non_critical_target
  returning id, step_order
)
insert into _asthma_non_critical_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Breath sounds and air movement', 2, 'This is indicated to assess severity of obstruction.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'B', 'Work of breathing and ability to speak', 2, 'This helps assess severity and fatigue risk.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'C', 'Pulse oximetry and vital signs', 2, 'This is indicated to assess severity and trend.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'D', 'Complete pulmonary function testing', -3, 'This is not indicated in the current condition.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'E', 'Allergy skin testing before treatment', -3, 'This delays urgent care.' from _asthma_non_critical_steps s where s.step_order = 1

union all select s.id, 'A', 'Administer oxygen, short-acting bronchodilator therapy, and systemic corticosteroid treatment', 3, 'This is the best first treatment in this situation.' from _asthma_non_critical_steps s where s.step_order = 2
union all select s.id, 'B', 'Observe without treatment because the patient is still speaking', -3, 'This delays indicated treatment.' from _asthma_non_critical_steps s where s.step_order = 2
union all select s.id, 'C', 'Start only long-acting controller medication', -3, 'This does not address the acute problem.' from _asthma_non_critical_steps s where s.step_order = 2
union all select s.id, 'D', 'Proceed directly to intubation', -2, 'This is too aggressive without immediate ventilatory-failure signs.' from _asthma_non_critical_steps s where s.step_order = 2

union all select s.id, 'A', 'Breath sounds and work of breathing', 2, 'This helps assess response to therapy.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'B', 'Oxygen saturation and vital-sign trend', 2, 'This is indicated to assess ongoing oxygen needs.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'C', 'Ability to speak and symptom improvement', 2, 'This helps assess clinical improvement.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'D', 'Peak expiratory flow only after all acute decisions are complete', -1, 'Useful later, but not the most important immediate reassessment item.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'E', 'Discharge paperwork', -3, 'This is premature.' from _asthma_non_critical_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue bronchodilator therapy and maintain close reassessment', 3, 'This is the best next step for persistent symptoms without failure signs.' from _asthma_non_critical_steps s where s.step_order = 4
union all select s.id, 'B', 'Stop bronchodilator therapy because the patient is less anxious', -3, 'This is premature.' from _asthma_non_critical_steps s where s.step_order = 4
union all select s.id, 'C', 'Proceed directly to intubation', -3, 'This is not indicated in the current condition.' from _asthma_non_critical_steps s where s.step_order = 4
union all select s.id, 'D', 'Delay treatment and reassess tomorrow', -3, 'This delays indicated care.' from _asthma_non_critical_steps s where s.step_order = 4

union all select s.id, 'A', 'Sustained symptom improvement and stable oxygen saturation', 2, 'This is indicated before discharge.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'B', 'Inhaler technique and controller adherence plan', 2, 'This is important to reduce recurrence.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'C', 'Return precautions and follow-up plan', 2, 'This is indicated for safe discharge planning.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'D', 'Routine antibiotics without infection evidence', -3, 'This is not indicated.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'E', 'Discharge without trigger-avoidance counseling', -3, 'This is unsafe.' from _asthma_non_critical_steps s where s.step_order = 5

union all select s.id, 'A', 'Discharge with an asthma action plan and close follow-up after sustained stability', 3, 'This is appropriate when discharge criteria are met.' from _asthma_non_critical_steps s where s.step_order = 6
union all select s.id, 'B', 'Admit for monitored care if symptoms worsen again or oxygen needs increase', 1, 'This is a reasonable alternative if stability is not sustained.' from _asthma_non_critical_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge without follow-up', -3, 'This is unsafe.' from _asthma_non_critical_steps s where s.step_order = 6
union all select s.id, 'D', 'Place in hallway observation without a treatment plan', -3, 'This is not an appropriate disposition.' from _asthma_non_critical_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Diffuse wheezing persists, and work of breathing remains increased.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0, "etco2": 0}'::jsonb
from _asthma_non_critical_steps s1 cross join _asthma_non_critical_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Wheezing and dyspnea persist.',
  '{"spo2": -2, "hr": 3, "rr": 2, "bp_sys": 2, "bp_dia": 1, "etco2": 1}'::jsonb
from _asthma_non_critical_steps s1 cross join _asthma_non_critical_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Oxygenation improves, but wheezing persists.',
  '{"spo2": 4, "hr": -4, "rr": -3, "bp_sys": -2, "bp_dia": -1, "etco2": -1}'::jsonb
from _asthma_non_critical_steps s2 cross join _asthma_non_critical_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Symptoms improve little, and reassessment remains necessary.',
  '{"spo2": -3, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 2}'::jsonb
from _asthma_non_critical_steps s2 cross join _asthma_non_critical_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Wheezing persists, but the patient remains alert and is improving.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _asthma_non_critical_steps s3 cross join _asthma_non_critical_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and symptoms persist.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": 2, "bp_dia": 1, "etco2": 1}'::jsonb
from _asthma_non_critical_steps s3 cross join _asthma_non_critical_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Breathing becomes easier, and symptom improvement continues.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _asthma_non_critical_steps s4 cross join _asthma_non_critical_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Symptoms remain active, and discharge readiness is uncertain.',
  '{"spo2": -3, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 1}'::jsonb
from _asthma_non_critical_steps s4 cross join _asthma_non_critical_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'Symptoms remain improved, and discharge planning is complete.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": 0}'::jsonb
from _asthma_non_critical_steps s5 cross join _asthma_non_critical_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Discharge readiness remains incomplete.',
  '{"spo2": -2, "hr": 3, "rr": 2, "bp_sys": 2, "bp_dia": 1, "etco2": 1}'::jsonb
from _asthma_non_critical_steps s5 cross join _asthma_non_critical_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is discharged with an asthma action plan and follow-up.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": 0}'::jsonb
from _asthma_non_critical_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: the discharge plan is inadequate, and symptoms recur early.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": -4, "bp_dia": -2, "etco2": 2}'::jsonb
from _asthma_non_critical_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE13_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
    'bp_dia', coalesce((b.baseline_vitals->>'bp_dia')::int, 0) + coalesce((r.vitals_delta->>'bp_dia')::int, 0),
    'etco2', coalesce((b.baseline_vitals->>'etco2')::int, 0) + coalesce((r.vitals_delta->>'etco2')::int, 0)
  )
from public.cse_rules r
join public.cse_steps s on s.id = r.step_id
join public.cse_cases b on b.id = s.case_id
where s.case_id in (select id from _asthma_non_critical_target);

commit;
