-- Exhale Academy CSE Branching Seed (Pulmonary Embolism Decompensation Pattern)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case7_target (id uuid primary key) on commit drop;
create temporary table _case7_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-7-sudden-hypoxemia-hemodynamic-strain-pattern'
     or lower(coalesce(title, '')) like '%case 7%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-acute-pe-pattern',
    case_number = 7,
    slug = 'case-7-sudden-hypoxemia-hemodynamic-strain-pattern',
    title = 'Case 7 -- Sudden Hypoxemia With Hemodynamic Strain Pattern',
    intro_text = 'Adult with abrupt pleuritic dyspnea, tachycardia, and worsening oxygenation requiring rapid stabilization and escalation decisions.',
    description = 'Branching scenario focused on acute oxygen support, reassessment, and escalation in a high-risk pulmonary embolism pattern.',
    stem = 'Acute cardiopulmonary decompensation with severe gas-exchange mismatch and worsening perfusion.',
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
    'adult-acute-pe-pattern',
    7,
    'case-7-sudden-hypoxemia-hemodynamic-strain-pattern',
    'Case 7 -- Sudden Hypoxemia With Hemodynamic Strain Pattern',
    'Adult with abrupt pleuritic dyspnea, tachycardia, and worsening oxygenation requiring rapid stabilization and escalation decisions.',
    'Branching scenario focused on acute oxygen support, reassessment, and escalation in a high-risk pulmonary embolism pattern.',
    'Acute cardiopulmonary decompensation with severe gas-exchange mismatch and worsening perfusion.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case7_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":126,"rr":34,"spo2":80,"bp_sys":98,"bp_dia":62}'::jsonb
where id in (select id from _case7_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case7_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case7_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case7_target)
);

delete from public.cse_attempts where case_id in (select id from _case7_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case7_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case7_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case7_target));
delete from public.cse_steps where case_id in (select id from _case7_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 46-year-old woman comes to the emergency department because of sudden right-sided pleuritic chest pain and severe dyspnea.

While breathing room air, the following are noted:
HR 126/min
RR 34/min
BP 98/62 mm Hg
SpO2 80%

She is anxious and diaphoretic.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case7_target
  union all
  select id, 2, 2, 'DM',
    'Breath sounds are clear bilaterally. Neck veins are distended, and the patient remains tachycardic. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case7_target
  union all
  select id, 3, 3, 'IG',
    'After oxygen therapy is started, the patient remains dyspneic.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 122/min
RR 32/min
BP 92/58 mm Hg
SpO2 88%

ABG analysis reveals:
pH 7.47
PaCO2 31 torr
PaO2 56 torr
HCO3- 22 mEq/L

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case7_target
  union all
  select id, 4, 4, 'DM',
    'Blood pressure continues to fall, and hypoxemia persists. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case7_target
  union all
  select id, 5, 5, 'IG',
    'After escalation, oxygenation improves slightly and perfusion stabilizes. Which of the following should be evaluated or monitored now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case7_target
  union all
  select id, 6, 6, 'DM',
    'The patient remains high risk for recurrent instability. Which of the following should be recommended postadmission?',
    null, 'STOP', '{}'::jsonb from _case7_target
  returning id, step_order
)
insert into _case7_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Breath sounds and symmetry of chest expansion', 2, 'This is indicated in the initial assessment.' from _case7_steps s where s.step_order = 1
union all select s.id, 'B', 'Pulse oximetry, heart rate, and blood pressure', 2, 'This is indicated to assess severity and perfusion.' from _case7_steps s where s.step_order = 1
union all select s.id, 'C', 'Signs of right-heart strain and mental status', 2, 'This helps assess severity and instability.' from _case7_steps s where s.step_order = 1
union all select s.id, 'D', 'Routine pulmonary function testing', -3, 'This is not indicated in the current condition.' from _case7_steps s where s.step_order = 1
union all select s.id, 'E', 'Exercise oximetry', -3, 'This delays urgent care.' from _case7_steps s where s.step_order = 1

union all select s.id, 'A', 'Administer high-concentration oxygen and maintain close monitoring', 3, 'This is the best first respiratory intervention in this situation.' from _case7_steps s where s.step_order = 2
union all select s.id, 'B', 'Delay treatment until imaging is completed', -3, 'This delays indicated treatment.' from _case7_steps s where s.step_order = 2
union all select s.id, 'C', 'Intubate immediately before any reassessment', -2, 'This may be required later, but it is not the best first step now.' from _case7_steps s where s.step_order = 2
union all select s.id, 'D', 'Use low-flow oxygen by nasal cannula only', -2, 'This is not the best initial oxygen strategy for this severity.' from _case7_steps s where s.step_order = 2

union all select s.id, 'A', 'Oxygen saturation and blood pressure trend', 2, 'This is indicated to assess response and instability.' from _case7_steps s where s.step_order = 3
union all select s.id, 'B', 'Mental status and signs of worsening perfusion', 2, 'This helps identify early shock progression.' from _case7_steps s where s.step_order = 3
union all select s.id, 'C', 'ABG trend', 2, 'This is indicated to assess ongoing gas-exchange failure.' from _case7_steps s where s.step_order = 3
union all select s.id, 'D', 'Smoking-cessation counseling', -3, 'Important later, but not the next acute priority.' from _case7_steps s where s.step_order = 3
union all select s.id, 'E', 'Routine discharge planning', -3, 'This is premature.' from _case7_steps s where s.step_order = 3

union all select s.id, 'A', 'Escalate to high-acuity management with immediate specialist coordination', 3, 'This is indicated with worsening perfusion and persistent hypoxemia.' from _case7_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue the same treatment and reassess later', -3, 'This delays indicated escalation.' from _case7_steps s where s.step_order = 4
union all select s.id, 'C', 'Send the patient for routine testing before stabilization', -3, 'This is unsafe in the current condition.' from _case7_steps s where s.step_order = 4
union all select s.id, 'D', 'Reduce oxygen because the patient is tachypneic', -3, 'This worsens hypoxemia.' from _case7_steps s where s.step_order = 4

union all select s.id, 'A', 'Continuous hemodynamic and oxygenation monitoring', 2, 'This is indicated after initial stabilization.' from _case7_steps s where s.step_order = 5
union all select s.id, 'B', 'Response to oxygen therapy and symptom trend', 2, 'This helps assess ongoing support needs.' from _case7_steps s where s.step_order = 5
union all select s.id, 'C', 'Coordination of definitive therapy pathway', 2, 'This is indicated in a high-risk PE pattern.' from _case7_steps s where s.step_order = 5
union all select s.id, 'D', 'Stop close monitoring after brief improvement', -3, 'This is unsafe.' from _case7_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer early to a low-acuity unit', -3, 'This is not appropriate for the current condition.' from _case7_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to the ICU for continued respiratory and hemodynamic monitoring', 3, 'This is the safest disposition in this situation.' from _case7_steps s where s.step_order = 6
union all select s.id, 'B', 'Admit to an unmonitored floor bed', -3, 'This is not an appropriate level of care.' from _case7_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge after temporary improvement', -3, 'This is unsafe.' from _case7_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe without a defined escalation plan', -3, 'This is not an appropriate disposition.' from _case7_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Pleuritic chest pain and dyspnea persist, and hypoxemia remains severe.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case7_steps s1 cross join _case7_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Hypoxemia worsens, and perfusion remains poor.',
  '{"spo2": -5, "hr": 6, "rr": 3, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case7_steps s1 cross join _case7_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Oxygenation improves slightly, but tachycardia and dyspnea persist.',
  '{"spo2": 8, "hr": -4, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case7_steps s2 cross join _case7_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Symptoms worsen, and blood pressure continues to fall.',
  '{"spo2": -4, "hr": 7, "rr": 4, "bp_sys": -8, "bp_dia": -5}'::jsonb
from _case7_steps s2 cross join _case7_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Hypoxemia and hypotension persist, and the patient remains high risk.',
  '{"spo2": -1, "hr": 1, "rr": 1, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case7_steps s3 cross join _case7_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and shock worsens.',
  '{"spo2": -4, "hr": 6, "rr": 3, "bp_sys": -10, "bp_dia": -6}'::jsonb
from _case7_steps s3 cross join _case7_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Perfusion improves slightly, and oxygenation stabilizes.',
  '{"spo2": 5, "hr": -5, "rr": -2, "bp_sys": 10, "bp_dia": 6}'::jsonb
from _case7_steps s4 cross join _case7_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Hypoxemia worsens, and hemodynamic instability increases.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": -12, "bp_dia": -7}'::jsonb
from _case7_steps s4 cross join _case7_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'Stabilization is maintained with ongoing high-acuity monitoring.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case7_steps s5 cross join _case7_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Monitoring gaps leave a high risk of recurrent collapse.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case7_steps s5 cross join _case7_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is admitted to the ICU for continued monitoring and definitive management.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case7_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: the level of care is inadequate, and recurrent instability occurs.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": -8, "bp_dia": -5}'::jsonb
from _case7_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE7_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case7_target);

commit;
