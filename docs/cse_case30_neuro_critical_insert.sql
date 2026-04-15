-- Exhale Academy CSE Branching Seed (Case 30)
-- Neuromuscular Critical (Tetanus Airway Risk)

begin;

create temporary table _case30_target (id uuid primary key) on commit drop;
create temporary table _case30_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'neuromuscular-critical-tetanus-airway-risk'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-neuromuscular-critical',
    disease_slug = 'tetanus',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 30),
    slug = 'neuromuscular-critical-tetanus-airway-risk',
    title = 'Neuromuscular Critical (Tetanus Airway Risk)',
    intro_text = 'Puncture-wound history with trismus, rigidity, and rising airway-protection risk.',
    description = 'Critical tetanus case focused on bedside recognition, secretion risk, and controlled airway escalation.',
    stem = 'Patient develops trismus, rigidity, and worsening respiratory difficulty after a contaminated wound.',
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
    'adult-neuromuscular-critical',
    'tetanus',
    'critical',
    30,
    'neuromuscular-critical-tetanus-airway-risk',
    'Neuromuscular Critical (Tetanus Airway Risk)',
    'Puncture-wound history with trismus, rigidity, and rising airway-protection risk.',
    'Critical tetanus case focused on bedside recognition, secretion risk, and controlled airway escalation.',
    'Patient develops trismus, rigidity, and worsening respiratory difficulty after a contaminated wound.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case30_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":122,"rr":30,"spo2":86,"bp_sys":154,"bp_dia":92,"etco2":48}'::jsonb
where id in (select id from _case30_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case30_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case30_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case30_target)
);

delete from public.cse_attempts where case_id in (select id from _case30_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case30_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case30_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case30_target));
delete from public.cse_steps where case_id in (select id from _case30_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
'A 43-year-old man comes to the emergency department because of progressive difficulty opening his mouth and swallowing 4 days after stepping on a nail.

While breathing room air, the following are noted:
HR 122/min
RR 30/min
BP 154/92 mm Hg
SpO2 86%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).',
  4,
  'STOP',
  '{
    "show_appearance_after_submit": true,
    "appearance_text": "the patient is anxious and has intermittent generalized muscle spasms",
    "extra_reveals": [
      {"text":"The jaw is difficult to open, and speech is muffled.","keys_any":["A"]},
      {"text":"Neck and abdominal muscles are rigid, and secretions are difficult to clear.","keys_any":["B"]},
      {"text":"ABG: pH 7.35, PaCO2 50 torr, PaO2 55 torr, HCO3 27 mEq/L.","keys_any":["C"]},
      {"text":"The patient reports no recent tetanus booster after the puncture wound.","keys_any":["D"]}
    ]
  }'::jsonb
  from _case30_target
  union all
  select id, 2, 2, 'DM',
'Findings suggest tetanus with rising airway-protection risk. Which of the following should be recommended FIRST?',
  null,
  'STOP',
  '{}'::jsonb
  from _case30_target
  union all
  select id, 3, 3, 'IG',
'Thirty minutes after oxygen, low-stimulation precautions, and tetanus-directed therapy are started, the patient remains rigid and increasingly fatigued.

While receiving O2 by aerosol mask at an FIO2 of 0.50, the following are noted:
HR 126/min
RR 34/min
BP 162/96 mm Hg
SpO2 88%
EtCO2 52 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
  4,
  'STOP',
  '{
    "show_appearance_after_submit": true,
    "appearance_text": "secretions pool in the oropharynx during spasms",
    "extra_reveals": [
      {"text":"Air movement is reduced bilaterally because the chest wall is rigid.","keys_any":["A"]},
      {"text":"The patient is no longer handling secretions effectively.","keys_any":["B"]},
      {"text":"Repeat ABG: pH 7.31, PaCO2 56 torr, PaO2 60 torr, HCO3 28 mEq/L.","keys_any":["C"]},
      {"text":"A controlled airway approach is now indicated before complete respiratory failure occurs.","keys_any":["D"]}
    ]
  }'::jsonb
  from _case30_target
  union all
  select id, 4, 4, 'DM',
'Airway protection and ventilation continue to worsen. Which of the following should be recommended now?',
  null,
  'STOP',
  '{}'::jsonb
  from _case30_target
  returning id, step_order
)
insert into _case30_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Assess ability to open the airway and speak clearly', 2, 'This helps define immediate airway risk.' from _case30_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess secretion handling, chest wall rigidity, and work of breathing', 2, 'This is indicated to determine impending ventilatory failure.' from _case30_steps s where s.step_order = 1
union all select s.id, 'C', 'Obtain an ABG', 2, 'This helps assess oxygenation and ventilation.' from _case30_steps s where s.step_order = 1
union all select s.id, 'D', 'Review wound history and immunization status', 2, 'This supports bedside recognition of tetanus.' from _case30_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay stabilization until culture results return', -3, 'This delays indicated care.' from _case30_steps s where s.step_order = 1
union all select s.id, 'F', 'Assume anxiety is the only cause of respiratory distress', -3, 'This misses the airway threat.' from _case30_steps s where s.step_order = 1

union all select s.id, 'A', 'Provide high-concentration oxygen, reduce stimulation, and prepare for a controlled airway because secretion control is worsening', 3, 'This is the best first strategy in rising tetanus airway risk.' from _case30_steps s where s.step_order = 2
union all select s.id, 'B', 'Give reassurance and observe without airway planning', -3, 'This is unsafe.' from _case30_steps s where s.step_order = 2
union all select s.id, 'C', 'Delay treatment until spasms stop on their own', -3, 'This delays indicated management.' from _case30_steps s where s.step_order = 2
union all select s.id, 'D', 'Treat with oxygen only and discharge if SpO2 improves briefly', -3, 'This ignores the clinical trajectory.' from _case30_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess air movement and chest wall excursion', 2, 'This helps detect worsening ventilatory mechanics.' from _case30_steps s where s.step_order = 3
union all select s.id, 'B', 'Reassess airway protection and secretion clearance', 2, 'This is a key escalation trigger.' from _case30_steps s where s.step_order = 3
union all select s.id, 'C', 'Repeat ABG and trend EtCO2', 2, 'This confirms worsening ventilatory failure.' from _case30_steps s where s.step_order = 3
union all select s.id, 'D', 'Determine whether controlled intubation is now required', 2, 'This is the central next-step decision.' from _case30_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop close monitoring after a small SpO2 improvement', -3, 'This is unsafe.' from _case30_steps s where s.step_order = 3
union all select s.id, 'F', 'Delay reassessment for several hours', -3, 'This is unsafe.' from _case30_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed with controlled endotracheal intubation and ICU-level ventilatory support', 3, 'This is indicated for worsening secretion control and rising hypercapnia.' from _case30_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue the same treatment unchanged and reassess later', -3, 'This delays indicated airway control.' from _case30_steps s where s.step_order = 4
union all select s.id, 'C', 'Use CPAP alone and avoid invasive support', -3, 'This does not protect the airway.' from _case30_steps s where s.step_order = 4
union all select s.id, 'D', 'Transfer to an unmonitored bed once the patient is calmer', -3, 'This is unsafe.' from _case30_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Jaw opening is limited, secretions are difficult to clear, and tetanus is strongly suspected.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case30_steps s1 cross join _case30_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Rigidity worsens, and oxygenation declines.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":4,"bp_dia":2,"etco2":2}'::jsonb
from _case30_steps s1 cross join _case30_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Initial stabilization begins, but secretion management and ventilation remain poor.',
  '{"spo2":2,"hr":0,"rr":2,"bp_sys":2,"bp_dia":1,"etco2":2}'::jsonb
from _case30_steps s2 cross join _case30_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Treatment is delayed. Hypercapnia and rigidity worsen.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":6,"bp_dia":3,"etco2":4}'::jsonb
from _case30_steps s2 cross join _case30_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Air movement remains poor, secretions pool, and rising PaCO2 confirms the need for airway control.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case30_steps s3 cross join _case30_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed. The patient becomes progressively harder to ventilate.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":4,"bp_dia":2,"etco2":3}'::jsonb
from _case30_steps s3 cross join _case30_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is intubated and admitted to the ICU for tetanus-related ventilatory support.',
  '{"spo2":4,"hr":-4,"rr":-6,"bp_sys":-2,"bp_dia":-1,"etco2":-4}'::jsonb
from _case30_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed airway control leads to worsening respiratory failure.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":6,"bp_dia":3,"etco2":4}'::jsonb
from _case30_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE30_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case30_target);

commit;
