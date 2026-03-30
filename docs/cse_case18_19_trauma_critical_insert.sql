-- Combined runner for case 18 + case 19
-- Generated: 2026-03-30

-- Exhale Academy CSE Branching Seed (Trauma Critical - Flail Chest with Pulmonary Contusion)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case18_target (id uuid primary key) on commit drop;
create temporary table _case18_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-18-trauma-critical-flail-chest-contusion',
    'trauma-critical-flail-chest-contusion'
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
    case_number = coalesce(c.case_number, 18),
    slug = 'trauma-critical-flail-chest-contusion',
    title = 'Trauma Critical (Flail Chest + Pulmonary Contusion)',
    intro_text = 'Blunt chest trauma with severe pain, shallow respirations, and worsening oxygenation requiring high-priority stabilization.',
    description = 'Critical trauma branching case focused on flail-chest recognition, oxygen support, pain control, reassessment, and escalation.',
    stem = 'Trauma patient has severe chest pain, shallow respirations, and progressive hypoxemia after blunt injury.',
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
    18,
    'trauma-critical-flail-chest-contusion',
    'Trauma Critical (Flail Chest + Pulmonary Contusion)',
    'Blunt chest trauma with severe pain, shallow respirations, and worsening oxygenation requiring high-priority stabilization.',
    'Critical trauma branching case focused on flail-chest recognition, oxygen support, pain control, reassessment, and escalation.',
    'Trauma patient has severe chest pain, shallow respirations, and progressive hypoxemia after blunt injury.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case18_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":132,"rr":36,"spo2":81,"bp_sys":162,"bp_dia":96}'::jsonb
where id in (select id from _case18_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case18_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case18_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case18_target)
);

delete from public.cse_attempts where case_id in (select id from _case18_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case18_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case18_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case18_target));
delete from public.cse_steps where case_id in (select id from _case18_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 29-year-old man is brought to the emergency department after blunt chest trauma.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 132/min
RR 36/min
BP 162/96 mm Hg
SpO2 81%

He is in severe respiratory distress after the injury.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "severe pain and respiratory distress persist after the chest injury",
      "extra_reveals": [
        { "text": "Paradoxical movement of the left lateral chest is present.", "keys_any": ["A"] },
        { "text": "Breath sounds are decreased on the left.", "keys_any": ["B"] },
        { "text": "Pain is limiting inspiratory effort.", "keys_any": ["C"] }
      ]
    }'::jsonb from _case18_target
  union all
  select id, 2, 2, 'DM',
    'The patient remains severely hypoxemic and is taking shallow breaths because of pain. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case18_target
  union all
  select id, 3, 3, 'IG',
    'After oxygen therapy and pain control are started, the patient remains tachypneic.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 124/min
RR 32/min
BP 154/90 mm Hg
SpO2 86%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
    4, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "shallow respirations persist and fatigue is increasing",
      "extra_reveals": [
        { "text": "Chest radiograph reveals multiple left rib fractures with patchy left-sided opacities.", "keys_any": ["A"] },
        { "text": "ABG: pH 7.31, PaCO2 48 torr, PaO2 58 torr, HCO3 24 mEq/L.", "keys_any": ["B"] },
        { "text": "Mental status remains intact, but work of breathing is increasing.", "keys_any": ["C"] },
        { "text": "The patient may require ventilatory support if fatigue worsens.", "keys_any": ["D"] }
      ]
    }'::jsonb from _case18_target
  union all
  select id, 4, 4, 'DM',
    'Work of breathing increases, and oxygenation remains poor. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case18_target
  returning id, step_order
)
insert into _case18_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Inspect chest-wall movement', 2, 'This is indicated in the initial trauma assessment.' from _case18_steps s where s.step_order = 1
union all select s.id, 'B', 'Auscultate breath sounds', 2, 'This is indicated in the initial trauma assessment.' from _case18_steps s where s.step_order = 1
union all select s.id, 'C', 'Assess how pain is affecting inspiratory effort', 2, 'This is indicated in suspected flail chest.' from _case18_steps s where s.step_order = 1
union all select s.id, 'D', 'Obtain bedside spirometry', -3, 'This is not indicated in the current condition.' from _case18_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay treatment until all imaging is completed', -3, 'This delays urgent care.' from _case18_steps s where s.step_order = 1

union all select s.id, 'A', 'Administer high-concentration oxygen, provide analgesia, and begin close monitoring', 3, 'This is the best first treatment in this situation.' from _case18_steps s where s.step_order = 2
union all select s.id, 'B', 'Provide analgesia only and reassess later', -3, 'This does not adequately treat the hypoxemia.' from _case18_steps s where s.step_order = 2
union all select s.id, 'C', 'Delay oxygen because imaging suggests contusion', -3, 'This is unsafe.' from _case18_steps s where s.step_order = 2
union all select s.id, 'D', 'Discharge when pain improves', -3, 'This is not appropriate.' from _case18_steps s where s.step_order = 2

union all select s.id, 'A', 'Obtain chest radiograph results', 2, 'This is indicated to assess traumatic chest injury.' from _case18_steps s where s.step_order = 3
union all select s.id, 'B', 'Obtain an ABG', 2, 'This is indicated to assess worsening gas-exchange failure.' from _case18_steps s where s.step_order = 3
union all select s.id, 'C', 'Reassess mental status and work of breathing', 2, 'This helps assess impending ventilatory failure.' from _case18_steps s where s.step_order = 3
union all select s.id, 'D', 'Determine whether ventilatory support is now needed', 2, 'This is indicated when hypoxemia and fatigue persist.' from _case18_steps s where s.step_order = 3
union all select s.id, 'E', 'Routine discharge planning', -3, 'This is premature.' from _case18_steps s where s.step_order = 3
union all select s.id, 'F', 'Stop close monitoring after brief improvement', -3, 'This is unsafe.' from _case18_steps s where s.step_order = 3

union all select s.id, 'A', 'Escalate to mechanical ventilation and ICU care', 3, 'This is indicated with worsening ventilatory failure.' from _case18_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue unchanged therapy and reassess tomorrow', -3, 'This delays indicated escalation.' from _case18_steps s where s.step_order = 4
union all select s.id, 'C', 'Transfer to an unmonitored floor bed', -3, 'This is not an appropriate level of care.' from _case18_steps s where s.step_order = 4
union all select s.id, 'D', 'Discharge when oxygenation improves briefly', -3, 'This is unsafe.' from _case18_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Paradoxical chest movement is present, inspiratory effort is limited by pain, and hypoxemia persists.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case18_steps s1 cross join _case18_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Hypoxemia and fatigue worsen.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case18_steps s1 cross join _case18_steps s2 where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Pain control improves chest movement slightly, but oxygenation remains impaired.',
  '{"spo2": 5, "hr": -8, "rr": -4, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case18_steps s2 cross join _case18_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Respiratory distress worsens, and oxygenation declines further.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case18_steps s2 cross join _case18_steps s3 where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Chest radiograph and ABG support flail chest with pulmonary contusion, and fatigue persists despite initial therapy.',
  '{"spo2": -1, "hr": 1, "rr": 1, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case18_steps s3 cross join _case18_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed, and respiratory failure worsens.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case18_steps s3 cross join _case18_steps s4 where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: flail chest and pulmonary contusion are managed with ventilatory support and ICU care.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case18_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation leads to worsening respiratory failure.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case18_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE18_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case18_target);

commit;
-- Exhale Academy CSE Branching Seed (Trauma Critical - Ventilator Pneumothorax Deterioration)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case19_target (id uuid primary key) on commit drop;
create temporary table _case19_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-19-trauma-critical-ventilator-pneumothorax',
    'trauma-critical-ventilator-pneumothorax'
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
    case_number = coalesce(c.case_number, 19),
    slug = 'trauma-critical-ventilator-pneumothorax',
    title = 'Trauma Critical (Ventilator-Associated Pneumothorax Deterioration)',
    intro_text = 'Ventilated trauma patient develops abrupt respiratory deterioration requiring bedside ventilator and pleural assessment.',
    description = 'Critical trauma branching case focused on identifying ventilator-associated tension physiology and urgent pleural intervention.',
    stem = 'Intubated trauma patient develops sudden hypoxemia, hypotension, and ventilator alarm changes after trauma.',
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
    19,
    'trauma-critical-ventilator-pneumothorax',
    'Trauma Critical (Ventilator-Associated Pneumothorax Deterioration)',
    'Ventilated trauma patient develops abrupt respiratory deterioration requiring bedside ventilator and pleural assessment.',
    'Critical trauma branching case focused on identifying ventilator-associated tension physiology and urgent pleural intervention.',
    'Intubated trauma patient develops sudden hypoxemia, hypotension, and ventilator alarm changes after trauma.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case19_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":124,"rr":30,"spo2":79,"bp_sys":86,"bp_dia":52,"etco2":60}'::jsonb
where id in (select id from _case19_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case19_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case19_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case19_target)
);

delete from public.cse_attempts where case_id in (select id from _case19_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case19_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case19_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case19_target));
delete from public.cse_steps where case_id in (select id from _case19_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 52-year-old woman is receiving mechanical ventilation after blunt chest trauma.

Current ventilator settings are:
AC/VC
VT 450 mL
RR 16/min
FiO2 0.60
PEEP 5 cmH2O

The ventilator alarms suddenly activate.

The following are noted:
HR 124/min
BP 86/52 mm Hg
SpO2 79%
EtCO2 60 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).',
    4, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "the patient remains unstable on the ventilator",
      "extra_reveals": [
        { "text": "Peak airway pressure has risen sharply, and delivered tidal volume has fallen.", "keys_any": ["A"] },
        { "text": "Breath sounds are absent on the right.", "keys_any": ["B"] },
        { "text": "Percussion is hyperresonant on the right.", "keys_any": ["C"] },
        { "text": "The suction catheter passes easily through the endotracheal tube.", "keys_any": ["D"] }
      ]
    }'::jsonb from _case19_target
  union all
  select id, 2, 2, 'DM',
    'The patient remains severely hypoxemic and hypotensive. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case19_target
  union all
  select id, 3, 3, 'IG',
    'After immediate pleural decompression, the following are noted:

HR 112/min
BP 98/60 mm Hg
SpO2 88%
EtCO2 48 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
    4, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "oxygenation and hemodynamics have improved, but the patient remains high risk",
      "extra_reveals": [
        { "text": "Breath sounds are now faintly present on the right.", "keys_any": ["A"] },
        { "text": "ABG: pH 7.28, PaCO2 54 torr, PaO2 64 torr, HCO3 25 mEq/L.", "keys_any": ["B"] },
        { "text": "Peak airway pressure is lower, but the pleural injury still requires definitive management.", "keys_any": ["C"] },
        { "text": "Hemoglobin is 10.2 g/dL and hematocrit is 31%.", "keys_any": ["D"] }
      ]
    }'::jsonb from _case19_target
  union all
  select id, 4, 4, 'DM',
    'The patient remains at risk for recurrent deterioration. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case19_target
  returning id, step_order
)
insert into _case19_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Check peak airway pressure and delivered tidal volume', 2, 'This is indicated with sudden ventilator alarm changes.' from _case19_steps s where s.step_order = 1
union all select s.id, 'B', 'Auscultate breath sounds', 2, 'This is indicated in the bedside assessment.' from _case19_steps s where s.step_order = 1
union all select s.id, 'C', 'Percuss the chest', 2, 'This helps identify pleural air under pressure.' from _case19_steps s where s.step_order = 1
union all select s.id, 'D', 'Pass a suction catheter through the endotracheal tube', 2, 'This helps rule out tube obstruction.' from _case19_steps s where s.step_order = 1
union all select s.id, 'E', 'Wait for repeat ABGs before assessing the chest', -3, 'This delays urgent bedside assessment.' from _case19_steps s where s.step_order = 1
union all select s.id, 'F', 'Increase sedation and ignore the alarm pattern', -3, 'This is unsafe.' from _case19_steps s where s.step_order = 1

union all select s.id, 'A', 'Administer 100% oxygen and perform immediate pleural decompression', 3, 'Correct immediate sequence.' from _case19_steps s where s.step_order = 2
union all select s.id, 'B', 'Obtain chest radiograph before intervention', -3, 'This delays lifesaving treatment.' from _case19_steps s where s.step_order = 2
union all select s.id, 'C', 'Increase tidal volume to force oxygenation improvement', -3, 'This may worsen barotrauma and instability.' from _case19_steps s where s.step_order = 2
union all select s.id, 'D', 'Give bronchodilator therapy and reassess later', -2, 'This is insufficient for a pleural emergency.' from _case19_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess breath sounds', 2, 'This is indicated after decompression.' from _case19_steps s where s.step_order = 3
union all select s.id, 'B', 'Repeat ABG', 2, 'This helps assess ventilation and oxygenation response.' from _case19_steps s where s.step_order = 3
union all select s.id, 'C', 'Trend airway pressure and delivered tidal volume', 2, 'This helps assess response and ongoing risk.' from _case19_steps s where s.step_order = 3
union all select s.id, 'D', 'Obtain CBC with hemoglobin and hematocrit', 1, 'Reasonable in trauma if ongoing blood loss is being considered, but not as critical as pleural reassessment.' from _case19_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop close monitoring after the first improvement', -3, 'This is unsafe.' from _case19_steps s where s.step_order = 3
union all select s.id, 'F', 'Delay reassessment for several hours', -3, 'This is dangerous.' from _case19_steps s where s.step_order = 3

union all select s.id, 'A', 'Insert a chest tube and continue ICU-level ventilator management', 3, 'This is the safest next step after temporary decompression.' from _case19_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to a low-acuity floor bed once oxygenation improves briefly', -3, 'This is unsafe.' from _case19_steps s where s.step_order = 4
union all select s.id, 'C', 'Stop ventilator optimization because decompression was performed', -2, 'This is incomplete management.' from _case19_steps s where s.step_order = 4
union all select s.id, 'D', 'Observe without definitive pleural management', -3, 'This is unsafe.' from _case19_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Peak airway pressure has risen sharply, delivered tidal volume has fallen, breath sounds are absent on the right, and percussion is hyperresonant on the right.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _case19_steps s1 cross join _case19_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Missed ventilator warning signs increase collapse risk.',
  '{"spo2": -5, "hr": 5, "rr": 3, "bp_sys": -5, "bp_dia": -4, "etco2": 4}'::jsonb
from _case19_steps s1 cross join _case19_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Immediate decompression improves oxygenation and hemodynamics.',
  '{"spo2": 7, "hr": -4, "rr": -4, "bp_sys": 8, "bp_dia": 6, "etco2": -5}'::jsonb
from _case19_steps s2 cross join _case19_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate intervention worsens respiratory/hemodynamic failure.',
  '{"spo2": -7, "hr": 7, "rr": 4, "bp_sys": -8, "bp_dia": -6, "etco2": 6}'::jsonb
from _case19_steps s2 cross join _case19_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Breath sounds are returning on the right, airway pressure is lower, and definitive pleural management is still required.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 2, "bp_dia": 1, "etco2": -2}'::jsonb
from _case19_steps s3 cross join _case19_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps leave high risk for recurrent deterioration.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -3, "bp_dia": -2, "etco2": 3}'::jsonb
from _case19_steps s3 cross join _case19_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: ventilator-associated pneumothorax deterioration is managed with timely decompression, chest tube placement, and ICU continuity.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _case19_steps s4
where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed treatment and poor monitoring cause recurrent instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _case19_steps s4
where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE19_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case19_target);

commit;
