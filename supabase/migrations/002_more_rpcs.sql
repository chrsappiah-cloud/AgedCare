-- Acknowledge an alert
create or replace function public.acknowledge_alert(
  p_alert_id bigint,
  p_staff_id uuid
)
returns void
language sql
security definer
as $$
  update public.alerts
  set status = 'ack', acknowledged_at = now(), assigned_to = p_staff_id
  where id = p_alert_id;
$$;

-- Close an alert with optional notes
create or replace function public.close_alert(
  p_alert_id bigint,
  p_notes text default ''
)
returns void
language sql
security definer
as $$
  update public.alerts
  set status = 'closed', closed_at = now(), notes = coalesce(p_notes, notes)
  where id = p_alert_id;
$$;

-- Create a manual SOS alert
create or replace function public.create_sos_alert(
  p_facility_id uuid,
  p_resident_id uuid
)
returns table (alert_id bigint)
language plpgsql
security definer
as $$
begin
  insert into public.alerts(facility_id, resident_id, type, status, priority)
  values (p_facility_id, p_resident_id, 'manualSOS', 'open', 1)
  returning id into alert_id;
  return;
end;
$$;

-- Get residents for a facility (returns JSON)
create or replace function public.get_residents_for_facility(
  p_facility_id uuid
)
returns jsonb
language sql
security definer
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', id,
    'facility_id', facility_id,
    'name', name,
    'risk_level', risk_level,
    'date_of_birth', date_of_birth
  ) order by name), '[]'::jsonb)
  from public.residents
  where facility_id = p_facility_id;
$$;

-- Get fall count summary for a resident
create or replace function public.get_fall_summary_for_resident(
  p_resident_id uuid,
  p_days int default 7
)
returns int
language sql
security definer
as $$
  select count(*)::int
  from public.fall_incidents
  where resident_id = p_resident_id
    and detected_at >= now() - (p_days || ' days')::interval;
$$;

-- Get resident timeline (falls + vitals)
create or replace function public.get_resident_timeline(
  p_resident_id uuid,
  p_limit int default 50
)
returns jsonb
language sql
security definer
as $$
  select coalesce(jsonb_agg(sub order by sub.ts desc), '[]'::jsonb)
  from (
    select
      'fall' as kind,
      detected_at as ts,
      'Fall detected' as summary
    from public.fall_incidents
    where resident_id = p_resident_id
    union all
    select
      'vital' as kind,
      timestamp as ts,
      metric || ': ' || (payload->>'value') as summary
    from public.sensor_events
    where resident_id = p_resident_id and type = 'vital'
    order by ts desc
    limit p_limit
  ) sub;
$$;

-- Facility stats for last 7 days
create or replace function public.get_facility_stats(
  p_facility_id uuid
)
returns jsonb
language sql
security definer
as $$
  select jsonb_build_object(
    'falls_last_7d', (select count(*)::int from public.fall_incidents
                      where facility_id = p_facility_id
                        and detected_at >= now() - interval '7 days'),
    'open_alerts', (select count(*)::int from public.alerts
                    where facility_id = p_facility_id and status = 'open'),
    'avg_acknowledge_minutes', (select coalesce(round(avg(extract(epoch from (acknowledged_at - created_at)) / 60)), 0)::int
                                from public.alerts
                                where facility_id = p_facility_id
                                  and acknowledged_at is not null
                                  and created_at >= now() - interval '30 days')
  );
$$;
