-- Exhale Academy CSE Branching Seed (Cases 38-40)
-- Pediatric Critical (Bronchiolitis / Cystic Fibrosis / Foreign Body Aspiration)

begin;

create temporary table _ped_lower_seed (
  case_number int4 primary key,
  disease_key text not null,
  slug text not null,
  title text not null,
  intro_text text not null,
  description text not null,
  stem text not null,
  baseline_vitals jsonb not null
) on commit drop;

insert into _ped_lower_seed (case_number, disease_key, slug, title, intro_text, description, stem, baseline_vitals) values
(38, 'bronchiolitis', 'pediatric-critical-bronchiolitis-rsv-edema-apnea-risk',
 'Pediatric Critical (Bronchiolitis RSV Edema/Apnea Risk)',
 'Infant with bronchiolitis pattern, feeding difficulty, and escalating distress with apnea risk.',
 'Pediatric bronchiolitis case focused on supportive care, suction/oxygen strategy, and avoiding low-yield routine therapies.',
 'Infant has tachypnea, retractions, and worsening lower-airway distress after URI progression.',
 '{"hr":162,"rr":48,"spo2":84,"bp_sys":92,"bp_dia":54}'::jsonb),
(39, 'cf', 'pediatric-critical-cystic-fibrosis-secretion-burden',
 'Pediatric Critical (Cystic Fibrosis Secretion Burden)',
 'Child with CF has thick secretions, infection burden, and worsening oxygenation/work of breathing.',
 'Pediatric CF case focused on airway-clearance sequencing, oxygenation, and culture-directed respiratory support.',
 'Child with chronic productive cough now has heavier secretions and increasing respiratory distress.',
 '{"hr":146,"rr":38,"spo2":85,"bp_sys":106,"bp_dia":66}'::jsonb),
(40, 'fba', 'pediatric-critical-foreign-body-aspiration-unilateral-wheeze',
 'Pediatric Critical (Foreign Body Aspiration Unilateral Wheeze)',
 'Toddler with sudden aspiration pattern and unilateral obstruction findings.',
 'Pediatric foreign-body case focused on recognition, radiographic limits, and bronchoscopy-first management.',
 'Toddler develops sudden respiratory distress after a choking episode.',
 '{"hr":158,"rr":46,"spo2":81,"bp_sys":98,"bp_dia":58}'::jsonb);

create temporary table _ped_lower_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _ped_lower_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _ped_lower_seed s
  join public.cse_cases c on c.slug = s.slug
),
updated as (
  update public.cse_cases c
  set
    source = case when s.disease_key = 'bronchiolitis' then 'pediatric-critical-lower-airway' when s.disease_key = 'cf' then 'pediatric-critical-chronic' else 'pediatric-critical-airway' end,
    disease_slug = case when s.disease_key = 'bronchiolitis' then 'bronchiolitis' when s.disease_key = 'cf' then 'cystic-fibrosis' else 'foreign-body-aspiration' end,
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
  from _ped_lower_seed s
  where c.id in (select id from existing where case_number = s.case_number)
  returning s.case_number, c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty,
    is_active, is_published, baseline_vitals, nbrc_category_code, nbrc_category_name, nbrc_subcategory
  )
  select
    case when s.disease_key = 'bronchiolitis' then 'pediatric-critical-lower-airway' when s.disease_key = 'cf' then 'pediatric-critical-chronic' else 'pediatric-critical-airway' end,
    case when s.disease_key = 'bronchiolitis' then 'bronchiolitis' when s.disease_key = 'cf' then 'cystic-fibrosis' else 'foreign-body-aspiration' end,
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
  from _ped_lower_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _ped_lower_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _ped_lower_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _ped_lower_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _ped_lower_target)
);

delete from public.cse_attempts where case_id in (select case_id from _ped_lower_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_lower_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_lower_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_lower_target));
delete from public.cse_steps where case_id in (select case_id from _ped_lower_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'bronchiolitis' then
'A 7-month-old boy is brought to the emergency department because of worsening breathing after several days of cough and nasal congestion.

While receiving room air, the following are noted:
HR 162/min
RR 48/min
BP 92/54 mm Hg
SpO2 84%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'cf' then
'A 12-year-old girl with cystic fibrosis is brought to the emergency department because of increased cough, thick secretions, and worsening shortness of breath.

While receiving room air, the following are noted:
HR 146/min
RR 38/min
BP 106/66 mm Hg
SpO2 85%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      else
'A 2-year-old girl is brought to the emergency department because of sudden coughing and respiratory distress while eating peanuts.

While receiving room air, the following are noted:
HR 158/min
RR 46/min
BP 98/58 mm Hg
SpO2 81%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'bronchiolitis' then
      '{"show_appearance_after_submit":true,"appearance_text":"the infant has nasal flaring and intercostal retractions","extra_reveals":[{"text":"Breath sounds reveal diffuse crackles and wheezes.","keys_any":["A"]},{"text":"Feeding has decreased, and brief apnea episodes are reported.","keys_any":["B"]},{"text":"Hydration is poor with fewer wet diapers.","keys_any":["C"]},{"text":"ABG: pH 7.33, PaCO2 48 torr, PaO2 54 torr, HCO3 25 mEq/L.","keys_any":["D"]}]}'::jsonb
      when 'cf' then
      '{"show_appearance_after_submit":true,"appearance_text":"the child has a frequent wet cough and looks fatigued","extra_reveals":[{"text":"Breath sounds reveal coarse crackles and rhonchi with prolonged exhalation.","keys_any":["A"]},{"text":"Thick purulent sputum is present, and clubbing is noted.","keys_any":["B"]},{"text":"Chest radiograph shows hyperinflation with patchy infiltrates.","keys_any":["C"]},{"text":"Sputum culture is indicated to guide antibiotic therapy.","keys_any":["D"]}]}'::jsonb
      else
      '{"show_appearance_after_submit":true,"appearance_text":"the toddler is agitated and clutching at the chest","extra_reveals":[{"text":"Breath sounds are markedly reduced on the right.","keys_any":["A"]},{"text":"Wheezing is unilateral rather than diffuse.","keys_any":["B"]},{"text":"The choking episode was witnessed immediately before symptoms began.","keys_any":["C"]},{"text":"Chest radiograph may be normal if the object is radiolucent.","keys_any":["D"]}]}'::jsonb
    end
  from _ped_lower_target t join _ped_lower_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    case s.disease_key
      when 'bronchiolitis' then 'Findings suggest bronchiolitis with significant distress. Which of the following should be recommended FIRST?'
      when 'cf' then 'Findings suggest cystic fibrosis exacerbation with secretion burden. Which of the following should be recommended FIRST?'
      else 'Findings suggest foreign-body aspiration. Which of the following should be recommended FIRST?'
    end,
    null,
    'STOP',
    '{}'::jsonb
  from _ped_lower_target t join _ped_lower_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 3, 3, 'IG',
    case s.disease_key
      when 'bronchiolitis' then
'Thirty minutes after initial treatment, the infant remains under close observation.

Current findings are:
HR 154/min
RR 44/min
BP 94/56 mm Hg
SpO2 90%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'cf' then
'Thirty minutes after initial treatment, the child remains on oxygen and airway-clearance therapy.

Current findings are:
HR 138/min
RR 34/min
BP 104/64 mm Hg
SpO2 90%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      else
'After initial stabilization, the child remains on high-concentration oxygen.

Current findings are:
HR 150/min
RR 40/min
BP 96/58 mm Hg
SpO2 88%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'bronchiolitis' then
      '{"show_appearance_after_submit":true,"appearance_text":"the infant is calmer but still tachypneic","extra_reveals":[{"text":"Retractions and breath sounds should be trended closely.","keys_any":["A"]},{"text":"Hydration status and apnea frequency still require close monitoring.","keys_any":["B"]},{"text":"Repeat oxygenation assessment determines whether higher-level support is needed.","keys_any":["C"]},{"text":"Routine bronchodilator or steroid escalation is still not indicated by default.","keys_any":["D"]}]}'::jsonb
      when 'cf' then
      '{"show_appearance_after_submit":true,"appearance_text":"secretions are easier to mobilize but not cleared completely","extra_reveals":[{"text":"Breath sounds and oxygenation improve but remain abnormal.","keys_any":["A"]},{"text":"Sputum culture and infection response should be followed.","keys_any":["B"]},{"text":"Airway-clearance effectiveness and secretion burden still require reassessment.","keys_any":["C"]},{"text":"ABG: pH 7.35, PaCO2 46 torr, PaO2 63 torr, HCO3 25 mEq/L.","keys_any":["D"]}]}'::jsonb
      else
      '{"show_appearance_after_submit":true,"appearance_text":"respiratory distress improves only slightly","extra_reveals":[{"text":"Unilateral breath-sound reduction persists.","keys_any":["A"]},{"text":"Radiology still cannot safely exclude a radiolucent airway foreign body.","keys_any":["B"]},{"text":"Definitive bronchoscopy remains indicated.","keys_any":["C"]},{"text":"ABG: pH 7.34, PaCO2 47 torr, PaO2 58 torr, HCO3 25 mEq/L.","keys_any":["D"]}]}'::jsonb
    end
  from _ped_lower_target t join _ped_lower_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM',
    'Which of the following should be recommended now?',
    null,
    'STOP',
    '{}'::jsonb
  from _ped_lower_target t
  returning case_id, step_order, id
)
insert into _ped_lower_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id from inserted_steps i join _ped_lower_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case when s.disease_key = 'bronchiolitis' then 'Auscultate breath sounds and assess retractions'
       when s.disease_key = 'cf' then 'Auscultate breath sounds and assess work of breathing'
       else 'Auscultate for unilateral breath-sound reduction' end,
  2, 'This is indicated in the initial bedside assessment.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'B',
  case when s.disease_key = 'bronchiolitis' then 'Assess feeding tolerance and apnea history'
       when s.disease_key = 'cf' then 'Assess sputum burden and chronic disease clues'
       else 'Assess whether wheezing is unilateral rather than diffuse' end,
  2, 'This helps identify the correct disease pattern.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'C',
  case when s.disease_key = 'bronchiolitis' then 'Assess hydration status'
       when s.disease_key = 'cf' then 'Review chest radiograph findings'
       else 'Clarify the choking-event history' end,
  2, 'This is a high-yield bedside clue.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'D',
  case when s.disease_key = 'bronchiolitis' then 'Obtain an ABG if distress is significant'
       when s.disease_key = 'cf' then 'Order sputum culture and objective gas-exchange assessment'
       else 'Use imaging only as supportive data, not to rule the diagnosis out' end,
  2, 'This is appropriate supporting evaluation.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 1
union all select st.step_id, 'E', 'Delay stabilization while waiting for full diagnostics', -3, 'This is unsafe.' from _ped_lower_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Assume all wheezing children should receive the same treatment', -3, 'This misses disease-specific management.' from _ped_lower_steps st where st.step_order = 1

union all
select st.step_id, 'A',
  case when s.disease_key = 'bronchiolitis' then 'Provide supportive care with oxygen and nasal suctioning, and escalate support only if distress or apnea worsens'
       when s.disease_key = 'cf' then 'Provide oxygen, initiate airway-clearance therapy, and begin culture-directed antimicrobial support'
       else 'Arrange urgent rigid bronchoscopy and maintain airway support while awaiting removal' end,
  3, 'This is the best first treatment strategy.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen only and defer definitive management', -3, 'This is incomplete and unsafe.' from _ped_lower_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Apply routine bronchodilator and steroid escalation by default', case when st.case_number = 38 then -2 else -3 end, 'This is not the best disease-specific plan here.' from _ped_lower_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Transfer to a lower-acuity setting after brief improvement', -3, 'This is unsafe.' from _ped_lower_steps st where st.step_order = 2

union all
select st.step_id, 'A',
  case when s.disease_key = 'bronchiolitis' then 'Reassess retractions, breath sounds, and oxygenation trend'
       when s.disease_key = 'cf' then 'Reassess breath sounds, secretion clearance, and oxygenation trend'
       else 'Reassess unilateral breath sounds and overall work of breathing' end,
  2, 'This is indicated now.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'B',
  case when s.disease_key = 'bronchiolitis' then 'Track hydration and apnea frequency'
       when s.disease_key = 'cf' then 'Track culture/infection response'
       else 'Determine whether imaging limitations still leave bronchoscopy necessary' end,
  2, 'This is a high-yield reassessment.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'C',
  case when s.disease_key = 'bronchiolitis' then 'Determine whether escalation to higher-level respiratory support is needed'
       when s.disease_key = 'cf' then 'Determine whether airway-clearance and oxygen support remain adequate'
       else 'Confirm that definitive bronchoscopy is still the next step' end,
  2, 'This addresses the core next decision.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'D',
  case when s.disease_key = 'bronchiolitis' then 'Avoid routine bronchodilator/steroid escalation if the pattern still fits bronchiolitis'
       when s.disease_key = 'cf' then 'Repeat ABG if gas-exchange concern persists'
       else 'Repeat ABG if significant respiratory distress persists' end,
  2, 'This is appropriate contextual reassessment.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'E', 'Stop close monitoring after one modest improvement', -3, 'This is unsafe.' from _ped_lower_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Delay reassessment for several hours', -3, 'This is unsafe.' from _ped_lower_steps st where st.step_order = 3

union all
select st.step_id, 'A',
  case when s.disease_key = 'bronchiolitis' then 'Continue monitored pediatric care with supportive therapy and escalation triggers for apnea or fatigue'
       when s.disease_key = 'cf' then 'Continue high-acuity pediatric care with airway-clearance therapy, oxygen, and infection follow-up'
       else 'Proceed with definitive bronchoscopy and monitored pediatric care after foreign-body removal' end,
  3, 'This is the safest ongoing plan.'
from _ped_lower_steps st join _ped_lower_seed s on s.case_number = st.case_number where st.step_order = 4
union all select st.step_id, 'B', 'Transfer to an unmonitored bed', -3, 'This is unsafe.' from _ped_lower_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discharge after temporary improvement', -3, 'This is unsafe.' from _ped_lower_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Observe without explicit escalation triggers', -2, 'This is an inadequate safety plan.' from _ped_lower_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.step_id,
  'Initial pediatric assessment captures the disease pattern and severity correctly.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0}'::jsonb
from _ped_lower_steps s1 join _ped_lower_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2 where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment is incomplete, and respiratory distress worsens.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _ped_lower_steps s1 join _ped_lower_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2 where s1.step_order = 1
union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  'Initial management is appropriate, but close reassessment is still required.',
  case when s.case_number = 40 then '{"spo2":4,"hr":-4,"rr":-4,"bp_sys":0,"bp_dia":0}'::jsonb else '{"spo2":5,"hr":-6,"rr":-4,"bp_sys":0,"bp_dia":0}'::jsonb end
from _ped_lower_steps s2 join _ped_lower_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3 join _ped_lower_seed s on s.case_number = s2.case_number where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Treatment is delayed or incomplete, and instability persists.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _ped_lower_steps s2 join _ped_lower_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3 where s2.step_order = 2
union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  'Reassessment is complete and supports the next management decision.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0}'::jsonb
from _ped_lower_steps s3 join _ped_lower_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4 where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Monitoring gaps leave high risk for recurrent deterioration.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _ped_lower_steps s3 join _ped_lower_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4 where s3.step_order = 3
union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the child remains in appropriate monitored pediatric care with a disease-specific plan.',
  '{"spo2":2,"hr":-2,"rr":-2,"bp_sys":0,"bp_dia":0}'::jsonb
from _ped_lower_steps s4 where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: unsafe de-escalation leads to recurrent respiratory instability.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-2,"bp_dia":-1}'::jsonb
from _ped_lower_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override)
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
join _ped_lower_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _ped_lower_target);

commit;
