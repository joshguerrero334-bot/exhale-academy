-- Exhale Academy CSE NBRC category taxonomy migration
-- Adds NBRC category fields to cse_cases for A-G case organization.

begin;

alter table public.cse_cases
  add column if not exists nbrc_category_code text,
  add column if not exists nbrc_category_name text,
  add column if not exists nbrc_subcategory text;

alter table public.cse_cases
  drop constraint if exists cse_cases_nbrc_category_code_check;

alter table public.cse_cases
  add constraint cse_cases_nbrc_category_code_check
  check (
    nbrc_category_code is null
    or nbrc_category_code in ('A', 'B', 'C', 'D', 'E', 'F', 'G')
  );

create index if not exists idx_cse_cases_nbrc_category
  on public.cse_cases (nbrc_category_code, nbrc_subcategory);

commit;
