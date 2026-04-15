-- Exhale Academy CSE Branching Seed (Case 41)
-- Neonatal Critical (Delivery Room Apgar Resuscitation)

begin;

create temporary table _case41_target (id uuid primary key) on commit drop;
create temporary table _case41_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'neonatal-critical-delivery-room-apgar-resuscitation'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'neonatal-critical-delivery-room',
    disease_slug = 'delivery-room-management',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 41),
    slug = 'neonatal-critical-delivery-room-apgar-resuscitation',
    title = 'Neonatal Critical (Delivery Room Apgar Resuscitation)',
    intro_text = 'High-risk preterm delivery with poor respiratory effort requiring timed Apgar-based stabilization and reassessment.',
    description = 'Neonatal delivery-room case focused on Apgar components, immediate respiratory support, and NICU transition.',
    stem = 'Newborn has poor effort and cyanosis after delivery and requires rapid resuscitation decisions.',
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
    'neonatal-critical-delivery-room',
    'delivery-room-management',
    'critical',
    41,
    'neonatal-critical-delivery-room-apgar-resuscitation',
    'Neonatal Critical (Delivery Room Apgar Resuscitation)',
    'High-risk preterm delivery with poor respiratory effort requiring timed Apgar-based stabilization and reassessment.',
    'Neonatal delivery-room case focused on Apgar components, immediate respiratory support, and NICU transition.',
    'Newborn has poor effort and cyanosis after delivery and requires rapid resuscitation decisions.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case41_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":92,"rr":18,"spo2":74,"bp_sys":56,"bp_dia":34,"etco2":50}'::jsonb
where id in (select id from _case41_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case41_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case41_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o join public.cse_steps s on s.id = o.step_id where s.case_id in (select id from _case41_target)
);

delete from public.cse_attempts where case_id in (select id from _case41_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case41_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case41_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case41_target));
delete from public.cse_steps where case_id in (select id from _case41_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
'A 30-week preterm infant is brought to the warmer immediately after delivery.

The following are noted:
HR 92/min
Weak respiratory effort
Poor color
SpO2 74%

Which of the following should be evaluated or performed initially? SELECT AS MANY AS INDICATED (MAX 4).',
  4,
  'STOP',
  '{"show_appearance_after_submit":true,"appearance_text":"the infant is floppy with weak respirations","extra_reveals":[{"text":"The airway, tone, and respiratory effort should be scored as part of the Apgar assessment.","keys_any":["A"]},{"text":"Heart rate remains below 100/min.","keys_any":["B"]},{"text":"The infant needs thermal support and immediate respiratory stabilization.","keys_any":["C"]},{"text":"Apgar reassessment will need to continue at the appropriate interval after intervention.","keys_any":["D"]}]}'::jsonb
  from _case41_target
  union all
  select id, 2, 2, 'DM',
'Findings suggest significant neonatal depression with ineffective respirations. Which of the following should be recommended FIRST?',
  null,
  'STOP',
  '{}'::jsonb
  from _case41_target
  union all
  select id, 3, 3, 'IG',
'After initial respiratory support, the infant shows improving chest movement but still needs close reassessment.

Current findings are:
HR 118/min
SpO2 84%
Improved but still labored respirations

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
  4,
  'STOP',
  '{"show_appearance_after_submit":true,"appearance_text":"color and tone improve but remain suboptimal","extra_reveals":[{"text":"Repeat Apgar components should be documented on time.","keys_any":["A"]},{"text":"Oxygenation trend and work of breathing still require close monitoring.","keys_any":["B"]},{"text":"ABG may help if respiratory distress remains significant.","keys_any":["C"]},{"text":"NICU-level post-resuscitation observation is still required.","keys_any":["D"]}]}'::jsonb
  from _case41_target
  union all
  select id, 4, 4, 'DM',
'Which of the following should be recommended now?',
  null,
  'STOP',
  '{}'::jsonb
  from _case41_target
  returning id, step_order
)
insert into _case41_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Assess Apgar components, including respiratory effort and tone', 2, 'This is a high-yield neonatal first step.' from _case41_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess heart rate immediately', 2, 'This determines the next resuscitation action.' from _case41_steps s where s.step_order = 1
union all select s.id, 'C', 'Provide thermal support and immediate stabilization at the warmer', 2, 'This is indicated at once.' from _case41_steps s where s.step_order = 1
union all select s.id, 'D', 'Plan timed Apgar reassessment after intervention', 2, 'This is part of the neonatal workflow.' from _case41_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay intervention until the full delivery-room history is complete', -3, 'This is unsafe.' from _case41_steps s where s.step_order = 1
union all select s.id, 'F', 'Transfer to routine care before stabilization', -3, 'This is unsafe.' from _case41_steps s where s.step_order = 1

union all select s.id, 'A', 'Provide appropriate assisted ventilation and oxygen support based on the infant’s ineffective respirations', 3, 'This is the best first intervention.' from _case41_steps s where s.step_order = 2
union all select s.id, 'B', 'Observe without respiratory support because the infant is preterm', -3, 'This is unsafe.' from _case41_steps s where s.step_order = 2
union all select s.id, 'C', 'Begin chest compressions before correcting ventilation', -3, 'This is premature here.' from _case41_steps s where s.step_order = 2
union all select s.id, 'D', 'Transfer to routine nursery care after the first improvement', -3, 'This is unsafe.' from _case41_steps s where s.step_order = 2

union all select s.id, 'A', 'Repeat Apgar components at the correct interval', 2, 'This is indicated.' from _case41_steps s where s.step_order = 3
union all select s.id, 'B', 'Trend oxygenation and work of breathing', 2, 'This guides ongoing support.' from _case41_steps s where s.step_order = 3
union all select s.id, 'C', 'Obtain objective gas-exchange data if distress remains significant', 2, 'This is appropriate if instability persists.' from _case41_steps s where s.step_order = 3
union all select s.id, 'D', 'Determine the need for NICU-level post-resuscitation monitoring', 2, 'This is the key disposition question.' from _case41_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop monitoring after one modest improvement', -3, 'This is unsafe.' from _case41_steps s where s.step_order = 3
union all select s.id, 'F', 'Delay reassessment for several hours', -3, 'This is unsafe.' from _case41_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue monitored NICU-level care with oxygen titration and post-resuscitation reassessment', 3, 'This is the safest ongoing plan.' from _case41_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to routine nursery care immediately', -3, 'This is unsafe.' from _case41_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge after temporary improvement', -3, 'This is unsafe.' from _case41_steps s where s.step_order = 4
union all select s.id, 'D', 'Observe without structured escalation triggers', -2, 'This is inadequate.' from _case41_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Initial neonatal assessment identifies significant depression and need for respiratory support.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case41_steps s1 cross join _case41_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is delayed, and neonatal instability worsens.',
  '{"spo2":-5,"hr":-8,"rr":-2,"bp_sys":-2,"bp_dia":-1,"etco2":2}'::jsonb
from _case41_steps s1 cross join _case41_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Respiratory support improves heart rate and oxygenation, but continued reassessment is required.',
  '{"spo2":10,"hr":26,"rr":6,"bp_sys":2,"bp_dia":1,"etco2":-4}'::jsonb
from _case41_steps s2 cross join _case41_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate support leads to worsening respiratory transition.',
  '{"spo2":-6,"hr":-10,"rr":-2,"bp_sys":-2,"bp_dia":-1,"etco2":3}'::jsonb
from _case41_steps s2 cross join _case41_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Reassessment confirms improvement but continued need for monitored neonatal care.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case41_steps s3 cross join _case41_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps leave high risk for recurrent neonatal deterioration.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-2,"bp_dia":-1,"etco2":2}'::jsonb
from _case41_steps s3 cross join _case41_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the infant remains in the NICU for monitored post-resuscitation care.',
  '{"spo2":2,"hr":4,"rr":2,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case41_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: inadequate monitoring leads to recurrent neonatal instability.',
  '{"spo2":-6,"hr":-6,"rr":4,"bp_sys":-2,"bp_dia":-1,"etco2":2}'::jsonb
from _case41_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override)
select
  r.step_id,
  'CASE41_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case41_target);

commit;
