-- Exhale Academy CSE hard reset (data only)
-- Keeps schema, deletes all CSE content + attempts so you can rebuild from scratch.

begin;

do $$
begin
  if to_regclass('public.cse_attempt_events') is not null then
    execute 'delete from public.cse_attempt_events';
  end if;
  if to_regclass('public.cse_attempt_steps') is not null then
    execute 'delete from public.cse_attempt_steps';
  end if;
  if to_regclass('public.cse_attempts') is not null then
    execute 'delete from public.cse_attempts';
  end if;
  if to_regclass('public.cse_rules') is not null then
    execute 'delete from public.cse_rules';
  end if;
  if to_regclass('public.cse_outcomes') is not null then
    execute 'delete from public.cse_outcomes';
  end if;
  if to_regclass('public.cse_options') is not null then
    execute 'delete from public.cse_options';
  end if;
  if to_regclass('public.cse_choices') is not null then
    execute 'delete from public.cse_choices';
  end if;
  if to_regclass('public.cse_steps') is not null then
    execute 'delete from public.cse_steps';
  end if;
  if to_regclass('public.cse_scenarios') is not null then
    execute 'delete from public.cse_scenarios';
  end if;
  if to_regclass('public.cse_cases') is not null then
    execute 'delete from public.cse_cases';
  end if;
end $$;

commit;
