-- MVP read access for authenticated users on public.questions
-- Recommended:
alter table public.questions enable row level security;

drop policy if exists "questions_select_authenticated" on public.questions;
create policy "questions_select_authenticated"
on public.questions
for select
to authenticated
using (true);

-- Optional emergency fallback for tonight only (less secure):
-- alter table public.questions disable row level security;
