-- Exhale Academy CSE Case #1 Branching Seed (Practice Layout Audit)
-- Rewritten to use reveal-based airway assessment.

begin;

create temporary table _case1_target (id uuid primary key) on commit drop;
create temporary table _case1_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-1-practice-layout-audit'
     or lower(coalesce(title, '')) like '%case 1%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'practice-layout-audit',
    disease_slug = 'upper-airway-emergency',
    disease_track = 'acute',
    case_number = 1,
    slug = 'case-1-practice-layout-audit',
    title = 'Case 1 -- Practice Layout Audit (Upper Airway)',
    intro_text = 'Upper-airway emergency practice case focused on choosing the right assessments and controlled airway strategy.',
    description = 'Practice branching case that now uses the same reveal-first CSE structure as the live master exam pool.',
    stem = 'Patient with rapidly progressive upper-airway distress requiring controlled airway planning.',
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
    'practice-layout-audit',
    'upper-airway-emergency',
    'acute',
    1,
    'case-1-practice-layout-audit',
    'Case 1 -- Practice Layout Audit (Upper Airway)',
    'Upper-airway emergency practice case focused on choosing the right assessments and controlled airway strategy.',
    'Practice branching case that now uses the same reveal-first CSE structure as the live master exam pool.',
    'Patient with rapidly progressive upper-airway distress requiring controlled airway planning.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case1_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":110,"rr":30,"spo2":86,"bp_sys":142,"bp_dia":96}'::jsonb
where id in (select id from _case1_target);

delete from public.cse_attempt_events
where attempt_id in (select a.id from public.cse_attempts a where a.case_id in (select id from _case1_target))
   or step_id in (select s.id from public.cse_steps s where s.case_id in (select id from _case1_target))
   or outcome_id in (
      select o.id from public.cse_outcomes o
      join public.cse_steps s on s.id = o.step_id
      where s.case_id in (select id from _case1_target)
   );

delete from public.cse_attempts where case_id in (select id from _case1_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case1_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case1_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case1_target));
delete from public.cse_steps where case_id in (select id from _case1_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
'A 43-year-old man arrives with rapidly worsening noisy breathing after a day of severe throat pain.

While breathing room air, the following are noted:
HR 110/min
RR 30/min
BP 142/96 mm Hg
SpO2 86%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).',
  4, 'STOP',
  '{
    "show_appearance_after_submit": true,
    "appearance_text": "the patient is anxious, drooling, and sitting upright",
    "extra_reveals": [
      { "text": "Inspiratory stridor is present.", "keys_any": ["A"] },
      { "text": "Speech is limited to one- or two-word phrases.", "keys_any": ["B"] },
      { "text": "The patient has a muffled voice and severe throat pain.", "keys_any": ["C"] },
      { "text": "WBC is 18,200/mm3.", "keys_any": ["D"] },
      { "text": "Portable lateral neck radiograph reveals an enlarged epiglottic shadow.", "keys_any": ["E"] }
    ]
  }'::jsonb from _case1_target
  union all
  select id, 2, 2, 'DM',
'The findings suggest an upper-airway emergency with high risk of abrupt obstruction. Which of the following should be recommended FIRST?',
  null, 'STOP', '{}'::jsonb from _case1_target
  union all
  select id, 3, 3, 'IG',
'While the airway team is assembling, oxygenation remains marginal.

While receiving humidified O2, the following are noted:
HR 114/min
RR 32/min
BP 146/98 mm Hg
SpO2 88%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
  4, 'STOP',
  '{
    "show_appearance_after_submit": true,
    "appearance_text": "the patient remains upright and appears increasingly fatigued",
    "extra_reveals": [
      { "text": "Work of breathing is increasing, and the patient appears more exhausted.", "keys_any": ["A"] },
      { "text": "ABG: pH 7.31, PaCO2 50 torr, PaO2 58 torr, HCO3 24 mEq/L.", "keys_any": ["B"] },
      { "text": "Continuous pulse oximetry continues to show borderline oxygenation.", "keys_any": ["C"] },
      { "text": "A backup surgical-airway plan is still required.", "keys_any": ["D"] }
    ]
  }'::jsonb from _case1_target
  union all
  select id, 4, 4, 'DM',
'Oxygenation and fatigue worsen while the upper-airway obstruction risk remains high. Which of the following should be recommended now?',
  null, 'STOP', '{}'::jsonb from _case1_target
  returning id, step_order
)
insert into _case1_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Auscultate for stridor', 2, 'This is indicated in the initial assessment.' from _case1_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess the ability to speak', 2, 'This helps define airway severity.' from _case1_steps s where s.step_order = 1
union all select s.id, 'C', 'Assess the voice and throat pain history', 2, 'This is indicated in the initial assessment.' from _case1_steps s where s.step_order = 1
union all select s.id, 'D', 'Review the CBC', 1, 'This provides supporting information.' from _case1_steps s where s.step_order = 1
union all select s.id, 'E', 'Review a portable lateral neck radiograph only if it can be obtained without destabilizing the airway', 1, 'This can support the diagnosis.' from _case1_steps s where s.step_order = 1
union all select s.id, 'F', 'Force the patient supine for a complete oral examination', -3, 'This is unsafe.' from _case1_steps s where s.step_order = 1
union all select s.id, 'G', 'Delay all treatment until imaging is complete', -3, 'This delays indicated care.' from _case1_steps s where s.step_order = 1

union all select s.id, 'A', 'Maintain the patient upright, provide humidified oxygen, and proceed with controlled airway planning with anesthesia and ENT backup', 3, 'This is the best first strategy.' from _case1_steps s where s.step_order = 2
union all select s.id, 'B', 'Observe on oxygen alone without a definitive airway plan', -3, 'This is unsafe.' from _case1_steps s where s.step_order = 2
union all select s.id, 'C', 'Use heavy sedation before the airway is secured', -3, 'This may precipitate total obstruction.' from _case1_steps s where s.step_order = 2
union all select s.id, 'D', 'Transport for CT before airway control', -3, 'This is unsafe.' from _case1_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess work of breathing and fatigue', 2, 'This is indicated in reassessment.' from _case1_steps s where s.step_order = 3
union all select s.id, 'B', 'Obtain an ABG', 2, 'This helps quantify ventilatory decline.' from _case1_steps s where s.step_order = 3
union all select s.id, 'C', 'Trend continuous pulse oximetry', 2, 'This remains essential.' from _case1_steps s where s.step_order = 3
union all select s.id, 'D', 'Confirm that a backup surgical-airway plan is ready', 2, 'This is indicated before further deterioration.' from _case1_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop reassessment after a brief improvement in oxygen saturation', -3, 'This is unsafe.' from _case1_steps s where s.step_order = 3
union all select s.id, 'F', 'Delay airway planning until the next routine cycle', -3, 'This is unsafe.' from _case1_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed with definitive airway control in a controlled setting with full backup available', 3, 'This is the best next step.' from _case1_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue the same therapy unchanged and reassess much later', -3, 'This delays indicated escalation.' from _case1_steps s where s.step_order = 4
union all select s.id, 'C', 'Transfer to a low-acuity bed', -3, 'This is unsafe.' from _case1_steps s where s.step_order = 4
union all select s.id, 'D', 'Discharge if anxiety decreases briefly', -3, 'This is unsafe.' from _case1_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Upper-airway findings are identified, and the risk of abrupt obstruction remains high.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0}'::jsonb
from _case1_steps s1 cross join _case1_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete, and airway distress worsens.',
  '{"spo2":-4,"hr":5,"rr":3,"bp_sys":4,"bp_dia":3}'::jsonb
from _case1_steps s1 cross join _case1_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'A controlled airway plan is in place, but the patient remains unstable.',
  '{"spo2":2,"hr":-2,"rr":-1,"bp_sys":0,"bp_dia":0}'::jsonb
from _case1_steps s2 cross join _case1_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all select s2.id, 99, 'DEFAULT', null, s3.id,
  'Airway compromise worsens because treatment is inadequate.',
  '{"spo2":-5,"hr":6,"rr":4,"bp_sys":4,"bp_dia":3}'::jsonb
from _case1_steps s2 cross join _case1_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all select s3.id, 1, 'SCORE_AT_LEAST', '6'::jsonb, s4.id,
  'Reassessment confirms the need for definitive airway control.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0}'::jsonb
from _case1_steps s3 cross join _case1_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and respiratory failure worsens.',
  '{"spo2":-4,"hr":5,"rr":3,"bp_sys":4,"bp_dia":3}'::jsonb
from _case1_steps s3 cross join _case1_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the airway is secured in a controlled setting, and the patient is stabilized for ICU care.',
  '{"spo2":2,"hr":-2,"rr":-2,"bp_sys":2,"bp_dia":1}'::jsonb
from _case1_steps s4 where s4.step_order = 4
union all select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed airway control leads to critical deterioration.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-6,"bp_dia":-4}'::jsonb
from _case1_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE1_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case1_target);

commit;
