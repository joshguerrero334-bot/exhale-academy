-- Combined runner for case 16 + case 17
-- Generated: 2026-03-30

-- Exhale Academy CSE Branching Seed (Trauma Critical - Tension Pneumothorax)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case16_target (id uuid primary key) on commit drop;
create temporary table _case16_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-16-trauma-critical-tension-pneumothorax',
    'trauma-critical-tension-pneumothorax'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'trauma-critical',
    disease_slug = 'chest-trauma',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 16),
    slug = 'trauma-critical-tension-pneumothorax',
    title = 'Trauma Critical (Tension Pneumothorax)',
    intro_text = 'Chest trauma with severe respiratory distress and hemodynamic compromise requiring decompression-first management.',
    description = 'Critical trauma branching case focused on bedside recognition of tension physiology and urgent pleural decompression.',
    stem = 'Trauma patient has severe respiratory distress and hemodynamic instability after chest injury.',
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
    'trauma-critical',
    'chest-trauma',
    'critical',
    16,
    'trauma-critical-tension-pneumothorax',
    'Trauma Critical (Tension Pneumothorax)',
    'Chest trauma with severe respiratory distress and hemodynamic compromise requiring decompression-first management.',
    'Critical trauma branching case focused on bedside recognition of tension physiology and urgent pleural decompression.',
    'Trauma patient has severe respiratory distress and hemodynamic instability after chest injury.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case16_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":148,"rr":38,"spo2":78,"bp_sys":78,"bp_dia":46}'::jsonb
where id in (select id from _case16_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case16_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case16_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case16_target)
);

delete from public.cse_attempts where case_id in (select id from _case16_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case16_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case16_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case16_target));
delete from public.cse_steps where case_id in (select id from _case16_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 34-year-old man is brought to the emergency department after a motorcycle crash.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 148/min
RR 38/min
BP 78/46 mm Hg
SpO2 78%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).',
    4, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "severe distress persists with marked asymmetry of the right hemithorax",
      "extra_reveals": [
        { "text": "Chest expansion is markedly reduced on the right.", "keys_any": ["A"] },
        { "text": "Breath sounds are absent on the right.", "keys_any": ["B"] },
        { "text": "Percussion is hyperresonant on the right.", "keys_any": ["C"] },
        { "text": "The trachea is shifted to the left.", "keys_any": ["D"] }
      ]
    }'::jsonb from _case16_target
  union all
  select id, 2, 2, 'DM',
    'The patient remains severely hypoxemic and hypotensive. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case16_target
  union all
  select id, 3, 3, 'IG',
    'After immediate decompression, oxygenation improves and blood pressure increases.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 126/min
RR 30/min
BP 96/60 mm Hg
SpO2 88%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
    4, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "manual ventilation is easier and distress is less severe",
      "extra_reveals": [
        { "text": "Right chest expansion has improved.", "keys_any": ["A"] },
        { "text": "Faint breath sounds are now heard on the right.", "keys_any": ["B"] },
        { "text": "Blood pressure and oxygenation are improving but still unstable.", "keys_any": ["C"] },
        { "text": "Definitive chest tube placement is still required.", "keys_any": ["D"] }
      ]
    }'::jsonb from _case16_target
  union all
  select id, 4, 4, 'DM',
    'The patient remains at high risk for recurrent deterioration. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case16_target
  returning id, step_order
)
insert into _case16_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Inspect chest expansion', 2, 'This is indicated in the initial trauma assessment.' from _case16_steps s where s.step_order = 1
union all select s.id, 'B', 'Auscultate breath sounds', 2, 'This is indicated in the initial trauma assessment.' from _case16_steps s where s.step_order = 1
union all select s.id, 'C', 'Percuss both hemithoraces', 2, 'This helps identify pleural air under pressure.' from _case16_steps s where s.step_order = 1
union all select s.id, 'D', 'Check tracheal position', 2, 'This helps identify tension physiology.' from _case16_steps s where s.step_order = 1
union all select s.id, 'E', 'Obtain bedside spirometry', -3, 'This is not indicated in the current condition.' from _case16_steps s where s.step_order = 1
union all select s.id, 'F', 'Delay treatment until chest radiograph is obtained', -3, 'This delays lifesaving intervention.' from _case16_steps s where s.step_order = 1

union all select s.id, 'A', 'Perform immediate pleural decompression while administering high-concentration oxygen', 3, 'This is the best first treatment in this situation.' from _case16_steps s where s.step_order = 2
union all select s.id, 'B', 'Obtain a chest radiograph before intervention', -3, 'This delays indicated treatment.' from _case16_steps s where s.step_order = 2
union all select s.id, 'C', 'Administer analgesia and reassess later', -3, 'This does not treat the life-threatening problem.' from _case16_steps s where s.step_order = 2
union all select s.id, 'D', 'Start bronchodilator therapy', -3, 'This is not the primary problem.' from _case16_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess chest expansion', 2, 'This is indicated after decompression.' from _case16_steps s where s.step_order = 3
union all select s.id, 'B', 'Reassess breath sounds', 2, 'This is indicated after decompression.' from _case16_steps s where s.step_order = 3
union all select s.id, 'C', 'Trend oxygen saturation and blood pressure', 2, 'This helps assess response to intervention.' from _case16_steps s where s.step_order = 3
union all select s.id, 'D', 'Determine whether chest tube placement is still required', 2, 'This is indicated after immediate decompression.' from _case16_steps s where s.step_order = 3
union all select s.id, 'E', 'Routine discharge planning', -3, 'This is premature.' from _case16_steps s where s.step_order = 3
union all select s.id, 'F', 'Stop close monitoring after the first improvement', -3, 'This is unsafe.' from _case16_steps s where s.step_order = 3

union all select s.id, 'A', 'Insert a chest tube and admit to the ICU for continued monitoring', 3, 'This is the safest next step after temporary decompression.' from _case16_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to an unmonitored floor bed', -3, 'This is not an appropriate level of care.' from _case16_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge after oxygenation improves briefly', -3, 'This is unsafe.' from _case16_steps s where s.step_order = 4
union all select s.id, 'D', 'Observe without definitive pleural management', -3, 'This is not an appropriate plan.' from _case16_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Right chest expansion is reduced. Right breath sounds are absent, percussion is hyperresonant, and the trachea is shifted to the left.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case16_steps s1 cross join _case16_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Hemodynamic instability worsens.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": -10, "bp_dia": -6}'::jsonb
from _case16_steps s1 cross join _case16_steps s2 where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Right breath sounds improve, and blood pressure increases.',
  '{"spo2": 10, "hr": -18, "rr": -8, "bp_sys": 18, "bp_dia": 14}'::jsonb
from _case16_steps s2 cross join _case16_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Hypoxemia worsens, and shock progresses.',
  '{"spo2": -8, "hr": 10, "rr": 4, "bp_sys": -12, "bp_dia": -8}'::jsonb
from _case16_steps s2 cross join _case16_steps s3 where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Right chest expansion and breath sounds improve, but definitive pleural management is still required.',
  '{"spo2": 1, "hr": -2, "rr": -1, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case16_steps s3 cross join _case16_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and recurrent deterioration occurs.',
  '{"spo2": -5, "hr": 6, "rr": 3, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case16_steps s3 cross join _case16_steps s4 where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: tension pneumothorax is treated with decompression, chest tube placement, and ICU care.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case16_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed definitive management leads to recurrent instability.',
  '{"spo2": -6, "hr": 7, "rr": 4, "bp_sys": -8, "bp_dia": -5}'::jsonb
from _case16_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE16_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case16_target);

commit;


-- Exhale Academy CSE Branching Seed (Trauma Critical - Hemothorax)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case17_target (id uuid primary key) on commit drop;
create temporary table _case17_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-17-trauma-critical-hemothorax',
    'trauma-critical-hemothorax'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'trauma-critical',
    disease_slug = 'chest-trauma',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 17),
    slug = 'trauma-critical-hemothorax',
    title = 'Trauma Critical (Hemothorax)',
    intro_text = 'Chest trauma with progressive dyspnea and suspected pleural blood accumulation requiring drainage-first management.',
    description = 'Critical trauma branching case focused on bedside recognition of hemothorax and early pleural drainage.',
    stem = 'Trauma patient has dyspnea and worsening oxygenation after blunt chest injury.',
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
    'trauma-critical',
    'chest-trauma',
    'critical',
    17,
    'trauma-critical-hemothorax',
    'Trauma Critical (Hemothorax)',
    'Chest trauma with progressive dyspnea and suspected pleural blood accumulation requiring drainage-first management.',
    'Critical trauma branching case focused on bedside recognition of hemothorax and early pleural drainage.',
    'Trauma patient has dyspnea and worsening oxygenation after blunt chest injury.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case17_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":126,"rr":34,"spo2":84,"bp_sys":102,"bp_dia":64}'::jsonb
where id in (select id from _case17_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case17_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case17_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case17_target)
);

delete from public.cse_attempts where case_id in (select id from _case17_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case17_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case17_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case17_target));
delete from public.cse_steps where case_id in (select id from _case17_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 47-year-old woman is brought to the emergency department after blunt chest trauma.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 126/min
RR 34/min
BP 102/64 mm Hg
SpO2 84%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "tachypnea and distress persist after the chest injury",
      "extra_reveals": [
        { "text": "Chest expansion is decreased on the left.", "keys_any": ["A"] },
        { "text": "Breath sounds are decreased on the left.", "keys_any": ["B"] },
        { "text": "Percussion is dull on the left.", "keys_any": ["C"] }
      ]
    }'::jsonb from _case17_target
  union all
  select id, 2, 2, 'DM',
    'Dyspnea and hypoxemia persist, and pleural blood is suspected. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case17_target
  union all
  select id, 3, 3, 'IG',
    'After pleural drainage is started, oxygenation improves.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 114/min
RR 28/min
BP 110/70 mm Hg
SpO2 90%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
    4, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "dyspnea is less severe after drainage",
      "extra_reveals": [
        { "text": "Breath sounds are louder on the left than before.", "keys_any": ["A"] },
        { "text": "Chest-tube output should be followed closely for ongoing blood loss.", "keys_any": ["B"] },
        { "text": "Oxygenation and blood pressure are improving but still require close monitoring.", "keys_any": ["C"] },
        { "text": "Repeat imaging may still be needed after stabilization.", "keys_any": ["D"] }
      ]
    }'::jsonb from _case17_target
  union all
  select id, 4, 4, 'DM',
    'The patient remains at risk for recurrent bleeding and respiratory deterioration. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case17_target
  returning id, step_order
)
insert into _case17_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Inspect chest expansion', 2, 'This is indicated in the initial assessment.' from _case17_steps s where s.step_order = 1
union all select s.id, 'B', 'Auscultate breath sounds', 2, 'This is indicated in the initial assessment.' from _case17_steps s where s.step_order = 1
union all select s.id, 'C', 'Percuss the chest', 2, 'This is indicated when hemothorax is suspected.' from _case17_steps s where s.step_order = 1
union all select s.id, 'D', 'Obtain bedside spirometry', -3, 'This is not indicated in the current condition.' from _case17_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay treatment until a complete imaging workup is finished', -3, 'This delays indicated care.' from _case17_steps s where s.step_order = 1

union all select s.id, 'A', 'Administer high-concentration oxygen and begin pleural drainage', 3, 'This is the best first treatment in this situation.' from _case17_steps s where s.step_order = 2
union all select s.id, 'B', 'Provide analgesia only and reassess later', -3, 'This does not treat the pleural blood accumulation.' from _case17_steps s where s.step_order = 2
union all select s.id, 'C', 'Delay drainage until symptoms worsen further', -3, 'This delays indicated treatment.' from _case17_steps s where s.step_order = 2
union all select s.id, 'D', 'Start bronchodilator therapy', -3, 'This is not the primary problem.' from _case17_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess breath sounds', 2, 'This is indicated after pleural drainage.' from _case17_steps s where s.step_order = 3
union all select s.id, 'B', 'Check chest-tube output for ongoing bleeding', 2, 'This helps assess recurrent blood loss risk.' from _case17_steps s where s.step_order = 3
union all select s.id, 'C', 'Trend oxygen saturation and blood pressure', 2, 'This is indicated after initial stabilization.' from _case17_steps s where s.step_order = 3
union all select s.id, 'D', 'Determine whether repeat imaging is needed after stabilization', 2, 'This is indicated after initial stabilization.' from _case17_steps s where s.step_order = 3
union all select s.id, 'E', 'Routine discharge paperwork', -3, 'This is premature.' from _case17_steps s where s.step_order = 3
union all select s.id, 'F', 'Stop close monitoring after the first improvement', -3, 'This is unsafe.' from _case17_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue monitored trauma care with chest-tube management and ICU-level reassessment', 3, 'This is the safest next step in this situation.' from _case17_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to an unmonitored floor bed', -3, 'This is not an appropriate level of care.' from _case17_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge after oxygenation improves briefly', -3, 'This is unsafe.' from _case17_steps s where s.step_order = 4
union all select s.id, 'D', 'Stop oxygen because drainage has started', -3, 'This may worsen residual hypoxemia.' from _case17_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Left chest expansion is reduced. Breath sounds are decreased on the left, and percussion is dull on the left.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case17_steps s1 cross join _case17_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Hypoxemia and blood-loss risk worsen.',
  '{"spo2": -5, "hr": 6, "rr": 3, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case17_steps s1 cross join _case17_steps s2 where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Breath sounds improve slightly, and oxygenation begins to increase.',
  '{"spo2": 6, "hr": -8, "rr": -6, "bp_sys": 8, "bp_dia": 6}'::jsonb
from _case17_steps s2 cross join _case17_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Pleural blood continues to impair ventilation and oxygenation.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case17_steps s2 cross join _case17_steps s3 where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Drainage response is present, but continued monitoring is required.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case17_steps s3 cross join _case17_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and recurrent instability develops.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case17_steps s3 cross join _case17_steps s4 where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: hemothorax is treated with pleural drainage and continued high-acuity monitoring.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case17_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: inadequate monitoring leads to recurrent deterioration.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case17_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE17_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case17_target);

commit;
