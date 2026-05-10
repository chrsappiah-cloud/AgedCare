-- Facilities
create table if not exists public.facilities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique not null,
  timezone text not null default 'Australia/Sydney',
  created_at timestamptz not null default now()
);

-- Staff users (linked to auth.users)
create table if not exists public.staff_users (
  id uuid primary key references auth.users(id) on delete cascade,
  facility_id uuid not null references public.facilities(id) on delete cascade,
  role text not null check (role in ('admin','rn','carer','physio','psych','gp')),
  display_name text,
  created_at timestamptz not null default now()
);

-- Residents
create table if not exists public.residents (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities(id) on delete cascade,
  external_cloudkit_id text,
  name text not null,
  date_of_birth date,
  risk_level text,
  mobility_profile text,
  created_at timestamptz not null default now()
);

-- Sensor events (motion + vitals)
create table if not exists public.sensor_events (
  id bigserial primary key,
  facility_id uuid not null references public.facilities(id) on delete cascade,
  resident_id uuid not null references public.residents(id) on delete cascade,
  type text not null,
  subtype text not null,
  metric text,
  timestamp timestamptz not null,
  confidence numeric,
  source_device_id text,
  payload jsonb,
  created_at timestamptz not null default now()
);
create index if not exists sensor_events_facility_ts_idx
  on public.sensor_events(facility_id, resident_id, timestamp);

-- Fall incidents
create table if not exists public.fall_incidents (
  id bigserial primary key,
  facility_id uuid not null references public.facilities(id) on delete cascade,
  resident_id uuid not null references public.residents(id) on delete cascade,
  detected_at timestamptz not null,
  resolved boolean not null default false,
  severity text,
  location_note text,
  vital_summary jsonb,
  payload jsonb,
  created_by uuid references public.staff_users(id),
  created_at timestamptz not null default now()
);
create index if not exists fall_incidents_facility_ts_idx
  on public.fall_incidents(facility_id, resident_id, detected_at);

-- Alerts
create table if not exists public.alerts (
  id bigserial primary key,
  facility_id uuid not null references public.facilities(id) on delete cascade,
  resident_id uuid not null references public.residents(id) on delete cascade,
  fall_incident_id bigint references public.fall_incidents(id),
  type text not null,
  status text not null check (status in ('open','ack','closed')) default 'open',
  priority int not null default 3,
  created_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  closed_at timestamptz,
  assigned_to uuid references public.staff_users(id),
  notes text
);
create index if not exists alerts_facility_status_idx
  on public.alerts(facility_id, status, priority, created_at);

-- Subscriptions (for StoreKit integration later)
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities(id) on delete cascade,
  storekit_product_id text not null,
  status text not null check (status in ('active','past_due','canceled','trial')),
  seats int not null default 10,
  current_period_end timestamptz,
  created_at timestamptz not null default now()
);

-- Enable Row-Level Security
alter table public.staff_users enable row level security;
alter table public.facilities enable row level security;
alter table public.residents enable row level security;
alter table public.sensor_events enable row level security;
alter table public.fall_incidents enable row level security;
alter table public.alerts enable row level security;
alter table public.subscriptions enable row level security;

-- RLS policies
create policy "staff sees own staff_user" on public.staff_users
  for select using (id = auth.uid());

create policy "staff sees facility" on public.facilities
  for select using (
    id in (select facility_id from public.staff_users where id = auth.uid())
  );

create policy "facility residents read" on public.residents
  for select using (
    facility_id in (select facility_id from public.staff_users where id = auth.uid())
  );

create policy "facility sensor_events read" on public.sensor_events
  for select using (
    facility_id in (select facility_id from public.staff_users where id = auth.uid())
  );

create policy "facility fall_incidents read" on public.fall_incidents
  for select using (
    facility_id in (select facility_id from public.staff_users where id = auth.uid())
  );

create policy "facility alerts read" on public.alerts
  for select using (
    facility_id in (select facility_id from public.staff_users where id = auth.uid())
  );

create policy "clinical alerts write" on public.alerts
  for insert with check (
    facility_id in (select facility_id from public.staff_users where id = auth.uid())
  );

create policy "clinical incidents write" on public.fall_incidents
  for insert with check (
    facility_id in (select facility_id from public.staff_users where id = auth.uid())
  );

create policy "admin manage subscriptions" on public.subscriptions
  for all using (
    facility_id in (select facility_id from public.staff_users where id = auth.uid())
    and exists (
      select 1 from public.staff_users su
      where su.id = auth.uid() and su.role = 'admin'
    )
  );

-- Core RPCs
create or replace function public.create_fall_alert(
  p_facility_id uuid,
  p_resident_id uuid,
  p_priority int default 3
)
returns table (alert_id bigint)
language plpgsql
security definer
as $$
begin
  insert into public.alerts(facility_id, resident_id, type, status, priority)
  values (p_facility_id, p_resident_id, 'fall', 'open', p_priority)
  returning id into alert_id;
  return;
end;
$$;

create or replace function public.get_open_alerts_for_facility(
  p_facility_id uuid
)
returns table (
  id bigint,
  resident_id uuid,
  type text,
  status text,
  priority int,
  created_at timestamptz
)
language sql
security definer
as $$
  select id, resident_id, type, status, priority, created_at
  from public.alerts
  where facility_id = p_facility_id and status = 'open'
  order by priority desc, created_at desc;
$$;

create or replace function public.record_vital_event(
  p_facility_id uuid,
  p_resident_id uuid,
  p_metric text,
  p_value numeric,
  p_timestamp timestamptz
)
returns void
language sql
security definer
as $$
  insert into public.sensor_events(facility_id, resident_id, type, subtype, metric, timestamp, payload)
  values (p_facility_id, p_resident_id, 'vital', 'snapshot', p_metric, p_timestamp, jsonb_build_object('value', p_value));
$$;
