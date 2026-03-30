-- Combined runner for case 14 + case 15
-- Rewritten to the Exhale CSE realism standard

-- Exhale Academy CSE Branching Seed (COPD Critical - NPPV Failure Escalation)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case14_target (id uuid primary key) on commit drop;
create temporary table _case14_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-14-copd-critical-nppv-failure-escalation',
    'copd-critical-nppv-failure-escalation'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'copd-critical',
    disease_slug = 'copd',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 14),
    slug = 'copd-critical-nppv-failure-escalation',
    title = 'COPD Critical (NPPV Failure Escalation)',
    intro_text = 'Critical COPD exacerbation with persistent hypercapnia despite initial therapy and need for timely escalation from bilevel support to intubation.',
    description = 'Branching case focused on recognizing noninvasive ventilation failure and proceeding to invasive ventilation without delay.',
    stem = 'Critical COPD exacerbation with worsening ABGs during bilevel support.',
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
    'copd-critical',
    'copd',
    'critical',
    14,
    'copd-critical-nppv-failure-escalation',
    'COPD Critical (NPPV Failure Escalation)',
    'Critical COPD exacerbation with persistent hypercapnia despite initial therapy and need for timely escalation from bilevel support to intubation.',
    'Branching case focused on recognizing noninvasive ventilation failure and proceeding to invasive ventilation without delay.',
    'Critical COPD exacerbation with worsening ABGs during bilevel support.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case14_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":126,"rr":36,"spo2":82,"bp_sys":154,"bp_dia":94,"etco2":62}'::jsonb
where id in (select id from _case14_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case14_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case14_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case14_target)
);

delete from public.cse_attempts where case_id in (select id from _case14_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case14_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case14_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case14_target));
delete from public.cse_steps where case_id in (select id from _case14_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 68-year-old man with severe COPD is brought to the emergency department because of worsening dyspnea.

While breathing room air, the following are noted:
HR 126/min
RR 36/min
BP 154/94 mm Hg
SpO2 82%

He is anxious, diaphoretic, and speaking in short phrases.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case14_target
  union all
  select id, 2, 2, 'DM',
    'Controlled oxygen, bronchodilator therapy, and IV corticosteroids are started.

ABG analysis reveals:
pH 7.30
PaCO2 64 torr
PaO2 55 torr
HCO3- 30 mEq/L

Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case14_target
  union all
  select id, 3, 3, 'IG',
    'Thirty minutes after bilevel positive airway pressure is started, the patient remains tachypneic.

While receiving IPAP 12 cm H2O, EPAP 5 cm H2O, and FIO2 0.35, the following are noted:
HR 124/min
RR 34/min
BP 150/90 mm Hg
SpO2 88%

Breath sounds remain diminished bilaterally.

Repeat ABG analysis reveals:
pH 7.25
PaCO2 70 torr
PaO2 54 torr
HCO3- 30 mEq/L

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case14_target
  union all
  select id, 4, 4, 'DM',
    'The patient becomes more fatigued and difficult to arouse. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case14_target
  union all
  select id, 5, 5, 'IG',
    'After endotracheal intubation, the patient is receiving volume-controlled ventilation with the following settings:
VT 460 mL
Rate 18/min
FIO2 0.60
PEEP 5 cm H2O

ABG analysis reveals:
pH 7.28
PaCO2 58 torr
PaO2 62 torr
HCO3- 27 mEq/L

Which of the following should be evaluated or adjusted now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case14_target
  union all
  select id, 6, 6, 'DM',
    'The patient is easier to ventilate, and gas exchange begins to improve. Which of the following should be recommended postadmission?',
    null, 'STOP', '{}'::jsonb from _case14_target
  returning id, step_order
)
insert into _case14_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Breath sounds and air movement', 2, 'This is indicated to assess severity of obstruction.' from _case14_steps s where s.step_order = 1
union all select s.id, 'B', 'Mental status and ability to speak', 2, 'This helps assess ventilatory fatigue.' from _case14_steps s where s.step_order = 1
union all select s.id, 'C', 'Pulse oximetry and vital signs', 2, 'This is indicated to assess severity and trend.' from _case14_steps s where s.step_order = 1
union all select s.id, 'D', 'Complete pulmonary function testing', -3, 'This is not indicated in the current condition.' from _case14_steps s where s.step_order = 1
union all select s.id, 'E', 'Exercise oximetry', -3, 'This delays urgent care.' from _case14_steps s where s.step_order = 1

union all select s.id, 'A', 'Begin bilevel positive airway pressure', 3, 'This is indicated for acute hypercapnic respiratory failure when the patient is still alert enough to tolerate it.' from _case14_steps s where s.step_order = 2
union all select s.id, 'B', 'Continue oxygen therapy alone and repeat the ABG later', -3, 'This delays needed ventilatory support.' from _case14_steps s where s.step_order = 2
union all select s.id, 'C', 'Proceed directly to endotracheal intubation', -1, 'This may become necessary, but bilevel support is the best next step now.' from _case14_steps s where s.step_order = 2
union all select s.id, 'D', 'Withhold oxygen because of chronic CO2 retention', -3, 'This is not appropriate in severe hypoxemia.' from _case14_steps s where s.step_order = 2

union all select s.id, 'A', 'Mental status', 2, 'This is indicated to detect worsening ventilatory failure.' from _case14_steps s where s.step_order = 3
union all select s.id, 'B', 'ABG trend', 2, 'This is indicated to assess failure of noninvasive ventilation.' from _case14_steps s where s.step_order = 3
union all select s.id, 'C', 'Work of breathing and air movement', 2, 'This helps identify worsening fatigue and poor response.' from _case14_steps s where s.step_order = 3
union all select s.id, 'D', 'Smoking-cessation readiness', -3, 'This is not the next urgent priority.' from _case14_steps s where s.step_order = 3
union all select s.id, 'E', 'Discharge planning', -3, 'This is clearly premature.' from _case14_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed with endotracheal intubation and mechanical ventilation', 3, 'This is indicated for worsening hypercapnia, fatigue, and declining mental status.' from _case14_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue bilevel support and repeat the ABG later', -3, 'This delays definitive treatment.' from _case14_steps s where s.step_order = 4
union all select s.id, 'C', 'Decrease the FIO2', -3, 'This ignores the immediate problem.' from _case14_steps s where s.step_order = 4
union all select s.id, 'D', 'Discontinue bronchodilator therapy', -3, 'This is not indicated.' from _case14_steps s where s.step_order = 4

union all select s.id, 'A', 'Increase the ventilator rate', 2, 'This helps improve ventilation and lower PaCO2.' from _case14_steps s where s.step_order = 5
union all select s.id, 'B', 'Adjust FIO2 to improve oxygenation', 2, 'This is indicated for persistent hypoxemia.' from _case14_steps s where s.step_order = 5
union all select s.id, 'C', 'Monitor for dynamic hyperinflation and barotrauma', 2, 'This is important after intubation in severe COPD.' from _case14_steps s where s.step_order = 5
union all select s.id, 'D', 'Reduce the ventilator rate to 8/min immediately', -2, 'This will worsen ventilation in the current state.' from _case14_steps s where s.step_order = 5
union all select s.id, 'E', 'Stop reassessing the ABG because the airway is secured', -3, 'This is not appropriate.' from _case14_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to the ICU for continued ventilatory management and reassessment', 3, 'This is the appropriate level of care after intubation for critical COPD.' from _case14_steps s where s.step_order = 6
union all select s.id, 'B', 'Transfer to a low-acuity bed when SpO2 reaches 90%', -3, 'This is premature.' from _case14_steps s where s.step_order = 6
union all select s.id, 'C', 'Extubate and discharge after the next ABG', -3, 'This is unsafe.' from _case14_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe in the emergency department without ICU admission', -3, 'This is not the appropriate level of care.' from _case14_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Breath sounds remain diminished, and severe dyspnea persists.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0, "etco2": 0}'::jsonb
from _case14_steps s1 cross join _case14_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Hypoxemia and fatigue worsen.',
  '{"spo2": -3, "hr": 4, "rr": 2, "bp_sys": 2, "bp_dia": 1, "etco2": 2}'::jsonb
from _case14_steps s1 cross join _case14_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Oxygenation improves slightly, but hypercapnia and tachypnea persist.',
  '{"spo2": 5, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1, "etco2": -2}'::jsonb
from _case14_steps s2 cross join _case14_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Respiratory distress continues to worsen.',
  '{"spo2": -5, "hr": 6, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 4}'::jsonb
from _case14_steps s2 cross join _case14_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'PaCO2 continues to rise, and mental status worsens.',
  '{"spo2": -2, "hr": 2, "rr": 1, "bp_sys": 1, "bp_dia": 1, "etco2": 2}'::jsonb
from _case14_steps s3 cross join _case14_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Failure of bilevel support is recognized late, and ventilatory failure worsens.',
  '{"spo2": -5, "hr": 5, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 4}'::jsonb
from _case14_steps s3 cross join _case14_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'The airway is secured, and oxygenation begins to improve.',
  '{"spo2": 8, "hr": -6, "rr": -8, "bp_sys": -3, "bp_dia": -2, "etco2": -6}'::jsonb
from _case14_steps s4 cross join _case14_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'The patient develops worsening hypercapnia and hypoxemia.',
  '{"spo2": -7, "hr": 7, "rr": 4, "bp_sys": 4, "bp_dia": 3, "etco2": 6}'::jsonb
from _case14_steps s4 cross join _case14_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'Ventilation becomes easier, and gas exchange continues to improve.',
  '{"spo2": 4, "hr": -4, "rr": -2, "bp_sys": -2, "bp_dia": -1, "etco2": -3}'::jsonb
from _case14_steps s5 cross join _case14_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Gas exchange remains unstable, and close monitoring is still required.',
  '{"spo2": -4, "hr": 4, "rr": 2, "bp_sys": 2, "bp_dia": 1, "etco2": 3}'::jsonb
from _case14_steps s5 cross join _case14_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is admitted to the ICU for ongoing ventilatory support and reassessment.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _case14_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation leads to recurrent critical respiratory failure.',
  '{"spo2": -6, "hr": 6, "rr": 4, "bp_sys": -4, "bp_dia": -2, "etco2": 5}'::jsonb
from _case14_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE14_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case14_target);

commit;


-- Exhale Academy CSE Branching Seed (COPD Critical - NPPV Contraindication Pathway)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case15_target (id uuid primary key) on commit drop;
create temporary table _case15_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-15-copd-critical-nppv-contraindication-pathway',
    'copd-critical-nppv-contraindication-pathway'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'copd-critical',
    disease_slug = 'copd',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 15),
    slug = 'copd-critical-nppv-contraindication-pathway',
    title = 'COPD Critical (High-Risk Airway Pathway)',
    intro_text = 'Critical COPD exacerbation with secretion burden, mental-status decline, and airway protection risk requiring immediate invasive support.',
    description = 'Branching case focused on recognizing when bilevel support is inappropriate and immediate intubation is indicated.',
    stem = 'Critical COPD exacerbation with airway protection concern and hemodynamic instability.',
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
    'copd-critical',
    'copd',
    'critical',
    15,
    'copd-critical-nppv-contraindication-pathway',
    'COPD Critical (High-Risk Airway Pathway)',
    'Critical COPD exacerbation with secretion burden, mental-status decline, and airway protection risk requiring immediate invasive support.',
    'Branching case focused on recognizing when bilevel support is inappropriate and immediate intubation is indicated.',
    'Critical COPD exacerbation with airway protection concern and hemodynamic instability.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case15_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":132,"rr":38,"spo2":80,"bp_sys":88,"bp_dia":54,"etco2":66}'::jsonb
where id in (select id from _case15_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case15_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case15_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case15_target)
);

delete from public.cse_attempts where case_id in (select id from _case15_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case15_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case15_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case15_target));
delete from public.cse_steps where case_id in (select id from _case15_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'A 59-year-old woman with severe COPD is brought to the emergency department because of worsening dyspnea.

While breathing room air, the following are noted:
HR 132/min
RR 38/min
BP 88/54 mm Hg
SpO2 80%

She is confused, has a weak cough, and has copious secretions.

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case15_target
  union all
  select id, 2, 2, 'DM',
    'ABG analysis reveals:
pH 7.23
PaCO2 72 torr
PaO2 50 torr
HCO3- 29 mEq/L

Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case15_target
  union all
  select id, 3, 3, 'IG',
    'After endotracheal intubation, the patient is receiving volume-controlled ventilation with the following settings:
VT 430 mL
Rate 20/min
FIO2 0.70
PEEP 8 cm H2O

ABG analysis reveals:
pH 7.21
PaCO2 72 torr
PaO2 58 torr
HCO3- 28 mEq/L

Which of the following should be evaluated or adjusted now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case15_target
  union all
  select id, 4, 4, 'DM',
    'Repeat ABG analysis after ventilator adjustment reveals:
pH 7.26
PaCO2 64 torr
PaO2 66 torr
HCO3- 28 mEq/L

The patient remains intubated and sedated. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case15_target
  union all
  select id, 5, 5, 'IG',
    'As oxygenation and ventilation begin to stabilize, which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 3).',
    3, 'STOP', '{}'::jsonb from _case15_target
  union all
  select id, 6, 6, 'DM',
    'The patient continues to require invasive ventilatory support. Which of the following should be recommended postadmission?',
    null, 'STOP', '{}'::jsonb from _case15_target
  returning id, step_order
)
insert into _case15_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Mental status and ability to protect the airway', 2, 'This is indicated to assess appropriateness of noninvasive ventilation.' from _case15_steps s where s.step_order = 1
union all select s.id, 'B', 'Cough strength and secretion burden', 2, 'This is indicated to assess airway clearance and aspiration risk.' from _case15_steps s where s.step_order = 1
union all select s.id, 'C', 'Blood pressure, pulse oximetry, and respiratory rate', 2, 'This is indicated to assess severity and stability.' from _case15_steps s where s.step_order = 1
union all select s.id, 'D', 'Complete pulmonary function testing', -3, 'This is not indicated in the current condition.' from _case15_steps s where s.step_order = 1
union all select s.id, 'E', 'Exercise oximetry', -3, 'This delays urgent care.' from _case15_steps s where s.step_order = 1

union all select s.id, 'A', 'Proceed with endotracheal intubation and mechanical ventilation', 3, 'This is indicated because of confusion, secretion burden, and hemodynamic instability.' from _case15_steps s where s.step_order = 2
union all select s.id, 'B', 'Begin bilevel positive airway pressure', -3, 'This is not appropriate when airway protection is impaired.' from _case15_steps s where s.step_order = 2
union all select s.id, 'C', 'Continue oxygen therapy alone and repeat the ABG later', -3, 'This delays definitive treatment.' from _case15_steps s where s.step_order = 2
union all select s.id, 'D', 'Administer a sedative before deciding on airway management', -3, 'This is a dangerous sequence.' from _case15_steps s where s.step_order = 2

union all select s.id, 'A', 'Repeat ABG analysis after ventilator adjustments', 2, 'This is indicated to assess response.' from _case15_steps s where s.step_order = 3
union all select s.id, 'B', 'Adjust ventilator rate or tidal volume to improve ventilation', 2, 'This helps lower PaCO2.' from _case15_steps s where s.step_order = 3
union all select s.id, 'C', 'Monitor hemodynamics and secretion clearance', 2, 'This is important in this condition.' from _case15_steps s where s.step_order = 3
union all select s.id, 'D', 'Stop reassessment because the patient is intubated', -3, 'This is not appropriate.' from _case15_steps s where s.step_order = 3
union all select s.id, 'E', 'Plan discharge instructions', -3, 'This is clearly premature.' from _case15_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue invasive ventilatory support with frequent reassessment', 3, 'This is the best next step while the patient remains unstable.' from _case15_steps s where s.step_order = 4
union all select s.id, 'B', 'Extubate because oxygenation improved', -3, 'This is unsafe.' from _case15_steps s where s.step_order = 4
union all select s.id, 'C', 'Transition immediately to bilevel positive airway pressure', -3, 'This is premature.' from _case15_steps s where s.step_order = 4
union all select s.id, 'D', 'Transfer to a medical floor', -3, 'This is not the appropriate level of care.' from _case15_steps s where s.step_order = 4

union all select s.id, 'A', 'Mental status', 2, 'This is indicated before any future de-escalation.' from _case15_steps s where s.step_order = 5
union all select s.id, 'B', 'Secretion burden and cough effectiveness', 2, 'This is important to ongoing airway management.' from _case15_steps s where s.step_order = 5
union all select s.id, 'C', 'ABG trend', 2, 'This is indicated to confirm ongoing improvement.' from _case15_steps s where s.step_order = 5
union all select s.id, 'D', 'Pulmonary rehabilitation schedule', -3, 'This is not the next urgent priority.' from _case15_steps s where s.step_order = 5
union all select s.id, 'E', 'Smoking-cessation readiness', -1, 'This is useful later, but it does not answer the next critical question.' from _case15_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to the ICU for continued ventilatory management and reassessment', 3, 'This is the appropriate disposition after critical respiratory failure and intubation.' from _case15_steps s where s.step_order = 6
union all select s.id, 'B', 'Transfer to an unmonitored floor', -3, 'This is not the appropriate level of care.' from _case15_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge after the next ABG', -3, 'This is unsafe.' from _case15_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe in the emergency department without ICU admission', -3, 'This is not the appropriate level of care.' from _case15_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s2.id,
  'Confusion, secretion burden, and hypotension remain concerning.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0, "etco2": 0}'::jsonb
from _case15_steps s1 cross join _case15_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete. Airway protection and gas exchange continue to worsen.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -3, "bp_dia": -2, "etco2": 3}'::jsonb
from _case15_steps s1 cross join _case15_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'The airway is secured, but severe hypercapnia persists on the initial ABG.',
  '{"spo2": 8, "hr": -5, "rr": -10, "bp_sys": 4, "bp_dia": 3, "etco2": -6}'::jsonb
from _case15_steps s2 cross join _case15_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate airway management leads to worsening instability.',
  '{"spo2": -7, "hr": 7, "rr": 4, "bp_sys": -5, "bp_dia": -3, "etco2": 6}'::jsonb
from _case15_steps s2 cross join _case15_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s4.id,
  'Ventilation improves gradually, but close monitoring is still required.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": 2, "bp_dia": 1, "etco2": -3}'::jsonb
from _case15_steps s3 cross join _case15_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring and adjustment are insufficient, and gas exchange remains unstable.',
  '{"spo2": -4, "hr": 4, "rr": 2, "bp_sys": -2, "bp_dia": -1, "etco2": 3}'::jsonb
from _case15_steps s3 cross join _case15_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Invasive ventilatory support continues appropriately, and gas exchange begins to stabilize.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -2}'::jsonb
from _case15_steps s4 cross join _case15_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Premature de-escalation causes recurrent instability.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -3, "bp_dia": -2, "etco2": 3}'::jsonb
from _case15_steps s4 cross join _case15_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '5'::jsonb, s6.id,
  'Mental status, secretion burden, and ABG values continue to improve.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _case15_steps s5 cross join _case15_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Reassessment is incomplete, and the patient remains high risk.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": -2, "bp_dia": -1, "etco2": 2}'::jsonb
from _case15_steps s5 cross join _case15_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is admitted to the ICU for continued invasive ventilatory support and reassessment.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _case15_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: inadequate level of care leads to recurrent critical respiratory failure.',
  '{"spo2": -6, "hr": 6, "rr": 4, "bp_sys": -4, "bp_dia": -2, "etco2": 5}'::jsonb
from _case15_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE15_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case15_target);

commit;
