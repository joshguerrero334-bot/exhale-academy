-- Exhale Academy CSE Branching Seed (COPD Non-Critical - Chronic Bronchitis Pattern)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case12_target (id uuid primary key) on commit drop;
create temporary table _case12_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-12-copd-conservative-chronic-bronchitis-phenotype',
    'copd-conservative-chronic-bronchitis-phenotype',
    'case-12-copd-non-critical-chronic-bronchitis-phenotype',
    'copd-non-critical-chronic-bronchitis-phenotype'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'copd-non-critical',
    disease_slug = 'copd',
    disease_track = 'non_critical',
    case_number = coalesce(c.case_number, 12),
    slug = 'copd-non-critical-chronic-bronchitis-phenotype',
    title = 'COPD Non-Critical (Chronic Bronchitis-Predominant Flare)',
    intro_text = 'Noncritical COPD exacerbation with productive cough, secretion burden, and possible infective trigger requiring acute treatment and safe discharge planning.',
    description = 'Branching case focused on bronchodilator treatment, secretion-heavy reassessment, and transition planning in a chronic-bronchitis-predominant flare.',
    stem = 'Chronic-bronchitis-predominant COPD flare with productive cough and moderate hypoxemia.',
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
    'copd-non-critical',
    'copd',
    'non_critical',
    12,
    'copd-non-critical-chronic-bronchitis-phenotype',
    'COPD Non-Critical (Chronic Bronchitis-Predominant Flare)',
    'Noncritical COPD exacerbation with productive cough, secretion burden, and possible infective trigger requiring acute treatment and safe discharge planning.',
    'Branching case focused on bronchodilator treatment, secretion-heavy reassessment, and transition planning in a chronic-bronchitis-predominant flare.',
    'Chronic-bronchitis-predominant COPD flare with productive cough and moderate hypoxemia.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case12_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":106,"rr":28,"spo2":86,"bp_sys":152,"bp_dia":94,"temp_c":38.1}'::jsonb
where id in (select id from _case12_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case12_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case12_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case12_target)
);

delete from public.cse_attempts where case_id in (select id from _case12_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case12_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case12_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case12_target));
delete from public.cse_steps where case_id in (select id from _case12_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 61-year-old man with severe COPD comes to the emergency department because of worsening dyspnea and increased yellow-green sputum.

While breathing room air, the following are noted:
HR 106/min
RR 28/min
BP 152/94 mm Hg
Temperature 38.1 C
SpO2 86%

He has a frequent productive cough.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case12_target
  union all
  select id, 2, 2, 'DM',
    'Breath sounds reveal diffuse rhonchi and scattered wheezes. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case12_target
  union all
  select id, 3, 3, 'IG',
    'Thirty minutes after controlled oxygen and bronchodilator therapy are started, the patient remains productive but less dyspneic.

While receiving O2 by nasal cannula at 2 L/min, the following are noted:
HR 102/min
RR 26/min
Temperature 37.9 C
SpO2 89%

ABG analysis reveals:
pH 7.35
PaCO2 54 torr
PaO2 60 torr
HCO3- 29 mEq/L

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case12_target
  union all
  select id, 4, 4, 'DM',
    'Productive cough and dyspnea persist, but the patient remains alert. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case12_target
  union all
  select id, 5, 5, 'IG',
    'After additional treatment, the patient is breathing more comfortably. Which of the following should be evaluated before disposition? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case12_target
  union all
  select id, 6, 6, 'DM',
    'Symptoms are improving and oxygenation is stable. Which of the following should be recommended postdischarge?',
    null, 'STOP', '{}'::jsonb from _case12_target
  returning id, step_order
)
insert into _case12_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Sputum amount and character', 2, 'This is indicated in a secretion-heavy exacerbation.' from _case12_steps s where s.step_order = 1
union all select s.id, 'B', 'Breath sounds and work of breathing', 2, 'This helps assess severity of obstruction and secretion burden.' from _case12_steps s where s.step_order = 1
union all select s.id, 'C', 'Pulse oximetry, temperature, and vital signs', 2, 'This is indicated to assess severity and infective features.' from _case12_steps s where s.step_order = 1
union all select s.id, 'D', 'Exercise oximetry', -3, 'This is not indicated in the current condition.' from _case12_steps s where s.step_order = 1
union all select s.id, 'E', 'Routine CT scan before treatment', -3, 'This delays indicated care.' from _case12_steps s where s.step_order = 1

union all select s.id, 'A', 'Administer controlled oxygen and short-acting bronchodilator therapy', 3, 'This is the best first treatment in this situation.' from _case12_steps s where s.step_order = 2
union all select s.id, 'B', 'Start antibiotics as the only initial treatment', -2, 'This does not address the immediate obstructive problem.' from _case12_steps s where s.step_order = 2
union all select s.id, 'C', 'Observe without treatment because the patient is still alert', -3, 'This delays indicated treatment.' from _case12_steps s where s.step_order = 2
union all select s.id, 'D', 'Proceed directly to intubation', -3, 'This is not indicated in the current condition.' from _case12_steps s where s.step_order = 2

union all select s.id, 'A', 'Sputum burden and effectiveness of cough', 2, 'This is indicated to assess secretion clearance.' from _case12_steps s where s.step_order = 3
union all select s.id, 'B', 'Breath sounds and work of breathing', 2, 'This helps assess ongoing obstruction.' from _case12_steps s where s.step_order = 3
union all select s.id, 'C', 'ABG and oxygen saturation trend', 2, 'This is indicated to assess gas-exchange response.' from _case12_steps s where s.step_order = 3
union all select s.id, 'D', 'Pulmonary rehabilitation schedule', -3, 'This is not the next urgent priority.' from _case12_steps s where s.step_order = 3
union all select s.id, 'E', 'Discharge paperwork', -3, 'This is premature.' from _case12_steps s where s.step_order = 3

union all select s.id, 'A', 'Add systemic corticosteroid therapy and continue bronchodilator treatment', 3, 'This is the best next step for persistent symptoms in a noncritical flare.' from _case12_steps s where s.step_order = 4
union all select s.id, 'B', 'Stop bronchodilator therapy because wheezing decreased', -3, 'This is premature.' from _case12_steps s where s.step_order = 4
union all select s.id, 'C', 'Proceed directly to intubation', -3, 'This is not indicated in the current condition.' from _case12_steps s where s.step_order = 4
union all select s.id, 'D', 'Delay additional therapy until tomorrow', -3, 'This delays indicated care.' from _case12_steps s where s.step_order = 4

union all select s.id, 'A', 'Stable oxygen requirement and sustained symptom improvement', 2, 'This is indicated before discharge.' from _case12_steps s where s.step_order = 5
union all select s.id, 'B', 'Inhaler technique and medication adherence', 2, 'This is important to reduce recurrence.' from _case12_steps s where s.step_order = 5
union all select s.id, 'C', 'Return precautions and follow-up plan', 2, 'This is indicated for safe discharge planning.' from _case12_steps s where s.step_order = 5
union all select s.id, 'D', 'Routine antibiotics without infection assessment', -3, 'This is not indicated as a blanket step.' from _case12_steps s where s.step_order = 5
union all select s.id, 'E', 'Discharge without addressing home oxygen needs', -3, 'This is unsafe.' from _case12_steps s where s.step_order = 5

union all select s.id, 'A', 'Discharge with follow-up and COPD action planning after sustained stability', 3, 'This is appropriate when discharge criteria are met.' from _case12_steps s where s.step_order = 6
union all select s.id, 'B', 'Admit for monitored care if dyspnea or oxygen needs worsen again', 1, 'This is a reasonable alternative if stability is not sustained.' from _case12_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge without follow-up', -3, 'This is unsafe.' from _case12_steps s where s.step_order = 6
union all select s.id, 'D', 'Place in hallway observation without a treatment plan', -3, 'This is not an appropriate disposition.' from _case12_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Productive cough persists, and moderate hypoxemia remains present.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0, "temp_c": 0}'::jsonb
from _case12_steps s1 cross join _case12_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Dyspnea and secretion burden persist.',
  '{"spo2": -2, "hr": 3, "rr": 2, "bp_sys": 2, "bp_dia": 1, "temp_c": 0}'::jsonb
from _case12_steps s1 cross join _case12_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Breathing improves slightly, but productive cough remains.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1, "temp_c": -0.1}'::jsonb
from _case12_steps s2 cross join _case12_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Symptoms remain unstable, and oxygenation improves little.',
  '{"spo2": -3, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "temp_c": 0}'::jsonb
from _case12_steps s2 cross join _case12_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Productive cough persists, but the patient remains stable.',
  '{"spo2": 0, "hr": 1, "rr": 1, "bp_sys": 1, "bp_dia": 1, "temp_c": 0}'::jsonb
from _case12_steps s3 cross join _case12_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and symptoms persist.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": 2, "bp_dia": 1, "temp_c": 0}'::jsonb
from _case12_steps s3 cross join _case12_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Breathing becomes easier, and cough burden begins to improve.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1, "temp_c": -0.2}'::jsonb
from _case12_steps s4 cross join _case12_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Symptoms remain persistent, and discharge readiness is uncertain.',
  '{"spo2": -3, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "temp_c": 0}'::jsonb
from _case12_steps s4 cross join _case12_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'Symptoms remain improved, and discharge planning is complete.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "temp_c": -0.1}'::jsonb
from _case12_steps s5 cross join _case12_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Discharge readiness remains incomplete.',
  '{"spo2": -2, "hr": 3, "rr": 2, "bp_sys": 2, "bp_dia": 1, "temp_c": 0}'::jsonb
from _case12_steps s5 cross join _case12_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is discharged with follow-up and COPD action planning.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": -1, "bp_dia": -1, "temp_c": 0}'::jsonb
from _case12_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: the discharge plan is inadequate, and symptoms recur early.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": -4, "bp_dia": -2, "temp_c": 0}'::jsonb
from _case12_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE12_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
    'temp_c', coalesce((b.baseline_vitals->>'temp_c')::numeric, 0) + coalesce((r.vitals_delta->>'temp_c')::numeric, 0)
  )
from public.cse_rules r
join public.cse_steps s on s.id = r.step_id
join public.cse_cases b on b.id = s.case_id
where s.case_id in (select id from _case12_target);

commit;
