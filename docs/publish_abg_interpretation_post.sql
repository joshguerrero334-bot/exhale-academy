with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_category as (
  insert into public.blog_categories (name, slug, description)
  values (
    'ABG Interpretation',
    'abg-interpretation',
    'Simple ABG interpretation guides, acid-base walkthroughs, and TMC-focused respiratory therapy study content.'
  )
  on conflict (slug) do update
  set name = excluded.name,
      description = excluded.description,
      updated_at = now()
  returning id
), upsert_tags as (
  insert into public.blog_tags (name, slug)
  values
    ('ABG', 'abg'),
    ('TMC', 'tmc'),
    ('Respiratory Therapy', 'respiratory-therapy'),
    ('Ventilator Management', 'ventilator-management'),
    ('RT Student', 'rt-student'),
    ('Exam Tips', 'exam-tips')
  on conflict (slug) do update
  set name = excluded.name,
      updated_at = now()
  returning id, slug
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
    'ABG Interpretation Made Simple for Respiratory Therapy Students (Step-by-Step Guide)',
    'abg-interpretation-made-simple-for-respiratory-therapy-students',
    'Learn ABG interpretation step by step for the TMC exam with a simple, repeatable process respiratory therapy students can use under pressure.',
    '# ABG Interpretation Made Simple for Respiratory Therapy Students

If you’re studying for the TMC exam, ABGs can feel overwhelming at first.

Too many numbers. Too many rules. Too easy to second guess.

But here’s the truth:

ABG interpretation is actually one of the most predictable and testable skills on the exam.

Once you follow a simple system, it becomes easy.

## Step-by-Step ABG Interpretation

Use this exact method every time you see an ABG:

### Step 1: Check the pH
- pH < 7.35 → Acidosis
- pH > 7.45 → Alkalosis

This tells you whether the patient is acidotic or alkalotic.

### Step 2: Look at PaCO₂ (Respiratory Component)
- PaCO₂ > 45 → Respiratory Acidosis
- PaCO₂ < 35 → Respiratory Alkalosis

This reflects ventilation.

### Step 3: Look at HCO₃⁻ (Metabolic Component)
- HCO₃⁻ < 22 → Metabolic Acidosis
- HCO₃⁻ > 26 → Metabolic Alkalosis

This reflects metabolic balance.

### Step 4: Match the System to the pH

Ask yourself:

Which value matches the pH?
- If pH is acidic AND CO₂ is high → Respiratory Acidosis
- If pH is acidic AND HCO₃ is low → Metabolic Acidosis

This tells you the primary problem

### Step 5: Determine Compensation
- Uncompensated → one value abnormal, other normal
- Partially compensated → both abnormal, pH still abnormal
- Fully compensated → both abnormal, pH normal

## Example ABG

pH: 7.30  
PaCO₂: 55  
HCO₃⁻: 24

Step 1 → Acidosis  
Step 2 → CO₂ is high  
Step 3 → HCO₃ is normal

Final Answer → Respiratory Acidosis (Uncompensated)

## Ventilator Adjustments Based on ABGs

This is where most students struggle — but it’s actually simple.

### Respiratory Acidosis (High CO₂)

Problem: Not enough ventilation

Fix:
- Increase respiratory rate
- Increase tidal volume

### Respiratory Alkalosis (Low CO₂)

Problem: Too much ventilation

Fix:
- Decrease respiratory rate
- Decrease tidal volume

### Metabolic Acidosis

Problem: Metabolic issue

Fix:
- Treat underlying cause
- Consider bicarbonate if severe

### Metabolic Alkalosis

Problem: Loss of acid

Fix:
- Treat underlying cause
- May reduce ventilation if needed

### Hypoxemia (Low PaO₂)

Problem: Oxygenation

Fix:
- Increase FiO₂
- Increase PEEP

### Hyperoxemia (High PaO₂)

Problem: Too much oxygen

Fix:
- Decrease FiO₂
- Decrease PEEP

## Common ABG Mistakes RT Students Make

### 1. Skipping the pH

Always start with pH.

### 2. Mixing Up CO₂ and HCO₃

CO₂ = respiratory  
HCO₃ = metabolic

### 3. Overthinking Compensation

Focus on the primary disorder first.

### 4. Ignoring the Pattern

ABGs follow patterns — trust them.

## Key Takeaways
- Always follow the same 5-step process
- pH tells you the direction
- CO₂ and HCO₃ tell you the cause
- Match the system to the pH
- ABGs are pattern-based, not random

## Test Yourself

ABG:

pH: 7.48  
PaCO₂: 30  
HCO₃⁻: 24

What is the diagnosis?

Answer: Respiratory Alkalosis

## Want More Practice?

If you want to actually master ABGs and pass the TMC exam:

Exhale Academy gives you:
- practice questions
- step-by-step explanations
- exam-level scenarios
- a system that builds confidence

Start studying smarter with Exhale Academy.',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'ABG Interpretation Made Simple for Respiratory Therapy Students | Exhale Academy',
    'Learn ABG interpretation step by step for the TMC exam. Simple, clear guide for respiratory therapy students with examples, tips, and ventilator adjustments.',
    'https://exhaleacademy.net/blog/abg-interpretation-made-simple-for-respiratory-therapy-students',
    true,
    true,
    5
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
  select
    (select id from upsert_post),
    (select id from upsert_category)
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from upsert_category)
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select
    (select id from upsert_post),
    t.id
  from public.blog_tags t
  where t.slug in ('abg', 'tmc', 'respiratory-therapy', 'ventilator-management', 'rt-student', 'exam-tips')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/abg-interpretation-made-simple-for-respiratory-therapy-students' as result;
