create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.blog_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  excerpt text,
  content text not null,
  featured_image_url text,
  author_id uuid null references auth.users(id) on delete set null,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  published_at timestamptz null,
  seo_title text,
  seo_description text,
  canonical_url text,
  is_featured boolean not null default false,
  allow_comments boolean not null default true,
  read_time_minutes integer null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.blog_categories (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  slug text unique not null,
  description text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.blog_tags (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  slug text unique not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.blog_post_categories (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.blog_posts(id) on delete cascade,
  category_id uuid not null references public.blog_categories(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, category_id)
);

create unique index if not exists blog_post_categories_one_primary_idx on public.blog_post_categories(post_id);

create table if not exists public.blog_post_tags (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.blog_posts(id) on delete cascade,
  tag_id uuid not null references public.blog_tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, tag_id)
);

create table if not exists public.blog_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.blog_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  parent_id uuid null references public.blog_comments(id) on delete cascade,
  content text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'hidden', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists blog_posts_slug_idx on public.blog_posts(slug);
create index if not exists blog_posts_status_idx on public.blog_posts(status);
create index if not exists blog_posts_published_at_desc_idx on public.blog_posts(published_at desc);
create index if not exists blog_comments_post_id_idx on public.blog_comments(post_id);
create index if not exists blog_comments_user_id_idx on public.blog_comments(user_id);
create index if not exists blog_comments_post_status_created_idx on public.blog_comments(post_id, status, created_at);
create index if not exists blog_categories_slug_idx on public.blog_categories(slug);
create index if not exists blog_tags_slug_idx on public.blog_tags(slug);

create trigger set_blog_posts_updated_at
before update on public.blog_posts
for each row
execute function public.set_updated_at();

create trigger set_blog_categories_updated_at
before update on public.blog_categories
for each row
execute function public.set_updated_at();

create trigger set_blog_tags_updated_at
before update on public.blog_tags
for each row
execute function public.set_updated_at();

create trigger set_blog_comments_updated_at
before update on public.blog_comments
for each row
execute function public.set_updated_at();

alter table public.blog_posts enable row level security;
alter table public.blog_categories enable row level security;
alter table public.blog_tags enable row level security;
alter table public.blog_post_categories enable row level security;
alter table public.blog_post_tags enable row level security;
alter table public.blog_comments enable row level security;

drop policy if exists "public can read published blog posts" on public.blog_posts;
create policy "public can read published blog posts"
on public.blog_posts
for select
using (status = 'published');

drop policy if exists "public can read blog categories" on public.blog_categories;
create policy "public can read blog categories"
on public.blog_categories
for select
using (true);

drop policy if exists "public can read blog tags" on public.blog_tags;
create policy "public can read blog tags"
on public.blog_tags
for select
using (true);

drop policy if exists "public can read blog post categories" on public.blog_post_categories;
create policy "public can read blog post categories"
on public.blog_post_categories
for select
using (true);

drop policy if exists "public can read blog post tags" on public.blog_post_tags;
create policy "public can read blog post tags"
on public.blog_post_tags
for select
using (true);

drop policy if exists "public can read approved comments on published posts" on public.blog_comments;
create policy "public can read approved comments on published posts"
on public.blog_comments
for select
using (
  status = 'approved'
  and exists (
    select 1
    from public.blog_posts p
    where p.id = blog_comments.post_id
      and p.status = 'published'
  )
);

drop policy if exists "authenticated users can insert own comments" on public.blog_comments;
create policy "authenticated users can insert own comments"
on public.blog_comments
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "authenticated users can edit own comments briefly" on public.blog_comments;
create policy "authenticated users can edit own comments briefly"
on public.blog_comments
for update
to authenticated
using (
  auth.uid() = user_id
  and now() <= created_at + interval '15 minutes'
)
with check (
  auth.uid() = user_id
  and now() <= created_at + interval '15 minutes'
);

comment on table public.blog_posts is 'Admin writes should go through service-role server actions. Public reads are limited to published posts via RLS.';
comment on table public.blog_categories is 'Admin writes should go through service-role server actions.';
comment on table public.blog_tags is 'Admin writes should go through service-role server actions.';
comment on table public.blog_post_categories is 'One primary category per post is enforced in v1 by unique(post_id).';
comment on table public.blog_comments is 'Comment creation and subscription gating are enforced in server actions before insert.';

insert into public.blog_categories (name, slug, description)
values
  ('TMC Prep', 'tmc-prep', 'Free TMC exam prep articles and study strategy for respiratory therapy students.'),
  ('ABG Interpretation', 'abg-interpretation', 'Clear breakdowns of ABG interpretation, compensation, and pattern recognition.'),
  ('Ventilator Management', 'ventilator-management', 'Ventilator strategy, troubleshooting, and bedside decision-making for RT students.')
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description,
    updated_at = now();

insert into public.blog_tags (name, slug)
values
  ('TMC Strategy', 'tmc-strategy'),
  ('ABGs', 'abgs'),
  ('Respiratory Therapy', 'respiratory-therapy'),
  ('NBRC', 'nbrc'),
  ('Ventilator Management', 'ventilator-management'),
  ('Acid-Base', 'acid-base'),
  ('Exam Prep', 'exam-prep'),
  ('Clinical Reasoning', 'clinical-reasoning')
on conflict (slug) do update
set name = excluded.name,
    updated_at = now();

with seeded_author as (
  select u.id as user_id
  from auth.users u
  order by u.created_at asc
  limit 1
), upsert_posts as (
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
  values
  (
    'How to Pass the TMC Exam Without Wasting Study Time',
    'how-to-pass-the-tmc-exam-without-wasting-study-time',
    'A focused TMC study system for respiratory therapy students who want smarter practice and less burnout.',
    '# How to Pass the TMC Exam Without Wasting Study Time

Most RT students do not need more random studying. They need a repeatable system.

## Start with one weak area

Pick one topic and stay there long enough to notice patterns.

- Choose one category
- Complete a short set of questions
- Review every rationale slowly
- Track the mistake pattern, not just the score

## Mix categories later

Once your understanding improves, move into mixed exams so you stop relying on context clues.

> [!INFO]
> The TMC rewards structured practice, not scattered effort.

## Build a weekly rhythm

Do category work early in the week and mixed testing later in the week. That keeps confidence and pressure balanced.',
    null,
    (select user_id from seeded_author),
    'published',
    now() - interval '14 days',
    'How to Pass the TMC Exam Without Wasting Study Time | Exhale Academy',
    'Learn a practical TMC study framework that helps RT students improve faster without wasting time on outdated prep.',
    null,
    true,
    true,
    4
  ),
  (
    'ABG Interpretation Made Simple for RT Students',
    'abg-interpretation-made-simple-for-rt-students',
    'A straightforward way to read ABGs using pH first, primary disorder second, and compensation last.',
    '# ABG Interpretation Made Simple for RT Students

ABGs get easier when you stop trying to memorize every exception first.

## Use the same order every time

1. Check the pH
2. Identify the primary direction of PaCO2 or HCO3
3. Ask if compensation is moving in the expected direction

## Do not chase normal values

Students often freeze when one number is close to normal. Start with the variable driving the pH.

## Connect the gas to the patient

A compensated gas still tells a clinical story. COPD, metabolic losses, and ventilator changes all matter.

```text
Low pH + high PaCO2 = respiratory acidosis
High pH + low PaCO2 = respiratory alkalosis
Low pH + low HCO3 = metabolic acidosis
High pH + high HCO3 = metabolic alkalosis
```',
    null,
    (select user_id from seeded_author),
    'published',
    now() - interval '9 days',
    'ABG Interpretation Made Simple for RT Students | Exhale Academy',
    'A simple ABG framework for respiratory therapy students preparing for the TMC, CSE, and bedside practice.',
    null,
    false,
    true,
    4
  ),
  (
    'How to Adjust the Ventilator Based on ABGs',
    'how-to-adjust-the-ventilator-based-on-abgs',
    'A bedside-first guide to when ABGs should push you toward changing minute ventilation, oxygenation support, or neither.',
    '# How to Adjust the Ventilator Based on ABGs

Ventilator changes should come from the gas and the patient together.

## Start with the problem you are solving

Is the issue ventilation, oxygenation, or both?

## When CO2 is the problem

Changes in minute ventilation affect PaCO2 most directly.

- Increase rate or tidal volume when ventilation is too low
- Decrease support when the patient is being over-ventilated
- Reassess safety limits before each change

## When oxygenation is the problem

Look at FiO2, PEEP, the chest image, and the story behind the gas.

## Do not overreact to one gas

Trend the patient, confirm the clinical picture, and avoid reflex changes that create a second problem.',
    null,
    (select user_id from seeded_author),
    'published',
    now() - interval '4 days',
    'How to Adjust the Ventilator Based on ABGs | Exhale Academy',
    'Use ABGs more effectively by linking respiratory acidosis, oxygenation failure, and bedside ventilator adjustments.',
    null,
    false,
    true,
    4
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
      is_featured = excluded.is_featured,
      allow_comments = excluded.allow_comments,
      read_time_minutes = excluded.read_time_minutes,
      updated_at = now()
  returning id, slug
), category_map as (
  select slug, id from public.blog_categories
), tag_map as (
  select slug, id from public.blog_tags
)
insert into public.blog_post_categories (post_id, category_id)
select upsert_posts.id,
  case upsert_posts.slug
    when 'how-to-pass-the-tmc-exam-without-wasting-study-time' then (select id from category_map where slug = 'tmc-prep')
    when 'abg-interpretation-made-simple-for-rt-students' then (select id from category_map where slug = 'abg-interpretation')
    when 'how-to-adjust-the-ventilator-based-on-abgs' then (select id from category_map where slug = 'ventilator-management')
  end
from upsert_posts
on conflict (post_id, category_id) do nothing;

with post_map as (
  select id, slug from public.blog_posts where slug in (
    'how-to-pass-the-tmc-exam-without-wasting-study-time',
    'abg-interpretation-made-simple-for-rt-students',
    'how-to-adjust-the-ventilator-based-on-abgs'
  )
), tag_map as (
  select id, slug from public.blog_tags
)
insert into public.blog_post_tags (post_id, tag_id)
select post_map.id, tag_map.id
from post_map
join tag_map on (
  (post_map.slug = 'how-to-pass-the-tmc-exam-without-wasting-study-time' and tag_map.slug in ('tmc-strategy', 'nbrc', 'exam-prep', 'respiratory-therapy')) or
  (post_map.slug = 'abg-interpretation-made-simple-for-rt-students' and tag_map.slug in ('abgs', 'acid-base', 'clinical-reasoning', 'respiratory-therapy')) or
  (post_map.slug = 'how-to-adjust-the-ventilator-based-on-abgs' and tag_map.slug in ('ventilator-management', 'abgs', 'clinical-reasoning', 'respiratory-therapy'))
)
on conflict (post_id, tag_id) do nothing;

with post_map as (
  select id, slug from public.blog_posts where slug in (
    'how-to-pass-the-tmc-exam-without-wasting-study-time',
    'abg-interpretation-made-simple-for-rt-students',
    'how-to-adjust-the-ventilator-based-on-abgs'
  )
), user_map as (
  select id, row_number() over (order by created_at asc) as rn
  from auth.users
  limit 3
)
insert into public.blog_comments (post_id, user_id, parent_id, content, status)
select
  case user_map.rn
    when 1 then (select id from post_map where slug = 'how-to-pass-the-tmc-exam-without-wasting-study-time')
    when 2 then (select id from post_map where slug = 'abg-interpretation-made-simple-for-rt-students')
    else (select id from post_map where slug = 'how-to-adjust-the-ventilator-based-on-abgs')
  end,
  user_map.id,
  null,
  case user_map.rn
    when 1 then 'This study structure is way easier to follow than random review sessions.'
    when 2 then 'This made compensation much simpler for me.'
    else 'Helpful breakdown. I like that it starts with the actual problem first.'
  end,
  case user_map.rn
    when 1 then 'approved'
    when 2 then 'pending'
    else 'hidden'
  end
from user_map
where exists (select 1 from post_map)
on conflict do nothing;
