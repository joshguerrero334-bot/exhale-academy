begin;

with category_upsert as (
  insert into public.blog_categories (name, slug, description)
  values (
    'Diagnostics and Interpretation',
    'diagnostics-and-interpretation',
    'Board-focused respiratory diagnostics, interpretation guides, and pattern-recognition content for TMC and CSE prep.'
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
    ('PFT', 'pft'),
    ('Pulmonary Function Testing', 'pulmonary-function-testing'),
    ('Diagnostics', 'diagnostics'),
    ('Flow-Volume Loops', 'flow-volume-loops'),
    ('DLCO', 'dlco')
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
    title, slug, excerpt, content, featured_image_url, author_id, status, published_at,
    seo_title, seo_description, canonical_url, is_featured, allow_comments, read_time_minutes
  ) values (
    'How to Understand PFTs for the TMC: Obstructive vs Restrictive Made Simple',
    'how-to-understand-pfts-for-the-tmc-obstructive-vs-restrictive-made-simple',
    'Master pulmonary function testing for the TMC and CSE with a simple guide to normal values, obstructive vs restrictive patterns, DLCO clues, and flow-volume loops.',
    '# How to Understand PFTs for the TMC: Obstructive vs Restrictive Made Simple

Pulmonary function testing can feel overwhelming at first because there are so many numbers on the page. Students see FEV1, FVC, TLC, RV, DLCO, and flow-volume loops all at once, then freeze because they are not sure where to start.

The good news is that boards usually reward a simple pattern-based approach. If you know which number to check first and what each major clue means, PFTs become much more manageable. That matters on the TMC, and it matters on the CSE when a case gives you spirometry or lung-volume data and expects you to interpret it quickly.

## What Are PFTs?

Pulmonary function tests are breathing tests that help you measure how well the lungs move air and how well gases transfer across the alveolar-capillary membrane. They help you answer practical questions like:

- Is airflow obstructed?
- Is lung volume reduced?
- Is gas exchange impaired?
- Does the pattern fit obstructive disease, restrictive disease, or something else?

For respiratory therapy students, PFTs matter because they show up in board-style questions as pattern-recognition problems. The exam usually is not asking you to admire every number. It is asking whether you can tell what kind of disease process is happening and what clue matters most.

## Key PFT Terms Students Must Know

Here are the core terms that show up over and over:

- **FVC** = the total amount of air exhaled during a forced breath
- **FEV1** = the amount exhaled in the first second of that forced breath
- **FEV1/FVC ratio** = the key number used to separate obstructive from non-obstructive patterns
- **RV** = the amount of air left in the lungs after maximal exhalation
- **TLC** = the total lung volume after maximal inhalation
- **DLCO** = how well gas crosses the alveolar-capillary membrane

If you keep these definitions clear, the rest of the interpretation gets much easier.

## Normal Values Students Should Know

On boards, you do not need to obsess over tiny decimal-level differences. You need the approximate normal ranges and what they mean.

High-yield normal values include:

- **FEV1:** about 80% predicted or higher
- **FVC:** about 80% predicted or higher
- **FEV1/FVC ratio:** about 70% or higher, with age adjustment
- **TLC:** about 80% to 120% predicted
- **DLCO:** about 80% to 120% predicted

These are your anchors. Once you know the normal range, abnormal patterns become easier to spot fast.

## Step-by-Step Basic Interpretation Flow

The easiest way to read PFTs is to use the same order every time.

### Step 1: Check the FEV1/FVC Ratio First

This is the first major split.

- If the **FEV1/FVC ratio is below 70%**, think **obstructive pattern**.
- If the **FEV1/FVC ratio is 70% or higher**, the lungs may be normal or the pattern may be restrictive.

That first move keeps you from jumping to conclusions too early.

### Step 2: Check the FVC

If the ratio is normal or high, look at the FVC next.

- **Low FVC** raises concern for a **restrictive pattern**.
- A normal FVC makes restriction less likely.

This is where students often make an early mistake. Low FVC suggests restriction, but it does not prove it yet.

### Step 3: Use TLC to Confirm Restriction

Restriction is confirmed with total lung capacity.

- **Low TLC = restrictive disease**
- If TLC is not low, do not call it restrictive too quickly

This is one of the most testable steps in PFT interpretation.

### Step 4: Check DLCO for Gas-Exchange Clues

DLCO helps you understand whether the lung''s ability to transfer gas is affected.

- **Low DLCO** is often seen in **emphysema** and **pulmonary fibrosis**
- **Normal DLCO** can fit **asthma** or earlier disease

DLCO is often the clue that helps separate two conditions that might otherwise look similar.

## Obstructive vs Restrictive Patterns

This is the core comparison students need to own.

### Obstructive Pattern

In obstructive disease, the main problem is getting air out.

Common examples:

- COPD
- asthma

Typical pattern:

- **FEV1 low**
- **FVC normal or low**
- **FEV1/FVC low**
- **TLC normal or high**

Why does TLC rise sometimes? Because air trapping can increase total lung volume.

### Restrictive Pattern

In restrictive disease, the main problem is reduced total lung volume. The lungs cannot expand normally, so the patient cannot get enough air in.

Common examples:

- pulmonary fibrosis
- ARDS
- obesity
- neuromuscular disease

Typical pattern:

- **FEV1 low**
- **FVC low**
- **FEV1/FVC normal or high**
- **TLC low**

A lot of students remember obstruction because the ratio drops. Restriction takes a little more discipline because the ratio can look normal while the lung volume is clearly abnormal.

## Flow-Volume Loops

Flow-volume loops are another favorite board tool because they test recognition fast.

### Normal Loop

A normal loop is smooth and balanced.

Look for:

- rounded peak
- smooth descending expiratory limb
- overall symmetrical appearance

That shape suggests healthy airflow and normal volume.

### Obstructive Loop

The obstructive loop is the one students usually remember first.

Look for:

- a **scooped-out** or **coved** descending limb
- reduced peak flow
- a classic COPD or asthma shape

If the exam shows you that scooped descending limb, it is trying to steer you toward obstructive disease.

### Restrictive Loop

The restrictive loop is different because the main issue is reduced volume.

Look for:

- a **tall, narrow** shape
- reduced total volume
- peak flow that may still look fairly normal

This pattern fits conditions like fibrosis, ARDS, or neuromuscular weakness.

## Board Exam Buzzwords

Keep these high-yield clues in your head:

- **scooped loop** = obstructive
- **tall narrow loop** = restrictive
- **low FEV1/FVC** = obstructive
- **low TLC** = restrictive
- **low DLCO** = emphysema or fibrosis
- **normal DLCO** may point away from emphysema

These clues are usually more useful than memorizing isolated values without context.

## Common Exam Trap

The most common trap is calling something restrictive too early.

Students often see a low FVC and immediately label the pattern restrictive. That is not enough. A low FVC alone does not prove restriction. You still need **TLC** to confirm it.

Another trap is assuming a normal or high FEV1/FVC ratio means the lungs are normal. That is also not true. Restrictive disease can keep the ratio normal while overall lung volume is clearly reduced.

## Quick Memory Trick

Use this quick anchor:

- **Obstructive = trouble getting air out**
- **Restrictive = trouble getting air in and reduced total volume**

And when you interpret a full set of PFTs, remember:

**Ratio first, then FVC, then TLC, then DLCO.**

## Mini Practice Question

A patient has the following PFT findings:

- FEV1 is low
- FVC is low
- FEV1/FVC ratio is 82%
- TLC is low

Which pattern is most consistent with these results?

A. Obstructive disease  
B. Restrictive disease  
C. Normal pulmonary function  
D. Upper airway obstruction

**Correct answer:** B. Restrictive disease

**Rationale:** The ratio is normal to high, but both FVC and TLC are low. That pattern fits restriction, not obstruction.

## Want More Exhale Practice?

If you want to lock this in faster, pair this post with the [Pulmonary Function Testing flashcards](https://exhaleacademy.net/flashcards/pulmonary-function-testing) and keep reviewing disease-pattern posts like [COPD on the TMC](https://exhaleacademy.net/blog/copd-on-the-tmc-how-to-recognize-the-pattern-fast) and [Pulmonary Fibrosis on the TMC and CSE](https://exhaleacademy.net/blog/pulmonary-fibrosis-on-the-tmc-and-cse-recognizing-the-restrictive-pattern).',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'How to Understand PFTs for the TMC: Obstructive vs Restrictive Made Simple | Exhale Academy',
    'Master pulmonary function testing for the TMC and CSE with a simple guide to normal values, obstructive vs restrictive patterns, DLCO clues, and flow-volume loops.',
    'https://exhaleacademy.net/blog/how-to-understand-pfts-for-the-tmc-obstructive-vs-restrictive-made-simple',
    false,
    true,
    9
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
  where c.slug = 'diagnostics-and-interpretation'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'diagnostics-and-interpretation')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','respiratory-therapy','rt-student','exam-tips','pft','pulmonary-function-testing','diagnostics','flow-volume-loops','dlco')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/how-to-understand-pfts-for-the-tmc-obstructive-vs-restrictive-made-simple' as result;

commit;
