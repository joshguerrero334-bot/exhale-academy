-- Exhale Academy CSE Branching Seed (Case 47)
-- Neonatal Critical (Congenital Diaphragmatic Hernia)

begin;

create temporary table _case47_target (id uuid primary key) on commit drop;
create temporary table _case47_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'neonatal-critical-cdh-surgical-emergency-mediastinal-shift'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'neonatal-critical-surgical',
    disease_slug = 'congenital-diaphragmatic-hernia',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 47),
    slug = 'neonatal-critical-cdh-surgical-emergency-mediastinal-shift',
    title = 'Neonatal Critical (CDH Surgical Emergency Mediastinal Shift)',
    intro_text = 'Neonate with severe respiratory distress and classic congenital diaphragmatic hernia clues requiring immediate airway and decompression decisions.',
    description = 'Neonatal CDH case focused on recognition, avoiding bag-mask ventilation, intubation strategy, and surgical/NICU continuation.',
    stem = 'Newborn with severe distress and asymmetric chest findings requires immediate CDH-specific management.',
    difficulty = 'hard',
    is_active = true,
    is_published = true,
    baseline_vitals = '{"hr":170,"rr":64,"spo2":74,"bp_sys":58,"bp_dia":34,"etco2":58}'::jsonb,
    nbrc_category_code = 'G',
    nbrc_category_name = 'Neonatal',
    nbrc_subcategory = 'Respiratory distress syndrome'
  where c.id in (select id from existing)
  returning c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty,
    is_active, is_published, baseline_vitals, nbrc_category_code, nbrc_category_name, nbrc_subcategory
  )
  select
    'neonatal-critical-surgical',
    'congenital-diaphragmatic-hernia',
    'critical',
    47,
    'neonatal-critical-cdh-surgical-emergency-mediastinal-shift',
    'Neonatal Critical (CDH Surgical Emergency Mediastinal Shift)',
    'Neonate with severe respiratory distress and classic congenital diaphragmatic hernia clues requiring immediate airway and decompression decisions.',
    'Neonatal CDH case focused on recognition, avoiding bag-mask ventilation, intubation strategy, and surgical/NICU continuation.',
    'Newborn with severe distress and asymmetric chest findings requires immediate CDH-specific management.',
    'hard',
    true,
    true,
    '{"hr":170,"rr":64,"spo2":74,"bp_sys":58,"bp_dia":34,"etco2":58}'::jsonb,
    'G',
    'Neonatal',
    'Respiratory distress syndrome'
  where not exists (select 1 from existing)
  returning id
)
insert into _case47_target (id)
select id from updated
union all
select id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case47_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case47_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case47_target)
);

delete from public.cse_attempts where case_id in (select id from _case47_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case47_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case47_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case47_target));
delete from public.cse_steps where case_id in (select id from _case47_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
'A term newborn develops severe respiratory distress immediately after birth.

The following are noted:
HR 170/min
RR 64/min
SpO2 74%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).',
  4,
  'STOP',
  '{"show_appearance_after_submit":true,"appearance_text":"the infant is cyanotic with marked retractions","extra_reveals":[{"text":"Breath sounds are markedly reduced on the left.","keys_any":["A"]},{"text":"The abdomen appears scaphoid.","keys_any":["B"]},{"text":"Cardiac sounds are displaced to the right.","keys_any":["C"]},{"text":"Chest radiograph supports bowel in the thorax with mediastinal shift.","keys_any":["D"]}]}'::jsonb
  from _case47_target
  union all
  select id, 2, 2, 'DM',
'Findings suggest congenital diaphragmatic hernia. Which of the following should be recommended FIRST?',
  null,
  'STOP',
  '{}'::jsonb
  from _case47_target
  union all
  select id, 3, 3, 'IG',
'After initial CDH-specific stabilization, the infant remains critically ill.

Current findings are:
HR 156/min
SpO2 84%
EtCO2 50 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
  4,
  'STOP',
  '{"show_appearance_after_submit":true,"appearance_text":"the infant is intubated and less agitated but still unstable","extra_reveals":[{"text":"Endotracheal tube position and effective ventilation must be confirmed.","keys_any":["A"]},{"text":"OG decompression effectiveness should be reassessed.","keys_any":["B"]},{"text":"ABG: pH 7.27, PaCO2 54 torr, PaO2 52 torr, HCO3 24 mEq/L.","keys_any":["C"]},{"text":"Ongoing surgical/NICU readiness is still required.","keys_any":["D"]}]}'::jsonb
  from _case47_target
  union all
  select id, 4, 4, 'DM',
'Which of the following should be recommended now?',
  null,
  'STOP',
  '{}'::jsonb
  from _case47_target
  returning id, step_order
)
insert into _case47_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Assess unilateral breath sounds and chest movement', 2, 'This is indicated immediately.' from _case47_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess whether the abdomen is scaphoid', 2, 'This is a classic CDH clue.' from _case47_steps s where s.step_order = 1
union all select s.id, 'C', 'Assess cardiac sound displacement and severity of distress', 2, 'This helps identify mediastinal shift and severity.' from _case47_steps s where s.step_order = 1
union all select s.id, 'D', 'Review radiographic evidence if available without delaying stabilization', 2, 'This supports the diagnosis.' from _case47_steps s where s.step_order = 1
union all select s.id, 'E', 'Begin routine bag-mask ventilation while sorting out the diagnosis', -3, 'This is unsafe in suspected CDH.' from _case47_steps s where s.step_order = 1
union all select s.id, 'F', 'Delay stabilization until imaging is complete', -3, 'This is unsafe.' from _case47_steps s where s.step_order = 1

union all select s.id, 'A', 'Proceed with endotracheal intubation, place an OG tube for decompression, and avoid bag-mask ventilation', 3, 'This is the correct first treatment strategy.' from _case47_steps s where s.step_order = 2
union all select s.id, 'B', 'Use bag-mask ventilation and observe the response', -3, 'This worsens gastric distention in CDH.' from _case47_steps s where s.step_order = 2
union all select s.id, 'C', 'Use oxygen only and delay definitive airway management', -3, 'This is inadequate.' from _case47_steps s where s.step_order = 2
union all select s.id, 'D', 'Transfer to lower-acuity care after brief stabilization', -3, 'This is unsafe.' from _case47_steps s where s.step_order = 2

union all select s.id, 'A', 'Confirm endotracheal tube position and adequacy of ventilation', 2, 'This is indicated after intubation.' from _case47_steps s where s.step_order = 3
union all select s.id, 'B', 'Reassess OG decompression and abdominal/chest distention', 2, 'This is a key CDH-specific reassessment.' from _case47_steps s where s.step_order = 3
union all select s.id, 'C', 'Repeat blood-gas assessment and trend ventilation/oxygenation', 2, 'This is appropriate in ongoing instability.' from _case47_steps s where s.step_order = 3
union all select s.id, 'D', 'Determine ongoing NICU and surgical readiness', 2, 'This addresses the next management step.' from _case47_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop close monitoring after slight saturation improvement', -3, 'This is unsafe.' from _case47_steps s where s.step_order = 3
union all select s.id, 'F', 'Return to bag-mask ventilation if oxygenation remains low', -3, 'This is unsafe in CDH.' from _case47_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue NICU-level care with ventilatory support, gastric decompression, and urgent surgical planning', 3, 'This is the safest ongoing plan.' from _case47_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to routine nursery care', -3, 'This is unsafe.' from _case47_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge after temporary stabilization', -3, 'This is unsafe.' from _case47_steps s where s.step_order = 4
union all select s.id, 'D', 'Observe without explicit escalation or surgical planning', -2, 'This is inadequate.' from _case47_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Initial assessment supports congenital diaphragmatic hernia with mediastinal shift and severe distress.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case47_steps s1 cross join _case47_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment delays worsen hypoxemia and instability.',
  '{"spo2":-5,"hr":6,"rr":4,"bp_sys":-3,"bp_dia":-2,"etco2":3}'::jsonb
from _case47_steps s1 cross join _case47_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'CDH-specific stabilization begins, and oxygenation improves slightly.',
  '{"spo2":6,"hr":-8,"rr":-4,"bp_sys":2,"bp_dia":1,"etco2":-4}'::jsonb
from _case47_steps s2 cross join _case47_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Unsafe support worsens thoracic compression and gas exchange.',
  '{"spo2":-8,"hr":8,"rr":5,"bp_sys":-4,"bp_dia":-3,"etco2":4}'::jsonb
from _case47_steps s2 cross join _case47_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Reassessment confirms continued need for surgical/NICU management.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case47_steps s3 cross join _case47_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps leave high risk for recurrent deterioration.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-2,"bp_dia":-1,"etco2":2}'::jsonb
from _case47_steps s3 cross join _case47_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the infant remains in high-acuity neonatal care with definitive surgical planning.',
  '{"spo2":2,"hr":-2,"rr":-1,"bp_sys":0,"bp_dia":0,"etco2":-1}'::jsonb
from _case47_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: inadequate CDH management leads to recurrent neonatal instability.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-2,"bp_dia":-1,"etco2":3}'::jsonb
from _case47_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override)
select
  r.step_id,
  'CASE47_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case47_target);

commit;
