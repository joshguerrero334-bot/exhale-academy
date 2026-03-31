-- Exhale Academy CSE Case #3 Branching Seed (PACU Sudden Postoperative Respiratory Collapse)
-- Rewritten to reveal tension-pneumothorax findings through bedside assessment.

begin;

create temporary table _case3_target (id uuid primary key) on commit drop;
create temporary table _case3_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-3-pacu-sudden-postop-respiratory-collapse'
     or lower(coalesce(title, '')) like '%case 3%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'pacu-postop-respiratory-emergency',
    disease_slug = 'postoperative-tension-pneumothorax',
    disease_track = 'critical',
    case_number = 3,
    slug = 'case-3-pacu-sudden-postop-respiratory-collapse',
    title = 'Case 3 -- PACU Sudden Postoperative Respiratory Collapse',
    intro_text = 'Postoperative patient with abrupt respiratory collapse requiring bedside recognition of obstructive thoracic physiology.',
    description = 'Critical postoperative case focused on airway support, targeted chest assessment, and urgent pleural decompression.',
    stem = 'PACU patient develops sudden respiratory collapse and obstructive shock after surgery.',
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
    'pacu-postop-respiratory-emergency',
    'postoperative-tension-pneumothorax',
    'critical',
    3,
    'case-3-pacu-sudden-postop-respiratory-collapse',
    'Case 3 -- PACU Sudden Postoperative Respiratory Collapse',
    'Postoperative patient with abrupt respiratory collapse requiring bedside recognition of obstructive thoracic physiology.',
    'Critical postoperative case focused on airway support, targeted chest assessment, and urgent pleural decompression.',
    'PACU patient develops sudden respiratory collapse and obstructive shock after surgery.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case3_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":118,"rr":30,"spo2":83,"bp_sys":146,"bp_dia":84,"etco2":50}'::jsonb
where id in (select id from _case3_target);

delete from public.cse_attempt_events
where attempt_id in (select a.id from public.cse_attempts a where a.case_id in (select id from _case3_target))
   or step_id in (select s.id from public.cse_steps s where s.case_id in (select id from _case3_target))
   or outcome_id in (
      select o.id from public.cse_outcomes o
      join public.cse_steps s on s.id = o.step_id
      where s.case_id in (select id from _case3_target)
   );

delete from public.cse_attempts where case_id in (select id from _case3_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case3_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case3_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case3_target));
delete from public.cse_steps where case_id in (select id from _case3_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
'A 61-year-old man in the PACU becomes abruptly restless and then drowsy with increasing respiratory distress.

While receiving O2 by face mask, the following are noted:
HR 118/min
RR 30/min
BP 146/84 mm Hg
SpO2 83%
EtCO2 50 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).',
  4, 'STOP',
  '{
    "show_appearance_after_submit": true,
    "appearance_text": "the patient has marked distress and poor chest expansion",
    "extra_reveals": [
      { "text": "Breath sounds are markedly decreased on the right.", "keys_any": ["A"] },
      { "text": "Right chest expansion is reduced.", "keys_any": ["B"] },
      { "text": "Right chest percussion is hyperresonant.", "keys_any": ["C"] },
      { "text": "Continuous pulse oximetry and capnography confirm worsening oxygenation and ventilation.", "keys_any": ["D"] },
      { "text": "The operative note documents recent central-line placement during surgery.", "keys_any": ["E"] }
    ]
  }'::jsonb from _case3_target
  union all
  select id, 2, 2, 'DM',
'Ventilation remains poor, and obstructive thoracic physiology is suspected. Which of the following should be recommended FIRST?',
  null, 'STOP', '{}'::jsonb from _case3_target
  union all
  select id, 3, 3, 'IG',
'After assisted ventilation begins, the patient suddenly becomes hypotensive.

While receiving bag-mask ventilation with 100% O2, the following are noted:
HR 132/min
RR 18/min assisted
BP 82/48 mm Hg
SpO2 78%
EtCO2 58 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
  4, 'STOP',
  '{
    "show_appearance_after_submit": true,
    "appearance_text": "manual ventilation is difficult, and shock is worsening",
    "extra_reveals": [
      { "text": "Breath sounds remain absent on the right.", "keys_any": ["A"] },
      { "text": "Tracheal position is shifted to the left.", "keys_any": ["B"] },
      { "text": "The right chest remains hyperresonant to percussion.", "keys_any": ["C"] },
      { "text": "Immediate pleural decompression is required.", "keys_any": ["D"] }
    ]
  }'::jsonb from _case3_target
  union all
  select id, 4, 4, 'DM',
'Hypotension and hypoxemia worsen with findings consistent with tension pneumothorax. Which of the following should be recommended now?',
  null, 'STOP', '{}'::jsonb from _case3_target
  returning id, step_order
)
insert into _case3_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Auscultate breath sounds', 2, 'This is indicated in the initial assessment.' from _case3_steps s where s.step_order = 1
union all select s.id, 'B', 'Inspect chest expansion', 2, 'This is indicated in the initial assessment.' from _case3_steps s where s.step_order = 1
union all select s.id, 'C', 'Percuss the chest', 2, 'This is indicated in the initial assessment.' from _case3_steps s where s.step_order = 1
union all select s.id, 'D', 'Apply continuous pulse oximetry and capnography', 2, 'This is indicated in the initial assessment.' from _case3_steps s where s.step_order = 1
union all select s.id, 'E', 'Review the recent procedure history', 1, 'This provides useful supporting context.' from _case3_steps s where s.step_order = 1
union all select s.id, 'F', 'Delay treatment until chest CT is completed', -3, 'This delays indicated therapy.' from _case3_steps s where s.step_order = 1
union all select s.id, 'G', 'Give additional opioid for agitation', -3, 'This is unsafe.' from _case3_steps s where s.step_order = 1

union all select s.id, 'A', 'Insert an airway adjunct if needed and begin assisted ventilation with 100% O2 while calling for immediate help', 3, 'This is the best first step.' from _case3_steps s where s.step_order = 2
union all select s.id, 'B', 'Observe on oxygen only', -3, 'This is inadequate.' from _case3_steps s where s.step_order = 2
union all select s.id, 'C', 'Transfer to a regular floor bed', -3, 'This is unsafe.' from _case3_steps s where s.step_order = 2
union all select s.id, 'D', 'Sedate the patient before ventilation is controlled', -3, 'This is unsafe.' from _case3_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess breath sounds', 2, 'This is indicated in reassessment.' from _case3_steps s where s.step_order = 3
union all select s.id, 'B', 'Check tracheal position', 2, 'This is indicated in reassessment.' from _case3_steps s where s.step_order = 3
union all select s.id, 'C', 'Repeat chest percussion', 2, 'This is indicated in reassessment.' from _case3_steps s where s.step_order = 3
union all select s.id, 'D', 'Determine whether immediate pleural decompression is required', 2, 'This is the key escalation decision.' from _case3_steps s where s.step_order = 3
union all select s.id, 'E', 'Delay reassessment until a radiograph is available', -3, 'This is unsafe.' from _case3_steps s where s.step_order = 3
union all select s.id, 'F', 'Stop close monitoring after bag-mask ventilation begins', -3, 'This is unsafe.' from _case3_steps s where s.step_order = 3

union all select s.id, 'A', 'Perform immediate right-sided pleural decompression and prepare definitive chest drainage', 3, 'This is the best next step.' from _case3_steps s where s.step_order = 4
union all select s.id, 'B', 'Obtain imaging before intervention', -3, 'This delays lifesaving treatment.' from _case3_steps s where s.step_order = 4
union all select s.id, 'C', 'Continue bag-mask ventilation and reassess much later', -3, 'This delays indicated treatment.' from _case3_steps s where s.step_order = 4
union all select s.id, 'D', 'Transfer to a low-acuity bed after brief improvement', -3, 'This is unsafe.' from _case3_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Unilateral chest findings are identified, and respiratory failure remains severe.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case3_steps s1 cross join _case3_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete, and the patient deteriorates.',
  '{"spo2":-4,"hr":5,"rr":3,"bp_sys":-4,"bp_dia":-3,"etco2":3}'::jsonb
from _case3_steps s1 cross join _case3_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Ventilation is supported, but obstructive shock rapidly develops.',
  '{"spo2":2,"hr":2,"rr":-10,"bp_sys":-20,"bp_dia":-12,"etco2":8}'::jsonb
from _case3_steps s2 cross join _case3_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all select s2.id, 99, 'DEFAULT', null, s3.id,
  'Ventilation remains inadequate, and instability worsens.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-8,"bp_dia":-5,"etco2":4}'::jsonb
from _case3_steps s2 cross join _case3_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all select s3.id, 1, 'SCORE_AT_LEAST', '6'::jsonb, s4.id,
  'Reassessment confirms tension pneumothorax with obstructive shock.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case3_steps s3 cross join _case3_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and shock worsens.',
  '{"spo2":-4,"hr":5,"rr":3,"bp_sys":-6,"bp_dia":-4,"etco2":3}'::jsonb
from _case3_steps s3 cross join _case3_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: pleural decompression stabilizes the patient, and definitive drainage is completed in critical care.',
  '{"spo2":6,"hr":-6,"rr":-4,"bp_sys":12,"bp_dia":8,"etco2":-4}'::jsonb
from _case3_steps s4 where s4.step_order = 4
union all select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed decompression leads to worsening shock and hypoxemia.',
  '{"spo2":-8,"hr":8,"rr":4,"bp_sys":-10,"bp_dia":-6,"etco2":5}'::jsonb
from _case3_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE3_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case3_target);

commit;
