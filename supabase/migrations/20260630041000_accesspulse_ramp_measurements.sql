do $$
begin
  create type public.ramp_measurement_status as enum (
    'captured',
    'lowQuality',
    'failed',
    'fallback',
    'discarded'
  );
exception
  when duplicate_object then null;
end
$$;

create table if not exists public.ramp_measurements (
  id uuid primary key default gen_random_uuid(),
  evidence_id uuid not null unique references public.evidence(id) on delete cascade,
  observation_id uuid references public.observations(id) on delete set null,
  place_dimension_id uuid not null references public.place_dimensions(id) on delete cascade,
  submitted_by uuid references public.users(id) on delete set null,
  estimated_angle_degrees numeric(5, 2) not null check (estimated_angle_degrees >= 0 and estimated_angle_degrees <= 90),
  quality_score integer not null check (quality_score >= 0 and quality_score <= 100),
  quality_label text not null,
  capture_duration_ms integer not null check (capture_duration_ms >= 0),
  sample_count integer not null check (sample_count >= 0),
  status public.ramp_measurement_status not null,
  source text not null,
  captured_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists ramp_measurements_place_dimension_created_idx
on public.ramp_measurements(place_dimension_id, created_at desc);

create index if not exists ramp_measurements_evidence_id_idx
on public.ramp_measurements(evidence_id);
