begin;

with category_upsert as (
  insert into public.blog_categories (name, slug, description)
  values (
    'Respiratory Disease Review',
    'respiratory-disease-review',
    'Board-focused respiratory disease guides for TMC and CSE prep, built for fast pattern recognition and clinical recall.'
  )
  on conflict (slug) do update
  set name = excluded.name,
      description = excluded.description,
      updated_at = now()
  returning id
), tag_upsert as (
  insert into public.blog_tags (name, slug)
  values
    ('TMC', 'tmc'),
    ('CSE', 'cse'),
    ('Respiratory Therapy', 'respiratory-therapy'),
    ('RT Student', 'rt-student'),
    ('Exam Tips', 'exam-tips'),
    ('Disease Recognition', 'disease-recognition'),
    ('Asthma', 'asthma'),
    ('COPD', 'copd'),
    ('ARDS', 'ards'),
    ('Cystic Fibrosis', 'cystic-fibrosis'),
    ('Pneumonia', 'pneumonia'),
    ('Tuberculosis', 'tuberculosis'),
    ('Pulmonary Embolism', 'pulmonary-embolism'),
    ('Pulmonary Fibrosis', 'pulmonary-fibrosis'),
    ('Bronchiectasis', 'bronchiectasis')
  on conflict (slug) do update
  set name = excluded.name,
      updated_at = now()
  returning id
)
select 1;

with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'Asthma on the TMC and CSE: How to Recognize the Pattern Fast',
    'asthma-on-the-tmc-and-cse-how-to-recognize-the-pattern-fast',
    'Learn the high-yield asthma pattern for the TMC and CSE, including common triggers, key diagnostics, RT interventions, and board exam buzzwords.',
    '# Asthma on the TMC and CSE: How to Recognize the Pattern Fast

Asthma shows up all over respiratory therapy board prep because it tests more than one skill at once. You need to recognize the disease pattern, understand what happens to airflow, and know which intervention comes first when the patient starts to tighten up.

It also shows up in both low-pressure recall questions and high-pressure clinical decision-making. On the TMC, you may be asked to identify classic findings. On the CSE, you may need to recognize worsening bronchospasm, decide when bronchodilator therapy is enough, and know when the patient is moving toward fatigue.

## What It Is

Asthma is a chronic inflammatory airway disease that causes reversible bronchoconstriction. The key word is reversible. The airways tighten, swell, and produce more mucus, which narrows airflow and creates the classic obstructive pattern.

For board prep, think of asthma as an obstructive disease that usually improves with bronchodilator therapy, especially when treated early.

## Causes and Triggers

Common asthma triggers include:

- allergens such as dust, pollen, or pet dander
- cold air
- exercise
- stress
- respiratory infections
- smoke or airway irritants

On exam questions, the trigger is often part of the clue. A young patient with wheezing after exercise or exposure to an allergen should immediately make you think asthma.

## Signs and Symptoms

High-yield asthma clues include:

- wheezing
- coughing, especially at night or early morning
- chest tightness
- shortness of breath
- prolonged exhalation
- accessory muscle use during a severe attack
- decreased air movement if the attack is getting worse

For test questions, pay attention to severity. Mild asthma often has wheezing and tachypnea. Severe asthma may show very poor air movement, fatigue, and a rising PaCO2. That is the patient you do not want to underestimate.

## Diagnostics

The most important exam-relevant findings are the ones that confirm obstruction and reversibility.

You should know:

- decreased peak expiratory flow
- decreased FEV1
- improved airflow after bronchodilator therapy
- normal DLCO
- hyperinflation on chest x-ray during an acute attack

ABGs matter when the attack becomes more severe. Early in an asthma exacerbation, the patient may hyperventilate and show a low PaCO2. If PaCO2 starts climbing toward normal or above normal in a patient who still looks distressed, that is a warning sign for fatigue and impending ventilatory failure.

## RT Interventions

Respiratory therapy management should stay practical and stepwise.

High-yield RT interventions include:

- administer a short-acting bronchodilator such as albuterol
- provide oxygen if the patient is hypoxemic
- assist with corticosteroid therapy as ordered
- monitor peak flow when appropriate
- watch work of breathing and response to treatment closely
- teach and re-teach proper inhaler technique

For the CSE, remember that asthma treatment is not just about giving a medication. It is about reassessment. If the patient improves after bronchodilator therapy, you continue monitoring and supportive care. If wheezing worsens, air movement drops, or the patient tires out, the level of concern changes fast.

## Board Exam Buzzwords

Keep these pattern clues in your head:

- wheezing + chest tightness + trigger exposure = asthma
- decreased peak flow = worsening obstruction
- decreased FEV1 with normal DLCO = asthma pattern
- hyperinflation during attack = air trapping
- improvement after bronchodilator = reversible airway disease
- quiet chest in a struggling patient = severe airflow limitation

These clues help you identify asthma quickly even when the question never says the word asthma.

## Common Exam Trap

Students often confuse asthma with COPD or assume that any wheezing patient is stable enough for repeated nebulizers only.

The trap is missing the signs of fatigue. A rising PaCO2, declining air movement, or worsening exhaustion means the patient is no longer just tight. The patient may be failing.

## Quick Memory Trick

Asthma = obstructed but reversible.

## Mini Practice Question

A 19-year-old patient develops wheezing, chest tightness, and dyspnea after running in cold air. Peak flow is decreased, chest x-ray shows mild hyperinflation, and symptoms improve after albuterol. Which condition is most likely?

A. Pulmonary fibrosis  
B. Asthma  
C. Chronic bronchitis  
D. Pulmonary edema

**Correct answer:** B. Asthma

**Rationale:** The trigger, wheezing, decreased peak flow, hyperinflation during the attack, and improvement after bronchodilator therapy all point to reversible bronchoconstriction consistent with asthma.

## Want More Exhale Practice?

If you want to move faster on board questions, keep building pattern recognition with Exhale Academy. Then reinforce this topic with [COPD on the TMC](https://exhaleacademy.net/blog/copd-on-the-tmc-how-to-recognize-the-pattern-fast) and [ARDS on the TMC and CSE](https://exhaleacademy.net/blog/ards-on-the-tmc-and-cse-key-clues-you-cannot-miss).',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'Asthma on the TMC and CSE: How to Recognize the Pattern Fast | Exhale Academy',
    'Learn the high-yield asthma pattern for the TMC and CSE, including common triggers, key diagnostics, RT interventions, and board exam buzzwords.',
    'https://exhaleacademy.net/blog/asthma-on-the-tmc-and-cse-how-to-recognize-the-pattern-fast',
    false,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','disease-recognition','asthma')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/asthma-on-the-tmc-and-cse-how-to-recognize-the-pattern-fast' as result;


with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'COPD on the TMC: How to Recognize the Pattern Fast',
    'copd-on-the-tmc-how-to-recognize-the-pattern-fast',
    'Master the high-yield COPD pattern for the TMC with key diagnostics, oxygen considerations, RT interventions, and common board exam clues.',
    '# COPD on the TMC: How to Recognize the Pattern Fast

COPD is one of the most important disease patterns in respiratory therapy board prep because it keeps showing up from different angles. One question may test whether you recognize emphysema on imaging. Another may focus on chronic bronchitis, oxygen therapy, or CO2 retention. The disease is broad, but the exam clues are very repeatable.

If you can spot the pattern quickly, you stop overthinking. That matters on both the TMC and the CSE. COPD questions often reward the student who notices the chronic obstructive picture, respects oxygen carefully, and chooses the safest next step instead of jumping too aggressively.

## What It Is

COPD is a progressive, largely irreversible obstructive lung disease that includes chronic bronchitis and emphysema. Airflow limitation worsens over time, and patients often have chronic dyspnea, cough, sputum production, and air trapping.

For board prep, think chronic obstruction, smoking history, hyperinflation, and caution with oxygen.

## Causes and Triggers

Common COPD causes and triggers include:

- cigarette smoking
- long-term occupational or environmental irritant exposure
- alpha-1 antitrypsin deficiency
- respiratory infections
- poor medication adherence
- air pollution and smoke exposure

Exam stems often include an older patient with a smoking history, chronic cough, or gradual worsening dyspnea. That should move COPD high on your differential quickly.

## Signs and Symptoms

High-yield COPD clues include:

- chronic cough
- sputum production
- dyspnea on exertion that progresses over time
- wheezing
- prolonged exhalation
- diminished breath sounds
- barrel chest in emphysema-predominant disease
- signs of chronic hypoxemia in advanced disease

Students should also recognize the two classic flavors. Chronic bronchitis leans toward mucus, cough, and frequent infections. Emphysema leans toward hyperinflation, air trapping, and a more pronounced barrel chest pattern.

## Diagnostics

COPD diagnostics are very testable because the pattern is consistent.

Know these findings:

- FEV1/FVC less than 70%
- increased total lung capacity
- increased residual volume
- flattened diaphragm on chest x-ray
- hyperinflation on imaging
- obstructive flow-volume loop

ABGs can help you judge severity. In advanced COPD, you may see chronic hypercapnia and compensated respiratory acidosis. During an acute exacerbation, worsening hypoxemia and a rising PaCO2 suggest the patient may be tiring out.

## RT Interventions

High-yield RT management includes:

- administer bronchodilators
- assist with corticosteroid therapy when indicated
- provide low-flow oxygen and titrate carefully
- monitor oxygen saturation and clinical response
- support smoking cessation
- encourage pulmonary rehab when appropriate
- watch for signs of acute ventilatory failure

The oxygen point matters. The exam likes to test whether you understand that COPD patients still need oxygen when hypoxemic, but you should avoid blasting them with unnecessarily high oxygen when a lower titrated flow will do the job.

## Board Exam Buzzwords

Watch for these COPD clues:

- smoker + chronic cough + sputum = chronic bronchitis pattern
- barrel chest + flattened diaphragm = emphysema pattern
- decreased FEV1/FVC = obstruction
- increased TLC and RV = air trapping and hyperinflation
- chronic hypercapnia with compensation = advanced COPD pattern
- low-flow oxygen = safer oxygen strategy in chronic CO2 retainers

These details are often enough to identify COPD even before the question names it.

## Common Exam Trap

A common mistake is thinking COPD patients should not get oxygen.

That is not the right take. If the patient is hypoxemic, oxygen is indicated. The real issue is titration. Give what the patient needs, monitor closely, and do not assume more oxygen is always better.

## Quick Memory Trick

COPD = chronic obstruction plus trapped air.

## Mini Practice Question

A 67-year-old patient with a long smoking history has chronic cough, sputum production, dyspnea, a flattened diaphragm on chest x-ray, and an FEV1/FVC ratio of 58%. Which diagnosis best fits this pattern?

A. Pulmonary fibrosis  
B. COPD  
C. Asthma  
D. Tuberculosis

**Correct answer:** B. COPD

**Rationale:** The smoking history, chronic productive symptoms, obstructive spirometry, and flattened diaphragms point to COPD rather than a reversible or restrictive process.

## Want More Exhale Practice?

Use this post as a pattern anchor, then reinforce the difference between obstruction and restrictive failure with [Asthma on the TMC and CSE](https://exhaleacademy.net/blog/asthma-on-the-tmc-and-cse-how-to-recognize-the-pattern-fast) and [Pulmonary Fibrosis on the TMC and CSE](https://exhaleacademy.net/blog/pulmonary-fibrosis-on-the-tmc-and-cse-recognizing-the-restrictive-pattern).',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'COPD on the TMC: How to Recognize the Pattern Fast | Exhale Academy',
    'Master the high-yield COPD pattern for the TMC with key diagnostics, oxygen considerations, RT interventions, and common board exam clues.',
    'https://exhaleacademy.net/blog/copd-on-the-tmc-how-to-recognize-the-pattern-fast',
    true,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','respiratory-therapy','rt-student','exam-tips','disease-recognition','copd')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/copd-on-the-tmc-how-to-recognize-the-pattern-fast' as result;


with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'ARDS on the TMC and CSE: Key Clues You Cannot Miss',
    'ards-on-the-tmc-and-cse-key-clues-you-cannot-miss',
    'Learn the high-yield ARDS pattern for the TMC and CSE, including refractory hypoxemia, chest x-ray clues, ventilator strategy, and board exam buzzwords.',
    '# ARDS on the TMC and CSE: Key Clues You Cannot Miss

ARDS is one of the most important critical care patterns on the boards because it tests whether you can tell the difference between severe oxygenation failure and a problem that should respond to basic oxygen therapy. When the exam gives you worsening hypoxemia, bilateral infiltrates, and poor lung compliance, it wants you to recognize that this is not a routine pneumonia question anymore.

This topic matters on both the TMC and the CSE because ARDS combines disease recognition with ventilator management. You need to know the pattern, but you also need to know what to do with it.

## What It Is

ARDS is acute inflammatory injury to the alveolar-capillary membrane that causes severe hypoxemia and noncardiogenic pulmonary edema. In simple terms, the lungs become stiff, wet, and very poor at oxygen exchange.

The classic board concept is refractory hypoxemia. The patient stays hard to oxygenate even when support is escalating.

## Causes and Triggers

High-yield ARDS causes include:

- sepsis
- trauma
- aspiration
- severe pneumonia
- pancreatitis
- shock states

The question stem often includes one of these triggers before the oxygenation problem gets worse. That is your signal to keep ARDS in the front of your mind.

## Signs and Symptoms

Look for:

- severe dyspnea
- tachypnea
- diffuse crackles
- worsening oxygenation
- decreased lung compliance
- increasing work of breathing or ventilator pressure requirements

In a more advanced case, the patient may require mechanical ventilation and still remain difficult to oxygenate.

## Diagnostics

ARDS has some of the most recognizable exam findings in respiratory care.

Know these:

- bilateral infiltrates on chest x-ray
- PaO2/FiO2 ratio less than 300
- normal heart size, which helps separate it from cardiogenic edema
- poor compliance on the ventilator
- persistent hypoxemia despite increasing support

ABGs commonly show significant hypoxemia. Ventilator questions may give you plateau pressure, PEEP, or oxygenation trends to test whether you understand lung-protective strategy.

## RT Interventions

This is where boards love to go next.

High-yield ARDS management includes:

- low tidal volume ventilation, typically 4 to 6 mL/kg of ideal body weight
- increased PEEP to improve oxygenation
- close monitoring of plateau pressure
- prone positioning when indicated
- treatment of the underlying cause such as sepsis, aspiration, or pneumonia

The key ventilator principle is lung protection. ARDS management is not about trying to normalize everything with large tidal volumes. It is about protecting the injured lung while supporting oxygenation.

## Board Exam Buzzwords

These clues should immediately raise concern for ARDS:

- refractory hypoxemia
- bilateral infiltrates
- decreased compliance
- PaO2/FiO2 less than 300
- normal heart size with severe oxygenation failure
- low tidal volume ventilation and higher PEEP
- plateau pressure should stay under 30 cmH2O

If the exam gives you sepsis plus diffuse infiltrates plus stubborn hypoxemia, ARDS should be near the top instantly.

## Common Exam Trap

A common trap is confusing ARDS with cardiogenic pulmonary edema.

Both can present with bilateral infiltrates and hypoxemia. The difference is that ARDS is noncardiogenic and classically has a normal heart size on imaging. The history also helps. Sepsis, aspiration, trauma, and pancreatitis point you toward ARDS.

## Quick Memory Trick

ARDS = acute stiff lungs with refractory hypoxemia.

## Mini Practice Question

A mechanically ventilated patient with sepsis has bilateral infiltrates, a normal cardiac silhouette, poor lung compliance, and a PaO2/FiO2 ratio of 140. Which management strategy is most appropriate?

A. High tidal volume ventilation to improve oxygenation  
B. Low tidal volume ventilation with higher PEEP  
C. Decrease PEEP and observe  
D. Bronchodilator therapy as the primary treatment

**Correct answer:** B. Low tidal volume ventilation with higher PEEP

**Rationale:** This is a classic ARDS picture. Lung-protective ventilation with low tidal volume and appropriate PEEP is the correct strategy, while the underlying cause is treated in parallel.

## Want More Exhale Practice?

Keep this pattern next to [Pneumonia on the TMC and CSE](https://exhaleacademy.net/blog/pneumonia-on-the-tmc-and-cse-how-to-spot-the-pattern-fast) and [Pulmonary Embolism on the TMC and CSE](https://exhaleacademy.net/blog/pulmonary-embolism-on-the-tmc-and-cse-sudden-dyspnea-pattern-recognition) so you get faster at separating different causes of hypoxemia under pressure.',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'ARDS on the TMC and CSE: Key Clues You Cannot Miss | Exhale Academy',
    'Learn the high-yield ARDS pattern for the TMC and CSE, including refractory hypoxemia, chest x-ray clues, ventilator strategy, and board exam buzzwords.',
    'https://exhaleacademy.net/blog/ards-on-the-tmc-and-cse-key-clues-you-cannot-miss',
    false,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','disease-recognition','ards')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/ards-on-the-tmc-and-cse-key-clues-you-cannot-miss' as result;


with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'Cystic Fibrosis on the TMC and CSE: High-Yield Patterns for RT Students',
    'cystic-fibrosis-on-the-tmc-and-cse-high-yield-patterns-for-rt-students',
    'Study the high-yield cystic fibrosis pattern for the TMC and CSE with key diagnostics, airway clearance strategies, and board exam buzzwords.',
    '# Cystic Fibrosis on the TMC and CSE: High-Yield Patterns for RT Students

Cystic fibrosis is one of those diseases that boards love because it connects airway clearance, infection control, and long-term pulmonary care. It is a pattern-recognition disease. If you see thick secretions, repeated infections, and a younger patient with chronic respiratory problems, cystic fibrosis should be one of the first conditions you consider.

This topic matters for TMC and CSE prep because the disease reaches beyond the lungs. Questions may mention nutrition, clubbing, pancreatic issues, or recurrent infections. But for respiratory therapy students, the core theme stays the same: thick mucus and the need for aggressive airway clearance.

## What It Is

Cystic fibrosis is a genetic disorder caused by abnormal chloride transport. That leads to thick, sticky secretions in the lungs and other organs.

For boards, think thick mucus, repeated pulmonary infections, and chronic secretion management.

## Causes and Triggers

The underlying cause is a CFTR gene mutation. That mutation disrupts chloride and water movement across epithelial surfaces, so mucus becomes abnormally thick.

Clinical worsening can be triggered by:

- respiratory infections
- poor secretion clearance
- dehydration
- missed airway clearance treatments
- chronic colonization with pathogenic organisms

## Signs and Symptoms

High-yield clues include:

- persistent cough
- frequent lung infections
- thick secretions
- digital clubbing
- failure to thrive or malnutrition
- chronic sinus issues
- increased work of breathing during exacerbations

A question may also mention a younger patient with recurring pulmonary problems plus nutritional difficulty. That should strongly suggest cystic fibrosis rather than routine bronchitis.

## Diagnostics

Know the key tests and findings:

- positive sweat chloride test
- decreased PFT values
- chest imaging that may show hyperinflation or bronchiectatic changes
- sputum cultures during infectious workup

PFTs may show obstructive changes because mucus plugging and airway damage affect airflow. Imaging helps reinforce the chronic secretion burden and structural lung disease.

## RT Interventions

This is where the disease becomes very practical for RT students.

High-yield interventions include:

- chest physiotherapy or other airway clearance methods
- bronchodilator therapy when indicated
- mucolytic therapy such as dornase alfa
- hydration support
- infection control awareness
- coordination with nutritional and enzyme therapy plans

On the CSE, airway clearance should stay central. The question is often not whether the patient needs help moving secretions. The question is how aggressively and how consistently.

## Board Exam Buzzwords

Remember these CF clues:

- thick mucus
- recurrent infections
- clubbing
- malnutrition
- positive sweat chloride
- bronchiectatic changes on imaging
- airway clearance is a major management priority

When the question combines chronic lung infection with secretion clearance issues in a younger patient, cystic fibrosis should come to mind fast.

## Common Exam Trap

A common trap is treating cystic fibrosis like simple asthma or uncomplicated chronic bronchitis.

The difference is the secretion burden and chronic infection pattern. Bronchodilators alone are not the center of care. Airway clearance is.

## Quick Memory Trick

CF = chloride problem, thick secretions, constant clearance.

## Mini Practice Question

A young adult with chronic cough, repeated lung infections, clubbing, and poor weight gain has a positive sweat chloride test. Which intervention is most central to respiratory care?

A. High-flow oxygen as the main long-term therapy  
B. Routine airway clearance therapy  
C. Immediate lung transplant for all patients  
D. Bronchodilator therapy only

**Correct answer:** B. Routine airway clearance therapy

**Rationale:** Cystic fibrosis is driven by thick secretions and chronic infection risk. Airway clearance is one of the most important day-to-day respiratory interventions.

## Want More Exhale Practice?

To strengthen this pattern, compare cystic fibrosis with [Bronchiectasis on the TMC and CSE](https://exhaleacademy.net/blog/bronchiectasis-on-the-tmc-and-cse-secretion-clearance-and-pattern-recognition) and [Pneumonia on the TMC and CSE](https://exhaleacademy.net/blog/pneumonia-on-the-tmc-and-cse-how-to-spot-the-pattern-fast).',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'Cystic Fibrosis on the TMC and CSE: High-Yield Patterns for RT Students | Exhale Academy',
    'Study the high-yield cystic fibrosis pattern for the TMC and CSE with key diagnostics, airway clearance strategies, and board exam buzzwords.',
    'https://exhaleacademy.net/blog/cystic-fibrosis-on-the-tmc-and-cse-high-yield-patterns-for-rt-students',
    false,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','disease-recognition','cystic-fibrosis')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/cystic-fibrosis-on-the-tmc-and-cse-high-yield-patterns-for-rt-students' as result;


with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'Pneumonia on the TMC and CSE: How to Spot the Pattern Fast',
    'pneumonia-on-the-tmc-and-cse-how-to-spot-the-pattern-fast',
    'Review the high-yield pneumonia pattern for the TMC and CSE with imaging clues, ABG concerns, RT interventions, and common exam traps.',
    '# Pneumonia on the TMC and CSE: How to Spot the Pattern Fast

Pneumonia matters on the boards because it can look simple at first and then become a much bigger oxygenation problem. Students sometimes underestimate it because they associate it with routine infection questions. But on the TMC and CSE, pneumonia can test disease recognition, oxygenation assessment, secretion management, and escalation when the patient starts to fail.

The best way to stay sharp is to know the classic pattern cold. Fever, cough, sputum, infiltrates, and crackles should move you toward pneumonia quickly.

## What It Is

Pneumonia is an infection that inflames the alveoli and can fill them with fluid or pus. That reduces gas exchange and can cause both ventilation-perfusion mismatch and increased work of breathing.

On exam questions, think infection plus alveolar involvement.

## Causes and Triggers

Common causes include:

- bacterial infection
- viral infection
- fungal infection
- aspiration

The exact organism may not matter for pattern recognition. What matters first is identifying that an infectious alveolar process is present and could be affecting oxygenation.

## Signs and Symptoms

High-yield clues include:

- fever
- cough
- sputum production
- dyspnea
- pleuritic chest pain
- crackles
- decreased breath sounds over an involved area
- worsening hypoxemia in more severe disease

If the question gives you fever, productive cough, and focal crackles with an infiltrate on imaging, pneumonia should be one of your first answers.

## Diagnostics

Know the classic findings:

- chest x-ray with infiltrates or consolidation
- elevated white blood cell count
- crackles or decreased breath sounds on exam
- ABGs that may show hypoxemia when the disease is more severe
- sputum studies when needed for infectious workup

The boards may also test progression. If pneumonia is worsening, you may see increasing oxygen needs, tachypnea, or signs of sepsis.

## RT Interventions

High-yield RT care includes:

- humidified oxygen when needed
- monitoring oxygenation and work of breathing
- assisting with airway clearance when secretions are present
- encouraging hydration if appropriate
- supporting antibiotic therapy when bacterial pneumonia is suspected
- monitoring for worsening hypoxemia or sepsis

For respiratory therapy students, one of the biggest takeaways is that pneumonia is not just an infection question. It is an oxygenation and assessment question too.

## Board Exam Buzzwords

These clues should point you toward pneumonia:

- fever + cough + sputum
- pleuritic chest pain
- crackles
- localized infiltrate or consolidation
- elevated WBC
- worsening hypoxemia in a more severe case

When those clues show up together, think alveolar infection before you overcomplicate the question.

## Common Exam Trap

A common trap is confusing pneumonia with pulmonary edema or atelectasis.

The history helps. Fever, productive cough, and infectious symptoms point toward pneumonia. Pulmonary edema usually brings more fluid-overload clues. Atelectasis often centers around postoperative collapse or mucus plugging rather than infection.

## Quick Memory Trick

Pneumonia = pus, crackles, and infiltrates.

## Mini Practice Question

A patient has fever, productive cough, pleuritic chest pain, crackles in the right lower lobe, and a chest x-ray showing consolidation. Which diagnosis best fits this presentation?

A. Pulmonary embolism  
B. Pneumonia  
C. Asthma  
D. Pulmonary fibrosis

**Correct answer:** B. Pneumonia

**Rationale:** Fever, sputum, crackles, pleuritic pain, and focal consolidation are classic findings in pneumonia.

## Want More Exhale Practice?

Once you are comfortable with pneumonia, compare it with [ARDS on the TMC and CSE](https://exhaleacademy.net/blog/ards-on-the-tmc-and-cse-key-clues-you-cannot-miss) and [Tuberculosis on the TMC and CSE](https://exhaleacademy.net/blog/tuberculosis-on-the-tmc-and-cse-the-clues-rt-students-must-catch) so you get faster at sorting different infectious lung patterns.',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'Pneumonia on the TMC and CSE: How to Spot the Pattern Fast | Exhale Academy',
    'Review the high-yield pneumonia pattern for the TMC and CSE with imaging clues, ABG concerns, RT interventions, and common exam traps.',
    'https://exhaleacademy.net/blog/pneumonia-on-the-tmc-and-cse-how-to-spot-the-pattern-fast',
    false,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','disease-recognition','pneumonia')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/pneumonia-on-the-tmc-and-cse-how-to-spot-the-pattern-fast' as result;


with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'Tuberculosis on the TMC and CSE: The Clues RT Students Must Catch',
    'tuberculosis-on-the-tmc-and-cse-the-clues-rt-students-must-catch',
    'Learn the classic tuberculosis pattern for the TMC and CSE, including infection control clues, diagnostics, and the buzzwords RT students need to remember.',
    '# Tuberculosis on the TMC and CSE: The Clues RT Students Must Catch

Tuberculosis is one of those board topics where the diagnosis matters, but the response matters too. The disease is highly testable because it combines a recognizable symptom pattern with a major infection control priority. If you miss the isolation piece, you miss one of the most important parts of the question.

For respiratory therapy students, TB is not just about spotting a chronic cough. It is about recognizing when infection control must come first.

## What It Is

Tuberculosis is a contagious bacterial infection caused by Mycobacterium tuberculosis. It usually affects the lungs, though it can involve other body systems as well.

For board prep, think chronic respiratory symptoms plus airborne isolation.

## Causes and Triggers

TB spreads through airborne transmission from an infected person. The disease becomes more likely in patients with close exposure, crowded living conditions, immunocompromise, or other risk factors for infection.

In a test question, the clue is often not a single trigger. It is the chronic, systemic pattern.

## Signs and Symptoms

Classic TB findings include:

- cough lasting more than 3 weeks
- hemoptysis
- night sweats
- weight loss
- fever
- fatigue

The combination of chronic cough, weight loss, and night sweats is especially high-yield. That trio should make you think TB quickly.

## Diagnostics

Key test findings include:

- positive PPD or Mantoux testing
- chest x-ray that may show cavitary lesions
- sputum positive for acid-fast bacilli
- additional culture or confirmatory infectious workup

The boards often use the imaging and symptom combination rather than expecting you to memorize every lab detail. Cavitations plus chronic cough plus systemic symptoms is a strong TB pattern.

## RT Interventions

High-yield RT priorities include:

- airborne isolation
- use of an N95 respirator
- negative-pressure room placement
- oxygen support if needed
- assistance during bronchoscopy or sputum collection when indicated
- maintaining infection control throughout care

The most testable point is this: before you think about all the extra details, think isolation.

## Board Exam Buzzwords

Watch for these TB clues:

- cough longer than 3 weeks
- hemoptysis
- night sweats
- weight loss
- fever
- cavitary lesion on chest x-ray
- positive acid-fast bacilli sputum result
- negative-pressure room and N95 use

This is one of the cleanest pattern-recognition diseases on the exam.

## Common Exam Trap

A common trap is confusing TB with pneumonia or lung cancer and forgetting the infection control response.

The chronic timeline helps. Pneumonia is usually more acute. Cancer can overlap with weight loss and hemoptysis, but TB questions often include night sweats, cavitary lesions, and isolation clues.

## Quick Memory Trick

TB = three big clues: cough, cavitation, containment.

## Mini Practice Question

A patient has a cough for 5 weeks, weight loss, night sweats, intermittent hemoptysis, and a chest x-ray showing upper lobe cavitary lesions. What is the most important immediate respiratory care priority?

A. Start chest physiotherapy first  
B. Place the patient in airborne isolation  
C. Administer high-flow oxygen only  
D. Prepare for extubation

**Correct answer:** B. Place the patient in airborne isolation

**Rationale:** The presentation is highly suspicious for pulmonary tuberculosis. Infection control with airborne isolation is a critical first priority.

## Want More Exhale Practice?

Pair this post with [Pneumonia on the TMC and CSE](https://exhaleacademy.net/blog/pneumonia-on-the-tmc-and-cse-how-to-spot-the-pattern-fast) and [Pulmonary Embolism on the TMC and CSE](https://exhaleacademy.net/blog/pulmonary-embolism-on-the-tmc-and-cse-sudden-dyspnea-pattern-recognition) so you get faster at separating chronic infectious symptoms from acute causes of dyspnea.',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'Tuberculosis on the TMC and CSE: The Clues RT Students Must Catch | Exhale Academy',
    'Learn the classic tuberculosis pattern for the TMC and CSE, including infection control clues, diagnostics, and the buzzwords RT students need to remember.',
    'https://exhaleacademy.net/blog/tuberculosis-on-the-tmc-and-cse-the-clues-rt-students-must-catch',
    false,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','disease-recognition','tuberculosis')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/tuberculosis-on-the-tmc-and-cse-the-clues-rt-students-must-catch' as result;


with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'Pulmonary Embolism on the TMC and CSE: Sudden Dyspnea Pattern Recognition',
    'pulmonary-embolism-on-the-tmc-and-cse-sudden-dyspnea-pattern-recognition',
    'Study the classic pulmonary embolism pattern for the TMC and CSE, including sudden dyspnea clues, ABG findings, diagnostics, and RT priorities.',
    '# Pulmonary Embolism on the TMC and CSE: Sudden Dyspnea Pattern Recognition

Pulmonary embolism is one of the most important sudden-onset board patterns in respiratory care. It often appears in exam questions that want to see if you can stay disciplined when the chest x-ray is not dramatic, the lungs may sound fairly normal, and the patient still looks bad.

That is why PE is so high-yield. Students tend to over-focus on wheezing, crackles, and imaging-heavy lung disease. PE reminds you that a dangerous respiratory problem can present with sudden dyspnea and surprisingly limited lung exam findings.

## What It Is

Pulmonary embolism is a blockage in the pulmonary arterial system, usually caused by a blood clot that traveled from the legs.

For board prep, think sudden onset, impaired perfusion, and oxygenation trouble without the classic secretions or infiltrate picture of pneumonia.

## Causes and Triggers

Common PE risk factors include:

- immobility
- recent surgery
- trauma
- clotting disorders
- prolonged travel
- prior thromboembolic history

The boards often give you a risk factor on purpose. A postop patient or someone with sudden dyspnea after prolonged immobility should immediately raise suspicion.

## Signs and Symptoms

High-yield clues include:

- sudden dyspnea
- chest pain, often pleuritic
- tachypnea
- tachycardia
- possible hemoptysis
- anxiety or sudden unexplained distress
- relatively clear breath sounds in some cases

One of the best board clues is sudden dyspnea with normal or near-normal lung sounds. That pattern should stop you from drifting toward asthma or pneumonia too quickly.

## Diagnostics

Know the exam-relevant findings:

- CT angiography is the gold standard test in many board contexts
- V/Q scan may also be used
- elevated D-dimer can support suspicion
- ABG may show hypoxemia with respiratory alkalosis
- chest x-ray may be less impressive than the patient''s distress level suggests

The ABG pattern matters. Many PE patients hyperventilate early, which can lower PaCO2 and create respiratory alkalosis.

## RT Interventions

High-yield RT priorities include:

- provide oxygen therapy
- monitor vital signs closely
- watch for hemodynamic instability
- support further diagnostic workup
- assist with care while anticoagulation or thrombolytic therapy is initiated as ordered

Respiratory therapy does not dissolve the clot, but RT plays a major role in recognizing the pattern, supporting oxygenation, and identifying deterioration fast.

## Board Exam Buzzwords

These clues should make you think PE:

- sudden dyspnea
- pleuritic chest pain
- tachycardia
- tachypnea
- hemoptysis
- normal or near-normal lung sounds
- postoperative or immobile patient
- hypoxemia with respiratory alkalosis

That combination is one of the most recognizable acute board patterns.

## Common Exam Trap

A common trap is choosing pneumonia or asthma just because the patient is short of breath.

The timing matters. Pneumonia usually has fever and infiltrates. Asthma usually has wheezing and a clear obstructive story. PE is more about sudden onset, risk factors, and a mismatch between how sick the patient feels and how little you hear in the lungs.

## Quick Memory Trick

PE = sudden shortness of breath with a perfusion problem.

## Mini Practice Question

A patient 2 days after major surgery develops sudden dyspnea, pleuritic chest pain, tachycardia, and hypoxemia. Breath sounds are essentially normal. Which diagnosis is most likely?

A. Asthma  
B. Pneumonia  
C. Pulmonary embolism  
D. Pulmonary fibrosis

**Correct answer:** C. Pulmonary embolism

**Rationale:** The sudden onset, postop risk, pleuritic pain, hypoxemia, and relatively normal lung sounds strongly suggest pulmonary embolism.

## Want More Exhale Practice?

Use this alongside [ARDS on the TMC and CSE](https://exhaleacademy.net/blog/ards-on-the-tmc-and-cse-key-clues-you-cannot-miss) and [Pneumonia on the TMC and CSE](https://exhaleacademy.net/blog/pneumonia-on-the-tmc-and-cse-how-to-spot-the-pattern-fast) to sharpen your differential for acute hypoxemia.',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'Pulmonary Embolism on the TMC and CSE: Sudden Dyspnea Pattern Recognition | Exhale Academy',
    'Study the classic pulmonary embolism pattern for the TMC and CSE, including sudden dyspnea clues, ABG findings, diagnostics, and RT priorities.',
    'https://exhaleacademy.net/blog/pulmonary-embolism-on-the-tmc-and-cse-sudden-dyspnea-pattern-recognition',
    false,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','disease-recognition','pulmonary-embolism')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/pulmonary-embolism-on-the-tmc-and-cse-sudden-dyspnea-pattern-recognition' as result;


with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'Pulmonary Fibrosis on the TMC and CSE: Recognizing the Restrictive Pattern',
    'pulmonary-fibrosis-on-the-tmc-and-cse-recognizing-the-restrictive-pattern',
    'Learn the restrictive pattern of pulmonary fibrosis for the TMC and CSE, including imaging clues, PFT findings, RT interventions, and exam traps.',
    '# Pulmonary Fibrosis on the TMC and CSE: Recognizing the Restrictive Pattern

Pulmonary fibrosis is a disease students often recognize as serious but still mix up on exams. That happens because the symptoms can overlap with other chronic lung problems. The difference is the pattern. This is not primarily an obstructive disease with air trapping. It is a stiff-lung, restrictive process with poor gas diffusion.

Once you see that pattern clearly, board questions become much easier.

## What It Is

Pulmonary fibrosis is chronic progressive scarring of lung tissue. As the lungs scar, compliance falls and gas exchange worsens.

For board prep, think restrictive disease, low diffusion capacity, and poor response to bronchodilators.

## Causes and Triggers

Pulmonary fibrosis is often idiopathic, but it may also be associated with:

- autoimmune disease
- environmental or occupational exposure
- chronic inflammatory injury

Board questions do not always focus on the exact cause. More often, they focus on how the disease behaves physiologically.

## Signs and Symptoms

High-yield clues include:

- progressive dyspnea
- dry cough
- fatigue
- digital clubbing
- exercise intolerance
- reduced activity tolerance over time

Unlike asthma or chronic bronchitis, pulmonary fibrosis usually does not present as a mucus-heavy or wheezing-dominant disease.

## Diagnostics

This is where the restrictive pattern becomes obvious.

Know these findings:

- chest x-ray or CT with honeycombing or reticulonodular changes
- decreased total lung capacity
- decreased DLCO
- restrictive pulmonary function pattern
- hypoxemia that may worsen with exertion

The low DLCO is especially important because it helps point toward diffusion impairment rather than pure airway obstruction.

## RT Interventions

Respiratory therapy priorities include:

- supplemental oxygen when indicated
- pulmonary rehab support
- monitoring oxygenation during activity
- education on disease progression and functional limitation
- support for transplant evaluation when appropriate

This is not a disease that usually improves with bronchodilators in a major way. That is one of the key board distinctions.

## Board Exam Buzzwords

Watch for these fibrosis clues:

- progressive dyspnea
- dry cough
- clubbing
- honeycomb lung
- reticulonodular pattern
- decreased TLC
- decreased DLCO
- restrictive pattern with poor bronchodilator response

When those clues show up together, think pulmonary fibrosis or interstitial lung disease.

## Common Exam Trap

A common trap is confusing pulmonary fibrosis with COPD or asthma.

The difference is the physiology. COPD and asthma are obstructive. Pulmonary fibrosis is restrictive. The lungs are stiff, total lung capacity is down, diffusion is poor, and bronchodilators do not dramatically reverse the disease.

## Quick Memory Trick

Fibrosis = fixed, stiff, and restrictive.

## Mini Practice Question

A patient has progressive dyspnea, dry cough, clubbing, CT findings of honeycombing, decreased TLC, and decreased DLCO. Which diagnosis is most likely?

A. Pulmonary fibrosis  
B. Asthma  
C. Chronic bronchitis  
D. Pulmonary embolism

**Correct answer:** A. Pulmonary fibrosis

**Rationale:** The restrictive pattern, low DLCO, clubbing, and honeycombing are classic findings in pulmonary fibrosis.

## Want More Exhale Practice?

Use this post next to [COPD on the TMC](https://exhaleacademy.net/blog/copd-on-the-tmc-how-to-recognize-the-pattern-fast) and [ARDS on the TMC and CSE](https://exhaleacademy.net/blog/ards-on-the-tmc-and-cse-key-clues-you-cannot-miss) so you can separate chronic restrictive disease from acute oxygenation failure.',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'Pulmonary Fibrosis on the TMC and CSE: Recognizing the Restrictive Pattern | Exhale Academy',
    'Learn the restrictive pattern of pulmonary fibrosis for the TMC and CSE, including imaging clues, PFT findings, RT interventions, and exam traps.',
    'https://exhaleacademy.net/blog/pulmonary-fibrosis-on-the-tmc-and-cse-recognizing-the-restrictive-pattern',
    false,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','disease-recognition','pulmonary-fibrosis')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/pulmonary-fibrosis-on-the-tmc-and-cse-recognizing-the-restrictive-pattern' as result;


with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_post as (
  insert into public.blog_posts (
    title,
    slug,
    excerpt,
    content,
    featured_image_url,
    author_id,
    status,
    published_at,
    seo_title,
    seo_description,
    canonical_url,
    is_featured,
    allow_comments,
    read_time_minutes
  )
  values (
    'Bronchiectasis on the TMC and CSE: Secretion Clearance and Pattern Recognition',
    'bronchiectasis-on-the-tmc-and-cse-secretion-clearance-and-pattern-recognition',
    'Study the bronchiectasis pattern for the TMC and CSE with high-yield diagnostics, secretion clues, RT interventions, and board exam buzzwords.',
    '# Bronchiectasis on the TMC and CSE: Secretion Clearance and Pattern Recognition

Bronchiectasis is one of the best examples of how boards test chronic secretion disease. If you learn to spot the pattern, you can separate it from asthma, COPD, and simple recurrent bronchitis much faster. The disease is really about structurally damaged airways, mucus retention, and repeated infection.

For respiratory therapy students, that means one management theme rises above the rest: secretion clearance.

## What It Is

Bronchiectasis is chronic dilation and destruction of the bronchi. Damaged airways collect mucus, which leads to recurrent infection and more airway injury over time.

On the boards, think chronic productive cough plus repeated infection plus structural airway damage.

## Causes and Triggers

Common causes include:

- repeated lung infections
- cystic fibrosis
- immune deficiencies
- post-infectious airway damage

The disease may show up as part of a cystic fibrosis question or as its own chronic secretion-clearing problem.

## Signs and Symptoms

High-yield clues include:

- chronic productive cough
- purulent sputum
- recurrent respiratory infections
- crackles
- rhonchi
- intermittent dyspnea
- chronic secretion burden

This is not usually a dry-cough disease. Thick sputum and repeated infection are major clues.

## Diagnostics

Know these findings:

- chest CT confirms diagnosis by showing dilated airways
- sputum cultures may help guide infectious workup
- PFTs may show an obstructive pattern
- chronic radiographic changes may support the diagnosis

The CT finding is the biggest exam clue because it confirms the airway dilation directly.

## RT Interventions

Respiratory therapy should stay focused on moving mucus and preventing secretion buildup.

High-yield interventions include:

- chest physiotherapy
- bronchodilator therapy when indicated
- mucolytics
- hydration
- secretion mobilization strategies
- monitoring during infectious exacerbations

This is one of those diseases where routine, consistent airway clearance often matters more than flashy interventions.

## Board Exam Buzzwords

Watch for these bronchiectasis clues:

- chronic productive cough
- purulent sputum
- recurrent infections
- crackles or rhonchi
- dilated airways on chest CT
- secretion clearance priority
- think CF-associated or post-infectious disease

Those clues should push bronchiectasis high on your list fast.

## Common Exam Trap

A common trap is confusing bronchiectasis with uncomplicated COPD or asthma.

The difference is the heavy secretion burden and repeated infectious history. Bronchiectasis questions often point toward chronic mucus retention and airway-clearance needs, not just bronchodilator response.

## Quick Memory Trick

Bronchiectasis = broken bronchi full of mucus.

## Mini Practice Question

A patient has chronic productive cough, purulent sputum, recurrent lung infections, crackles, and a chest CT showing dilated airways. Which diagnosis is most likely?

A. Bronchiectasis  
B. Pulmonary fibrosis  
C. Asthma  
D. Pulmonary embolism

**Correct answer:** A. Bronchiectasis

**Rationale:** The chronic purulent sputum, recurrent infection history, and CT evidence of airway dilation are classic for bronchiectasis.

## Want More Exhale Practice?

To lock this in, compare [Bronchiectasis on the TMC and CSE](https://exhaleacademy.net/blog/bronchiectasis-on-the-tmc-and-cse-secretion-clearance-and-pattern-recognition) with [Cystic Fibrosis on the TMC and CSE](https://exhaleacademy.net/blog/cystic-fibrosis-on-the-tmc-and-cse-high-yield-patterns-for-rt-students) and [Pneumonia on the TMC and CSE](https://exhaleacademy.net/blog/pneumonia-on-the-tmc-and-cse-how-to-spot-the-pattern-fast).',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'Bronchiectasis on the TMC and CSE: Secretion Clearance and Pattern Recognition | Exhale Academy',
    'Study the bronchiectasis pattern for the TMC and CSE with high-yield diagnostics, secretion clues, RT interventions, and board exam buzzwords.',
    'https://exhaleacademy.net/blog/bronchiectasis-on-the-tmc-and-cse-secretion-clearance-and-pattern-recognition',
    false,
    true,
    6
  )
  on conflict (slug) do update
  set title = excluded.title,
      excerpt = excluded.excerpt,
      content = excluded.content,
      author_id = excluded.author_id,
      status = excluded.status,
      published_at = excluded.published_at,
      seo_title = excluded.seo_title,
      seo_description = excluded.seo_description,
      canonical_url = excluded.canonical_url,
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id
), ensure_primary_category as (
  insert into public.blog_post_categories (post_id, category_id)
  select (select id from upsert_post), c.id
  from public.blog_categories c
  where c.slug = 'respiratory-disease-review'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'respiratory-disease-review')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','disease-recognition','bronchiectasis')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/bronchiectasis-on-the-tmc-and-cse-secretion-clearance-and-pattern-recognition' as result;

commit;
