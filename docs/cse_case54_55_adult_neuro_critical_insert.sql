-- Exhale Academy CSE Branching Seed (Cases 54-55)
-- Adult Neuro Critical (Head Trauma / Spinal Injury)

begin;

create temporary table _neuro_seed (
  case_number int4 primary key,
  disease_key text not null,
  slug text not null,
  title text not null,
  intro_text text not null,
  description text not null,
  stem text not null,
  baseline_vitals jsonb not null
) on commit drop;

insert into _neuro_seed (case_number, disease_key, slug, title, intro_text, description, stem, baseline_vitals) values
(54, 'head_trauma', 'adult-neuro-critical-head-trauma-cheyne-stokes-icp',
 'Adult Neuro Critical (Head Trauma Cheyne-Stokes/ICP)',
 'Head trauma with declining consciousness, abnormal breathing pattern, and rising ICP concern.',
 'Critical head-trauma case focused on neuro-respiratory assessment, airway protection, and ICP-conscious ventilation.',
 'Trauma patient has worsening mental status, abnormal breathing, and signs of intracranial injury.',
 '{"hr":112,"rr":28,"spo2":86,"bp_sys":170,"bp_dia":102,"etco2":50}'::jsonb),
(55, 'spinal_injury', 'adult-neuro-critical-spinal-injury-airway-stability',
 'Adult Neuro Critical (Spinal Injury Airway Stability)',
 'Cervical trauma with evolving ventilatory weakness and strict immobilization needs.',
 'Critical spinal-injury case focused on inline airway management, respiratory-muscle surveillance, and high-acuity support.',
 'Trauma patient has possible high cervical injury with progressive respiratory compromise.',
 '{"hr":108,"rr":24,"spo2":87,"bp_sys":122,"bp_dia":74,"etco2":45}'::jsonb);

create temporary table _neuro_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _neuro_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _neuro_seed s
  join public.cse_cases c on c.slug = s.slug
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-neurocritical',
    disease_slug = case when s.disease_key = 'head_trauma' then 'head-trauma' else 'spinal-injury' end,
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
    nbrc_category_code = 'D',
    nbrc_category_name = 'Adult Neurological or Neuromuscular',
    nbrc_subcategory = null
  from _neuro_seed s
  where c.id in (select id from existing where case_number = s.case_number)
  returning s.case_number, c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty,
    is_active, is_published, baseline_vitals, nbrc_category_code, nbrc_category_name, nbrc_subcategory
  )
  select
    'adult-neurocritical',
    case when s.disease_key = 'head_trauma' then 'head-trauma' else 'spinal-injury' end,
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
    'D',
    'Adult Neurological or Neuromuscular',
    null
  from _neuro_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _neuro_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _neuro_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _neuro_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _neuro_target)
);

delete from public.cse_attempts where case_id in (select case_id from _neuro_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _neuro_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _neuro_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _neuro_target));
delete from public.cse_steps where case_id in (select case_id from _neuro_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'head_trauma' then
'A 32-year-old woman is brought to the emergency department after a motor vehicle crash.

While receiving O2 by nonrebreathing mask with cervical stabilization in place, the following are noted:
HR 112/min
RR 28/min with an irregular waxing and waning pattern
BP 170/102 mm Hg
SpO2 86%
EtCO2 50 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      else
'A 27-year-old man is brought to the emergency department after a diving accident.

While receiving O2 by nonrebreathing mask with cervical stabilization in place, the following are noted:
HR 108/min
RR 24/min with shallow respirations
BP 122/74 mm Hg
SpO2 87%
EtCO2 45 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'head_trauma' then
      '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient responds only to painful stimulation",
        "extra_reveals": [
          {"text":"Pupils are unequal, and the GCS is 7.","keys_any":["A"]},
          {"text":"Breathing pattern is consistent with Cheyne-Stokes respirations.","keys_any":["B"]},
          {"text":"ABG: pH 7.29, PaCO2 54 torr, PaO2 58 torr, HCO3 25 mEq/L.","keys_any":["C"]},
          {"text":"Head CT reveals acute intracranial hemorrhage with mass effect.","keys_any":["D"]}
        ]
      }'::jsonb
      else
      '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient has weak voice and poor cough effort",
        "extra_reveals": [
          {"text":"Motor strength is markedly reduced in both upper and lower extremities.","keys_any":["A"]},
          {"text":"Diaphragmatic breathing is weak, and secretion clearance is poor.","keys_any":["B"]},
          {"text":"ABG: pH 7.33, PaCO2 50 torr, PaO2 60 torr, HCO3 26 mEq/L.","keys_any":["C"]},
          {"text":"Cervical spine imaging shows unstable high cervical injury.","keys_any":["D"]}
        ]
      }'::jsonb
    end
  from _neuro_target t join _neuro_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    case s.disease_key
      when 'head_trauma' then 'Findings suggest severe head injury with impaired airway protection and hypercapnia. Which of the following should be recommended FIRST?'
      else 'Findings suggest high cervical spinal injury with evolving ventilatory weakness. Which of the following should be recommended FIRST?'
    end,
    null,
    'STOP',
    '{}'::jsonb
  from _neuro_target t join _neuro_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 3, 3, 'IG',
    case s.disease_key
      when 'head_trauma' then
'After initial stabilization, the patient is intubated and receiving volume-controlled ventilation.

Current findings are:
HR 106/min
RR 20/min
BP 160/96 mm Hg
SpO2 92%
EtCO2 38 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      else
'After initial stabilization, the patient remains immobilized and is receiving O2 by face mask.

Current findings are:
HR 104/min
RR 26/min
BP 118/72 mm Hg
SpO2 90%
EtCO2 48 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'head_trauma' then
      '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains unresponsive to verbal command",
        "extra_reveals": [
          {"text":"Repeat ABG: pH 7.37, PaCO2 37 torr, PaO2 74 torr, HCO3 23 mEq/L.","keys_any":["A"]},
          {"text":"Pupillary asymmetry persists, and neuro checks remain abnormal.","keys_any":["B"]},
          {"text":"Ventilator settings keep EtCO2 near the desired range without severe hypocapnia.","keys_any":["C"]},
          {"text":"Ongoing ICP-focused ICU management is still required.","keys_any":["D"]}
        ]
      }'::jsonb
      else
      '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient struggles to clear secretions with each shallow breath",
        "extra_reveals": [
          {"text":"VC is reduced, and inspiratory effort is weakening.","keys_any":["A"]},
          {"text":"Repeat ABG: pH 7.30, PaCO2 55 torr, PaO2 62 torr, HCO3 27 mEq/L.","keys_any":["B"]},
          {"text":"Inline stabilization remains mandatory during any airway intervention.","keys_any":["C"]},
          {"text":"Definitive airway support is now indicated because ventilatory weakness is progressing.","keys_any":["D"]}
        ]
      }'::jsonb
    end
  from _neuro_target t join _neuro_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM',
    case s.disease_key
      when 'head_trauma' then 'Which of the following should be recommended now?'
      else 'Ventilatory weakness continues to worsen. Which of the following should be recommended now?'
    end,
    null,
    'STOP',
    '{}'::jsonb
  from _neuro_target t join _neuro_seed s on s.case_number = t.case_number
  returning case_id, step_order, id
)
insert into _neuro_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _neuro_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case when s.disease_key = 'head_trauma' then 'Assess GCS, pupil size, and airway reflexes' else 'Assess motor strength, cough strength, and airway protection' end,
  2,
  'This is a high-yield first assessment.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'B',
  case when s.disease_key = 'head_trauma' then 'Characterize the breathing pattern and look for signs of ICP-related deterioration' else 'Assess breathing pattern, chest expansion, and secretion burden' end,
  2,
  'This defines the immediate respiratory threat.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'C', 'Obtain an ABG', 2, 'This is indicated to assess oxygenation and ventilation.' from _neuro_steps st where st.step_order = 1
union all
select st.step_id, 'D',
  case when s.disease_key = 'head_trauma' then 'Review emergent head imaging after stabilization' else 'Review cervical spine imaging while maintaining immobilization' end,
  2,
  'This helps confirm the injury pattern without replacing bedside stabilization.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 1
union all select st.step_id, 'E', 'Delay stabilization until all imaging is complete', -3, 'This delays indicated care.' from _neuro_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Remove cervical stabilization for easier assessment', -3, 'This is unsafe.' from _neuro_steps st where st.step_order = 1

union all
select st.step_id, 'A',
  case when s.disease_key = 'head_trauma'
    then 'Preoxygenate, intubate, and provide controlled ventilation while avoiding severe hypercapnia'
    else 'Maintain inline stabilization, provide oxygen, and secure a controlled airway because ventilatory weakness is evolving'
  end,
  3,
  'This is the best first intervention.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen only and delay airway planning', -3, 'This is unsafe.' from _neuro_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Sedate the patient before securing ventilation strategy', -3, 'This can worsen instability.' from _neuro_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Transfer to lower-acuity care once saturation improves briefly', -3, 'This is unsafe.' from _neuro_steps st where st.step_order = 2

union all
select st.step_id, 'A',
  case when s.disease_key = 'head_trauma' then 'Repeat ABG and trend EtCO2' else 'Trend VC and repeat ABG' end,
  2,
  'This helps judge the next escalation step.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'B',
  case when s.disease_key = 'head_trauma' then 'Repeat focused neurologic assessment' else 'Reassess airway protection and secretion clearance' end,
  2,
  'This is a key reassessment item.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'C',
  case when s.disease_key = 'head_trauma' then 'Confirm ventilator targets are avoiding worsening hypercapnia or excessive hypocapnia' else 'Verify that inline stabilization is maintained for any airway escalation' end,
  2,
  'This is appropriate and high yield.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'D',
  case when s.disease_key = 'head_trauma' then 'Determine whether ICU-level ICP-focused care remains necessary' else 'Determine whether definitive endotracheal intubation is now required' end,
  2,
  'This is the core next-step decision.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'E', 'Stop close monitoring after one modest improvement', -3, 'This is unsafe.' from _neuro_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Delay reassessment for several hours', -3, 'This is unsafe.' from _neuro_steps st where st.step_order = 3

union all
select st.step_id, 'A',
  case when s.disease_key = 'head_trauma'
    then 'Continue ICU-level neurocritical care with controlled ventilation and serial neurologic reassessment'
    else 'Proceed with controlled endotracheal intubation and ICU-level ventilatory support with spinal precautions'
  end,
  3,
  'This is the safest next step.'
from _neuro_steps st join _neuro_seed s on s.case_number = st.case_number where st.step_order = 4
union all select st.step_id, 'B', 'Continue current therapy unchanged and reassess later', -3, 'This delays indicated escalation.' from _neuro_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Transfer to an unmonitored bed', -3, 'This is unsafe.' from _neuro_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Discharge after temporary improvement', -3, 'This is unsafe.' from _neuro_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.step_id,
  case when s.disease_key = 'head_trauma'
    then 'Neuro-respiratory assessment confirms severe head injury with poor airway protection.'
    else 'Assessment confirms high cervical injury with weak cough and rising ventilatory risk.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _neuro_steps s1
join _neuro_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
join _neuro_seed s on s.case_number = s1.case_number
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment is incomplete, and respiratory instability worsens.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":4,"bp_dia":2,"etco2":3}'::jsonb
from _neuro_steps s1
join _neuro_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  case when s.disease_key = 'head_trauma'
    then 'The airway is secured, and ventilation is controlled while neurocritical risk remains high.'
    else 'Initial stabilization begins, but respiratory-muscle weakness continues to progress.'
  end,
  case when s.disease_key = 'head_trauma'
    then '{"spo2":6,"hr":-4,"rr":-8,"bp_sys":-6,"bp_dia":-4,"etco2":-12}'::jsonb
    else '{"spo2":3,"hr":-2,"rr":2,"bp_sys":0,"bp_dia":0,"etco2":2}'::jsonb
  end
from _neuro_steps s2
join _neuro_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
join _neuro_seed s on s.case_number = s2.case_number
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Treatment is delayed, and ventilation worsens.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":4,"bp_dia":2,"etco2":4}'::jsonb
from _neuro_steps s2
join _neuro_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  case when s.disease_key = 'head_trauma'
    then 'Reassessment shows controlled ventilation, but ICP-focused ICU care is still required.'
    else 'Reassessment confirms worsening ventilatory weakness and need for definitive airway support.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _neuro_steps s3
join _neuro_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
join _neuro_seed s on s.case_number = s3.case_number
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Reassessment is incomplete, and deterioration risk remains high.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":4,"bp_dia":2,"etco2":3}'::jsonb
from _neuro_steps s3
join _neuro_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  case when s.disease_key = 'head_trauma'
    then 'Final outcome: the patient remains in neurocritical care with controlled ventilation and serial neurologic monitoring.'
    else 'Final outcome: the patient is intubated with spinal precautions and admitted for ICU-level support.'
  end,
  case when s.disease_key = 'head_trauma'
    then '{"spo2":2,"hr":-2,"rr":0,"bp_sys":-2,"bp_dia":-1,"etco2":0}'::jsonb
    else '{"spo2":5,"hr":-4,"rr":-6,"bp_sys":-2,"bp_dia":-1,"etco2":-4}'::jsonb
  end
from _neuro_steps s4 join _neuro_seed s on s.case_number = s4.case_number
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation leads to recurrent respiratory instability.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":4,"bp_dia":2,"etco2":4}'::jsonb
from _neuro_steps s4 where s4.step_order = 4;

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
    'bp_dia', coalesce((b.baseline_vitals->>'bp_dia')::int, 0) + coalesce((r.vitals_delta->>'bp_dia')::int, 0),
    'etco2', coalesce((b.baseline_vitals->>'etco2')::int, 0) + coalesce((r.vitals_delta->>'etco2')::int, 0)
  )
from public.cse_rules r
join public.cse_steps s on s.id = r.step_id
join public.cse_cases b on b.id = s.case_id
join _neuro_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _neuro_target);

commit;
