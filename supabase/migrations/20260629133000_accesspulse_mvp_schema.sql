create extension if not exists pgcrypto;

create type public.accesspulse_user_role as enum (
  'community_user',
  'lgu_reviewer',
  'inspector'
);

create type public.dimension_state_value as enum (
  'unknown',
  'claimed_accessible',
  'reliable',
  'degraded',
  'officially_verified_degraded',
  'under_review',
  'resolved'
);

create type public.dimension_pulse_level as enum (
  'weak',
  'moderate',
  'strong'
);

create type public.case_status as enum (
  'open',
  'triaging',
  'inspection_requested',
  'verified',
  'disputed',
  'resolved',
  'closed'
);

create type public.observation_outcome as enum (
  'positive',
  'negative',
  'mixed',
  'unknown'
);

create type public.evidence_type as enum (
  'image',
  'text_note',
  'structured_response'
);

create type public.case_severity as enum (
  'low',
  'medium',
  'high'
);

create type public.verification_outcome as enum (
  'confirmed',
  'disputed',
  'insufficient_evidence'
);

create type public.memory_event_type as enum (
  'place_seeded',
  'state_seeded',
  'visit_confirmed',
  'evidence_added',
  'ai_signal_created',
  'case_opened',
  'case_triaged',
  'inspection_requested',
  'verification_submitted',
  'state_changed',
  'pulse_changed',
  'case_closed',
  'remediation_verified'
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  organization_type text not null,
  jurisdiction text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.users (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  role public.accesspulse_user_role not null,
  organization_id uuid references public.organizations(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.places (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  place_type text not null,
  address text,
  municipality text,
  province text,
  country text not null default 'Philippines',
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.accessibility_dimensions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name text not null,
  description text not null,
  created_at timestamptz not null default now()
);

create table public.place_dimensions (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  dimension_id uuid not null references public.accessibility_dimensions(id) on delete restrict,
  summary text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (place_id, dimension_id)
);

create table public.dimension_states (
  id uuid primary key default gen_random_uuid(),
  place_dimension_id uuid not null unique references public.place_dimensions(id) on delete cascade,
  state public.dimension_state_value not null default 'unknown',
  confidence numeric(4, 3) not null default 0 check (confidence >= 0 and confidence <= 1),
  explanation text not null,
  last_confirmed_at timestamptz,
  source text not null default 'system',
  updated_at timestamptz not null default now()
);

create table public.dimension_pulses (
  id uuid primary key default gen_random_uuid(),
  place_dimension_id uuid not null unique references public.place_dimensions(id) on delete cascade,
  level public.dimension_pulse_level not null default 'weak',
  score numeric(4, 3) not null default 0 check (score >= 0 and score <= 1),
  supporting_observations_count integer not null default 0 check (supporting_observations_count >= 0),
  has_recent_verification boolean not null default false,
  contradiction_flag boolean not null default false,
  last_calculated_at timestamptz not null default now(),
  explanation text not null
);

create table public.observations (
  id uuid primary key default gen_random_uuid(),
  place_dimension_id uuid not null references public.place_dimensions(id) on delete cascade,
  submitted_by uuid references public.users(id) on delete set null,
  visit_date date not null default current_date,
  entrance_usable_independently boolean,
  ramp_usable boolean,
  needed_assistance boolean,
  completed_purpose boolean,
  note text,
  outcome public.observation_outcome not null default 'unknown',
  created_at timestamptz not null default now()
);

create table public.evidence (
  id uuid primary key default gen_random_uuid(),
  observation_id uuid references public.observations(id) on delete cascade,
  place_dimension_id uuid not null references public.place_dimensions(id) on delete cascade,
  submitted_by uuid references public.users(id) on delete set null,
  evidence_type public.evidence_type not null,
  storage_path text,
  public_url text,
  note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check (
    observation_id is not null
    or note is not null
    or storage_path is not null
    or public_url is not null
  )
);

create table public.barrier_signals (
  id uuid primary key default gen_random_uuid(),
  place_dimension_id uuid not null references public.place_dimensions(id) on delete cascade,
  observation_id uuid references public.observations(id) on delete set null,
  evidence_id uuid references public.evidence(id) on delete set null,
  issue_type text not null,
  observed_features text[] not null default array[]::text[],
  possible_barrier text not null,
  missing_evidence text[] not null default array[]::text[],
  confidence numeric(4, 3) not null check (confidence >= 0 and confidence <= 1),
  structured_summary text not null,
  recommended_action text not null,
  ai_model text,
  ai_explanation jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.cases (
  id uuid primary key default gen_random_uuid(),
  place_dimension_id uuid not null references public.place_dimensions(id) on delete cascade,
  barrier_signal_id uuid references public.barrier_signals(id) on delete set null,
  status public.case_status not null default 'open',
  severity public.case_severity not null default 'medium',
  confidence numeric(4, 3) not null check (confidence >= 0 and confidence <= 1),
  title text not null,
  summary text not null,
  assigned_organization_id uuid references public.organizations(id) on delete set null,
  opened_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz
);

create table public.verifications (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  place_dimension_id uuid not null references public.place_dimensions(id) on delete cascade,
  verified_by uuid references public.users(id) on delete set null,
  outcome public.verification_outcome not null,
  note text not null,
  performed_at timestamptz not null default now()
);

create table public.memory_events (
  id uuid primary key default gen_random_uuid(),
  place_dimension_id uuid not null references public.place_dimensions(id) on delete cascade,
  event_type public.memory_event_type not null,
  actor_type text not null,
  actor_id uuid,
  previous_state public.dimension_state_value,
  new_state public.dimension_state_value,
  previous_pulse public.dimension_pulse_level,
  new_pulse public.dimension_pulse_level,
  observation_id uuid references public.observations(id) on delete set null,
  evidence_id uuid references public.evidence(id) on delete set null,
  barrier_signal_id uuid references public.barrier_signals(id) on delete set null,
  case_id uuid references public.cases(id) on delete set null,
  verification_id uuid references public.verifications(id) on delete set null,
  summary text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.prevent_memory_event_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'memory_events are append-only';
end;
$$;

create trigger memory_events_no_update
before update on public.memory_events
for each row execute function public.prevent_memory_event_mutation();

create trigger memory_events_no_delete
before delete on public.memory_events
for each row execute function public.prevent_memory_event_mutation();

create index organizations_type_idx on public.organizations(organization_type);
create index users_role_idx on public.users(role);
create index places_place_type_idx on public.places(place_type);
create index places_municipality_idx on public.places(municipality);
create index place_dimensions_place_id_idx on public.place_dimensions(place_id);
create index dimension_states_state_idx on public.dimension_states(state);
create index dimension_pulses_level_idx on public.dimension_pulses(level);
create index observations_place_dimension_id_idx on public.observations(place_dimension_id);
create index observations_created_at_idx on public.observations(created_at desc);
create index evidence_place_dimension_id_idx on public.evidence(place_dimension_id);
create index barrier_signals_place_dimension_id_idx on public.barrier_signals(place_dimension_id);
create index cases_place_dimension_id_idx on public.cases(place_dimension_id);
create index cases_status_idx on public.cases(status);
create index verifications_case_id_idx on public.verifications(case_id);
create index memory_events_place_dimension_created_idx on public.memory_events(place_dimension_id, created_at desc);
