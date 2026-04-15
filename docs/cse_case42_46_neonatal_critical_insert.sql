-- Exhale Academy CSE Branching Seed (Cases 42-46)
-- Neonatal Critical (MAS / AOP / IRDS / CHD / BPD)

begin;

create temporary table _neo2_seed (
  case_number int4 primary key,
  disease_key text not null,
  slug text not null,
  title text not null,
  intro_text text not null,
  description text not null,
  stem text not null,
  baseline_vitals jsonb not null
) on commit drop;

insert into _neo2_seed (case_number, disease_key, slug, title, intro_text, description, stem, baseline_vitals) values
(42, 'mas', 'neonatal-critical-meconium-aspiration-vigor-intubation-threshold',
 'Neonatal Critical (Meconium Aspiration Vigor/Intubation Threshold)',
 'Meconium-stained term infant with respiratory distress requiring the correct airway decision without delaying ventilation.',
 'Neonatal meconium aspiration case focused on vigor assessment, early support, and escalation when oxygenation fails.',
 'Newborn delivered through meconium-stained fluid has respiratory distress and uncertain transition stability.',
 '{"hr":108,"rr":44,"spo2":82,"bp_sys":64,"bp_dia":40,"etco2":47}'::jsonb),
(43, 'aop', 'neonatal-critical-apnea-of-prematurity-bradycardia-episodes',
 'Neonatal Critical (Apnea of Prematurity Bradycardia Episodes)',
 'Very preterm infant with recurrent apnea, bradycardia, and desaturation episodes requiring monitoring and escalation decisions.',
 'Neonatal apnea case focused on event characterization, caffeine/noninvasive support, and escalation thresholds.',
 'Premature infant in the NICU has recurrent apnea spells with bradycardia and hypoxemia.',
 '{"hr":96,"rr":22,"spo2":80,"bp_sys":58,"bp_dia":36,"etco2":52}'::jsonb),
(44, 'irds', 'neonatal-critical-irds-surfactant-deficiency-ground-glass',
 'Neonatal Critical (IRDS Surfactant Deficiency Ground Glass)',
 'Premature infant with surfactant-deficiency respiratory failure requiring CPAP, reassessment, and possible surfactant/intubation escalation.',
 'Neonatal IRDS case focused on respiratory-support sequence and objective escalation triggers.',
 'Very preterm infant has grunting, retractions, and worsening oxygenation shortly after birth.',
 '{"hr":154,"rr":58,"spo2":78,"bp_sys":60,"bp_dia":38,"etco2":55}'::jsonb),
(45, 'chd', 'neonatal-critical-congenital-heart-defect-cyanotic-shunt',
 'Neonatal Critical (Congenital Heart Defect Cyanotic Shunt)',
 'Neonate with persistent cyanosis and poor oxygen response requiring structural-cardiac recognition and monitored stabilization.',
 'Neonatal congenital-heart case focused on distinguishing cyanotic heart disease from primary lung failure.',
 'Neonate has persistent cyanosis despite supplemental oxygen and shows concern for ductal-dependent cardiac disease.',
 '{"hr":166,"rr":52,"spo2":76,"bp_sys":62,"bp_dia":40,"etco2":42}'::jsonb),
(46, 'bpd', 'neonatal-critical-bpd-chronic-oxygen-dependence',
 'Neonatal Critical (BPD Chronic Oxygen Dependence)',
 'Former preterm infant with chronic lung disease has worsening work of breathing and oxygen need requiring careful support adjustment.',
 'Neonatal BPD case focused on low-effective oxygen strategy, secretion assessment, and escalation without overaggressive support.',
 'Former premature infant with chronic oxygen dependence has increased retractions and declining oxygenation.',
 '{"hr":162,"rr":60,"spo2":81,"bp_sys":66,"bp_dia":42,"etco2":53}'::jsonb);

create temporary table _neo2_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _neo2_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _neo2_seed s
  join public.cse_cases c on c.slug = s.slug
),
updated as (
  update public.cse_cases c
  set
    source = case
      when s.disease_key = 'mas' then 'neonatal-critical-aspiration'
      when s.disease_key = 'aop' then 'neonatal-critical-prematurity'
      when s.disease_key = 'irds' then 'neonatal-critical-prematurity'
      when s.disease_key = 'chd' then 'neonatal-critical-cardiac'
      else 'neonatal-critical-chronic-lung'
    end,
    disease_slug = case
      when s.disease_key = 'mas' then 'meconium-aspiration'
      when s.disease_key = 'aop' then 'apnea-of-prematurity'
      when s.disease_key = 'irds' then 'infant-respiratory-distress-syndrome'
      when s.disease_key = 'chd' then 'congenital-heart-defect'
      else 'bronchopulmonary-dysplasia'
    end,
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
    nbrc_category_code = 'G',
    nbrc_category_name = 'Neonatal',
    nbrc_subcategory = case
      when s.disease_key = 'chd' then 'Cardiopulmonary'
      when s.disease_key = 'bpd' then 'Chronic lung disease'
      else 'Respiratory distress syndrome'
    end
  from _neo2_seed s
  where c.id in (select id from existing where case_number = s.case_number)
  returning s.case_number, c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty,
    is_active, is_published, baseline_vitals, nbrc_category_code, nbrc_category_name, nbrc_subcategory
  )
  select
    case
      when s.disease_key = 'mas' then 'neonatal-critical-aspiration'
      when s.disease_key = 'aop' then 'neonatal-critical-prematurity'
      when s.disease_key = 'irds' then 'neonatal-critical-prematurity'
      when s.disease_key = 'chd' then 'neonatal-critical-cardiac'
      else 'neonatal-critical-chronic-lung'
    end,
    case
      when s.disease_key = 'mas' then 'meconium-aspiration'
      when s.disease_key = 'aop' then 'apnea-of-prematurity'
      when s.disease_key = 'irds' then 'infant-respiratory-distress-syndrome'
      when s.disease_key = 'chd' then 'congenital-heart-defect'
      else 'bronchopulmonary-dysplasia'
    end,
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
    'G',
    'Neonatal',
    case
      when s.disease_key = 'chd' then 'Cardiopulmonary'
      when s.disease_key = 'bpd' then 'Chronic lung disease'
      else 'Respiratory distress syndrome'
    end
  from _neo2_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _neo2_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _neo2_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _neo2_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _neo2_target)
);

delete from public.cse_attempts where case_id in (select case_id from _neo2_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _neo2_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _neo2_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _neo2_target));
delete from public.cse_steps where case_id in (select case_id from _neo2_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'mas' then
'A term infant is brought to the warmer after delivery through thick meconium-stained fluid.

The following are noted:
HR 108/min
RR 44/min
SpO2 82%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'aop' then
'A 29-week premature infant in the NICU has recurrent apnea alarms.

The following are noted:
HR 96/min
RR 22/min between episodes
SpO2 80%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'irds' then
'A 30-week premature infant develops worsening respiratory distress shortly after birth.

The following are noted:
HR 154/min
RR 58/min
SpO2 78%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'chd' then
'A 2-day-old neonate remains cyanotic despite supplemental oxygen.

The following are noted:
HR 166/min
RR 52/min
SpO2 76%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      else
'A former 26-week premature infant with chronic oxygen dependence has worsening breathing difficulty.

The following are noted:
HR 162/min
RR 60/min
SpO2 81%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'mas' then
      '{"show_appearance_after_submit":true,"appearance_text":"the infant has moderate retractions and coarse respirations","extra_reveals":[{"text":"The infant is not vigorous and has ineffective respirations.","keys_any":["A"]},{"text":"Meconium staining is present, but ventilation should not be delayed automatically.","keys_any":["B"]},{"text":"Breath sounds are coarse bilaterally with poor aeration.","keys_any":["C"]},{"text":"ABG: pH 7.28, PaCO2 50 torr, PaO2 48 torr, HCO3 23 mEq/L.","keys_any":["D"]}]}'::jsonb
      when 'aop' then
      '{"show_appearance_after_submit":true,"appearance_text":"the infant has another brief pause in breathing during observation","extra_reveals":[{"text":"Apnea episodes are accompanied by bradycardia and desaturation.","keys_any":["A"]},{"text":"The infant is very premature and not maintaining stable spontaneous drive.","keys_any":["B"]},{"text":"Airway patency and gentle stimulation response should be assessed.","keys_any":["C"]},{"text":"ABG: pH 7.31, PaCO2 52 torr, PaO2 46 torr, HCO3 26 mEq/L.","keys_any":["D"]}]}'::jsonb
      when 'irds' then
      '{"show_appearance_after_submit":true,"appearance_text":"the infant is grunting with nasal flaring and retractions","extra_reveals":[{"text":"Chest radiograph shows diffuse ground-glass opacity with air bronchograms.","keys_any":["A"]},{"text":"Prematurity and surfactant-deficiency pattern strongly support IRDS.","keys_any":["B"]},{"text":"Breath sounds are diminished bilaterally with poor aeration.","keys_any":["C"]},{"text":"ABG: pH 7.24, PaCO2 58 torr, PaO2 44 torr, HCO3 24 mEq/L.","keys_any":["D"]}]}'::jsonb
      when 'chd' then
      '{"show_appearance_after_submit":true,"appearance_text":"cyanosis persists despite oxygen administration","extra_reveals":[{"text":"A murmur is present, and perfusion is borderline.","keys_any":["A"]},{"text":"Preductal and postductal oxygenation should be compared.","keys_any":["B"]},{"text":"Poor oxygen response raises concern for a cyanotic structural lesion rather than primary lung disease.","keys_any":["C"]},{"text":"Echocardiography is needed urgently.","keys_any":["D"]}]}'::jsonb
      else
      '{"show_appearance_after_submit":true,"appearance_text":"the infant is tachypneic with chronic retractions","extra_reveals":[{"text":"Oxygen requirement has increased above the prior baseline.","keys_any":["A"]},{"text":"Breath sounds reveal crackles and wheezing with prolonged exhalation.","keys_any":["B"]},{"text":"A chronic lung disease pattern is present rather than an acute delivery-room problem.","keys_any":["C"]},{"text":"ABG: pH 7.32, PaCO2 56 torr, PaO2 50 torr, HCO3 28 mEq/L.","keys_any":["D"]}]}'::jsonb
    end
  from _neo2_target t join _neo2_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    case s.disease_key
      when 'mas' then 'Findings suggest meconium aspiration with respiratory distress. Which of the following should be recommended FIRST?'
      when 'aop' then 'Findings suggest apnea of prematurity with recurrent bradycardia/desaturation. Which of the following should be recommended FIRST?'
      when 'irds' then 'Findings suggest infant respiratory distress syndrome. Which of the following should be recommended FIRST?'
      when 'chd' then 'Findings suggest cyanotic congenital heart disease. Which of the following should be recommended FIRST?'
      else 'Findings suggest worsening bronchopulmonary dysplasia. Which of the following should be recommended FIRST?'
    end,
    null,
    'STOP',
    '{}'::jsonb
  from _neo2_target t join _neo2_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 3, 3, 'IG',
    case s.disease_key
      when 'mas' then
'Fifteen minutes after initial support, the infant remains under close observation.

Current findings are:
HR 118/min
RR 48/min
SpO2 88%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'aop' then
'After initial treatment and close monitoring, the infant still has intermittent events.

Current findings are:
HR 104/min between episodes
RR 26/min between episodes
SpO2 88%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'irds' then
'After initial support, the infant remains on CPAP with persistent distress.

Current findings are:
HR 148/min
RR 54/min
SpO2 86%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'chd' then
'After initial stabilization, cyanosis persists and the infant remains under close monitoring.

Current findings are:
HR 160/min
RR 50/min
SpO2 78%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      else
'After initial support adjustment, the infant remains in the NICU.

Current findings are:
HR 156/min
RR 56/min
SpO2 87%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'mas' then
      '{"show_appearance_after_submit":true,"appearance_text":"oxygenation improves slightly but work of breathing remains high","extra_reveals":[{"text":"Repeat oxygenation and air movement should be trended closely.","keys_any":["A"]},{"text":"ABG may help determine whether ventilation is failing.","keys_any":["B"]},{"text":"Need for intubation or advanced support should be reassessed if distress persists.","keys_any":["C"]},{"text":"Chest radiograph may show patchy infiltrates and hyperinflation.","keys_any":["D"]}]}'::jsonb
      when 'aop' then
      '{"show_appearance_after_submit":true,"appearance_text":"brief apnea continues despite initial measures","extra_reveals":[{"text":"Event frequency and severity still determine whether support is adequate.","keys_any":["A"]},{"text":"Heart-rate and oxygenation trends must continue to be tracked.","keys_any":["B"]},{"text":"Response to caffeine and need for noninvasive support should be reassessed.","keys_any":["C"]},{"text":"ABG: pH 7.33, PaCO2 49 torr, PaO2 52 torr, HCO3 25 mEq/L.","keys_any":["D"]}]}'::jsonb
      when 'irds' then
      '{"show_appearance_after_submit":true,"appearance_text":"retractions persist and oxygen need remains high","extra_reveals":[{"text":"Repeat gas exchange is needed to judge CPAP failure.","keys_any":["A"]},{"text":"Chest movement and distress level should be trended closely.","keys_any":["B"]},{"text":"Surfactant or intubation may be required if support remains inadequate.","keys_any":["C"]},{"text":"ABG: pH 7.22, PaCO2 60 torr, PaO2 48 torr, HCO3 24 mEq/L.","keys_any":["D"]}]}'::jsonb
      when 'chd' then
      '{"show_appearance_after_submit":true,"appearance_text":"the infant remains cyanotic without major change in work of breathing","extra_reveals":[{"text":"Persistent hypoxemia despite oxygen continues to support a cardiac shunt pattern.","keys_any":["A"]},{"text":"Preductal and postductal data remain important.","keys_any":["B"]},{"text":"Definitive echocardiographic and cardiology-directed planning is still required.","keys_any":["C"]},{"text":"ABG may show hypoxemia without a primary ventilatory pattern severe enough to explain the cyanosis.","keys_any":["D"]}]}'::jsonb
      else
      '{"show_appearance_after_submit":true,"appearance_text":"tachypnea remains but the infant looks less distressed than on arrival","extra_reveals":[{"text":"Oxygen requirement and work of breathing still need trending against baseline.","keys_any":["A"]},{"text":"Secretion burden and ventilation adequacy still require reassessment.","keys_any":["B"]},{"text":"Overaggressive oxygen or support should be avoided if a lower effective strategy works.","keys_any":["C"]},{"text":"ABG: pH 7.34, PaCO2 54 torr, PaO2 56 torr, HCO3 29 mEq/L.","keys_any":["D"]}]}'::jsonb
    end
  from _neo2_target t join _neo2_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM',
    'Which of the following should be recommended now?',
    null,
    'STOP',
    '{}'::jsonb
  from _neo2_target t
  returning case_id, step_order, id
)
insert into _neo2_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id from inserted_steps i join _neo2_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case when s.disease_key = 'mas' then 'Assess vigor, respiratory effort, and chest movement'
       when s.disease_key = 'aop' then 'Assess apnea event frequency and whether bradycardia/desaturation accompany episodes'
       when s.disease_key = 'irds' then 'Assess work of breathing and overall severity of distress'
       when s.disease_key = 'chd' then 'Assess perfusion, murmur, and cyanosis severity'
       else 'Assess current work of breathing and compare with prior oxygen baseline' end,
  2, 'This is indicated in the initial assessment.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'B',
  case when s.disease_key = 'mas' then 'Determine whether meconium is present but ventilation should not be delayed automatically'
       when s.disease_key = 'aop' then 'Confirm prematurity-related central apnea pattern'
       when s.disease_key = 'irds' then 'Review prematurity and surfactant-deficiency context'
       when s.disease_key = 'chd' then 'Compare preductal and postductal oxygenation when available'
       else 'Assess chronic lung disease pattern rather than assuming an acute transient problem' end,
  2, 'This helps identify the correct pattern.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'C',
  case when s.disease_key = 'mas' then 'Auscultate breath sounds and aeration'
       when s.disease_key = 'aop' then 'Assess airway patency and response to gentle stimulation'
       when s.disease_key = 'irds' then 'Auscultate aeration and assess retractions/grunting'
       when s.disease_key = 'chd' then 'Determine whether oxygen response is disproportionately poor for the level of respiratory effort'
       else 'Auscultate for crackles, wheezing, and prolonged exhalation' end,
  2, 'This is a high-yield bedside check.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'D',
  case when s.disease_key = 'mas' then 'Obtain objective gas-exchange data if distress is significant'
       when s.disease_key = 'aop' then 'Obtain objective gas-exchange data if events are recurrent or severe'
       when s.disease_key = 'irds' then 'Obtain chest radiograph and blood gas data'
       when s.disease_key = 'chd' then 'Arrange urgent echocardiography and supporting data'
       else 'Obtain objective gas-exchange data if oxygen need continues to rise' end,
  2, 'This is appropriate supporting evaluation.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 1
union all select st.step_id, 'E', 'Delay stabilization until all diagnostics are complete', -3, 'This is unsafe.' from _neo2_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Assume every neonatal respiratory problem follows the same pathway', -3, 'This misses pathology-specific management.' from _neo2_steps st where st.step_order = 1

union all
select st.step_id, 'A',
  case when s.disease_key = 'mas' then 'Provide appropriate respiratory support and proceed with ventilation-focused management rather than delaying for routine suction-only decisions'
       when s.disease_key = 'aop' then 'Continue close monitoring, initiate caffeine therapy, and support ventilation/oxygenation as needed based on event burden'
       when s.disease_key = 'irds' then 'Begin or continue CPAP with oxygen support and prepare for surfactant/escalation if distress persists'
       when s.disease_key = 'chd' then 'Stabilize oxygenation and perfusion while arranging urgent cardiology-directed evaluation and ductal-dependent management planning'
       else 'Use the lowest effective oxygen/support strategy and continue NICU-level management while reassessing ventilation and secretion burden' end,
  3, 'This is the best first treatment strategy.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen only and defer definitive disease-specific management', -3, 'This is incomplete and unsafe.' from _neo2_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Delay escalation planning until prolonged deterioration occurs', -3, 'This is unsafe.' from _neo2_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Transfer to lower-acuity care after brief early improvement', -3, 'This is unsafe.' from _neo2_steps st where st.step_order = 2

union all
select st.step_id, 'A',
  case when s.disease_key = 'mas' then 'Trend oxygenation, breath sounds, and work of breathing'
       when s.disease_key = 'aop' then 'Trend apnea frequency and event severity'
       when s.disease_key = 'irds' then 'Trend gas exchange and overall work of breathing on current support'
       when s.disease_key = 'chd' then 'Trend oxygenation pattern and perfusion findings'
       else 'Trend oxygen requirement and work of breathing against chronic baseline' end,
  2, 'This is indicated now.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'B',
  case when s.disease_key = 'mas' then 'Use ABG and clinical trend to decide whether ventilation is failing'
       when s.disease_key = 'aop' then 'Trend heart-rate and oxygenation response during episodes'
       when s.disease_key = 'irds' then 'Reassess whether CPAP remains adequate or failure is developing'
       when s.disease_key = 'chd' then 'Continue comparing data that support a structural-cardiac pattern'
       else 'Reassess secretion burden and ventilation adequacy' end,
  2, 'This is a high-yield reassessment.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'C',
  case when s.disease_key = 'mas' then 'Determine whether intubation or advanced support is now required'
       when s.disease_key = 'aop' then 'Determine whether noninvasive escalation is needed if events continue'
       when s.disease_key = 'irds' then 'Determine whether surfactant or intubation is now required'
       when s.disease_key = 'chd' then 'Determine whether cardiology-directed ICU care remains necessary'
       else 'Determine whether current support remains appropriate without over-escalation' end,
  2, 'This addresses the next decision.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'D',
  case when s.disease_key = 'mas' then 'Review radiographic and gas-exchange data if instability persists'
       when s.disease_key = 'aop' then 'Repeat blood gas if instability persists despite treatment'
       when s.disease_key = 'irds' then 'Review repeat blood gas if oxygen need remains high'
       when s.disease_key = 'chd' then 'Use blood-gas and echo-directed data to support the ongoing plan'
       else 'Repeat blood gas if oxygenation or ventilation concern persists' end,
  2, 'This is an appropriate contextual reassessment.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'E', 'Stop close monitoring after one modest improvement', -3, 'This is unsafe.' from _neo2_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Delay reassessment for several hours', -3, 'This is unsafe.' from _neo2_steps st where st.step_order = 3

union all
select st.step_id, 'A',
  case when s.disease_key = 'mas' then 'Continue NICU-level care with explicit respiratory escalation triggers'
       when s.disease_key = 'aop' then 'Continue NICU-level monitoring with apnea/bradycardia trend-based escalation triggers'
       when s.disease_key = 'irds' then 'Continue NICU-level respiratory care with surfactant/intubation escalation triggers'
       when s.disease_key = 'chd' then 'Continue ICU/NICU-level monitored care with urgent cardiology/surgical planning'
       else 'Continue NICU-level care using the lowest effective support with structured reassessment' end,
  3, 'This is the safest ongoing plan.'
from _neo2_steps st join _neo2_seed s on s.case_number = st.case_number where st.step_order = 4
union all select st.step_id, 'B', 'Transfer to lower-acuity nursery care now', -3, 'This is unsafe.' from _neo2_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discharge after temporary stabilization', -3, 'This is unsafe.' from _neo2_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Observe without explicit escalation triggers', -2, 'This is an inadequate plan.' from _neo2_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.step_id,
  'Initial neonatal assessment captures the correct disease pattern and severity.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _neo2_steps s1 join _neo2_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2 where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment is incomplete, and neonatal instability worsens.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-2,"bp_dia":-1,"etco2":2}'::jsonb
from _neo2_steps s1 join _neo2_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2 where s1.step_order = 1
union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  'Initial neonatal management is appropriate, but close reassessment is still required.',
  case when s2.case_number in (44,45) then '{"spo2":4,"hr":-4,"rr":-2,"bp_sys":1,"bp_dia":1,"etco2":-2}'::jsonb else '{"spo2":5,"hr":-4,"rr":-2,"bp_sys":1,"bp_dia":1,"etco2":-2}'::jsonb end
from _neo2_steps s2 join _neo2_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3 where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Treatment is delayed or incomplete, and instability persists.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":-2,"bp_dia":-1,"etco2":3}'::jsonb
from _neo2_steps s2 join _neo2_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3 where s2.step_order = 2
union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  'Reassessment is complete and supports the next management decision.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _neo2_steps s3 join _neo2_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4 where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Monitoring gaps leave high risk for recurrent neonatal deterioration.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-2,"bp_dia":-1,"etco2":2}'::jsonb
from _neo2_steps s3 join _neo2_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4 where s3.step_order = 3
union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the infant remains in appropriate monitored neonatal care with a disease-specific plan.',
  '{"spo2":2,"hr":-2,"rr":-1,"bp_sys":0,"bp_dia":0,"etco2":-1}'::jsonb
from _neo2_steps s4 where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: unsafe de-escalation leads to recurrent neonatal instability.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-2,"bp_dia":-1,"etco2":3}'::jsonb
from _neo2_steps s4 where s4.step_order = 4;

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
    'bp_dia', coalesce((b.baseline_vitals->>'bp_dia')::int, 0) + coalesce((r.vitals_delta->>'bp_dia')::int, 0),
    'etco2', coalesce((b.baseline_vitals->>'etco2')::int, 0) + coalesce((r.vitals_delta->>'etco2')::int, 0)
  )
from public.cse_rules r
join public.cse_steps s on s.id = r.step_id
join public.cse_cases b on b.id = s.case_id
join _neo2_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _neo2_target);

commit;
