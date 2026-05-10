-- AI Media Monitoring & Audio Analysis System
-- Tracks AI-generated insights from uploaded media and real-time audio monitoring

-- Analysis results for uploaded media (photos, audio, video)
CREATE TABLE IF NOT EXISTS public.media_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES public.facilities(id) ON DELETE CASCADE,
  resident_id UUID REFERENCES public.residents(id) ON DELETE SET NULL,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('photo', 'audio', 'video')),
  alert_id BIGINT REFERENCES public.alerts(id) ON DELETE SET NULL,
  analysis_status TEXT NOT NULL DEFAULT 'pending' CHECK (analysis_status IN ('pending', 'processing', 'completed', 'failed')),
  summary TEXT,
  confidence REAL DEFAULT 0.0,
  insights JSONB DEFAULT '[]'::jsonb,
  detected_keywords JSONB DEFAULT '[]'::jsonb,
  sentiment TEXT,
  safety_flags JSONB DEFAULT '[]'::jsonb,
  transcribed_text TEXT,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- Audio monitoring sessions for real-time listening
CREATE TABLE IF NOT EXISTS public.audio_monitoring_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES public.facilities(id) ON DELETE CASCADE,
  resident_id UUID REFERENCES public.residents(id) ON DELETE CASCADE,
  started_by UUID REFERENCES public.staff_users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'stopped')),
  device_id TEXT,
  ambient_level REAL DEFAULT 0.0,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  stopped_at TIMESTAMPTZ,
  last_event_at TIMESTAMPTZ
);

-- Events detected during audio monitoring
CREATE TABLE IF NOT EXISTS public.audio_monitoring_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.audio_monitoring_sessions(id) ON DELETE CASCADE,
  facility_id UUID NOT NULL REFERENCES public.facilities(id) ON DELETE CASCADE,
  resident_id UUID REFERENCES public.residents(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL CHECK (event_type IN (
    'keyword_detected', 'distress_sound', 'fall_sound', 'silence_anomaly',
    'loud_noise', 'call_for_help', 'medication_reminder', 'unknown'
  )),
  keyword TEXT,
  confidence REAL DEFAULT 0.0,
  transcript_snippet TEXT,
  audio_level REAL,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  acknowledged BOOLEAN NOT NULL DEFAULT false,
  acknowledged_by UUID REFERENCES public.staff_users(id) ON DELETE SET NULL,
  alert_id BIGINT REFERENCES public.alerts(id) ON DELETE SET NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_media_analysis_facility ON public.media_analysis(facility_id);
CREATE INDEX IF NOT EXISTS idx_media_analysis_resident ON public.media_analysis(resident_id);
CREATE INDEX IF NOT EXISTS idx_media_analysis_status ON public.media_analysis(analysis_status);
CREATE INDEX IF NOT EXISTS idx_media_analysis_created ON public.media_analysis(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audio_sessions_facility ON public.audio_monitoring_sessions(facility_id);
CREATE INDEX IF NOT EXISTS idx_audio_sessions_status ON public.audio_monitoring_sessions(status);
CREATE INDEX IF NOT EXISTS idx_audio_events_session ON public.audio_monitoring_events(session_id);
CREATE INDEX IF NOT EXISTS idx_audio_events_facility ON public.audio_monitoring_events(facility_id);
CREATE INDEX IF NOT EXISTS idx_audio_events_detected ON public.audio_monitoring_events(detected_at DESC);

-- Enable RLS
ALTER TABLE public.media_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audio_monitoring_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audio_monitoring_events ENABLE ROW LEVEL SECURITY;

-- RLS policies: staff can see their own facility's data
CREATE POLICY "Staff can view media analysis for their facility"
  ON public.media_analysis FOR SELECT
  USING (
    facility_id IN (
      SELECT facility_id FROM public.staff_users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Staff can insert media analysis for their facility"
  ON public.media_analysis FOR INSERT
  WITH CHECK (
    facility_id IN (
      SELECT facility_id FROM public.staff_users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Staff can view audio sessions for their facility"
  ON public.audio_monitoring_sessions FOR SELECT
  USING (
    facility_id IN (
      SELECT facility_id FROM public.staff_users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Staff can manage audio sessions for their facility"
  ON public.audio_monitoring_sessions FOR INSERT
  WITH CHECK (
    facility_id IN (
      SELECT facility_id FROM public.staff_users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Staff can view audio events for their facility"
  ON public.audio_monitoring_events FOR SELECT
  USING (
    facility_id IN (
      SELECT facility_id FROM public.staff_users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Staff can insert audio events for their facility"
  ON public.audio_monitoring_events FOR INSERT
  WITH CHECK (
    facility_id IN (
      SELECT facility_id FROM public.staff_users WHERE id = auth.uid()
    )
  );

-- RPCs for the monitoring system

CREATE OR REPLACE FUNCTION public.get_media_insights(
  p_facility_id UUID,
  p_limit INT DEFAULT 20,
  p_status TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_agg(sub ORDER BY sub->>'created_at' DESC)
  INTO result
  FROM (
    SELECT jsonb_build_object(
      'id', ma.id,
      'facility_id', ma.facility_id,
      'resident_id', ma.resident_id,
      'resident_name', r.name,
      'media_url', ma.media_url,
      'media_type', ma.media_type,
      'analysis_status', ma.analysis_status,
      'summary', ma.summary,
      'confidence', ma.confidence,
      'insights', ma.insights,
      'detected_keywords', ma.detected_keywords,
      'sentiment', ma.sentiment,
      'safety_flags', ma.safety_flags,
      'transcribed_text', ma.transcribed_text,
      'created_at', ma.created_at,
      'completed_at', ma.completed_at
    )
    FROM public.media_analysis ma
    LEFT JOIN public.residents r ON r.id = ma.resident_id
    WHERE ma.facility_id = p_facility_id
      AND (p_status IS NULL OR ma.analysis_status = p_status)
    ORDER BY ma.created_at DESC
    LIMIT p_limit
  ) sub;
  RETURN COALESCE(result, '[]'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_audio_monitoring_summary(
  p_facility_id UUID,
  p_limit INT DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_agg(sub ORDER BY sub->>'started_at' DESC)
  INTO result
  FROM (
    SELECT jsonb_build_object(
      'id', s.id,
      'facility_id', s.facility_id,
      'resident_id', s.resident_id,
      'resident_name', r.name,
      'status', s.status,
      'started_at', s.started_at,
      'stopped_at', s.stopped_at,
      'last_event_at', s.last_event_at,
      'event_count', (SELECT COUNT(*)::int FROM public.audio_monitoring_events e WHERE e.session_id = s.id),
      'critical_events', (SELECT COUNT(*)::int FROM public.audio_monitoring_events e WHERE e.session_id = s.id AND e.event_type IN ('distress_sound', 'fall_sound', 'call_for_help'))
    )
    FROM public.audio_monitoring_sessions s
    LEFT JOIN public.residents r ON r.id = s.resident_id
    WHERE s.facility_id = p_facility_id
    ORDER BY s.started_at DESC
    LIMIT p_limit
  ) sub;
  RETURN COALESCE(result, '[]'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_active_audio_events(
  p_facility_id UUID,
  p_since TIMESTAMPTZ DEFAULT now() - interval '24 hours'
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_agg(sub ORDER BY sub->>'detected_at' DESC)
  INTO result
  FROM (
    SELECT jsonb_build_object(
      'id', e.id,
      'session_id', e.session_id,
      'facility_id', e.facility_id,
      'resident_id', e.resident_id,
      'resident_name', r.name,
      'event_type', e.event_type,
      'keyword', e.keyword,
      'confidence', e.confidence,
      'transcript_snippet', e.transcript_snippet,
      'audio_level', e.audio_level,
      'detected_at', e.detected_at,
      'acknowledged', e.acknowledged
    )
    FROM public.audio_monitoring_events e
    LEFT JOIN public.residents r ON r.id = e.resident_id
    WHERE e.facility_id = p_facility_id
      AND e.detected_at >= p_since
    ORDER BY e.detected_at DESC
  ) sub;
  RETURN COALESCE(result, '[]'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION public.acknowledge_audio_event(
  p_event_id UUID,
  p_staff_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.audio_monitoring_events
  SET acknowledged = true, acknowledged_by = p_staff_id
  WHERE id = p_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_audio_monitoring_session(
  p_facility_id UUID,
  p_resident_id UUID DEFAULT NULL,
  p_started_by UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  session_id UUID;
BEGIN
  INSERT INTO public.audio_monitoring_sessions (facility_id, resident_id, started_by)
  VALUES (p_facility_id, p_resident_id, p_started_by)
  RETURNING id INTO session_id;
  RETURN jsonb_build_object('id', session_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.stop_audio_monitoring_session(
  p_session_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.audio_monitoring_sessions
  SET status = 'stopped', stopped_at = now()
  WHERE id = p_session_id;
END;
$$;
