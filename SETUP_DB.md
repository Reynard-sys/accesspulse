# Supabase Database Setup

Use this guide when setting up the AccessPulse MVP database manually through the Supabase SQL Editor.

## Prerequisites

- A Supabase project
- Access to the project dashboard
- The SQL files in this repository:
  - `supabase/migrations/20260629133000_accesspulse_mvp_schema.sql`
  - `supabase/seed.sql`

## Step 1 - Open SQL Editor

1. Open your Supabase project dashboard.
2. In the left sidebar, select **SQL Editor**.
3. Click **New query**.

## Step 2 - Run the schema migration

1. Open `supabase/migrations/20260629133000_accesspulse_mvp_schema.sql` locally.
2. Copy the entire file contents.
3. Paste it into the Supabase SQL Editor.
4. Click **Run**.
5. Wait for the query to complete successfully.

This creates the AccessPulse MVP database structure, including:

- users and organizations
- places
- accessibility dimensions
- place dimensions
- dimension states
- dimension pulses
- observations
- evidence
- barrier signals
- cases
- verifications
- append-only memory events

## Step 3 - Run the seed data

1. Click **New query** again in the SQL Editor.
2. Open `supabase/seed.sql` locally.
3. Copy the entire file contents.
4. Paste it into the Supabase SQL Editor.
5. Click **Run**.
6. Wait for the query to complete successfully.

This seeds the demo data for:

- Quezon City Hall Main Entrance
- Public Hospital Main Entrance
- Transport Terminal Entrance
- Mobility Access dimension
- demo community user, LGU reviewer, and inspector
- initial state, pulse, observations, and memory events

## Step 4 - Verify seeded places

Run this query in the SQL Editor:

```sql
select
  p.name as place_name,
  ad.key as dimension_key,
  ds.state,
  ds.confidence,
  dp.level as pulse,
  dp.score as pulse_score,
  ds.last_confirmed_at
from public.place_dimensions pd
join public.places p on p.id = pd.place_id
join public.accessibility_dimensions ad on ad.id = pd.dimension_id
join public.dimension_states ds on ds.place_dimension_id = pd.id
join public.dimension_pulses dp on dp.place_dimension_id = pd.id
order by p.name;
```

Expected result:

- 3 rows
- all rows use `mobility_access`
- one place starts as `claimed_accessible` with `moderate` pulse
- one place starts as `reliable` with `strong` pulse
- one place starts as `unknown` with `weak` pulse

## Step 5 - Verify memory events

Run this query:

```sql
select
  p.name as place_name,
  me.event_type,
  me.new_state,
  me.new_pulse,
  me.summary,
  me.created_at
from public.memory_events me
join public.place_dimensions pd on pd.id = me.place_dimension_id
join public.places p on p.id = pd.place_id
order by me.created_at;
```

Expected result:

- at least 3 rows
- each seeded place has an initial memory event
- memory describes how the initial Mobility Access state was created

## Step 6 - Optional append-only memory check

Run this only if you want to confirm that memory events cannot be edited:

```sql
update public.memory_events
set summary = 'test update'
where id = '90000000-0000-4000-8000-000000000001';
```

Expected result:

- the query fails
- the error says `memory_events are append-only`

After this check, no cleanup is needed because the update should not succeed.

## If setup fails

If the schema migration fails because a type, table, or trigger already exists, the database may have a partial previous setup. For the hackathon MVP, the simplest fix is to create a fresh Supabase project and rerun the schema migration followed by the seed script.

If the seed script fails, confirm that the schema migration completed first. The seed data depends on the enum types and tables created by the migration.
