with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_category as (
  insert into public.blog_categories (name, slug, description)
  values (
    'TMC Exam Prep',
    'tmc-exam-prep',
    'Free TMC exam prep articles, keyword guides, and strategy breakdowns for respiratory therapy students.'
  )
  on conflict (slug) do update
  set name = excluded.name,
      description = excluded.description,
      updated_at = now()
  returning id
), upsert_tags as (
  insert into public.blog_tags (name, slug)
  values
    ('TMC', 'tmc'),
    ('NBRC', 'nbrc'),
    ('Respiratory Therapy', 'respiratory-therapy'),
    ('Buzzwords', 'buzzwords'),
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
    'TMC Buzzwords Every Respiratory Therapy Student Must Know (2026 Guide)',
    'tmc-buzzwords-every-respiratory-therapy-student-must-know',
    'Learn the most important TMC buzzwords for the NBRC exam so you can recognize key disease patterns faster, avoid overthinking, and answer questions with more confidence.',
    '# TMC Buzzwords Every Respiratory Therapy Student Must Know

If you''re studying for the TMC exam, you’ve probably realized something frustrating:

The test isn’t just about knowledge — it’s about pattern recognition.

The NBRC loves to use buzzwords to point you toward the correct answer without saying it directly.

If you can recognize these patterns quickly, you can:
- answer faster
- avoid overthinking
- score higher

This guide will break down the most important TMC buzzwords you need to know.

## What Are TMC Buzzwords?

TMC buzzwords are key phrases in exam questions that hint at a specific diagnosis or condition.

Instead of giving you a direct answer, the exam will describe a situation like:

“Patient presents with pink frothy sputum…”

If you recognize the buzzword, you instantly know:

Pulmonary edema

## Disease Recognition Buzzwords

### ARDS
Refractory hypoxemia  
→ ARDS

### Pulmonary Edema / CHF
Pink frothy sputum  
→ Pulmonary edema

### COPD / Chronic Hypoxia
Clubbing of fingers  
→ Chronic hypoxia

Barrel chest  
→ Emphysema

### Airway Emergencies
Steeple sign (X-ray)  
→ Croup

Thumb sign (X-ray)  
→ Epiglottitis

### Pneumothorax
Hyperresonant percussion  
→ Pneumothorax

Tracheal deviation away from affected side  
→ Tension pneumothorax

### Atelectasis
Tracheal deviation toward affected side  
→ Atelectasis

### Infection / TB / Cancer
Hemoptysis (blood in sputum)  
→ TB, cancer, PE

Night sweats + weight loss  
→ Tuberculosis

## Diagnostic Buzzwords

### Chest X-ray Findings
Flattened diaphragm  
→ COPD

Ground-glass opacity  
→ ARDS or fibrosis

Batwing pattern  
→ Pulmonary edema

Honeycomb lung  
→ Interstitial lung disease

### Pulmonary Function Testing
Scooped flow-volume loop  
→ Obstructive disease

Peaked/narrow loop  
→ Restrictive disease

### Capnography Clues
Sudden loss of waveform  
→ Tube dislodgement

Gradual rise in baseline  
→ Rebreathing

## Ventilator Management Buzzwords

### Airway Problems
High PIP with normal plateau  
→ Airway resistance problem

### Compliance Problems
High PIP + high plateau  
→ Lung compliance issue

### Emergency Clues
Sudden drop in SpO₂ post-intubation  
→ Check tube placement

Suction catheter won’t pass  
→ Mucus plug

### Mechanical Issues
Leaky cuff (hissing sound)  
→ Check pilot balloon

Patient biting tube  
→ Add bite block or sedation

## How to Use Buzzwords on the TMC Exam

### 1. Trust the Keyword
If you see “refractory hypoxemia,” it’s ARDS. Don’t overthink it.

### 2. Think: Safest, Simplest, Fastest
The NBRC wants the least invasive effective answer first.

### 3. Look for Patterns (Not Just Numbers)
Low pH + high CO₂ = respiratory acidosis

### 4. Watch for Sudden Changes
Sudden changes = emergency  
Think obstruction, dislodgement, pneumothorax

## Key Takeaways
- TMC questions often hide the diagnosis inside a buzzword
- Pattern recognition helps you answer faster
- The NBRC usually prefers the safest and least invasive effective action
- Sudden changes often point to emergencies
- Mastering buzzwords builds confidence for test day

## Test Yourself

A patient presents with:
- pink frothy sputum
- dyspnea
- crackles

What is the most likely diagnosis?

Answer: Pulmonary edema

## Want More Practice?

If you''re serious about passing the TMC exam, Exhale Academy helps you:
- practice with real exam-style questions
- understand concepts quickly
- build confidence before test day

Start studying smarter with Exhale Academy.',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'TMC Buzzwords Every Respiratory Therapy Student Must Know | Exhale Academy',
    'Master the most important TMC buzzwords for the NBRC exam. Learn how to quickly recognize ARDS, COPD, pneumothorax, and more with this simple guide for RT students.',
    'https://exhaleacademy.net/blog/tmc-buzzwords-every-respiratory-therapy-student-must-know',
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
  where t.slug in ('tmc', 'nbrc', 'respiratory-therapy', 'buzzwords', 'rt-student', 'exam-tips')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/tmc-buzzwords-every-respiratory-therapy-student-must-know' as result;

insert into public.blog_posts (
  title,
  slug,
  excerpt,
  content,
  status,
  published_at,
  seo_title,
  seo_description,
  canonical_url,
  is_featured,
  allow_comments,
  read_time_minutes
)
values
  (
    'Ventilator Adjustments Based on ABGs',
    'ventilator-adjustments-based-on-abgs',
    'A draft reference for ABG-driven ventilator changes that will be expanded into a full Exhale Academy article.',
    '# Ventilator Adjustments Based on ABGs

Coming soon.',
    'draft',
    null,
    'Ventilator Adjustments Based on ABGs | Exhale Academy',
    'Coming soon: a practical guide to ventilator adjustments based on ABGs for RT students.',
    'https://exhaleacademy.net/blog/ventilator-adjustments-based-on-abgs',
    false,
    true,
    2
  ),
  (
    'How to Pass the TMC Exam on Your First Attempt',
    'how-to-pass-the-tmc-exam-on-your-first-attempt',
    'A draft reference for a focused first-attempt TMC strategy guide from Exhale Academy.',
    '# How to Pass the TMC Exam on Your First Attempt

Coming soon.',
    'draft',
    null,
    'How to Pass the TMC Exam on Your First Attempt | Exhale Academy',
    'Coming soon: a first-attempt TMC strategy guide for respiratory therapy students.',
    'https://exhaleacademy.net/blog/how-to-pass-the-tmc-exam-on-your-first-attempt',
    false,
    true,
    2
  )
on conflict (slug) do update
set title = excluded.title,
    excerpt = excluded.excerpt,
    content = excluded.content,
    status = excluded.status,
    seo_title = excluded.seo_title,
    seo_description = excluded.seo_description,
    canonical_url = excluded.canonical_url,
    allow_comments = excluded.allow_comments,
    read_time_minutes = excluded.read_time_minutes,
    updated_at = now();
