-- Exhale Academy CSE Branching Seed (Cases 36-37)
-- Pediatric Critical (Croup / Epiglottitis)

begin;

create temporary table _ped_airway_seed (
  case_number int4 primary key,
  disease_key text not null,
  slug text not null,
  title text not null,
  intro_text text not null,
  description text not null,
  stem text not null,
  baseline_vitals jsonb not null
) on commit drop;

insert into _ped_airway_seed (case_number, disease_key, slug, title, intro_text, description, stem, baseline_vitals) values
(36, 'croup', 'pediatric-critical-croup-gradual-barking-stridor',
 'Pediatric Critical (Croup Gradual Barking Stridor)',
 'Gradual viral upper-airway illness with barking cough and stridor at rest.',
 'Pediatric croup case focused on upper-airway severity assessment, racemic epinephrine use, and escalation timing.',
 'Child has progressive barking cough, inspiratory stridor, and increasing work of breathing.',
 '{"hr":148,"rr":42,"spo2":86,"bp_sys":104,"bp_dia":64}'::jsonb),
(37, 'epiglottitis', 'pediatric-critical-epiglottitis-sudden-thumb-sign-emergency',
 'Pediatric Critical (Epiglottitis Sudden Thumb-Sign Emergency)',
 'Sudden toxic upper-airway emergency with drooling, tripod positioning, and immediate airway risk.',
 'Pediatric epiglottitis case focused on keeping the child calm, controlled airway management, and ICU follow-up.',
 'Child has abrupt fever, drooling, muffled voice, and rapidly worsening airway obstruction risk.',
 '{"hr":156,"rr":44,"spo2":82,"bp_sys":100,"bp_dia":60}'::jsonb);

create temporary table _ped_airway_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _ped_airway_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _ped_airway_seed s
  join public.cse_cases c on c.slug = s.slug
),
updated as (
  update public.cse_cases c
  set
    source = 'pediatric-critical-airway',
    disease_slug = case when s.disease_key = 'croup' then 'croup' else 'epiglottitis' end,
    disease_track = 'critical',
    case_number = coalesce(c.case_number, s.case_number),
    slug = s.slug,
    title = s.title,
    intro_text = s.intro_text,
    description = s.description,
    stem = s.stem,
    difficulty = 'hard',
    is_active = true,
    is_published = true,
    baseline_vitals = s.baseline_vitals,
    nbrc_category_code = 'F',
    nbrc_category_name = 'Pediatric',
    nbrc_subcategory = 'Other'
  from _ped_airway_seed s
  where c.id in (select id from existing where case_number = s.case_number)
  returning s.case_number, c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty,
    is_active, is_published, baseline_vitals, nbrc_category_code, nbrc_category_name, nbrc_subcategory
  )
  select
    'pediatric-critical-airway',
    case when s.disease_key = 'croup' then 'croup' else 'epiglottitis' end,
    'critical',
    s.case_number,
    s.slug,
    s.title,
    s.intro_text,
    s.description,
    s.stem,
    'hard',
    true,
    true,
    s.baseline_vitals,
    'F',
    'Pediatric',
    'Other'
  from _ped_airway_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _ped_airway_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _ped_airway_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _ped_airway_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _ped_airway_target)
);

delete from public.cse_attempts where case_id in (select case_id from _ped_airway_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_airway_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_airway_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_airway_target));
delete from public.cse_steps where case_id in (select case_id from _ped_airway_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'croup' then
'A 3-year-old boy is brought to the emergency department because of worsening noisy breathing overnight after several days of upper respiratory symptoms.

While receiving room air, the following are noted:
HR 148/min
RR 42/min
BP 104/64 mm Hg
SpO2 86%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      else
'A 6-year-old girl is brought to the emergency department because of abrupt fever, drooling, and severe difficulty breathing.

While receiving room air, the following are noted:
HR 156/min
RR 44/min
BP 100/60 mm Hg
SpO2 82%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'croup' then
      '{
        "show_appearance_after_submit": true,
        "appearance_text": "the child is alert but frightened",
        "extra_reveals": [
          {"text":"There is inspiratory stridor at rest with suprasternal retractions.","keys_any":["A"]},
          {"text":"The cough is harsh and barking, and the voice is hoarse.","keys_any":["B"]},
          {"text":"Air movement is decreased but breath sounds remain bilateral.","keys_any":["C"]},
          {"text":"The child can swallow secretions and is not drooling.","keys_any":["D"]}
        ]
      }'::jsonb
      else
      '{
        "show_appearance_after_submit": true,
        "appearance_text": "the child sits leaning forward and resists being handled",
        "extra_reveals": [
          {"text":"Drooling is present, and the voice is muffled.","keys_any":["A"]},
          {"text":"Inspiratory stridor is severe, and air entry is limited.","keys_any":["B"]},
          {"text":"The child cannot tolerate lying flat or opening the mouth for routine examination.","keys_any":["C"]},
          {"text":"High fever and toxic appearance are present.","keys_any":["D"]}
        ]
      }'::jsonb
    end
  from _ped_airway_target t join _ped_airway_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    case s.disease_key
      when 'croup' then 'Findings suggest moderate-to-severe croup. Which of the following should be recommended FIRST?'
      else 'Findings suggest epiglottitis with impending airway obstruction. Which of the following should be recommended FIRST?'
    end,
    null,
    'STOP',
    '{}'::jsonb
  from _ped_airway_target t join _ped_airway_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 3, 3, 'IG',
    case s.disease_key
      when 'croup' then
'Twenty minutes after initial treatment, the child remains under close observation.

Current findings are:
HR 138/min
RR 36/min
BP 102/62 mm Hg
SpO2 91%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      else
'After controlled airway management, the child is receiving mechanical ventilation in the ICU.

Current findings are:
HR 132/min
RR 22/min
BP 104/64 mm Hg
SpO2 96%
EtCO2 36 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'croup' then
      '{
        "show_appearance_after_submit": true,
        "appearance_text": "the child is calmer but still working to breathe",
        "extra_reveals": [
          {"text":"Stridor decreases when calm but returns at rest with agitation.","keys_any":["A"]},
          {"text":"Retractions improve but have not resolved completely.","keys_any":["B"]},
          {"text":"SpO2 improves with therapy, but monitored observation is still needed.","keys_any":["C"]},
          {"text":"Further escalation remains necessary if stridor at rest worsens again.","keys_any":["D"]}
        ]
      }'::jsonb
      else
      '{
        "show_appearance_after_submit": true,
        "appearance_text": "the child is sedated and ventilating without severe distress",
        "extra_reveals": [
          {"text":"Breath sounds are equal bilaterally, and EtCO2 is acceptable.","keys_any":["A"]},
          {"text":"ABG: pH 7.39, PaCO2 38 torr, PaO2 88 torr, HCO3 23 mEq/L.","keys_any":["B"]},
          {"text":"Airway edema still requires ICU monitoring before extubation is considered.","keys_any":["C"]},
          {"text":"IV antibiotic therapy should continue while the airway stabilizes.","keys_any":["D"]}
        ]
      }'::jsonb
    end
  from _ped_airway_target t join _ped_airway_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM',
    case s.disease_key
      when 'croup' then 'Which of the following should be recommended now?'
      else 'Which of the following should be recommended now?'
    end,
    null,
    'STOP',
    '{}'::jsonb
  from _ped_airway_target t join _ped_airway_seed s on s.case_number = t.case_number
  returning case_id, step_order, id
)
insert into _ped_airway_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _ped_airway_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case when s.disease_key = 'croup' then 'Assess stridor at rest and degree of retractions' else 'Assess drooling, voice quality, and ability to handle secretions' end,
  2,
  'This is high-yield for the immediate airway decision.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'B',
  case when s.disease_key = 'croup' then 'Characterize the cough and upper-airway sound pattern' else 'Assess stridor severity and overall air entry' end,
  2,
  'This helps identify the airway syndrome.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'C',
  case when s.disease_key = 'croup' then 'Auscultate air movement and monitor oxygenation' else 'Determine whether the child can tolerate routine examination or lying flat' end,
  2,
  'This supports severity assessment.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'D',
  case when s.disease_key = 'croup' then 'Determine whether drooling or inability to swallow is absent' else 'Assess fever and toxic appearance' end,
  2,
  'This helps distinguish the likely diagnosis.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 1
union all select st.step_id, 'E', 'Delay stabilization while waiting for complete imaging', -3, 'This is unsafe.' from _ped_airway_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Assume all pediatric stridor is managed the same way', -3, 'This misses disease-specific priorities.' from _ped_airway_steps st where st.step_order = 1

union all
select st.step_id, 'A',
  case when s.disease_key = 'croup'
    then 'Administer humidified oxygen, corticosteroid therapy, and racemic epinephrine while observing closely'
    else 'Keep the child calm, provide blow-by oxygen, and arrange controlled endotracheal intubation with antibiotics after the airway is secured'
  end,
  3,
  'This is the best first intervention.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen only and postpone definitive treatment', -3, 'This is unsafe.' from _ped_airway_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Force a routine throat exam before airway planning', -3, 'This may worsen obstruction.' from _ped_airway_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Transfer to lower-acuity care after a brief improvement', -3, 'This is unsafe.' from _ped_airway_steps st where st.step_order = 2

union all
select st.step_id, 'A',
  case when s.disease_key = 'croup' then 'Reassess stridor, retractions, and work of breathing' else 'Reassess breath sounds and ventilatory stability' end,
  2,
  'This is indicated now.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'B',
  case when s.disease_key = 'croup' then 'Trend oxygenation and overall clinical response' else 'Repeat ABG and review ventilation status' end,
  2,
  'This helps guide the next decision.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'C',
  case when s.disease_key = 'croup' then 'Determine whether monitored admission is still required' else 'Determine whether airway edema is improved enough for any extubation planning' end,
  2,
  'This is a high-yield reassessment point.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'D',
  case when s.disease_key = 'croup' then 'Maintain readiness for airway escalation if stridor at rest worsens again' else 'Continue IV antibiotics and ICU airway monitoring' end,
  2,
  'This is an appropriate next evaluation item.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'E', 'Stop close monitoring after one modest improvement', -3, 'This is unsafe.' from _ped_airway_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Delay reassessment for several hours', -3, 'This is unsafe.' from _ped_airway_steps st where st.step_order = 3

union all
select st.step_id, 'A',
  case when s.disease_key = 'croup'
    then 'Admit for monitored pediatric high-acuity care until stridor at rest resolves'
    else 'Continue ICU-level airway management, ventilation, and antibiotics until edema improves'
  end,
  3,
  'This is the safest next step.'
from _ped_airway_steps st join _ped_airway_seed s on s.case_number = st.case_number where st.step_order = 4
union all select st.step_id, 'B', 'Transfer to an unmonitored bed', -3, 'This is unsafe.' from _ped_airway_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discharge after temporary improvement', -3, 'This is unsafe.' from _ped_airway_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Observe without explicit escalation triggers', -2, 'This is an inadequate safety plan.' from _ped_airway_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.step_id,
  case when s.disease_key = 'croup'
    then 'Assessment supports croup with significant upper-airway obstruction but preserved secretion handling.'
    else 'Assessment supports epiglottitis with immediate airway risk.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0}'::jsonb
from _ped_airway_steps s1
join _ped_airway_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
join _ped_airway_seed s on s.case_number = s1.case_number
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment is incomplete, and airway obstruction worsens.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _ped_airway_steps s1
join _ped_airway_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  case when s.disease_key = 'croup'
    then 'Initial therapy reduces distress, but stridor at rest has not resolved completely.'
    else 'The airway is secured, and oxygenation improves under controlled conditions.'
  end,
  case when s.disease_key = 'croup'
    then '{"spo2":5,"hr":-10,"rr":-6,"bp_sys":0,"bp_dia":0}'::jsonb
    else '{"spo2":14,"hr":-24,"rr":-22,"bp_sys":4,"bp_dia":4}'::jsonb
  end
from _ped_airway_steps s2
join _ped_airway_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
join _ped_airway_seed s on s.case_number = s2.case_number
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Treatment is delayed, and the airway becomes more unstable.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _ped_airway_steps s2
join _ped_airway_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  case when s.disease_key = 'croup'
    then 'Reassessment shows improvement but continued need for monitored care.'
    else 'Reassessment confirms stable ventilation but persistent airway edema requiring ICU care.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0}'::jsonb
from _ped_airway_steps s3
join _ped_airway_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
join _ped_airway_seed s on s.case_number = s3.case_number
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Reassessment is incomplete, and recurrence risk remains high.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _ped_airway_steps s3
join _ped_airway_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  case when s.disease_key = 'croup'
    then 'Final outcome: the child remains under monitored care until upper-airway obstruction improves.'
    else 'Final outcome: the child remains in the ICU for airway management and antibiotic therapy.'
  end,
  case when s.disease_key = 'croup'
    then '{"spo2":2,"hr":-4,"rr":-2,"bp_sys":0,"bp_dia":0}'::jsonb
    else '{"spo2":1,"hr":-2,"rr":0,"bp_sys":0,"bp_dia":0}'::jsonb
  end
from _ped_airway_steps s4 join _ped_airway_seed s on s.case_number = s4.case_number
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: unsafe de-escalation leads to recurrent airway instability.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _ped_airway_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE' || t.case_number::text || '_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
join _ped_airway_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _ped_airway_target);

commit;
