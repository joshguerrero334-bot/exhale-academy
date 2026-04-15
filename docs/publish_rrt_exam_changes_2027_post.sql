begin;

with category_upsert as (
  insert into public.blog_categories (name, slug, description)
  values (
    'Exam Updates',
    'exam-updates',
    'NBRC exam updates, board changes, and respiratory therapy credentialing guidance for RT students and new grads.'
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
    ('RRT', 'rrt'),
    ('CRT', 'crt'),
    ('NBRC', 'nbrc'),
    ('Respiratory Therapy', 'respiratory-therapy'),
    ('RT Student', 'rt-student'),
    ('Exam Tips', 'exam-tips'),
    ('Board Updates', 'board-updates'),
    ('RRT Exam Changes 2027', 'rrt-exam-changes-2027')
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
    'RRT Exam Changes 2027: What RT Students Need to Know About the New NBRC Exam',
    'rrt-exam-changes-2027',
    'Learn exactly how the 2027 NBRC RRT exam is changing, what the new Respiratory Therapy Examination includes, what happens to the TMC and CSE, and how RT students should prepare.',
    '# RRT Exam Changes 2027: What RT Students Need to Know About the New NBRC Exam

If you are planning your board path right now, the biggest update to understand is this: starting in **January 2027**, the current **TMC + CSE pathway** is being replaced for new candidates by **one combined exam**.

That is a major change, but it does not mean everything about respiratory therapy board prep is being rebuilt from scratch. A lot of the content RT students already study still matters. What is changing is the exam structure, the credentialing pathway, and how candidates reach the CRT or RRT level.

If you understand the **RRT exam changes 2027** early, your prep becomes much more focused.

## What is changing in 2027?

The biggest **NBRC exam changes 2027** students need to know are structural.

Right now, most students think of the RRT pathway this way:

- pass the TMC
- hit the high cut score
- then take the CSE

Starting in **January 2027**, new candidates will instead take **one combined exam**. That exam can award either the CRT or RRT credential depending on performance.

So the core shift is simple:

- **old pathway:** TMC + CSE
- **new pathway:** one combined exam with two cut scores

That is one of the most important **respiratory therapy board exam changes** because it changes how students should think about strategy, timing, and stamina.

## What is the new exam called?

The new exam is called the **Respiratory Therapy Examination**.

That name matters. Students will still hear people talk about the TMC and CSE during the transition period, but for new candidates entering the 2027 system, the official name to know is:

- **Respiratory Therapy Examination**

If you are searching for the **new RRT exam**, this is the official exam name tied to the 2027 pathway.

## How many questions are on the new exam?

The new Respiratory Therapy Examination contains **185 total multiple-choice items**.

That breaks down into:

- **160 scored items**
- **25 pretest items**

The pretest questions do not count toward your score, but students will not know which ones they are while testing. That means you should approach all 185 items seriously.

Another important structure point is that the scored exam includes:

- **100 Breadth of Knowledge items**
- **60 Depth of Clinical Judgment items**

That tells you a lot about the direction of the exam. The NBRC is still testing core RT knowledge, but it is also clearly emphasizing judgment and clinical application inside one multiple-choice exam.

## How long is the new exam?

The new Respiratory Therapy Examination has a **4-hour time limit**.

That matters because the 2027 format increases the importance of pacing and endurance. Under the current system, students think about the TMC and CSE as two separate challenges. In 2027, the experience becomes one longer exam session.

## How much does the new exam cost?

According to the NBRC, the fee structure is:

- **$360 for new applicants**
- **$300 for repeat applicants**

This is one of the practical pieces students should know when planning around the **new RRT exam**.

## What are the two parts of the new exam?

The new exam contains two scored portions inside one overall test.

### Breadth of Knowledge

This portion contains **100 items**.

Think of this as the wide RT foundation. It includes the kind of material students already expect to see in respiratory therapy exam prep, including:

- patient assessment
- ABGs
- PFTs
- oxygenation
- ventilation
- airway care
- device management
- troubleshooting
- interventions

### Depth of Clinical Judgment

This portion contains **60 items**.

This is where the exam more directly tests clinical thinking, prioritization, interpretation, and decision-making.

So while the old TMC-and-CSE structure is changing, clinical judgment is absolutely still part of the 2027 exam model.

## Is the CSE going away?

For new candidates in the 2027 pathway, yes, the separate CSE is being replaced by the combined Respiratory Therapy Examination.

But the CSE is **not** simply disappearing for every person overnight.

That transition detail matters, and it is where a lot of online summaries get too vague.

## What happens if you already passed the TMC high cut score before 2027?

There is a transition rule.

If you passed the **TMC at the high cut score before December 31, 2026** but did not complete the CSE, you may still take the CSE through **December 31, 2027**.

Those transition candidates also have another option:

- they may choose to take the **new Respiratory Therapy Examination** in 2027

This is one of the most important nuances in the **TMC and CSE changes** conversation. The transition rules are not identical for every student. Some candidates will still have a temporary CSE option during 2027 based on what they completed before the 2026 deadline.

## Is the CRT credential being eliminated?

No.

The **CRT credential is not being eliminated**.

That point is worth saying clearly because some students hear “single exam” and assume the CRT is disappearing. That is not what the NBRC says.

The new exam uses **two cut scores**:

- **low cut score = CRT**
- **high cut score = RRT**

So the credential structure remains, even though the testing pathway is changing.

## What is the CRT-to-Registry policy change?

The **CRT-to-Registry admission policy expires December 31, 2026**.

After **January 1, 2027**, candidates who have not already earned the RRT must be:

- graduates of
- with at least an **associate degree** from
- an **entry-into-practice CoARC-supported or CoARC-accredited respiratory therapy program**

to qualify for the new Respiratory Therapy Examination.

This is a major eligibility change, not just an exam-format change.

## What is staying the same?

A lot of the actual RT content still looks familiar.

Students should still expect core respiratory therapy material such as:

- patient assessment
- ABGs
- PFTs
- oxygenation
- ventilation
- airway care
- troubleshooting
- interventions
- device management
- bedside reasoning

So even with the **RRT exam changes 2027**, this is not a brand-new profession test. It is a new structure built around many of the same RT foundations students already need.

That is actually helpful. Strong fundamentals still transfer.

## What looks newer or more emphasized in the 2027 outline?

The 2027 outline more clearly and explicitly includes several topics that feel more current and more connected to real-world clinical care.

Examples include:

- **vaccination status**
- **vaping history**
- **respiratory pathogen studies**
- **SpCO**
- **SpO2/FiO2**
- **social determinants of health**
- **barriers to healthcare**

That does not mean the exam stops being about classic RT. It means the outline now shows a broader and more modern view of clinical assessment and patient context.

## What should students expect?

Students should expect:

- one longer exam session
- mixed multiple-choice testing rather than a separate simulation exam
- familiar RT content tested in a more integrated structure
- more emphasis on clinical judgment inside a multiple-choice format
- a stronger need for test endurance and mixed-topic transitions

The smartest mindset is this: you are not preparing for a totally different profession test. You are preparing for a **new delivery model** of respiratory therapy board assessment.

## How should students prepare?

The best way to prepare for the **Respiratory Therapy Examination** is to combine strong content review with mixed-question clinical reasoning.

### 1. Keep the RT basics strong

Students still need solid command of:

- ABGs
- oxygen devices
- ventilator adjustments
- disease recognition
- PFT interpretation
- airway management
- troubleshooting
- patient assessment

### 2. Practice longer mixed sets

Because the new exam is one 4-hour test, students should spend more time doing:

- mixed exams
- longer question blocks
- timed review sessions
- stamina-building practice

### 3. Build judgment, not just recall

The new structure makes it even more important to get comfortable with:

- choosing the safest next step
- interpreting patient data quickly
- separating similar answer choices
- recognizing priority changes in a clinical stem

### 4. Do not ignore newer outline details

Students should also be ready for newer assessment language and current clinical emphasis, especially around patient context, screening, and monitoring.

### 5. Prepare for the RRT level

Because the exam has two cut scores, the smart goal is not just “pass.” The better goal is to prepare at a level that supports the **high cut score**.

## What we still do not know

There is one important limit to what has been publicly listed.

The source material reviewed clearly states that there will be:

- a **low cut score** for CRT
- a **high cut score** for RRT

But the exact numeric low and high cut score values were **not publicly listed** in the material reviewed.

That means students should be cautious about overly confident posts online that act like every scoring number is already final and public.

## Bottom line

The biggest **RRT exam changes 2027** are easier to understand once you strip away the confusion:

- the current **TMC + CSE** pathway is being replaced for new candidates by one combined exam starting in January 2027
- that exam is called the **Respiratory Therapy Examination**
- it contains **185 total multiple-choice items**
- **160 items are scored**
- **25 items are pretest**
- the time limit is **4 hours**
- the exam includes **100 Breadth of Knowledge items** and **60 Depth of Clinical Judgment items**
- there are **two cut scores**
- **low cut score = CRT**
- **high cut score = RRT**
- the **CRT credential is staying**
- the CSE transition period still exists for certain candidates through **December 31, 2027**
- the **CRT-to-Registry** admission policy ends **December 31, 2026**

For students, the best response is not panic. It is clarity.

Build strong fundamentals. Practice mixed clinical reasoning. Get comfortable with longer testing sessions. And prepare for the kind of respiratory therapy thinking the NBRC has always expected, now delivered through a new structure.

## FAQ

### What are the RRT exam changes in 2027?

Starting in January 2027, new candidates will no longer use the TMC plus CSE pathway. Instead, they will take one combined exam called the Respiratory Therapy Examination.

### What is the new RRT exam called?

The new exam is called the **Respiratory Therapy Examination**.

### How many questions are on the new Respiratory Therapy Examination?

It has **185 total multiple-choice items**, including **160 scored items** and **25 pretest items**.

### Is the CSE going away in 2027?

For new candidates, the combined exam replaces the old separate CSE pathway. However, some transition candidates who passed the TMC high cut score before December 31, 2026 may still take the CSE through December 31, 2027.

### Is the CRT credential being eliminated?

No. The CRT credential remains. The new exam uses two cut scores, with the low cut score earning CRT and the high cut score earning RRT.

## Keep Studying with Exhale Academy

Helpful next reads and study tools for this topic:

- [TMC Practice](https://exhaleacademy.net/tmc)
- [Master CSE Practice](https://exhaleacademy.net/cse/master)
- [Pulmonary Function Testing Flashcards](https://exhaleacademy.net/flashcards/pulmonary-function-testing)
- [TMC Buzzwords Every Respiratory Therapy Student Must Know](https://exhaleacademy.net/blog/tmc-buzzwords-every-respiratory-therapy-student-must-know)
- [How to Understand PFTs for the TMC](https://exhaleacademy.net/blog/how-to-understand-pfts-for-the-tmc-obstructive-vs-restrictive-made-simple)',
    null,
    (select user_id from seeded_author),
    'published',
    now(),
    'RRT Exam Changes 2027: What the New NBRC Respiratory Therapy Examination Means | Exhale Academy',
    'Learn the 2027 RRT exam changes, including the new Respiratory Therapy Examination, TMC and CSE changes, transition rules, scoring structure, fees, and how RT students should prepare.',
    'https://exhaleacademy.net/blog/rrt-exam-changes-2027',
    true,
    true,
    10
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
  where c.slug = 'exam-updates'
  on conflict (post_id, category_id) do nothing
), cleanup_other_categories as (
  delete from public.blog_post_categories
  where post_id = (select id from upsert_post)
    and category_id <> (select id from public.blog_categories where slug = 'exam-updates')
), attach_tags as (
  insert into public.blog_post_tags (post_id, tag_id)
  select (select id from upsert_post), t.id
  from public.blog_tags t
  where t.slug in ('tmc','cse','rrt','crt','nbrc','respiratory-therapy','rt-student','exam-tips','board-updates','rrt-exam-changes-2027')
  on conflict (post_id, tag_id) do nothing
)
select 'Published blog post: /blog/rrt-exam-changes-2027' as result;

commit;
