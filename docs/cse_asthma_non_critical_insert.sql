-- Exhale Academy CSE Branching Seed (COPD Non-Critical - Asthma Triggered Exacerbation)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _asthma_non_critical_target (id uuid primary key) on commit drop;
create temporary table _asthma_non_critical_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-13-asthma-conservative-triggered-exacerbation',
    'asthma-conservative-triggered-exacerbation',
    'case-13-copd-non-critical-asthma-triggered-exacerbation',
    'copd-non-critical-asthma-triggered-exacerbation'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'copd-non-critical',
    disease_slug = 'copd',
    disease_track = 'non_critical',
    case_number = coalesce(c.case_number, 13),
    slug = 'copd-non-critical-asthma-triggered-exacerbation',
    title = 'COPD Non-Critical (Asthma Triggered Exacerbation)',
    intro_text = 'Reversible obstructive flare after trigger exposure requiring rapid acute treatment then transition to long-term control planning.',
    description = 'Non-critical COPD branching case using an asthma-triggered obstructive exacerbation pattern with acute bronchodilator strategy and safe disposition.',
    stem = 'Patient with acute wheeze, dyspnea, and obstructive-pattern distress after irritant exposure.',
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
    'copd-non-critical',
    'copd',
    'non_critical',
    13,
    'copd-non-critical-asthma-triggered-exacerbation',
    'COPD Non-Critical (Asthma Triggered Exacerbation)',
    'Reversible obstructive flare after trigger exposure requiring rapid acute treatment then transition to long-term control planning.',
    'Non-critical COPD branching case using an asthma-triggered obstructive exacerbation pattern with acute bronchodilator strategy and safe disposition.',
    'Patient with acute wheeze, dyspnea, and obstructive-pattern distress after irritant exposure.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _asthma_non_critical_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":118,"rr":32,"spo2":89,"bp_sys":146,"bp_dia":88,"etco2":49}'::jsonb
where id in (select id from _asthma_non_critical_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _asthma_non_critical_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _asthma_non_critical_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _asthma_non_critical_target)
);

delete from public.cse_attempts where case_id in (select id from _asthma_non_critical_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _asthma_non_critical_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _asthma_non_critical_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _asthma_non_critical_target));
delete from public.cse_steps where case_id in (select id from _asthma_non_critical_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 43-year-old male who was cleaning a dusty attic and now has acute dyspnea, chest tightness, and wheeze. Focused exam findings are still needed. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "anxious, diaphoretic, tachypneic, using accessory muscles with difficulty speaking full sentences",
      "appearance_keys_any": ["B", "C", "I"],
      "show_vitals_after_submit": true,
      "vitals_keys_any": ["A", "D", "E"],
      "vitals_fields": ["spo2", "rr", "hr", "etco2"],
      "extra_reveals": [
        { "text": "Trigger context confirmed; future avoidance counseling will be required.", "keys_any": ["J"] },
        { "text": "ABG tendency: early hyperventilation with hypoxemia; deterioration risk can shift toward rising PaCO2 and falling pH.", "keys_any": ["E"] }
      ]
    }'::jsonb from _asthma_non_critical_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is your FIRST treatment decision now?',
    null, 'STOP', '{}'::jsonb from _asthma_non_critical_target
  union all
  select id, 3, 3, 'IG',
    '30 minutes after initial therapy, distress is improved but still present. SELECT AS MANY AS INDICATED (MAX 8). What reassessment data are most useful now?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "wheeze persists but speaking tolerance and accessory-muscle strain are improving",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "bp"]
    }'::jsonb from _asthma_non_critical_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is your NEXT management decision if symptoms persist without immediate crash signs?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "airflow improves after escalation; fatigue risk still requires close monitoring",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "hr", "etco2"]
    }'::jsonb from _asthma_non_critical_target
  union all
  select id, 5, 5, 'IG',
    'The patient is stabilizing. SELECT AS MANY AS INDICATED (MAX 8). What long-term control and safety planning elements are indicated before disposition?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "patient appears less anxious and breathing effort continues to normalize",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr"]
    }'::jsonb from _asthma_non_critical_target
  union all
  select id, 6, 6, 'DM',
    'CHOOSE ONLY ONE. What is the most appropriate disposition now?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "clinical stability supports transition only with complete trigger-action plan and follow-up",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "hr", "bp"]
    }'::jsonb from _asthma_non_critical_target
  returning id, step_order
)
insert into _asthma_non_critical_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Provide oxygen for hypoxemia and begin continuous monitoring', 3, 'Best immediate oxygenation priority during acute asthma flare.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess appearance for anxiety/diaphoresis, speaking difficulty, and accessory-muscle use', 2, 'Critical distress severity indicators.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'C', 'Auscultate for wheeze versus markedly diminished airflow', 2, 'Determines obstruction severity and potential near-silent chest risk.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'D', 'Trend heart rate, respiratory rate, and blood pressure', 1, 'Useful objective severity trend.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'E', 'Obtain ABG if ventilatory concern persists', 1, 'Appropriate for rising PaCO2/falling pH detection.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'F', 'Delay treatment until complete broad lab panel returns', -3, 'Unsafe delay in a possible emergency episode.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'G', 'Ignore trigger history because treatment is already started', -2, 'Misses prevention and recurrence context.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'H', 'Send for non-indicated immediate CT before stabilization', -3, 'Unsafe transfer and delay.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'I', 'Assess chest tightness and ability to speak in full sentences', 1, 'Helps grade airflow limitation severity.' from _asthma_non_critical_steps s where s.step_order = 1
union all select s.id, 'J', 'Identify likely trigger and document avoidance target', 1, 'Supports long-term control planning.' from _asthma_non_critical_steps s where s.step_order = 1

union all select s.id, 'A', 'Start SABA + anticholinergic aerosol, give systemic corticosteroid, continue oxygen for hypoxemia', 3, 'Best acute asthma regimen in this scenario.' from _asthma_non_critical_steps s where s.step_order = 2
union all select s.id, 'B', 'Observe only because patient is still moving air', -2, 'Insufficient treatment for active exacerbation.' from _asthma_non_critical_steps s where s.step_order = 2
union all select s.id, 'C', 'Delay bronchodilator and give sedative first', -3, 'Unsafe sequence in respiratory distress.' from _asthma_non_critical_steps s where s.step_order = 2
union all select s.id, 'D', 'Start long-acting maintenance therapy only and reassess tomorrow', -3, 'Inappropriate for acute episode management.' from _asthma_non_critical_steps s where s.step_order = 2
union all select s.id, 'E', 'Use antibiotics as routine primary therapy without infection evidence', -3, 'Incorrect routine treatment choice.' from _asthma_non_critical_steps s where s.step_order = 2
union all select s.id, 'F', 'Give back-to-back bronchodilator treatments now, continue oxygen, and reassess in 15-30 minutes before deciding on further escalation', 1, 'Reasonable bridge step, but less complete than adding early systemic steroid.' from _asthma_non_critical_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess breath sounds for persistent wheeze vs diminished airflow', 2, 'Tracks response and residual obstruction.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'B', 'Trend SpO2/work of breathing and speaking tolerance', 2, 'Core post-treatment reassessment markers.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'C', 'Repeat focused vital trends (HR/RR/BP)', 1, 'Objective response tracking.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'D', 'Obtain ABG if concern for rising PaCO2 or fatigue remains', 2, 'Supports ventilatory failure detection.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'E', 'Review trigger timeline and ongoing exposure risk', 1, 'Important for recurrence prevention.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'F', 'Remove monitoring after short-term improvement', -2, 'Unsafe de-monitoring.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'G', 'Ignore persistent dyspnea because wheeze is softer', -2, 'Can miss worsening airflow limitation.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'H', 'Postpone all reassessment until next shift', -3, 'Detrimental delay.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'I', 'Check for pulsus paradoxus in severe pattern', 1, 'Useful severe-episode marker.' from _asthma_non_critical_steps s where s.step_order = 3
union all select s.id, 'J', 'Order non-indicated broad imaging first', -2, 'Low-yield priority before focused reassessment completion.' from _asthma_non_critical_steps s where s.step_order = 3

union all select s.id, 'A', 'Escalate to continuous aerosol therapy with close vitals/ABG trend monitoring', 3, 'Best next escalation when symptoms persist without immediate crash criteria.' from _asthma_non_critical_steps s where s.step_order = 4
union all select s.id, 'B', 'Stop bronchodilator therapy once symptoms partially improve', -2, 'Premature de-escalation.' from _asthma_non_critical_steps s where s.step_order = 4
union all select s.id, 'C', 'Delay additional treatment and reassess much later', -3, 'Unsafe delay.' from _asthma_non_critical_steps s where s.step_order = 4
union all select s.id, 'D', 'Proceed directly to intubation despite no ventilatory failure markers', -2, 'Over-escalation without criteria.' from _asthma_non_critical_steps s where s.step_order = 4
union all select s.id, 'E', 'Use maintenance-only long-term meds as sole next step', -2, 'Acute phase not adequately treated.' from _asthma_non_critical_steps s where s.step_order = 4
union all select s.id, 'F', 'Repeat short-interval bronchodilator cycle with serial bedside reassessment before major escalation', 1, 'Reasonable interim approach, though continuous therapy is usually stronger when symptoms persist.' from _asthma_non_critical_steps s where s.step_order = 4

union all select s.id, 'A', 'Finalize trigger-avoidance action plan', 2, 'Core long-term asthma control element.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'B', 'Confirm inhaled corticosteroid-based control plan', 2, 'Key long-term anti-inflammatory strategy.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'C', 'Review rescue bronchodilator and anticholinergic use instructions', 2, 'Improves home response to early exacerbation.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'D', 'Provide peak-flow monitoring education and thresholds', 2, 'Objective home trend tracking for obstruction.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'E', 'Provide return precautions for worsening dyspnea or speaking difficulty', 1, 'Safety-net planning.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'F', 'Skip education because acute symptoms improved', -2, 'Unsafe transition gap.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'G', 'Discharge without trigger discussion or follow-up', -3, 'High relapse risk plan.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'H', 'Use routine antibiotics as maintenance prevention', -3, 'Incorrect routine plan without infection indication.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'I', 'Use sedative-first strategy for future episodes', -3, 'Unsafe educational guidance.' from _asthma_non_critical_steps s where s.step_order = 5
union all select s.id, 'J', 'Arrange close outpatient follow-up', 1, 'Improves continuity and relapse prevention.' from _asthma_non_critical_steps s where s.step_order = 5

union all select s.id, 'A', 'Discharge with structured asthma action plan and close follow-up after sustained stability', 3, 'Best disposition when response is sustained and education completed.' from _asthma_non_critical_steps s where s.step_order = 6
union all select s.id, 'B', 'Admit for monitored care if instability, fatigue risk, or poor response persists', 1, 'Reasonable alternative when discharge criteria are not met.' from _asthma_non_critical_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge immediately without follow-up or action plan', -3, 'Unsafe high-risk transition.' from _asthma_non_critical_steps s where s.step_order = 6
union all select s.id, 'D', 'Observe in unstructured hallway status only', -2, 'Inadequate plan.' from _asthma_non_critical_steps s where s.step_order = 6
union all select s.id, 'E', 'Discharge with no trigger counseling because symptoms improved', -3, 'Major prevention failure.' from _asthma_non_critical_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Initial prioritization is strong and oxygenation begins improving with active treatment.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _asthma_non_critical_steps s1 cross join _asthma_non_critical_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Missed priorities increase fatigue risk and prolong severe symptoms.',
  '{"spo2": -5, "hr": 7, "rr": 4, "bp_sys": 5, "bp_dia": 3}'::jsonb
from _asthma_non_critical_steps s1 cross join _asthma_non_critical_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Appropriate acute regimen improves airflow, but close reassessment remains necessary.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _asthma_non_critical_steps s2 cross join _asthma_non_critical_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Suboptimal treatment leaves persistent obstruction and rising decompensation risk.',
  '{"spo2": -6, "hr": 8, "rr": 5, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _asthma_non_critical_steps s2 cross join _asthma_non_critical_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s4.id,
  'Focused reassessment supports safe and timely escalation decisions.',
  '{"spo2": 2, "hr": -2, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _asthma_non_critical_steps s3 cross join _asthma_non_critical_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment gaps increase risk of unrecognized ventilatory decline.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _asthma_non_critical_steps s3 cross join _asthma_non_critical_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Escalation improves airflow and supports transition toward long-term planning.',
  '{"spo2": 4, "hr": -4, "rr": -3, "bp_sys": -2, "bp_dia": -2}'::jsonb
from _asthma_non_critical_steps s4 cross join _asthma_non_critical_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Treatment mismatch prolongs instability and increases relapse risk.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 5, "bp_dia": 3}'::jsonb
from _asthma_non_critical_steps s4 cross join _asthma_non_critical_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s6.id,
  'Long-term planning is complete and supports safer disposition.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _asthma_non_critical_steps s5 cross join _asthma_non_critical_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Transition planning gaps raise near-term exacerbation recurrence risk.',
  '{"spo2": -3, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _asthma_non_critical_steps s5 cross join _asthma_non_critical_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient transitions safely with asthma action plan, trigger strategy, and follow-up.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _asthma_non_critical_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: disposition was insufficient and early symptom recurrence occurs.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _asthma_non_critical_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'COPD_NON_CRIT_ASTHMA_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _asthma_non_critical_target);

commit;
