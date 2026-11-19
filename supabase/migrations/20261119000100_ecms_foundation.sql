-- ECMS foundation: identity, residences, occupancy, meters, and readings.
-- No demo or live household records are inserted by this migration.

create schema if not exists extensions;
create extension if not exists btree_gist with schema extensions;

create schema if not exists ecms_private;
revoke all on schema ecms_private from public, anon, authenticated;
grant usage on schema ecms_private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  role text not null default 'resident'
    check (role in ('resident', 'administrator', 'management')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.residences (
  id uuid primary key default gen_random_uuid(),
  area text not null check (length(btrim(area)) > 0),
  block text,
  house_code text not null unique check (length(btrim(house_code)) > 0),
  created_at timestamptz not null default now()
);

create table public.occupancies (
  id uuid primary key default gen_random_uuid(),
  residence_id uuid not null references public.residences (id) on delete restrict,
  resident_id uuid not null references public.profiles (id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  constraint occupancies_valid_period check (ends_at is null or ends_at > starts_at),
  -- A resident account cannot be assigned to overlapping residence periods.
  constraint occupancies_no_resident_overlap exclude using gist (
    resident_id with =,
    tstzrange(starts_at, coalesce(ends_at, 'infinity'::timestamptz), '[)') with &&
  )
);

create table public.administrator_residences (
  administrator_id uuid not null references public.profiles (id) on delete cascade,
  residence_id uuid not null references public.residences (id) on delete cascade,
  assigned_at timestamptz not null default now(),
  primary key (administrator_id, residence_id)
);

create table public.meters (
  id uuid primary key default gen_random_uuid(),
  serial_number text not null unique check (length(btrim(serial_number)) > 0),
  label text,
  status text not null default 'active' check (status in ('active', 'inactive', 'maintenance')),
  expected_interval_minutes integer not null default 15
    check (expected_interval_minutes between 1 and 1440),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.meter_assignments (
  id uuid primary key default gen_random_uuid(),
  meter_id uuid not null references public.meters (id) on delete restrict,
  residence_id uuid not null references public.residences (id) on delete restrict,
  valid_from timestamptz not null,
  valid_to timestamptz,
  created_at timestamptz not null default now(),
  constraint meter_assignments_valid_period check (valid_to is null or valid_to > valid_from),
  -- Preserve history while preventing one meter from serving two residences at once.
  constraint meter_assignments_no_meter_overlap exclude using gist (
    meter_id with =,
    tstzrange(valid_from, coalesce(valid_to, 'infinity'::timestamptz), '[)') with &&
  )
);

create table public.meter_readings (
  id uuid primary key default gen_random_uuid(),
  meter_id uuid not null references public.meters (id) on delete restrict,
  observed_at timestamptz not null,
  received_at timestamptz not null default now(),
  cumulative_kwh numeric(14, 3) not null check (cumulative_kwh >= 0),
  source text not null check (source in ('manual', 'csv', 'device', 'simulated')),
  idempotency_key text not null check (length(btrim(idempotency_key)) > 0),
  status text not null default 'received'
    check (status in ('received', 'accepted', 'needs_review', 'rejected')),
  validation_reason text,
  voltage_v numeric(8, 2) check (voltage_v is null or voltage_v >= 0),
  current_a numeric(8, 3) check (current_a is null or current_a >= 0),
  power_w numeric(10, 2) check (power_w is null or power_w >= 0),
  recorded_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint meter_readings_idempotent unique (meter_id, idempotency_key)
);

create index occupancies_resident_period_idx
  on public.occupancies (resident_id, starts_at desc, ends_at);
create index occupancies_residence_period_idx
  on public.occupancies (residence_id, starts_at desc, ends_at);
create index administrator_residences_residence_idx
  on public.administrator_residences (residence_id, administrator_id);
create index meter_assignments_residence_period_idx
  on public.meter_assignments (residence_id, valid_from desc, valid_to);
create index meter_readings_meter_observed_idx
  on public.meter_readings (meter_id, observed_at desc);
create index meter_readings_status_received_idx
  on public.meter_readings (status, received_at desc)
  where status in ('received', 'needs_review', 'rejected');

-- New Auth users receive a resident profile. Privileged roles are never read
-- from user-supplied Auth metadata and must be assigned by a trusted operator.
create function ecms_private.create_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(btrim(coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', '')), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created_ecms_profile
  after insert on auth.users
  for each row execute function ecms_private.create_profile_for_auth_user();

-- Definer helpers keep authorization checks out of recursive RLS queries.
create function ecms_private.has_residence_access(p_residence_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and (
        (p.role = 'administrator' and exists (
          select 1 from public.administrator_residences ar
          where ar.administrator_id = p.id and ar.residence_id = p_residence_id
        ))
        or (p.role = 'resident' and exists (
          select 1 from public.occupancies o
          where o.resident_id = p.id
            and o.residence_id = p_residence_id
            and o.starts_at <= now()
        ))
      )
  );
$$;

create function ecms_private.is_assigned_administrator(p_residence_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.administrator_residences ar
    join public.profiles p on p.id = ar.administrator_id
    where ar.administrator_id = (select auth.uid())
      and ar.residence_id = p_residence_id
      and p.role = 'administrator'
  );
$$;

create function ecms_private.can_read_profile(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_profile_id = (select auth.uid())
    or exists (
      select 1
      from public.profiles admin_profile
      join public.administrator_residences ar on ar.administrator_id = admin_profile.id
      join public.occupancies o on o.residence_id = ar.residence_id
      where admin_profile.id = (select auth.uid())
        and admin_profile.role = 'administrator'
        and o.resident_id = p_profile_id
    );
$$;

create function ecms_private.can_read_meter(p_meter_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    join public.meter_assignments ma on ma.meter_id = p_meter_id
    where p.id = (select auth.uid())
      and ma.valid_from <= now()
      and (
        (p.role = 'administrator' and exists (
          select 1 from public.administrator_residences ar
          where ar.administrator_id = p.id and ar.residence_id = ma.residence_id
        ))
        or (p.role = 'resident' and exists (
          select 1 from public.occupancies o
          where o.resident_id = p.id
            and o.residence_id = ma.residence_id
            and o.starts_at < coalesce(ma.valid_to, 'infinity'::timestamptz)
            and coalesce(o.ends_at, 'infinity'::timestamptz) > ma.valid_from
        ))
      )
  );
$$;

create function ecms_private.can_read_meter_reading(p_meter_id uuid, p_observed_at timestamptz)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    join public.meter_assignments ma on ma.meter_id = p_meter_id
    where p.id = (select auth.uid())
      and ma.valid_from <= p_observed_at
      and (ma.valid_to is null or ma.valid_to > p_observed_at)
      and (
        (p.role = 'administrator' and exists (
          select 1 from public.administrator_residences ar
          where ar.administrator_id = p.id and ar.residence_id = ma.residence_id
        ))
        or (p.role = 'resident' and exists (
          select 1 from public.occupancies o
          where o.resident_id = p.id
            and o.residence_id = ma.residence_id
            and o.starts_at <= p_observed_at
            and (o.ends_at is null or o.ends_at > p_observed_at)
        ))
      )
  );
$$;

-- Management gets aggregate area/day totals only. It has no RLS policies or
-- direct grants on household-level tables and cannot select a residence or meter.
create function public.management_daily_usage(p_from timestamptz, p_to timestamptz)
returns table (area text, usage_date date, total_kwh numeric)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'management'
  ) then
    raise exception using errcode = '42501', message = 'Management role required';
  end if;

  if p_from is null or p_to is null or p_from >= p_to or p_to - p_from > interval '366 days' then
    raise exception using errcode = '22023', message = 'Provide a valid range of at most 366 days';
  end if;

  return query
  with ordered_readings as (
    select
      r.meter_id,
      r.observed_at,
      r.cumulative_kwh,
      lag(r.cumulative_kwh) over (partition by r.meter_id order by r.observed_at, r.id) as previous_kwh
    from public.meter_readings r
    where r.status = 'accepted'
  ), interval_usage as (
    select
      ma.residence_id,
      (o.observed_at at time zone 'Africa/Lagos')::date as local_day,
      o.cumulative_kwh - o.previous_kwh as kwh
    from ordered_readings o
    join public.meter_assignments ma
      on ma.meter_id = o.meter_id
      and ma.valid_from <= o.observed_at
      and (ma.valid_to is null or ma.valid_to > o.observed_at)
    where o.previous_kwh is not null
      and o.cumulative_kwh >= o.previous_kwh
      and o.observed_at >= p_from
      and o.observed_at < p_to
  )
  select res.area, iu.local_day, sum(iu.kwh)::numeric
  from interval_usage iu
  join public.residences res on res.id = iu.residence_id
  group by res.area, iu.local_day
  having count(distinct iu.residence_id) >= 5
  order by res.area, iu.local_day;
end;
$$;

revoke all on function ecms_private.create_profile_for_auth_user() from public, anon, authenticated;
revoke all on function ecms_private.has_residence_access(uuid) from public, anon;
revoke all on function ecms_private.is_assigned_administrator(uuid) from public, anon;
revoke all on function ecms_private.can_read_profile(uuid) from public, anon;
revoke all on function ecms_private.can_read_meter(uuid) from public, anon;
revoke all on function ecms_private.can_read_meter_reading(uuid, timestamptz) from public, anon;
grant execute on function ecms_private.has_residence_access(uuid) to authenticated;
grant execute on function ecms_private.is_assigned_administrator(uuid) to authenticated;
grant execute on function ecms_private.can_read_profile(uuid) to authenticated;
grant execute on function ecms_private.can_read_meter(uuid) to authenticated;
grant execute on function ecms_private.can_read_meter_reading(uuid, timestamptz) to authenticated;
revoke all on function public.management_daily_usage(timestamptz, timestamptz) from public, anon;
grant execute on function public.management_daily_usage(timestamptz, timestamptz) to authenticated;
grant usage on schema public to authenticated;

alter table public.profiles enable row level security;
alter table public.residences enable row level security;
alter table public.occupancies enable row level security;
alter table public.administrator_residences enable row level security;
alter table public.meters enable row level security;
alter table public.meter_assignments enable row level security;
alter table public.meter_readings enable row level security;

-- Management intentionally receives no policies on household-level tables.
create policy profiles_read_self_or_assigned_admin
  on public.profiles for select to authenticated
  using (ecms_private.can_read_profile(id));
create policy profiles_update_own_display_name
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy residences_read_authorized_residents_and_admins
  on public.residences for select to authenticated
  using (ecms_private.has_residence_access(id));
create policy residences_insert_admin
  on public.residences for insert to authenticated
  with check (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'administrator'
  ));
create policy residences_update_assigned_admin
  on public.residences for update to authenticated
  using (ecms_private.is_assigned_administrator(id))
  with check (ecms_private.is_assigned_administrator(id));
create policy residences_delete_assigned_admin
  on public.residences for delete to authenticated
  using (ecms_private.is_assigned_administrator(id));

create policy occupancies_read_self_or_assigned_admin
  on public.occupancies for select to authenticated
  using (
    resident_id = (select auth.uid())
    or ecms_private.has_residence_access(residence_id)
  );
create policy occupancies_insert_assigned_admin
  on public.occupancies for insert to authenticated
  with check (ecms_private.is_assigned_administrator(residence_id));
create policy occupancies_update_assigned_admin
  on public.occupancies for update to authenticated
  using (ecms_private.is_assigned_administrator(residence_id))
  with check (ecms_private.is_assigned_administrator(residence_id));
create policy occupancies_delete_assigned_admin
  on public.occupancies for delete to authenticated
  using (ecms_private.is_assigned_administrator(residence_id));

create policy administrator_residences_read_own_assignments
  on public.administrator_residences for select to authenticated
  using (administrator_id = (select auth.uid()));

create policy meters_read_via_residence_assignment
  on public.meters for select to authenticated
  using (ecms_private.can_read_meter(id));
create policy meters_insert_assigned_admin
  on public.meters for insert to authenticated
  with check (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'administrator'
  ));
create policy meters_update_assigned_admin
  on public.meters for update to authenticated
  using (exists (
    select 1 from public.meter_assignments ma
    where ma.meter_id = meters.id and ecms_private.is_assigned_administrator(ma.residence_id)
  ))
  with check (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'administrator'
  ));
create policy meters_delete_assigned_admin
  on public.meters for delete to authenticated
  using (exists (
    select 1 from public.meter_assignments ma
    where ma.meter_id = meters.id and ecms_private.is_assigned_administrator(ma.residence_id)
  ));

create policy meter_assignments_read_authorized_residence
  on public.meter_assignments for select to authenticated
  using (
    ecms_private.is_assigned_administrator(residence_id)
    or exists (
      select 1 from public.occupancies o
      where o.resident_id = (select auth.uid())
        and o.residence_id = meter_assignments.residence_id
        and o.starts_at < coalesce(meter_assignments.valid_to, 'infinity'::timestamptz)
        and coalesce(o.ends_at, 'infinity'::timestamptz) > meter_assignments.valid_from
    )
  );
create policy meter_assignments_insert_assigned_admin
  on public.meter_assignments for insert to authenticated
  with check (ecms_private.is_assigned_administrator(residence_id));
create policy meter_assignments_update_assigned_admin
  on public.meter_assignments for update to authenticated
  using (ecms_private.is_assigned_administrator(residence_id))
  with check (ecms_private.is_assigned_administrator(residence_id));
create policy meter_assignments_delete_assigned_admin
  on public.meter_assignments for delete to authenticated
  using (ecms_private.is_assigned_administrator(residence_id));

create policy meter_readings_read_scoped_by_observed_time
  on public.meter_readings for select to authenticated
  using (ecms_private.can_read_meter_reading(meter_id, observed_at));

-- Explicit client grants; readings and administrator assignments are read-only
-- to application clients until validated ingestion and role-management RPCs exist.
revoke all on table
  public.profiles,
  public.residences,
  public.occupancies,
  public.administrator_residences,
  public.meters,
  public.meter_assignments,
  public.meter_readings
from public, anon, authenticated;

grant select on table
  public.profiles,
  public.residences,
  public.occupancies,
  public.administrator_residences,
  public.meters,
  public.meter_assignments,
  public.meter_readings
to authenticated;
grant update (display_name) on public.profiles to authenticated;
grant insert, update, delete on public.residences to authenticated;
grant insert, update, delete on public.occupancies to authenticated;
grant insert, update, delete on public.meters to authenticated;
grant insert, update, delete on public.meter_assignments to authenticated;

