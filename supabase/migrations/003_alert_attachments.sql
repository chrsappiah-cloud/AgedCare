-- Alert attachments (photos, voice notes, videos)

create table if not exists public.alert_attachments (
  id bigserial primary key,
  alert_id bigint not null references public.alerts(id) on delete cascade,
  attachment_type text not null check (attachment_type in ('photo', 'audio', 'video')),
  file_url text not null,
  filename text,
  created_at timestamptz not null default now()
);

create index if not exists alert_attachments_alert_id_idx
  on public.alert_attachments(alert_id);

alter table public.alert_attachments enable row level security;

create policy "facility alert_attachments read" on public.alert_attachments
  for select using (
    alert_id in (
      select a.id from public.alerts a
      where a.facility_id in (select facility_id from public.staff_users where id = auth.uid())
    )
  );

create policy "facility alert_attachments write" on public.alert_attachments
  for insert with check (
    alert_id in (
      select a.id from public.alerts a
      where a.facility_id in (select facility_id from public.staff_users where id = auth.uid())
    )
  );
