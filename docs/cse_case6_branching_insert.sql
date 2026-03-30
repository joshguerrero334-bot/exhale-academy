-- Exhale Academy CSE Case #6 Branching Seed (Acute Severe Bronchospasm)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case6_target (id uuid primary key) on commit drop;
create temporary table _case6_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-6-acute-severe-bronchospasm-fatigue'
     or lower(coalesce(title, '')) like '%case 6%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-acute-severe-bronchospasm',
    case_number = 6,
    slug = 'case-6-acute-severe-bronchospasm-fatigue',
    title = 'Case 6 -- Acute Severe Bronchospasm Fatigue',
    intro_text = 'Adult with severe lower-airway obstruction presents with hypoxemia, poor speech tolerance, and increasing fatigue.',
    description = 'Branching case focused on severe bronchospasm, reassessment, and timely escalation to invasive ventilatory support.',
    stem = 'Severe bronchospasm with worsening work of breathing and risk of ventilatory failure.',
    difficulty = 'hard',
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
    'adult-acute-severe-bronchospasm',
    6,
    'case-6-acute-severe-bronchospasm-fatigue',
    'Case 6 -- Acute Severe Bronchospasm Fatigue',
    'Adult with severe lower-airway obstruction presents with hypoxemia, poor speech tolerance, and increasing fatigue.',
    'Branching case focused on severe bronchospasm, reassessment, and timely escalation to invasive ventilatory support.',
    'Severe bronchospasm with worsening work of breathing and risk of ventilatory failure.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case6_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":128,"rr":36,"spo2":82,"bp_sys":168,"bp_dia":96}'::jsonb
where id in (select id from _case6_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case6_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case6_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case6_target)
);

delete from public.cse_attempts where case_id in (select id from _case6_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case6_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case6_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case6_target));
delete from public.cse_steps where case_id in (select id from _case6_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG',
    'A 29-year-old woman comes to the emergency department because of severe dyspnea and chest tightness that began 2 days ago and worsened despite repeated albuterol use.

While breathing room air, the following are noted:
HR 128/min
RR 36/min
BP 168/96 mm Hg
SpO2 82%

She is using accessory muscles and can speak only 2 to 3 words at a time.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3,
    'STOP'
  from _case6_target
  union all
  select id, 2, 2, 'DM',
    'Breath sounds reveal diffuse expiratory wheezing with prolonged exhalation. Mental status is anxious but alert. Which of the following should be recommended FIRST?',
    null,
    'STOP'
  from _case6_target
  union all
  select id, 3, 3, 'IG',
    'Twenty minutes after continuous bronchodilator therapy and systemic corticosteroids are started, the patient remains tachypneic.

While receiving O2 by aerosol mask at an FIO2 of 0.40, the following are noted:
HR 122/min
RR 34/min
BP 160/92 mm Hg
SpO2 90%

She can now speak only 1 to 2 words at a time. Breath sounds are diminished bilaterally with faint wheezing.

ABG analysis reveals:
pH 7.31
PaCO2 52 torr
PaO2 58 torr
HCO3- 25 mEq/L

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3,
    'STOP'
  from _case6_target
  union all
  select id, 4, 4, 'DM',
    'Ten minutes later, the patient becomes difficult to arouse. Manual assessment shows very poor air movement.

Repeat ABG analysis reveals:
pH 7.24
PaCO2 61 torr
PaO2 55 torr
HCO3- 26 mEq/L

Which of the following should be recommended now?',
    null,
    'STOP'
  from _case6_target
  union all
  select id, 5, 5, 'IG',
    'After endotracheal intubation, the patient is receiving volume-controlled ventilation with the following settings:
VT 420 mL
Rate 18/min
FIO2 0.60
PEEP 5 cm H2O

ABG analysis reveals:
pH 7.29
PaCO2 55 torr
PaO2 64 torr
HCO3- 25 mEq/L

Which of the following should be evaluated or adjusted now? SELECT AS MANY AS INDICATED (MAX 3).',
    3,
    'STOP'
  from _case6_target
  union all
  select id, 6, 6, 'DM',
    'The patient becomes easier to ventilate, and oxygenation begins to improve. Which of the following should be recommended postadmission?',
    null,
    'STOP'
  from _case6_target
  returning id, step_order
)
insert into _case6_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Breath sounds and air movement', 2, 'This is indicated to assess severity of obstruction.' from _case6_steps s where s.step_order = 1
union all select s.id, 'B', 'Ability to speak and accessory-muscle use', 2, 'This helps identify impending fatigue.' from _case6_steps s where s.step_order = 1
union all select s.id, 'C', 'Pulse oximetry and vital signs', 2, 'This is indicated to assess severity and trend.' from _case6_steps s where s.step_order = 1
union all select s.id, 'D', 'Methacholine challenge testing', -3, 'This is not indicated during acute severe distress.' from _case6_steps s where s.step_order = 1
union all select s.id, 'E', 'Allergy skin testing before treatment', -3, 'This delays urgent care.' from _case6_steps s where s.step_order = 1
union all select s.id, 'F', 'Complete pulmonary function testing', -3, 'This is not indicated in unstable bronchospasm.' from _case6_steps s where s.step_order = 1

union all select s.id, 'A', 'Begin continuous nebulized albuterol while administering supplemental oxygen', 3, 'This is the best first treatment for severe bronchospasm with hypoxemia.' from _case6_steps s where s.step_order = 2
union all select s.id, 'B', 'Obtain a chest CT scan before starting therapy', -3, 'This delays indicated treatment.' from _case6_steps s where s.step_order = 2
union all select s.id, 'C', 'Proceed directly to endotracheal intubation', -1, 'This may be needed later, but it is premature while the patient is still alert and moving air.' from _case6_steps s where s.step_order = 2
union all select s.id, 'D', 'Administer a sedative to reduce tachypnea', -3, 'This may worsen ventilatory failure.' from _case6_steps s where s.step_order = 2
union all select s.id, 'E', 'Withhold oxygen because of concern for CO2 retention', -3, 'This is not appropriate in severe hypoxemia.' from _case6_steps s where s.step_order = 2

union all select s.id, 'A', 'Mental status', 2, 'This is indicated to detect worsening ventilatory failure.' from _case6_steps s where s.step_order = 3
union all select s.id, 'B', 'Repeat breath sounds and air movement', 2, 'This helps identify a silent chest pattern.' from _case6_steps s where s.step_order = 3
union all select s.id, 'C', 'ABG trend', 2, 'This is indicated to assess worsening hypercapnia and acidosis.' from _case6_steps s where s.step_order = 3
union all select s.id, 'D', 'Routine sputum culture before any further decision', -1, 'This may be useful later, but it does not answer the next urgent question.' from _case6_steps s where s.step_order = 3
union all select s.id, 'E', 'Exercise oximetry', -3, 'This is not indicated in this condition.' from _case6_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed with endotracheal intubation and mechanical ventilation', 3, 'This is indicated for worsening hypercapnia, fatigue, and declining mental status.' from _case6_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue the same treatment and repeat the ABG in 1 hour', -3, 'This delays definitive treatment.' from _case6_steps s where s.step_order = 4
union all select s.id, 'C', 'Begin noninvasive ventilation', -1, 'This may be considered earlier in selected patients, but declining mental status makes it a poor choice now.' from _case6_steps s where s.step_order = 4
union all select s.id, 'D', 'Decrease the FIO2 to reduce oxygen toxicity', -3, 'This ignores the immediate problem.' from _case6_steps s where s.step_order = 4

union all select s.id, 'A', 'Increase the ventilator rate', 2, 'This helps correct the elevated PaCO2.' from _case6_steps s where s.step_order = 5
union all select s.id, 'B', 'Adjust FIO2 to improve PaO2', 2, 'This is indicated for persistent hypoxemia.' from _case6_steps s where s.step_order = 5
union all select s.id, 'C', 'Monitor for barotrauma and dynamic hyperinflation', 2, 'This is important in severe bronchospasm after intubation.' from _case6_steps s where s.step_order = 5
union all select s.id, 'D', 'Decrease the ventilator rate to 8/min immediately', -2, 'This will worsen ventilation in the current state.' from _case6_steps s where s.step_order = 5
union all select s.id, 'E', 'Discontinue bronchodilator therapy', -3, 'This is not indicated.' from _case6_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to the ICU for continued ventilatory management and reassessment', 3, 'This is the appropriate disposition after intubation for severe bronchospasm.' from _case6_steps s where s.step_order = 6
union all select s.id, 'B', 'Transfer to a medical floor once SpO2 reaches 92%', -3, 'This is premature.' from _case6_steps s where s.step_order = 6
union all select s.id, 'C', 'Extubate and discharge when the next ABG improves', -3, 'This is unsafe.' from _case6_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe in the emergency department without ICU admission', -3, 'This is not the appropriate level of care.' from _case6_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Breath sounds reveal diffuse wheezing. Accessory-muscle use remains pronounced, and SpO2 remains low on room air.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case6_steps s1 cross join _case6_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. The patient becomes more restless, and hypoxemia persists.',
  '{"spo2": -2, "hr": 4, "rr": 2, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case6_steps s1 cross join _case6_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'SpO2 improves slightly, but tachypnea and poor speech tolerance persist.',
  '{"spo2": 8, "hr": -6, "rr": -2, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case6_steps s2 cross join _case6_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Air movement remains poor, and respiratory distress worsens.',
  '{"spo2": -4, "hr": 6, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case6_steps s2 cross join _case6_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Air movement decreases further, and the patient becomes more fatigued.',
  '{"spo2": -2, "hr": 3, "rr": 1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case6_steps s3 cross join _case6_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment is delayed. The patient becomes difficult to arouse, and ventilation worsens.',
  '{"spo2": -5, "hr": 6, "rr": 2, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case6_steps s3 cross join _case6_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'The airway is secured. Oxygenation improves, but hypercapnia persists on the first post-intubation ABG.',
  '{"spo2": 10, "hr": -8, "rr": -10, "bp_sys": -6, "bp_dia": -3}'::jsonb
from _case6_steps s4 cross join _case6_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'The patient develops worsening hypoxemia and rising PaCO2.',
  '{"spo2": -8, "hr": 8, "rr": 4, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case6_steps s4 cross join _case6_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'Ventilation becomes easier, and oxygenation begins to improve.',
  '{"spo2": 4, "hr": -4, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case6_steps s5 cross join _case6_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Gas exchange remains unstable, and close monitoring is still required.',
  '{"spo2": -3, "hr": 4, "rr": 2, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case6_steps s5 cross join _case6_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is admitted to the ICU for ongoing ventilatory support and reassessment.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case6_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: inadequate level of care leads to recurrent respiratory failure.',
  '{"spo2": -6, "hr": 6, "rr": 3, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case6_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE6_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case6_target);

commit;
