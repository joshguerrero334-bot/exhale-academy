-- Exhale Academy quiz attempt schema (Master + Category) with Tutor/Exam mode support
-- Required env in app: authenticated Supabase user

create extension if not exists pgcrypto;

-- ------------------------------
-- Master test tables
-- ------------------------------
create table if not exists public.master_test_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  mode text not null check (mode in ('tutor', 'exam')),
  created_at timestamptz not null default now(),
  completed_at timestamptz null,
  score int4 not null default 0,
  total int4 not null default 160
);

do $$
declare qid_udt text;
begin
  select c.udt_name into qid_udt
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'questions'
    and c.column_name = 'id';

  if qid_udt is null then
    raise exception 'questions.id not found';
  end if;

  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'master_test_attempt_questions'
  ) then
    if qid_udt = 'uuid' then
      execute $sql$
        create table public.master_test_attempt_questions (
          id uuid primary key default gen_random_uuid(),
          attempt_id uuid not null references public.master_test_attempts(id) on delete cascade,
          question_id uuid not null references public.questions(id) on delete cascade,
          order_index int4 not null,
          selected_answer text null check (selected_answer in ('A','B','C','D')),
          is_correct boolean null,
          unique (attempt_id, order_index),
          unique (attempt_id, question_id)
        )
      $sql$;
    elsif qid_udt = 'int8' then
      execute $sql$
        create table public.master_test_attempt_questions (
          id uuid primary key default gen_random_uuid(),
          attempt_id uuid not null references public.master_test_attempts(id) on delete cascade,
          question_id bigint not null references public.questions(id) on delete cascade,
          order_index int4 not null,
          selected_answer text null check (selected_answer in ('A','B','C','D')),
          is_correct boolean null,
          unique (attempt_id, order_index),
          unique (attempt_id, question_id)
        )
      $sql$;
    else
      raise exception 'Unsupported questions.id type: %', qid_udt;
    end if;
  end if;
end $$;

-- ------------------------------
-- Category quiz tables
-- ------------------------------
create table if not exists public.category_quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  category_slug text not null,
  mode text not null check (mode in ('tutor', 'exam')),
  created_at timestamptz not null default now(),
  completed_at timestamptz null,
  score int4 not null default 0,
  total int4 not null default 20
);

do $$
declare qid_udt text;
begin
  select c.udt_name into qid_udt
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'questions'
    and c.column_name = 'id';

  if qid_udt is null then
    raise exception 'questions.id not found';
  end if;

  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'category_quiz_attempt_questions'
  ) then
    if qid_udt = 'uuid' then
      execute $sql$
        create table public.category_quiz_attempt_questions (
          id uuid primary key default gen_random_uuid(),
          attempt_id uuid not null references public.category_quiz_attempts(id) on delete cascade,
          question_id uuid not null references public.questions(id) on delete cascade,
          order_index int4 not null,
          selected_answer text null check (selected_answer in ('A','B','C','D')),
          is_correct boolean null,
          unique (attempt_id, order_index),
          unique (attempt_id, question_id)
        )
      $sql$;
    elsif qid_udt = 'int8' then
      execute $sql$
        create table public.category_quiz_attempt_questions (
          id uuid primary key default gen_random_uuid(),
          attempt_id uuid not null references public.category_quiz_attempts(id) on delete cascade,
          question_id bigint not null references public.questions(id) on delete cascade,
          order_index int4 not null,
          selected_answer text null check (selected_answer in ('A','B','C','D')),
          is_correct boolean null,
          unique (attempt_id, order_index),
          unique (attempt_id, question_id)
        )
      $sql$;
    else
      raise exception 'Unsupported questions.id type: %', qid_udt;
    end if;
  end if;
end $$;

-- ------------------------------
-- Indexes
-- ------------------------------
create index if not exists idx_master_attempts_user_created
  on public.master_test_attempts (user_id, created_at desc);
create index if not exists idx_master_attempt_questions_attempt
  on public.master_test_attempt_questions (attempt_id, order_index);

create index if not exists idx_category_attempts_user_created
  on public.category_quiz_attempts (user_id, created_at desc);
create index if not exists idx_category_attempts_slug
  on public.category_quiz_attempts (category_slug);
create index if not exists idx_category_attempt_questions_attempt
  on public.category_quiz_attempt_questions (attempt_id, order_index);

-- ------------------------------
-- RLS + policies
-- ------------------------------
alter table public.master_test_attempts enable row level security;
alter table public.master_test_attempt_questions enable row level security;
alter table public.category_quiz_attempts enable row level security;
alter table public.category_quiz_attempt_questions enable row level security;
alter table public.questions enable row level security;

do $$
begin
  -- master attempts
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='master_test_attempts' and policyname='master_attempts_select_own'
  ) then
    create policy master_attempts_select_own on public.master_test_attempts
      for select to authenticated
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='master_test_attempts' and policyname='master_attempts_insert_own'
  ) then
    create policy master_attempts_insert_own on public.master_test_attempts
      for insert to authenticated
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='master_test_attempts' and policyname='master_attempts_update_own'
  ) then
    create policy master_attempts_update_own on public.master_test_attempts
      for update to authenticated
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;

  -- master attempt questions
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='master_test_attempt_questions' and policyname='master_items_select_own'
  ) then
    create policy master_items_select_own on public.master_test_attempt_questions
      for select to authenticated
      using (
        exists (
          select 1 from public.master_test_attempts a
          where a.id = master_test_attempt_questions.attempt_id
            and a.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='master_test_attempt_questions' and policyname='master_items_insert_own'
  ) then
    create policy master_items_insert_own on public.master_test_attempt_questions
      for insert to authenticated
      with check (
        exists (
          select 1 from public.master_test_attempts a
          where a.id = master_test_attempt_questions.attempt_id
            and a.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='master_test_attempt_questions' and policyname='master_items_update_own'
  ) then
    create policy master_items_update_own on public.master_test_attempt_questions
      for update to authenticated
      using (
        exists (
          select 1 from public.master_test_attempts a
          where a.id = master_test_attempt_questions.attempt_id
            and a.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.master_test_attempts a
          where a.id = master_test_attempt_questions.attempt_id
            and a.user_id = auth.uid()
        )
      );
  end if;

  -- category attempts
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='category_quiz_attempts' and policyname='category_attempts_select_own'
  ) then
    create policy category_attempts_select_own on public.category_quiz_attempts
      for select to authenticated
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='category_quiz_attempts' and policyname='category_attempts_insert_own'
  ) then
    create policy category_attempts_insert_own on public.category_quiz_attempts
      for insert to authenticated
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='category_quiz_attempts' and policyname='category_attempts_update_own'
  ) then
    create policy category_attempts_update_own on public.category_quiz_attempts
      for update to authenticated
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;

  -- category attempt questions
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='category_quiz_attempt_questions' and policyname='category_items_select_own'
  ) then
    create policy category_items_select_own on public.category_quiz_attempt_questions
      for select to authenticated
      using (
        exists (
          select 1 from public.category_quiz_attempts a
          where a.id = category_quiz_attempt_questions.attempt_id
            and a.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='category_quiz_attempt_questions' and policyname='category_items_insert_own'
  ) then
    create policy category_items_insert_own on public.category_quiz_attempt_questions
      for insert to authenticated
      with check (
        exists (
          select 1 from public.category_quiz_attempts a
          where a.id = category_quiz_attempt_questions.attempt_id
            and a.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='category_quiz_attempt_questions' and policyname='category_items_update_own'
  ) then
    create policy category_items_update_own on public.category_quiz_attempt_questions
      for update to authenticated
      using (
        exists (
          select 1 from public.category_quiz_attempts a
          where a.id = category_quiz_attempt_questions.attempt_id
            and a.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.category_quiz_attempts a
          where a.id = category_quiz_attempt_questions.attempt_id
            and a.user_id = auth.uid()
        )
      );
  end if;

  -- questions readable for authenticated quiz users
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='questions' and policyname='questions_select_authenticated'
  ) then
    create policy questions_select_authenticated on public.questions
      for select to authenticated
      using (true);
  end if;
end $$;
