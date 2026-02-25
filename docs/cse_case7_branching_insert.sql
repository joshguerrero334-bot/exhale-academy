-- Exhale Academy CSE Case #7 Branching Seed (Pulmonary Embolism Decompensation Pattern)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case7_target (id uuid primary key) on commit drop;
create temporary table _case7_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-7-sudden-hypoxemia-hemodynamic-strain-pattern'
     or lower(coalesce(title, '')) like '%case 7%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-acute-pe-pattern',
    case_number = 7,
    slug = 'case-7-sudden-hypoxemia-hemodynamic-strain-pattern',
    title = 'Case 7 -- Sudden Hypoxemia With Hemodynamic Strain Pattern',
    intro_text = 'Adult with abrupt pleuritic dyspnea, tachycardia, and worsening oxygenation requiring rapid stabilization and escalation decisions.',
    description = 'Branching scenario emphasizing oxygenation, perfusion support, and high-risk delay traps.',
    stem = 'Acute cardiopulmonary decompensation with severe gas-exchange mismatch.',
    difficulty = 'medium',
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
    'adult-acute-pe-pattern',
    7,
    'case-7-sudden-hypoxemia-hemodynamic-strain-pattern',
    'Case 7 -- Sudden Hypoxemia With Hemodynamic Strain Pattern',
    'Adult with abrupt pleuritic dyspnea, tachycardia, and worsening oxygenation requiring rapid stabilization and escalation decisions.',
    'Branching scenario emphasizing oxygenation, perfusion support, and high-risk delay traps.',
    'Acute cardiopulmonary decompensation with severe gas-exchange mismatch.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case7_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":126,"rr":34,"spo2":80,"bp_sys":98,"bp_dia":62}'::jsonb
where id in (select id from _case7_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case7_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case7_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case7_target)
);

delete from public.cse_steps
where case_id in (select id from _case7_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG', 'A 46-year-old female develops sudden pleuritic chest pain and severe dyspnea. She is anxious, pale, and tachypneic with SpO2 80% on room air and borderline blood pressure. SELECT AS MANY AS INDICATED (MAX 4). What immediate priorities are indicated?', 4, 'STOP' from _case7_target
  union all
  select id, 2, 2, 'DM', 'CHOOSE ONLY ONE. What is your FIRST respiratory support strategy now?', null, 'STOP' from _case7_target
  union all
  select id, 3, 3, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). After initial support, what reassessment actions should guide escalation?', 3, 'STOP' from _case7_target
  union all
  select id, 4, 4, 'DM', 'CHOOSE ONLY ONE. Perfusion worsens and hypoxemia persists. What is your NEXT escalation?', null, 'STOP' from _case7_target
  union all
  select id, 5, 5, 'IG', 'SELECT AS MANY AS INDICATED (MAX 3). Following stabilization efforts, what ongoing management is indicated?', 3, 'STOP' from _case7_target
  union all
  select id, 6, 6, 'DM', 'CHOOSE ONLY ONE. What is the safest disposition now?', null, 'STOP' from _case7_target
  returning id, step_order
)
insert into _case7_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Apply high-concentration oxygen and continuous cardiorespiratory monitoring', 2, 'Immediate oxygenation and surveillance are critical.' from _case7_steps s where s.step_order = 1
union all select s.id, 'B', 'Establish two IV lines and notify rapid-response team', 2, 'Supports urgent stabilization and escalation readiness.' from _case7_steps s where s.step_order = 1
union all select s.id, 'C', 'Perform focused hemodynamic and respiratory reassessment at bedside', 1, 'Clarifies progression and urgency.' from _case7_steps s where s.step_order = 1
union all select s.id, 'D', 'Send patient to CT before stabilization', -2, 'Unsafe transfer-first delay.' from _case7_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay oxygen until arterial blood gas returns', -2, 'Dangerous delay in severe hypoxemia.' from _case7_steps s where s.step_order = 1

union all select s.id, 'A', 'Use high-FiO2 support with close titration and frequent reassessment', 2, 'Best immediate support while evaluating perfusion trajectory.' from _case7_steps s where s.step_order = 2
union all select s.id, 'B', 'Use low-flow oxygen and wait for imaging', -1, 'Often inadequate in this severity.' from _case7_steps s where s.step_order = 2
union all select s.id, 'C', 'Remove oxygen to evaluate baseline trend', -2, 'Unsafe de-escalation.' from _case7_steps s where s.step_order = 2
union all select s.id, 'D', 'Intubate immediately without assessing hemodynamic impact', -1, 'May be required later but can worsen instability if premature.' from _case7_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend SpO2, BP, heart rate, and mental status every few minutes', 2, 'Captures early shock progression.' from _case7_steps s where s.step_order = 3
union all select s.id, 'B', 'Reassess signs of right-heart strain and perfusion adequacy', 2, 'Guides urgency of definitive therapy.' from _case7_steps s where s.step_order = 3
union all select s.id, 'C', 'Obtain focused blood gas/lactate trend without delaying care', 1, 'Supports objective risk tracking.' from _case7_steps s where s.step_order = 3
union all select s.id, 'D', 'Stop monitoring once saturation briefly improves', -2, 'Misses rapid decompensation.' from _case7_steps s where s.step_order = 3
union all select s.id, 'E', 'Pause all interventions pending complete diagnostics', -2, 'High-risk delay during active instability.' from _case7_steps s where s.step_order = 3

union all select s.id, 'A', 'Escalate to high-acuity shock protocol with immediate specialist coordination', 2, 'Appropriate for worsening perfusion and hypoxemia.' from _case7_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue unchanged therapy despite falling blood pressure', -1, 'Fails to address deterioration.' from _case7_steps s where s.step_order = 4
union all select s.id, 'C', 'Transport for routine imaging before perfusion stabilization', -2, 'Unsafe delay during shock pattern.' from _case7_steps s where s.step_order = 4
union all select s.id, 'D', 'Give sedative for anxiety without hemodynamic plan', -2, 'Can worsen instability.' from _case7_steps s where s.step_order = 4

union all select s.id, 'A', 'Titrate oxygen/ventilatory support to objective response', 2, 'Prevents avoidable over/under-support.' from _case7_steps s where s.step_order = 5
union all select s.id, 'B', 'Continue continuous hemodynamic monitoring and serial reassessment', 1, 'Detects relapse early.' from _case7_steps s where s.step_order = 5
union all select s.id, 'C', 'Coordinate definitive therapy pathway with critical care team', 2, 'Ensures timely follow-through.' from _case7_steps s where s.step_order = 5
union all select s.id, 'D', 'Stop frequent reassessment after transient stabilization', -1, 'Premature de-escalation.' from _case7_steps s where s.step_order = 5
union all select s.id, 'E', 'Transfer to low-acuity unit early', -2, 'Unsafe for current risk.' from _case7_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to ICU for ongoing respiratory and hemodynamic monitoring', 2, 'Matches acuity and relapse risk.' from _case7_steps s where s.step_order = 6
union all select s.id, 'B', 'Discharge after temporary symptom relief', -2, 'Unsafe disposition.' from _case7_steps s where s.step_order = 6
union all select s.id, 'C', 'Admit to unmonitored floor', -2, 'Inadequate monitoring level.' from _case7_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe in hallway without escalation plan', -1, 'Insufficient follow-through.' from _case7_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'INCLUDES_ALL', '["A","B"]'::jsonb, s2.id,
  'Early priorities modestly improve oxygenation, but high-risk physiology persists.',
  '{"spo2": 5, "hr": -4, "rr": -2, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case7_steps s1 cross join _case7_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Delay or harmful actions worsen hypoxemia and perfusion strain.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case7_steps s1 cross join _case7_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Support strategy improves gas exchange and buys reassessment time.',
  '{"spo2": 6, "hr": -5, "rr": -3, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case7_steps s2 cross join _case7_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Insufficient support leads to worsening fatigue and unstable perfusion.',
  '{"spo2": -5, "hr": 7, "rr": 4, "bp_sys": -5, "bp_dia": -3}'::jsonb
from _case7_steps s2 cross join _case7_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s4.id,
  'Focused reassessment identifies ongoing high-risk strain early.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 1, "bp_dia": 1}'::jsonb
from _case7_steps s3 cross join _case7_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Missed signals allow rapid deterioration toward shock.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case7_steps s3 cross join _case7_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Escalation improves perfusion trend and oxygenation stability.',
  '{"spo2": 5, "hr": -6, "rr": -3, "bp_sys": 8, "bp_dia": 5}'::jsonb
from _case7_steps s4 cross join _case7_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Inadequate escalation worsens shock physiology and hypoxemia.',
  '{"spo2": -7, "hr": 9, "rr": 5, "bp_sys": -10, "bp_dia": -6}'::jsonb
from _case7_steps s4 cross join _case7_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '4'::jsonb, s6.id,
  'Ongoing management stabilizes trajectory for safe high-acuity care.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case7_steps s5 cross join _case7_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Monitoring gaps leave high relapse and collapse risk.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case7_steps s5 cross join _case7_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient remains stable under ICU monitoring with definitive follow-through.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 2, "bp_dia": 1}'::jsonb
from _case7_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: disposition was unsafe and rapid re-decompensation occurred.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": -8, "bp_dia": -5}'::jsonb
from _case7_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE7_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case7_target);

commit;
