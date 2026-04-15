-- Exhale Academy CSE Branching Seed (Case 2)
-- Term Infant Transition Failure (Meconium Context)

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
    disease_slug = 'delivery-room-transition',
    disease_track = 'critical',
    case_number = 2,
    slug = 'case-2-term-infant-meconium-transition-failure',
    title = 'Case 2 -- Term Infant Transition Failure (Meconium Context)',
    intro_text = 'Term infant delivered through meconium-stained fluid with poor tone and ineffective respirations requiring immediate delivery-room stabilization.',
    description = 'Neonatal transition case focused on initial resuscitation priorities, effective ventilation, and monitored post-resuscitation care.',
    stem = 'Depressed term newborn requires rapid airway, ventilation, and reassessment decisions at the warmer.',
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
    'term-delivery-room-transition',
    'delivery-room-transition',
    'critical',
    2,
    'case-2-term-infant-meconium-transition-failure',
    'Case 2 -- Term Infant Transition Failure (Meconium Context)',
    'Term infant delivered through meconium-stained fluid with poor tone and ineffective respirations requiring immediate delivery-room stabilization.',
    'Neonatal transition case focused on initial resuscitation priorities, effective ventilation, and monitored post-resuscitation care.',
    'Depressed term newborn requires rapid airway, ventilation, and reassessment decisions at the warmer.',
    'hard',
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

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case2_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case2_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case2_target)
);

delete from public.cse_attempts where case_id in (select id from _case2_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case2_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case2_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case2_target));
delete from public.cse_steps where case_id in (select id from _case2_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
'A term male infant is brought to the warmer immediately after delivery through thick meconium-stained fluid.

The following are noted:
HR 84/min
Weak respiratory effort
Poor tone
SpO2 62%

Which of the following should be evaluated or performed initially? SELECT AS MANY AS INDICATED (MAX 4).',
  4,
  'STOP',
  '{"show_appearance_after_submit":true,"appearance_text":"the infant is limp and cyanotic","extra_reveals":[{"text":"The airway is not well positioned, and chest movement is minimal.","keys_any":["A"]},{"text":"Heart rate remains below 100/min after the initial quick assessment.","keys_any":["B"]},{"text":"The infant is not crying effectively and has poor tone.","keys_any":["C"]},{"text":"Routine deep tracheal suctioning before ventilation is not automatically indicated.","keys_any":["D"]}]}'::jsonb
  from _case2_target
  union all
  select id, 2, 2, 'DM',
'Heart rate remains below 100/min and respirations are ineffective. Which of the following should be recommended FIRST?',
  null,
  'STOP',
  '{}'::jsonb
  from _case2_target
  union all
  select id, 3, 3, 'IG',
'Positive-pressure ventilation is started, but chest rise is poor.

Current findings are:
HR 78/min
SpO2 66%

Which of the following should be evaluated or corrected now? SELECT AS MANY AS INDICATED (MAX 4).',
  4,
  'STOP',
  '{"show_appearance_after_submit":true,"appearance_text":"there is still little visible chest movement","extra_reveals":[{"text":"Head position and mask seal need correction.","keys_any":["A"]},{"text":"Secretions in the mouth and nose may be limiting airflow.","keys_any":["B"]},{"text":"More inspiratory pressure is required to achieve chest rise.","keys_any":["C"]},{"text":"Effective ventilation improves heart rate before compressions are considered.","keys_any":["D"]}]}'::jsonb
  from _case2_target
  union all
  select id, 4, 4, 'DM',
'After effective ventilation, heart rate rises above 100/min, but respiratory distress persists. Which of the following should be recommended now?',
  null,
  'STOP',
  '{}'::jsonb
  from _case2_target
  returning id, step_order
)
insert into _case2_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Position the airway and assess chest movement', 2, 'This is an appropriate first action.' from _case2_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess heart rate and breathing effectiveness immediately', 2, 'This determines the next resuscitation step.' from _case2_steps s where s.step_order = 1
union all select s.id, 'C', 'Assess tone and respiratory effort', 2, 'This helps define the degree of depression.' from _case2_steps s where s.step_order = 1
union all select s.id, 'D', 'Recognize that routine deep tracheal suctioning before ventilation is not automatic', 2, 'This avoids unnecessary delay.' from _case2_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay intervention until a complete physical exam is finished', -3, 'This is unsafe.' from _case2_steps s where s.step_order = 1
union all select s.id, 'F', 'Start compressions before correcting ventilation', -3, 'Ventilation is the first priority here.' from _case2_steps s where s.step_order = 1

union all select s.id, 'A', 'Begin positive-pressure ventilation and confirm effective chest movement', 3, 'This is the correct first intervention.' from _case2_steps s where s.step_order = 2
union all select s.id, 'B', 'Use blow-by oxygen only', -3, 'This is inadequate.' from _case2_steps s where s.step_order = 2
union all select s.id, 'C', 'Begin chest compressions immediately without ventilation correction', -3, 'This is premature.' from _case2_steps s where s.step_order = 2
union all select s.id, 'D', 'Transfer to routine nursery care and reassess later', -3, 'This is unsafe.' from _case2_steps s where s.step_order = 2

union all select s.id, 'A', 'Reposition the head and improve mask seal', 2, 'This is indicated when chest rise is poor.' from _case2_steps s where s.step_order = 3
union all select s.id, 'B', 'Clear mouth and nose secretions if they are obstructing ventilation', 2, 'This may improve airflow.' from _case2_steps s where s.step_order = 3
union all select s.id, 'C', 'Increase inspiratory pressure enough to obtain chest rise', 2, 'This is indicated if initial pressure is inadequate.' from _case2_steps s where s.step_order = 3
union all select s.id, 'D', 'Recognize that effective ventilation should improve heart rate before compressions are started', 2, 'This reflects correct sequence.' from _case2_steps s where s.step_order = 3
union all select s.id, 'E', 'Pause ventilation for diagnostic blood sampling', -3, 'This is unsafe.' from _case2_steps s where s.step_order = 3
union all select s.id, 'F', 'Continue ineffective breaths unchanged', -3, 'This delays correction.' from _case2_steps s where s.step_order = 3

union all select s.id, 'A', 'Admit to monitored neonatal care with oxygen titration, glucose/temperature monitoring, and continued respiratory reassessment', 3, 'This is the safest ongoing plan.' from _case2_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer immediately to routine well-baby care', -3, 'This is unsafe.' from _case2_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge after brief observation', -3, 'This is unsafe.' from _case2_steps s where s.step_order = 4
union all select s.id, 'D', 'Observe without structured monitoring', -2, 'This is an inadequate plan.' from _case2_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Initial neonatal assessment identifies poor tone, ineffective respirations, and the need for assisted ventilation.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0}'::jsonb
from _case2_steps s1 cross join _case2_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is delayed, and cyanosis and bradycardia worsen.',
  '{"spo2":-6,"hr":-10,"rr":-2,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _case2_steps s1 cross join _case2_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Ventilation begins, but chest rise remains inadequate and requires correction.',
  '{"spo2":4,"hr":-6,"rr":4,"bp_sys":0,"bp_dia":0}'::jsonb
from _case2_steps s2 cross join _case2_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate support leads to worsening bradycardia and hypoxemia.',
  '{"spo2":-8,"hr":-12,"rr":-2,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _case2_steps s2 cross join _case2_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Ventilation becomes effective, and heart rate rises above 100/min.',
  '{"spo2":12,"hr":28,"rr":10,"bp_sys":2,"bp_dia":1}'::jsonb
from _case2_steps s3 cross join _case2_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Ventilation remains ineffective, and the infant stays unstable.',
  '{"spo2":-6,"hr":-8,"rr":-2,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _case2_steps s3 cross join _case2_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the infant is admitted for monitored neonatal care after resuscitation and transition support.',
  '{"spo2":4,"hr":4,"rr":4,"bp_sys":0,"bp_dia":0}'::jsonb
from _case2_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: inadequate monitoring leads to recurrent neonatal instability.',
  '{"spo2":-6,"hr":-6,"rr":6,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _case2_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override)
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
