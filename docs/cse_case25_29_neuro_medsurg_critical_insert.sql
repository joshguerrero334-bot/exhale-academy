-- Exhale Academy CSE Branching Seed (Cases 25-29)
-- Adult neuro + adult med/surg critical batch rewritten with reveal-based assessment.

begin;

create temporary table _nmx_seed (
  case_number int4 primary key,
  disease_key text not null,
  profile text not null,
  source text not null,
  disease_slug text not null,
  slug text not null,
  title text not null,
  intro_text text not null,
  description text not null,
  stem text not null,
  baseline_vitals jsonb not null,
  nbrc_category_code text not null,
  nbrc_category_name text not null,
  nbrc_subcategory text
) on commit drop;

insert into _nmx_seed (
  case_number, disease_key, profile, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(25, 'mg', 'neuro', 'adult-neuromuscular-critical', 'myasthenia-gravis', 'neuromuscular-critical-myasthenia-gravis-crisis',
 'Neuromuscular Critical (Myasthenia Gravis Crisis)',
 'Bulbar weakness and worsening ventilatory muscle fatigue requiring early mechanics assessment and timely escalation.',
 'Critical MG case focused on bulbar signs, ventilatory mechanics, and deciding when airway protection is no longer adequate.',
 'Patient with myasthenia gravis develops progressive weakness, dysphagia, and shallow breathing.',
 '{"hr":118,"rr":32,"spo2":84,"bp_sys":146,"bp_dia":88,"etco2":52}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(26, 'gbs', 'neuro', 'adult-neuromuscular-critical', 'guillain-barre', 'neuromuscular-critical-guillain-barre-ascending-paralysis',
 'Neuromuscular Critical (Guillain-Barre Ascending Paralysis)',
 'Ascending weakness with poor cough and autonomic instability risk requiring close respiratory mechanics trending.',
 'Critical GBS case focused on airway protection, VC/NIF trend, secretion burden, and escalation when ventilatory failure emerges.',
 'Post-viral patient develops ascending weakness with increasing dyspnea and ineffective cough.',
 '{"hr":114,"rr":30,"spo2":85,"bp_sys":142,"bp_dia":86,"etco2":50}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(27, 'overdose', 'medsurg', 'adult-med-surg-critical', 'drug-overdose', 'adult-med-surg-critical-drug-overdose-airway-protection',
 'Adult Med/Surg Critical (Drug Overdose Airway Protection)',
 'Toxic ingestion with hypoventilation and aspiration risk requiring airway-first decisions and antidote use when indicated.',
 'Critical overdose case focused on airway protection, bedside tox clues, blood-gas severity, and targeted reversal.',
 'Obtunded patient presents with shallow respirations after a likely pill ingestion.',
 '{"hr":104,"rr":10,"spo2":82,"bp_sys":96,"bp_dia":58,"etco2":60}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(28, 'md', 'neuro', 'adult-neuromuscular-critical', 'muscular-dystrophy', 'neuromuscular-critical-muscular-dystrophy-hypoventilation',
 'Neuromuscular Critical (Muscular Dystrophy Hypoventilation)',
 'Chronic neuromuscular weakness with nocturnal hypoventilation and secretion-clearance failure requiring noninvasive support decisions.',
 'Critical muscular-dystrophy case focused on chronic hypoventilation recognition, cough-assist planning, and when monitored ventilatory support is needed.',
 'Patient with muscular dystrophy has worsening morning headaches, daytime fatigue, and weak cough.',
 '{"hr":108,"rr":26,"spo2":86,"bp_sys":138,"bp_dia":82,"etco2":54}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null),
(29, 'stroke', 'neuro', 'adult-neuromuscular-critical', 'stroke', 'neuromuscular-critical-stroke-neuro-respiratory-failure',
 'Neuromuscular Critical (Stroke Neuro-Respiratory Failure)',
 'Acute neurologic deficit with declining mental status and airway-risk progression requiring rapid neuro and respiratory decisions.',
 'Critical stroke case focused on airway protection, neuro imaging, aspiration risk, and neuro-ICU disposition.',
 'Patient with acute speech change and unilateral weakness develops decreasing responsiveness and abnormal respirations.',
 '{"hr":112,"rr":28,"spo2":87,"bp_sys":168,"bp_dia":96,"etco2":49}'::jsonb,
 'D', 'Adult Neurological or Neuromuscular', null);

create temporary table _nmx_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _nmx_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _nmx_seed s
  join public.cse_cases c on c.slug = s.slug
),
updated as (
  update public.cse_cases c
  set
    source = s.source,
    disease_slug = s.disease_slug,
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
    nbrc_category_code = s.nbrc_category_code,
    nbrc_category_name = s.nbrc_category_name,
    nbrc_subcategory = s.nbrc_subcategory
  from _nmx_seed s
  where c.id in (select id from existing where case_number = s.case_number)
  returning s.case_number, c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty,
    is_active, is_published, baseline_vitals, nbrc_category_code, nbrc_category_name, nbrc_subcategory
  )
  select
    s.source, s.disease_slug, 'critical', s.case_number, s.slug, s.title, s.intro_text, s.description, s.stem, 'hard',
    true, true, s.baseline_vitals, s.nbrc_category_code, s.nbrc_category_name, s.nbrc_subcategory
  from _nmx_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _nmx_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _nmx_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _nmx_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _nmx_target)
);

delete from public.cse_attempts where case_id in (select case_id from _nmx_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _nmx_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _nmx_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _nmx_target));
delete from public.cse_steps where case_id in (select case_id from _nmx_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'mg' then 'A 34-year-old woman with myasthenia gravis comes to the emergency department because of increasing weakness and difficulty swallowing.

While breathing room air, the following are noted:
HR 118/min
RR 32/min
BP 146/88 mm Hg
SpO2 84%
EtCO2 52 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'gbs' then 'A 51-year-old man is brought to the emergency department because of progressive ascending weakness and increasing shortness of breath.

While breathing room air, the following are noted:
HR 114/min
RR 30/min
BP 142/86 mm Hg
SpO2 85%
EtCO2 50 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'overdose' then 'A 39-year-old woman is brought to the emergency department after a likely pill ingestion.

While breathing room air, the following are noted:
HR 104/min
RR 10/min
BP 96/58 mm Hg
SpO2 82%
EtCO2 60 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'md' then 'A 45-year-old man with muscular dystrophy comes to the emergency department because of worsening fatigue and weak cough.

While breathing room air, the following are noted:
HR 108/min
RR 26/min
BP 138/82 mm Hg
SpO2 86%
EtCO2 54 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      else 'A 72-year-old woman is brought to the emergency department because of sudden speech change, unilateral weakness, and decreasing responsiveness.

While receiving O2 by nasal cannula at 4 L/min, the following are noted:
HR 112/min
RR 28/min
BP 168/96 mm Hg
SpO2 87%
EtCO2 49 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'mg' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient has ptosis, weak phonation, and trouble clearing secretions",
        "extra_reveals": [
          { "text": "Single-breath count is 8, and the cough is weak.", "keys_any": ["A"] },
          { "text": "VC is 11 mL/kg and MIP is -18 cm H2O.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.31, PaCO2 58 torr, PaO2 55 torr, HCO3 28 mEq/L.", "keys_any": ["C"] },
          { "text": "The patient coughs when attempting to swallow water.", "keys_any": ["D"] },
          { "text": "CBC and chemistry panel are unremarkable.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'gbs' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is anxious, weak, and has a very weak cough",
        "extra_reveals": [
          { "text": "VC is 13 mL/kg and MIP is -20 cm H2O.", "keys_any": ["A"] },
          { "text": "Breath sounds are diminished at the bases with retained secretions.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.33, PaCO2 54 torr, PaO2 58 torr, HCO3 27 mEq/L.", "keys_any": ["C"] },
          { "text": "Heart rate varies between 96/min and 126/min during the assessment.", "keys_any": ["D"] },
          { "text": "The patient has difficulty handling oral secretions.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'overdose' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is obtunded and has shallow respirations",
        "extra_reveals": [
          { "text": "Pupils are pinpoint, and bowel sounds are decreased.", "keys_any": ["A"] },
          { "text": "ABG: pH 7.24, PaCO2 68 torr, PaO2 48 torr, HCO3 28 mEq/L.", "keys_any": ["B"] },
          { "text": "Capillary glucose is 108 mg/dL.", "keys_any": ["C"] },
          { "text": "Toxicology screen is pending, and pill bottles are found in the patient''s bag.", "keys_any": ["D"] },
          { "text": "CBC is unremarkable, and there is no obvious trauma.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'md' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is weak, has ineffective cough, and cannot lie flat",
        "extra_reveals": [
          { "text": "VC is 14 mL/kg and MIP is -24 cm H2O.", "keys_any": ["A"] },
          { "text": "ABG: pH 7.34, PaCO2 60 torr, PaO2 54 torr, HCO3 31 mEq/L.", "keys_any": ["B"] },
          { "text": "Peak cough flow is poor, and retained secretions are audible.", "keys_any": ["C"] },
          { "text": "Overnight symptoms include morning headaches and restless sleep.", "keys_any": ["D"] },
          { "text": "Chest radiograph reveals bibasilar atelectatic change.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is somnolent, dysarthric, and unable to protect the airway well",
        "extra_reveals": [
          { "text": "Gag reflex is weak, and secretions pool in the oropharynx.", "keys_any": ["A"] },
          { "text": "Head CT reveals a large acute hemispheric infarct without hemorrhage.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.35, PaCO2 48 torr, PaO2 58 torr, HCO3 25 mEq/L.", "keys_any": ["C"] },
          { "text": "NIH stroke severity is high, and the patient does not follow commands consistently.", "keys_any": ["D"] },
          { "text": "CBC and chemistry panel show no major metabolic explanation for the mental-status change.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _nmx_target t
  join _nmx_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM', 'Which of the following should be recommended FIRST?', null, 'STOP', '{}'::jsonb
  from _nmx_target t
  union all
  select t.case_id, 3, 3, 'IG',
    case s.disease_key
      when 'mg' then 'After initial treatment is started, the patient remains weak and becomes more fatigued.

While receiving O2 by nasal cannula at 3 L/min, the following are noted:
HR 116/min
RR 30/min
BP 140/84 mm Hg
SpO2 88%
EtCO2 55 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'gbs' then 'After initial treatment is started, weakness continues to progress.

While receiving O2 by nasal cannula at 3 L/min, the following are noted:
HR 118/min
RR 30/min
BP 150/90 mm Hg
SpO2 88%
EtCO2 54 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'overdose' then 'After initial treatment is started, the patient remains obtunded.

While receiving bag-mask ventilation with an FiO2 of 1.0, the following are noted:
HR 98/min
RR 12 assisted/min
BP 102/62 mm Hg
SpO2 90%
EtCO2 50 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'md' then 'After initial treatment is started, breathing improves only slightly and cough remains weak.

While receiving NPPV with an FiO2 of 0.35, the following are noted:
HR 104/min
RR 24/min
BP 134/80 mm Hg
SpO2 90%
EtCO2 50 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      else 'After initial treatment is started, mental status does not improve and airway protection remains poor.

While receiving O2 by mask at an FiO2 of 0.50, the following are noted:
HR 108/min
RR 26/min
BP 164/92 mm Hg
SpO2 90%
EtCO2 50 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'mg' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient can barely count to 5 in one breath and cannot handle secretions",
        "extra_reveals": [
          { "text": "Repeat VC is 9 mL/kg and MIP is -14 cm H2O.", "keys_any": ["A"] },
          { "text": "Repeat ABG: pH 7.29, PaCO2 62 torr, PaO2 54 torr, HCO3 29 mEq/L.", "keys_any": ["B"] },
          { "text": "Bulbar weakness is worsening, and aspiration risk is high.", "keys_any": ["C"] },
          { "text": "The patient now requires definitive airway protection.", "keys_any": ["D"] },
          { "text": "Chemistry panel remains stable.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'gbs' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is weaker and has more trouble clearing secretions",
        "extra_reveals": [
          { "text": "Repeat VC is 10 mL/kg and MIP is -16 cm H2O.", "keys_any": ["A"] },
          { "text": "Repeat ABG: pH 7.30, PaCO2 60 torr, PaO2 56 torr, HCO3 29 mEq/L.", "keys_any": ["B"] },
          { "text": "Autonomic instability persists with labile heart rate and blood pressure.", "keys_any": ["C"] },
          { "text": "Secretion clearance is failing, and airway protection is worsening.", "keys_any": ["D"] },
          { "text": "Chest radiograph shows bibasilar atelectatic change from poor inspiratory effort.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'overdose' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient briefly becomes more alert, then again drifts into shallow breathing",
        "extra_reveals": [
          { "text": "Repeat ABG: pH 7.28, PaCO2 58 torr, PaO2 62 torr, HCO3 27 mEq/L.", "keys_any": ["A"] },
          { "text": "Pupils remain small, and hypoventilation recurs.", "keys_any": ["B"] },
          { "text": "Airway protection is still inadequate.", "keys_any": ["C"] },
          { "text": "Naloxone responsiveness suggests opioid toxicity, but continuous observation is still required.", "keys_any": ["D"] },
          { "text": "Chemistry panel and CBC remain stable.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'md' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient looks more comfortable on support but still cannot clear secretions well",
        "extra_reveals": [
          { "text": "Repeat ABG: pH 7.36, PaCO2 54 torr, PaO2 64 torr, HCO3 30 mEq/L.", "keys_any": ["A"] },
          { "text": "Cough-assist sessions improve secretion clearance.", "keys_any": ["B"] },
          { "text": "VC remains low, but the work of breathing decreases on NPPV.", "keys_any": ["C"] },
          { "text": "The patient still requires monitored noninvasive support overnight.", "keys_any": ["D"] },
          { "text": "Chest radiograph is unchanged.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is more somnolent and coughs weakly when suctioned",
        "extra_reveals": [
          { "text": "Repeat ABG: pH 7.32, PaCO2 52 torr, PaO2 60 torr, HCO3 26 mEq/L.", "keys_any": ["A"] },
          { "text": "Gag and cough remain poor, and aspiration risk is high.", "keys_any": ["B"] },
          { "text": "Neurologic status remains poor, and neuro-ICU care is indicated.", "keys_any": ["C"] },
          { "text": "Endotracheal intubation should be considered because airway protection is failing.", "keys_any": ["D"] },
          { "text": "Repeat CT shows no hemorrhagic conversion.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _nmx_target t
  join _nmx_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM', 'Which of the following should be recommended now?', null, 'STOP', '{}'::jsonb
  from _nmx_target t
  returning case_id, step_order, id
)
insert into _nmx_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _nmx_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case s.disease_key
    when 'mg' then 'Assess cough strength and bulbar function'
    when 'gbs' then 'Measure VC and MIP'
    when 'overdose' then 'Assess the pupils and breathing pattern'
    when 'md' then 'Measure VC and MIP'
    else 'Assess gag reflex and airway protection'
  end,
  2,
  'This is indicated in the initial assessment.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'B',
  case s.disease_key
    when 'mg' then 'Measure VC and MIP'
    when 'gbs' then 'Auscultate breath sounds and assess secretion burden'
    when 'overdose' then 'Obtain an ABG'
    when 'md' then 'Obtain an ABG'
    else 'Review the head CT'
  end,
  2,
  'This is indicated in the initial assessment.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'C',
  case s.disease_key
    when 'mg' then 'Obtain an ABG'
    when 'gbs' then 'Obtain an ABG'
    when 'overdose' then 'Check capillary glucose'
    when 'md' then 'Assess cough effectiveness'
    else 'Obtain an ABG'
  end,
  2,
  'This is indicated in the initial assessment.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'D',
  case s.disease_key
    when 'mg' then 'Assess swallowing safety'
    when 'gbs' then 'Monitor for autonomic instability'
    when 'overdose' then 'Review toxic ingestion clues and pill bottles'
    when 'md' then 'Review overnight hypoventilation symptoms'
    else 'Assess neurologic severity and command following'
  end,
  2,
  'This adds high-yield pathology-specific information.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'E',
  case s.disease_key
    when 'mg' then 'Review the CBC and chemistry panel'
    when 'gbs' then 'Determine secretion-handling ability'
    when 'overdose' then 'Review the CBC'
    when 'md' then 'Review the chest radiograph'
    else 'Review the CBC and chemistry panel'
  end,
  1,
  'This provides supporting information.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 1
union all select st.step_id, 'F', 'Delay treatment until all nonurgent testing is complete', -3, 'This delays indicated care.' from _nmx_steps st where st.step_order = 1
union all select st.step_id, 'G', 'Transfer to a low-acuity area before the evaluation is complete', -3, 'This is unsafe.' from _nmx_steps st where st.step_order = 1

union all
select st.step_id, 'A',
  case s.disease_key
    when 'mg' then 'Prepare for endotracheal intubation and ICU care while coordinating myasthenic-crisis treatment'
    when 'gbs' then 'Admit to the ICU, provide oxygen, and prepare for endotracheal intubation because respiratory mechanics are failing'
    when 'overdose' then 'Support ventilation, give naloxone, and intubate if airway protection remains inadequate'
    when 'md' then 'Begin noninvasive ventilation, start cough-assist therapy, and admit for monitored care'
    else 'Protect the airway, provide oxygen, and admit to the neuro ICU with intubation readiness'
  end,
  3,
  'This is the best first recommendation.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen alone and defer the syndrome-specific plan', -3, 'This is inadequate.' from _nmx_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Delay escalation until the next scheduled reassessment', -3, 'This is unsafe.' from _nmx_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Sedate first and then decide how to manage ventilation', -3, 'This is the wrong sequence.' from _nmx_steps st where st.step_order = 2

union all
select st.step_id, 'A',
  case s.disease_key
    when 'mg' then 'Repeat VC and MIP'
    when 'gbs' then 'Repeat VC and MIP'
    when 'overdose' then 'Repeat the ABG'
    when 'md' then 'Repeat the ABG'
    else 'Repeat the ABG'
  end,
  2,
  'This is indicated in reassessment.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'B',
  case s.disease_key
    when 'mg' then 'Repeat the ABG'
    when 'gbs' then 'Repeat the ABG'
    when 'overdose' then 'Reassess the pupils and ventilatory pattern'
    when 'md' then 'Evaluate secretion-clearance response'
    else 'Reassess gag and cough reflexes'
  end,
  2,
  'This is indicated in reassessment.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'C',
  case s.disease_key
    when 'mg' then 'Reassess secretion handling and aspiration risk'
    when 'gbs' then 'Monitor autonomic stability'
    when 'overdose' then 'Assess ongoing airway protection'
    when 'md' then 'Repeat VC/MIP or work of breathing assessment'
    else 'Review neurologic status and ICU-level needs'
  end,
  2,
  'This is the key progression check.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'D',
  case s.disease_key
    when 'mg' then 'Determine whether definitive airway protection is now required'
    when 'gbs' then 'Determine whether airway protection and invasive ventilation are now required'
    when 'overdose' then 'Determine whether naloxone response is durable or temporary'
    when 'md' then 'Determine whether monitored NPPV remains adequate overnight'
    else 'Determine whether endotracheal intubation is now required'
  end,
  2,
  'This guides the next recommendation.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'E',
  case s.disease_key
    when 'mg' then 'Review the chemistry panel'
    when 'gbs' then 'Review the chest radiograph'
    when 'overdose' then 'Review the chemistry panel and CBC'
    when 'md' then 'Review the chest radiograph'
    else 'Review the repeat head CT'
  end,
  1,
  'This adds supporting information.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'F', 'Stop close monitoring after the first response to treatment', -3, 'This is unsafe.' from _nmx_steps st where st.step_order = 3
union all select st.step_id, 'G', 'Plan transfer or discharge before reassessment is complete', -3, 'This is premature.' from _nmx_steps st where st.step_order = 3

union all
select st.step_id, 'A',
  case s.disease_key
    when 'mg' then 'Proceed with endotracheal intubation and ICU management for myasthenic crisis'
    when 'gbs' then 'Proceed with endotracheal intubation and ICU management for progressive neuromuscular ventilatory failure'
    when 'overdose' then 'Continue ICU-level care with airway protection and repeat naloxone or infusion as indicated'
    when 'md' then 'Continue monitored noninvasive ventilation and airway-clearance support in high-acuity care'
    else 'Proceed with endotracheal intubation and neuro-ICU care'
  end,
  3,
  'This is the best next recommendation.'
from _nmx_steps st join _nmx_seed s on s.case_number = st.case_number where st.step_order = 4
union all select st.step_id, 'B', 'Keep the current approach unchanged and reassess much later', -3, 'This delays needed escalation or monitoring.' from _nmx_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discontinue support after brief improvement', -3, 'This is unsafe.' from _nmx_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Transfer or discharge without a clear high-acuity plan', -3, 'This is not appropriate.' from _nmx_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.step_id,
  case s.disease_key
    when 'mg' then 'Bulbar weakness and declining respiratory mechanics are identified early.'
    when 'gbs' then 'Progressive neuromuscular weakness and ventilatory risk are identified early.'
    when 'overdose' then 'Hypoventilation and airway-protection failure are recognized promptly.'
    when 'md' then 'Chronic hypoventilation and secretion-clearance failure are identified.'
    else 'Neuro-respiratory failure and poor airway protection are recognized early.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _nmx_steps s1 join _nmx_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
join _nmx_seed s on s.case_number = s1.case_number
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment is incomplete, and respiratory risk remains under-recognized.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-4,"bp_dia":-3,"etco2":3}'::jsonb
from _nmx_steps s1 join _nmx_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  case s.disease_key
    when 'mg' then 'Initial management supports oxygenation, but bulbar weakness continues to worsen.'
    when 'gbs' then 'Initial management supports oxygenation, but weakness continues to progress.'
    when 'overdose' then 'Ventilation improves briefly, but the patient remains high risk for recurrent hypoventilation.'
    when 'md' then 'Noninvasive support improves gas exchange slightly, but secretion burden remains important.'
    else 'Initial management stabilizes oxygenation only temporarily while airway risk persists.'
  end,
  case s.disease_key
    when 'mg' then '{"spo2":4,"hr":-2,"rr":-2,"bp_sys":-2,"bp_dia":-2,"etco2":-1}'::jsonb
    when 'gbs' then '{"spo2":3,"hr":0,"rr":-1,"bp_sys":4,"bp_dia":4,"etco2":0}'::jsonb
    when 'overdose' then '{"spo2":8,"hr":-6,"rr":2,"bp_sys":6,"bp_dia":4,"etco2":-10}'::jsonb
    when 'md' then '{"spo2":4,"hr":-4,"rr":-2,"bp_sys":-4,"bp_dia":-2,"etco2":-4}'::jsonb
    else '{"spo2":3,"hr":-2,"rr":-2,"bp_sys":-4,"bp_dia":-4,"etco2":1}'::jsonb
  end
from _nmx_steps s2 join _nmx_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
join _nmx_seed s on s.case_number = s2.case_number
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Initial management is inadequate, and instability persists.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":-4,"bp_dia":-3,"etco2":4}'::jsonb
from _nmx_steps s2 join _nmx_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '6'::jsonb, s4.step_id,
  case s.disease_key
    when 'mg' then 'Reassessment confirms myasthenic crisis with failing airway protection.'
    when 'gbs' then 'Reassessment confirms progressive neuromuscular ventilatory failure.'
    when 'overdose' then 'Reassessment confirms persistent airway risk despite partial reversal.'
    when 'md' then 'Reassessment confirms that monitored noninvasive support is helping but must continue.'
    else 'Reassessment confirms persistent stroke-related airway failure.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _nmx_steps s3 join _nmx_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
join _nmx_seed s on s.case_number = s3.case_number
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Reassessment is incomplete, and the patient remains at high risk for deterioration.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-4,"bp_dia":-3,"etco2":3}'::jsonb
from _nmx_steps s3 join _nmx_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  case s.disease_key
    when 'mg' then 'Final outcome: the patient remains in the ICU with invasive support and myasthenic-crisis treatment.'
    when 'gbs' then 'Final outcome: the patient remains in the ICU with invasive support and close autonomic monitoring.'
    when 'overdose' then 'Final outcome: ICU-level airway protection continues while toxicologic treatment is completed.'
    when 'md' then 'Final outcome: high-acuity noninvasive support and secretion-clearance therapy continue.'
    else 'Final outcome: the patient remains in the neuro ICU with airway protection and stroke monitoring.'
  end,
  case s.disease_key
    when 'mg' then '{"spo2":2,"hr":-2,"rr":-2,"bp_sys":0,"bp_dia":0,"etco2":-2}'::jsonb
    when 'gbs' then '{"spo2":2,"hr":-2,"rr":-2,"bp_sys":2,"bp_dia":2,"etco2":-2}'::jsonb
    when 'overdose' then '{"spo2":2,"hr":-2,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":-2}'::jsonb
    when 'md' then '{"spo2":2,"hr":-2,"rr":-1,"bp_sys":0,"bp_dia":0,"etco2":-2}'::jsonb
    else '{"spo2":2,"hr":-2,"rr":-2,"bp_sys":0,"bp_dia":0,"etco2":-1}'::jsonb
  end
from _nmx_steps s4 join _nmx_seed s on s.case_number = s4.case_number where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation or unsafe de-escalation leads to recurrent critical instability.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-6,"bp_dia":-4,"etco2":4}'::jsonb
from _nmx_steps s4 where s4.step_order = 4;

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
join _nmx_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _nmx_target);

commit;
