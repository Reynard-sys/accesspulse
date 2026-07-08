do $$
begin
  alter type public.case_status add value if not exists 'remediation_requested';
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter type public.case_status add value if not exists 'remediation_verification_requested';
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter type public.memory_event_type add value if not exists 'remediation_requested';
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter type public.memory_event_type add value if not exists 'remediation_verification_requested';
exception
  when duplicate_object then null;
end
$$;

alter table public.places
  add column if not exists created_by uuid,
  add column if not exists created_from text,
  add column if not exists pending_review boolean not null default false;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'places_created_by_fkey'
  ) then
    alter table public.places
      add constraint places_created_by_fkey
      foreign key (created_by) references public.users(id) on delete set null;
  end if;
end
$$;

create index if not exists places_created_by_idx on public.places(created_by);
create index if not exists places_pending_review_idx on public.places(pending_review);
