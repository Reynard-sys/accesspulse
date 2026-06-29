insert into public.organizations (
  id,
  name,
  organization_type,
  jurisdiction
) values
  (
    '10000000-0000-4000-8000-000000000001',
    'Quezon City Accessibility Desk',
    'lgu',
    'Quezon City'
  )
on conflict (id) do update set
  name = excluded.name,
  organization_type = excluded.organization_type,
  jurisdiction = excluded.jurisdiction;

insert into public.users (
  id,
  display_name,
  role,
  organization_id
) values
  (
    '20000000-0000-4000-8000-000000000001',
    'Demo Community Contributor',
    'community_user',
    null
  ),
  (
    '20000000-0000-4000-8000-000000000002',
    'Demo LGU Reviewer',
    'lgu_reviewer',
    '10000000-0000-4000-8000-000000000001'
  ),
  (
    '20000000-0000-4000-8000-000000000003',
    'Demo Inspector',
    'inspector',
    '10000000-0000-4000-8000-000000000001'
  )
on conflict (id) do update set
  display_name = excluded.display_name,
  role = excluded.role,
  organization_id = excluded.organization_id;

insert into public.accessibility_dimensions (
  id,
  key,
  name,
  description
) values (
  '30000000-0000-4000-8000-000000000001',
  'mobility_access',
  'Mobility Access',
  'Entrance, route, ramp, and doorway usability for independent wheelchair access.'
)
on conflict (key) do update set
  name = excluded.name,
  description = excluded.description;

insert into public.places (
  id,
  name,
  place_type,
  address,
  municipality,
  province,
  latitude,
  longitude
) values
  (
    '40000000-0000-4000-8000-000000000001',
    'Quezon City Hall Main Entrance',
    'public_service_building',
    'Elliptical Road, Diliman',
    'Quezon City',
    'Metro Manila',
    14.6509000,
    121.0509000
  ),
  (
    '40000000-0000-4000-8000-000000000002',
    'Public Hospital Main Entrance',
    'public_service_building',
    'East Avenue',
    'Quezon City',
    'Metro Manila',
    14.6413000,
    121.0487000
  ),
  (
    '40000000-0000-4000-8000-000000000003',
    'Transport Terminal Entrance',
    'public_service_building',
    'Commonwealth Avenue',
    'Quezon City',
    'Metro Manila',
    14.6861000,
    121.0862000
  )
on conflict (id) do update set
  name = excluded.name,
  place_type = excluded.place_type,
  address = excluded.address,
  municipality = excluded.municipality,
  province = excluded.province,
  latitude = excluded.latitude,
  longitude = excluded.longitude;

insert into public.place_dimensions (
  id,
  place_id,
  dimension_id,
  summary
) values
  (
    '50000000-0000-4000-8000-000000000001',
    '40000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001',
    'Mobility Access state for the main public entrance. Seeded as claimed accessible but stale for the demo.'
  ),
  (
    '50000000-0000-4000-8000-000000000002',
    '40000000-0000-4000-8000-000000000002',
    '30000000-0000-4000-8000-000000000001',
    'Mobility Access state for the hospital main entrance.'
  ),
  (
    '50000000-0000-4000-8000-000000000003',
    '40000000-0000-4000-8000-000000000003',
    '30000000-0000-4000-8000-000000000001',
    'Mobility Access state for the terminal entrance.'
  )
on conflict (place_id, dimension_id) do update set
  summary = excluded.summary;

insert into public.dimension_states (
  id,
  place_dimension_id,
  state,
  confidence,
  explanation,
  last_confirmed_at,
  source
) values
  (
    '60000000-0000-4000-8000-000000000001',
    '50000000-0000-4000-8000-000000000001',
    'claimed_accessible',
    0.580,
    'Existing public record claims entrance access, but the confirmation is old and should be refreshed.',
    '2026-04-15 09:00:00+08',
    'seed_public_record'
  ),
  (
    '60000000-0000-4000-8000-000000000002',
    '50000000-0000-4000-8000-000000000002',
    'reliable',
    0.760,
    'Recent community confirmations support independent entrance access.',
    '2026-06-20 14:30:00+08',
    'seed_community_confirmation'
  ),
  (
    '60000000-0000-4000-8000-000000000003',
    '50000000-0000-4000-8000-000000000003',
    'unknown',
    0.240,
    'The system does not currently know enough about independent wheelchair access at this entrance.',
    null,
    'seed_unknown'
  )
on conflict (place_dimension_id) do update set
  state = excluded.state,
  confidence = excluded.confidence,
  explanation = excluded.explanation,
  last_confirmed_at = excluded.last_confirmed_at,
  source = excluded.source,
  updated_at = now();

insert into public.dimension_pulses (
  id,
  place_dimension_id,
  level,
  score,
  supporting_observations_count,
  has_recent_verification,
  contradiction_flag,
  last_calculated_at,
  explanation
) values
  (
    '70000000-0000-4000-8000-000000000001',
    '50000000-0000-4000-8000-000000000001',
    'moderate',
    0.520,
    1,
    false,
    false,
    '2026-06-29 21:30:00+08',
    'Knowledge is still usable for the demo, but the last confirmation is old enough to invite a fresh visit update.'
  ),
  (
    '70000000-0000-4000-8000-000000000002',
    '50000000-0000-4000-8000-000000000002',
    'strong',
    0.810,
    3,
    false,
    false,
    '2026-06-29 21:30:00+08',
    'Recent supporting confirmations make this current Mobility Access knowledge relatively fresh.'
  ),
  (
    '70000000-0000-4000-8000-000000000003',
    '50000000-0000-4000-8000-000000000003',
    'weak',
    0.180,
    0,
    false,
    false,
    '2026-06-29 21:30:00+08',
    'No recent supporting observations are available, so this place needs community confirmation.'
  )
on conflict (place_dimension_id) do update set
  level = excluded.level,
  score = excluded.score,
  supporting_observations_count = excluded.supporting_observations_count,
  has_recent_verification = excluded.has_recent_verification,
  contradiction_flag = excluded.contradiction_flag,
  last_calculated_at = excluded.last_calculated_at,
  explanation = excluded.explanation;

insert into public.observations (
  id,
  place_dimension_id,
  submitted_by,
  visit_date,
  entrance_usable_independently,
  ramp_usable,
  needed_assistance,
  completed_purpose,
  note,
  outcome,
  created_at
) values
  (
    '80000000-0000-4000-8000-000000000001',
    '50000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    '2026-04-15',
    true,
    true,
    false,
    true,
    'Seeded old confirmation: entrance was reported usable independently at the time.',
    'positive',
    '2026-04-15 09:00:00+08'
  ),
  (
    '80000000-0000-4000-8000-000000000002',
    '50000000-0000-4000-8000-000000000002',
    '20000000-0000-4000-8000-000000000001',
    '2026-06-20',
    true,
    true,
    false,
    true,
    'Seeded recent confirmation: ramp and entrance were usable independently.',
    'positive',
    '2026-06-20 14:30:00+08'
  )
on conflict (id) do update set
  note = excluded.note,
  outcome = excluded.outcome;

insert into public.memory_events (
  id,
  place_dimension_id,
  event_type,
  actor_type,
  actor_id,
  previous_state,
  new_state,
  previous_pulse,
  new_pulse,
  observation_id,
  summary,
  metadata,
  created_at
) values
  (
    '90000000-0000-4000-8000-000000000001',
    '50000000-0000-4000-8000-000000000001',
    'state_seeded',
    'system',
    null,
    null,
    'claimed_accessible',
    null,
    'moderate',
    '80000000-0000-4000-8000-000000000001',
    'Initial Mobility Access state seeded from an older public record and supporting confirmation.',
    '{"demoRole":"stale starting point","dimension":"mobility_access"}'::jsonb,
    '2026-04-15 09:00:00+08'
  ),
  (
    '90000000-0000-4000-8000-000000000002',
    '50000000-0000-4000-8000-000000000002',
    'state_seeded',
    'system',
    null,
    null,
    'reliable',
    null,
    'strong',
    '80000000-0000-4000-8000-000000000002',
    'Initial Mobility Access state seeded from recent positive community confirmations.',
    '{"demoRole":"comparison reliable place","dimension":"mobility_access"}'::jsonb,
    '2026-06-20 14:30:00+08'
  ),
  (
    '90000000-0000-4000-8000-000000000003',
    '50000000-0000-4000-8000-000000000003',
    'state_seeded',
    'system',
    null,
    null,
    'unknown',
    null,
    'weak',
    null,
    'Initial Mobility Access state seeded as unknown because there is not enough current public knowledge.',
    '{"demoRole":"unknown place","dimension":"mobility_access"}'::jsonb,
    '2026-06-29 21:30:00+08'
  )
on conflict (id) do nothing;
