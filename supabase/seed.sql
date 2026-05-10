-- Seed data for local development
-- Run: psql -d agedcare_prod -f supabase/seed.sql

-- Facility
INSERT INTO public.facilities (id, name, code, timezone)
VALUES ('f0000000-0000-4000-a000-000000000001', 'Green Valley Aged Care', 'GV-01', 'Australia/Sydney')
ON CONFLICT (id) DO NOTHING;

-- Auth users (password = "password" in plaintext for dev only)
INSERT INTO auth.users (id, email, password_hash)
VALUES
  ('a0000000-0000-4000-a000-000000000001', 'admin@gvcare.com', 'password'),
  ('a0000000-0000-4000-a000-000000000002', 'nurse@gvcare.com', 'password'),
  ('a0000000-0000-4000-a000-000000000003', 'carer@gvcare.com', 'password')
ON CONFLICT (id) DO NOTHING;

-- Staff users
INSERT INTO public.staff_users (id, facility_id, role, display_name)
VALUES
  ('a0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000001', 'admin', 'Dr. Sarah Chen'),
  ('a0000000-0000-4000-a000-000000000002', 'f0000000-0000-4000-a000-000000000001', 'rn', 'Nurse John Smith'),
  ('a0000000-0000-4000-a000-000000000003', 'f0000000-0000-4000-a000-000000000001', 'carer', 'Carer Emma Davis')
ON CONFLICT (id) DO NOTHING;

-- Residents
INSERT INTO public.residents (id, facility_id, name, date_of_birth, risk_level, mobility_profile)
VALUES
  ('f0000000-0000-4000-a000-000000000011', 'f0000000-0000-4000-a000-000000000001', 'Margaret Thatcher', '1935-10-13', 'high', 'walker'),
  ('f0000000-0000-4000-a000-000000000012', 'f0000000-0000-4000-a000-000000000001', 'Bob Hawke', '1929-12-09', 'medium', 'independent'),
  ('f0000000-0000-4000-a000-000000000013', 'f0000000-0000-4000-a000-000000000001', 'Nelson Mandela', '1918-07-18', 'high', 'wheelchair'),
  ('f0000000-0000-4000-a000-000000000014', 'f0000000-0000-4000-a000-000000000001', 'Diana Spencer', '1961-07-01', 'low', 'independent')
ON CONFLICT (id) DO NOTHING;

-- Fall incidents
INSERT INTO public.fall_incidents (facility_id, resident_id, detected_at, severity, location_note)
VALUES
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000011', now() - interval '1 day', 'moderate', 'Bathroom room 204'),
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000011', now() - interval '5 days', 'mild', 'Bedroom'),
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000013', now() - interval '3 days', 'severe', 'Common area near dining')
ON CONFLICT DO NOTHING;

-- Open alerts
INSERT INTO public.alerts (facility_id, resident_id, type, status, priority, created_at)
VALUES
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000011', 'fall', 'open', 3, now() - interval '1 day'),
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000013', 'fall', 'open', 3, now() - interval '3 days'),
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000012', 'vitaltrend', 'open', 2, now() - interval '6 hours'),
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000014', 'manualSOS', 'open', 1, now() - interval '30 minutes')
ON CONFLICT DO NOTHING;

-- Sensor events
INSERT INTO public.sensor_events (facility_id, resident_id, type, subtype, metric, timestamp, payload)
VALUES
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000012', 'vital', 'snapshot', 'heartRate', now() - interval '2 hours', '{"value": 78}'),
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000012', 'vital', 'snapshot', 'spo2', now() - interval '2 hours', '{"value": 97}'),
  ('f0000000-0000-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000014', 'vital', 'snapshot', 'heartRate', now() - interval '1 hour', '{"value": 72}')
ON CONFLICT DO NOTHING;
