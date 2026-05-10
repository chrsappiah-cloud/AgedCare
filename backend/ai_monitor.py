"""
AI Media & Audio Monitoring Service for AgedCare.

Provides:
- Image analysis: safety checks, wellbeing scoring, object/scene detection (rule-based)
- Audio transcription & keyword spotting: distress calls, medication reminders, fall sounds
- Real-time monitoring session management
"""

import json
import uuid
import re
import random
import math
import time
from datetime import datetime, timezone
from typing import Optional
from bottle import route, run, request, response, HTTPResponse
import pg8000.native

DB_NAME = "agedcare_prod"
DB_USER = "christopherappiah-thompson"
DB_HOST = "localhost"
DB_PORT = 5432


def get_db():
    return pg8000.native.Connection(
        database=DB_NAME, user=DB_USER, host=DB_HOST, port=DB_PORT,
    )


def q(conn, sql, **params):
    return conn.run(sql, **params)


def json_response(data, status=200):
    response.content_type = "application/json"
    response.status = status
    return json.dumps(data, default=str)


# ---------------------------------------------------------------------------
# AI Analysis Engines (rule-based / mock; swap with real ML models later)
# ---------------------------------------------------------------------------

CAREGIVING_KEYWORDS = [
    "help", "pain", "fall", "hurt", "please", "nurse", "doctor",
    "water", "bathroom", "toilet", "cold", "hot", "hungry", "thirsty",
    "medicine", "medication", "pill", "afraid", "scared", "alone",
    "hello", "good morning", "thank you", "sorry",
]

DISTRESS_PATTERNS = [
    r"\bhelp\b", r"\b(?:call\s+(?:a\s+)?)?nurse\b",
    r"\b(?:i\s+)?(?:fell|falling|fallen)\b",
    r"\b(?:it\s+)?hurts?\b",
    r"\b(?:can't\s+(?:breathe|move|get\s+up))\b",
    r"\b(?:someone|anybody)\s+help\b",
]

EMERGENCY_SOUND_KEYWORDS = [
    "help me", "call nurse", "emergency", "fall", "can't get up",
    "somebody help", "please help", "i need help",
]

WELLBEING_PHRASES = [
    "good morning", "feeling good", "i'm okay", "thank you",
    "feeling better", "great", "wonderful",
]


def analyze_image(file_bytes: bytes, filename: str) -> dict:
    """Rule-based image analysis. Returns insights dict."""
    size_kb = len(file_bytes) / 1024

    insights = []
    safety_flags = []
    summary_parts = []

    if size_kb < 50:
        insights.append("Low resolution image — may be too small for detailed analysis")
    elif size_kb > 2000:
        safety_flags.append({"type": "large_file", "detail": "File size exceeds 2MB"})

    name_lower = filename.lower()
    if "fall" in name_lower or "injury" in name_lower or "wound" in name_lower:
        safety_flags.append({"type": "potential_injury", "detail": "Filename suggests injury documentation"})
        insights.append("Medical documentation detected — route for nurse review")
        summary_parts.append("potential injury documentation")
    elif "room" in name_lower:
        insights.append("Environment photo — check for hazards")
        summary_parts.append("environment photo")
    elif "meal" in name_lower or "food" in name_lower:
        insights.append("Meal photo — nutrition tracking")
        summary_parts.append("meal documentation")
    elif "medication" in name_lower or "medicine" in name_lower:
        insights.append("Medication verification — confirm dosage compliance")
        summary_parts.append("medication verification")
    else:
        insights.append("Routine photo — no immediate concerns detected")
        summary_parts.append("routine documentation")

    confidence = random.uniform(0.65, 0.95)
    sentiment = "neutral"
    if safety_flags:
        sentiment = "concern"
    elif any(w in name_lower for w in ["great", "happy", "good"]):
        sentiment = "positive"

    return {
        "summary": " | ".join(summary_parts) if summary_parts else "Photo reviewed by AI monitor",
        "confidence": round(confidence, 2),
        "insights": insights,
        "sentiment": sentiment,
        "safety_flags": safety_flags,
        "detected_keywords": [],
    }


def analyze_audio(transcribed_text: str, audio_level: float = 0.5) -> dict:
    """Analyze transcribed audio for distress keywords and wellbeing indicators."""
    text_lower = transcribed_text.lower()

    detected_keywords = []
    for kw in CAREGIVING_KEYWORDS:
        if kw in text_lower:
            detected_keywords.append(kw)

    distress_matches = []
    for pattern in DISTRESS_PATTERNS:
        if re.search(pattern, text_lower):
            distress_matches.append(pattern.replace("\\b", ""))

    safety_flags = []
    event_type = None
    event_keyword = None

    for phrase in EMERGENCY_SOUND_KEYWORDS:
        if phrase in text_lower:
            safety_flags.append({"type": "emergency_request", "detail": f"Detected distress phrase: '{phrase}'"})
            detected_keywords.append(phrase)
            event_type = "call_for_help"
            event_keyword = phrase
            break

    if not event_type and distress_matches:
        safety_flags.append({"type": "possible_distress", "detail": "Speech patterns suggest possible distress"})
        event_type = "distress_sound"
        event_keyword = distress_matches[0].strip()

    if "fall" in text_lower and any(w in text_lower for w in ["help", "down", "ground", "floor", "can't get up"]):
        safety_flags.append({"type": "fall_detected", "detail": "Audio suggests a possible fall event"})
        event_type = "fall_sound"
        event_keyword = "fall"

    wellbeing_words = sum(1 for w in WELLBEING_PHRASES if w in text_lower)
    sentiment = "positive" if wellbeing_words >= 2 else "concern" if safety_flags else "neutral"

    insights = []
    if safety_flags:
        insights.append(f"⚠ {len(safety_flags)} safety concern(s) detected in audio")
    if detected_keywords:
        key_insight = ", ".join(detected_keywords[:5])
        insights.append(f"Key terms detected: {key_insight}")
    if audio_level > 0.8:
        insights.append("High audio level detected — possible raised voice or noise")
    if not detected_keywords and not safety_flags:
        insights.append("Routine conversation — no immediate concerns")

    return {
        "summary": insights[0] if insights else "Audio analyzed by AI monitor",
        "confidence": round(random.uniform(0.7, 0.98), 2),
        "insights": insights,
        "sentiment": sentiment,
        "safety_flags": safety_flags,
        "detected_keywords": list(set(detected_keywords)),
        "event_type": event_type,
        "event_keyword": event_keyword,
    }


# ---------------------------------------------------------------------------
# API Endpoints
# ---------------------------------------------------------------------------

@route("/ai/analyze/media", method="POST")
def analyze_media():
    """Analyze uploaded media (base64). Returns insights immediately."""
    data = request.json or {}
    file_b64 = data.get("data_base64", "")
    filename = data.get("filename", "unknown")
    media_type = data.get("media_type", "photo")
    facility_id = data.get("facility_id")
    resident_id = data.get("resident_id")
    alert_id = data.get("alert_id")

    if not file_b64 or not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "missing data_base64 or facility_id"}))

    try:
        file_bytes = __import__("base64").b64decode(file_b64)
    except Exception as e:
        return HTTPResponse(status=400, body=json.dumps({"error": f"invalid base64: {e}"}))

    if media_type == "photo":
        result = analyze_image(file_bytes, filename)
    elif media_type == "audio":
        transcribed = data.get("transcribed_text", "[Simulated transcription of audio recording]")
        audio_level = data.get("audio_level", random.uniform(0.3, 0.7))
        result = analyze_audio(transcribed, audio_level)
    else:
        result = {
            "summary": "Video analysis not yet supported",
            "confidence": 0.0,
            "insights": [],
            "sentiment": "neutral",
            "safety_flags": [{"type": "unsupported", "detail": "Video analysis is not yet available"}],
            "detected_keywords": [],
        }

    analysis_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)

    conn = get_db()
    try:
        q(conn,
            "INSERT INTO public.media_analysis "
            "(id, facility_id, resident_id, media_url, media_type, alert_id, "
            " analysis_status, summary, confidence, insights, detected_keywords, "
            " sentiment, safety_flags, transcribed_text, completed_at) "
            "VALUES (:id, :fid, :rid, :url, :mtype, :aid, "
            " 'completed', :summary, :conf, :insights, :keywords, "
            " :sent, :flags, :transcript, :now)",
            id=analysis_id, fid=facility_id, rid=resident_id,
            url=data.get("media_url", ""), mtype=media_type, aid=alert_id,
            summary=result["summary"], conf=result["confidence"],
            insights=json.dumps(result["insights"]),
            keywords=json.dumps(result["detected_keywords"]),
            sent=result["sentiment"],
            flags=json.dumps(result["safety_flags"]),
            transcript=data.get("transcribed_text", ""),
            now=now)
    finally:
        conn.close()

    return json_response({
        "analysis_id": analysis_id,
        **result,
        "created_at": now.isoformat(),
    })


@route("/ai/analyze/audio/transcribe", method="POST")
def transcribe_audio():
    """Simulate audio transcription. Accepts base64 audio, returns mock transcript."""
    data = request.json or {}
    file_b64 = data.get("data_base64", "")

    if not file_b64:
        file_b64 = ""

    try:
        file_bytes = __import__("base64").b64decode(file_b64)
        duration = max(1.0, len(file_bytes) / 16000)
    except Exception:
        duration = 5.0

    mock_transcripts = [
        "Hello, is anyone there? I need some help please.",
        "Good morning nurse, I'm feeling much better today thank you.",
        "Help! I've fallen and I can't get up, please someone help me.",
        "Can I have some water please? I'm very thirsty.",
        "I need to go to the bathroom, can someone help me?",
        "My medication is due, has the nurse come yet?",
        "It's quiet in here today, everything seems fine.",
        "I think I need to see a doctor, I'm in a lot of pain.",
        "Thank you for coming, I appreciate your help.",
        "Is anyone there? Hello? I need assistance please.",
    ]

    transcript = random.choice(mock_transcripts)
    words_per_sec = len(transcript.split()) / duration

    result = analyze_audio(transcript, audio_level=min(1.0, duration / 30))

    return json_response({
        "transcript": transcript,
        "duration_seconds": round(duration, 1),
        "words_per_second": round(words_per_sec, 1),
        **result,
    })


@route("/ai/monitor/session/start", method="POST")
def start_monitoring_session():
    """Start an audio monitoring session for a facility/resident."""
    data = request.json or {}
    facility_id = data.get("facility_id")
    resident_id = data.get("resident_id")
    staff_id = data.get("started_by")

    if not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "facility_id required"}))

    session_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)

    conn = get_db()
    try:
        q(conn,
            "INSERT INTO public.audio_monitoring_sessions "
            "(id, facility_id, resident_id, started_by, status, started_at) "
            "VALUES (:id, :fid, :rid, :sid, 'active', :now)",
            id=session_id, fid=facility_id, rid=resident_id,
            sid=staff_id, now=now)
    finally:
        conn.close()

    return json_response({
        "session_id": session_id,
        "status": "active",
        "started_at": now.isoformat(),
    })


@route("/ai/monitor/session/<session_id>/stop", method="POST")
def stop_monitoring_session(session_id):
    """Stop an active monitoring session."""
    now = datetime.now(timezone.utc)
    conn = get_db()
    try:
        q(conn,
            "UPDATE public.audio_monitoring_sessions "
            "SET status = 'stopped', stopped_at = :now WHERE id = :sid",
            sid=session_id, now=now)
    finally:
        conn.close()
    return json_response({"session_id": session_id, "status": "stopped"})


@route("/ai/monitor/session/<session_id>/event", method="POST")
def report_monitoring_event(session_id):
    """Report a detected event from the monitoring session."""
    data = request.json or {}
    now = datetime.now(timezone.utc)

    conn = get_db()
    try:
        session_rows = q(conn,
            "SELECT facility_id FROM public.audio_monitoring_sessions WHERE id = :sid",
            sid=session_id)
        if not session_rows:
            return HTTPResponse(status=404, body=json.dumps({"error": "session not found"}))
        facility_id = session_rows[0][0]

        event_id = str(uuid.uuid4())
        q(conn,
            "INSERT INTO public.audio_monitoring_events "
            "(id, session_id, facility_id, resident_id, event_type, keyword, "
            " confidence, transcript_snippet, audio_level, detected_at) "
            "VALUES (:eid, :sid, :fid, :rid, :etype, :kw, "
            " :conf, :snippet, :level, :now)",
            eid=event_id, sid=session_id, fid=facility_id,
            rid=data.get("resident_id"), etype=data.get("event_type", "unknown"),
            kw=data.get("keyword"), conf=data.get("confidence", 0.0),
            snippet=data.get("transcript_snippet"),
            level=data.get("audio_level"), now=now)

        q(conn,
            "UPDATE public.audio_monitoring_sessions SET last_event_at = :now WHERE id = :sid",
            sid=session_id, now=now)
    finally:
        conn.close()

    return json_response({"event_id": event_id, "detected_at": now.isoformat()})


@route("/ai/monitor/session/<session_id>/events", method="GET")
def get_session_events(session_id):
    """Get all events for a monitoring session."""
    conn = get_db()
    try:
        rows = q(conn,
            "SELECT id, session_id, facility_id, resident_id, event_type, keyword, "
            "       confidence, transcript_snippet, audio_level, detected_at, acknowledged "
            "FROM public.audio_monitoring_events WHERE session_id = :sid ORDER BY detected_at DESC",
            sid=session_id)
        return json_response([{
            "id": str(r[0]), "session_id": str(r[1]), "facility_id": str(r[2]),
            "resident_id": str(r[3]) if r[3] else None,
            "event_type": r[4], "keyword": r[5], "confidence": r[6],
            "transcript_snippet": r[7], "audio_level": r[8],
            "detected_at": r[9].isoformat(), "acknowledged": r[10],
        } for r in rows])
    finally:
        conn.close()


@route("/ai/insights", method="POST")
def get_media_insights():
    """Get media analysis insights for a facility."""
    data = request.json or {}
    facility_id = data.get("facility_id")
    limit = data.get("limit", 20)
    status_filter = data.get("status")

    if not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "facility_id required"}))

    conn = get_db()
    try:
        rows = q(conn,
            "SELECT ma.id, ma.facility_id, ma.resident_id, r.name, "
            "       ma.media_url, ma.media_type, ma.analysis_status, "
            "       ma.summary, ma.confidence, ma.insights, ma.detected_keywords, "
            "       ma.sentiment, ma.safety_flags, ma.transcribed_text, "
            "       ma.created_at, ma.completed_at "
            "FROM public.media_analysis ma "
            "LEFT JOIN public.residents r ON r.id = ma.resident_id "
            "WHERE ma.facility_id = :fid "
            + ("AND ma.analysis_status = :status " if status_filter else "") +
            "ORDER BY ma.created_at DESC LIMIT :lim",
            fid=facility_id, status=status_filter, lim=limit) \
            if status_filter else \
            q(conn,
            "SELECT ma.id, ma.facility_id, ma.resident_id, r.name, "
            "       ma.media_url, ma.media_type, ma.analysis_status, "
            "       ma.summary, ma.confidence, ma.insights, ma.detected_keywords, "
            "       ma.sentiment, ma.safety_flags, ma.transcribed_text, "
            "       ma.created_at, ma.completed_at "
            "FROM public.media_analysis ma "
            "LEFT JOIN public.residents r ON r.id = ma.resident_id "
            "WHERE ma.facility_id = :fid "
            "ORDER BY ma.created_at DESC LIMIT :lim",
            fid=facility_id, lim=limit)
        return json_response([{
            "id": str(r[0]), "facility_id": str(r[1]),
            "resident_id": str(r[2]) if r[2] else None,
            "resident_name": r[3],
            "media_url": r[4], "media_type": r[5],
            "analysis_status": r[6], "summary": r[7],
            "confidence": r[8],
            "insights": json.loads(r[9]) if isinstance(r[9], str) else r[9],
            "detected_keywords": json.loads(r[10]) if isinstance(r[10], str) else r[10],
            "sentiment": r[11],
            "safety_flags": json.loads(r[12]) if isinstance(r[12], str) else r[12],
            "transcribed_text": r[13],
            "created_at": r[14].isoformat(),
            "completed_at": r[15].isoformat() if r[15] else None,
        } for r in rows])
    finally:
        conn.close()


@route("/ai/sessions", method="POST")
def get_monitoring_sessions():
    """Get monitoring session summaries for a facility."""
    data = request.json or {}
    facility_id = data.get("facility_id")
    limit = data.get("limit", 10)

    if not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "facility_id required"}))

    conn = get_db()
    try:
        rows = q(conn,
            "SELECT s.id, s.facility_id, s.resident_id, r.name, "
            "       s.status, s.started_at, s.stopped_at, s.last_event_at, "
            "       (SELECT COUNT(*)::int FROM public.audio_monitoring_events e WHERE e.session_id = s.id) as event_count, "
            "       (SELECT COUNT(*)::int FROM public.audio_monitoring_events e "
            "        WHERE e.session_id = s.id AND e.event_type IN ('distress_sound', 'fall_sound', 'call_for_help')) as critical_count "
            "FROM public.audio_monitoring_sessions s "
            "LEFT JOIN public.residents r ON r.id = s.resident_id "
            "WHERE s.facility_id = :fid "
            "ORDER BY s.started_at DESC LIMIT :lim",
            fid=facility_id, lim=limit)
        return json_response([{
            "id": str(r[0]), "facility_id": str(r[1]),
            "resident_id": str(r[2]) if r[2] else None,
            "resident_name": r[3],
            "status": r[4], "started_at": r[5].isoformat(),
            "stopped_at": r[6].isoformat() if r[6] else None,
            "last_event_at": r[7].isoformat() if r[7] else None,
            "event_count": r[8], "critical_events": r[9],
        } for r in rows])
    finally:
        conn.close()


@route("/ai/events/active", method="POST")
def get_recent_events():
    """Get recent monitoring events for a facility."""
    data = request.json or {}
    facility_id = data.get("facility_id")
    hours = data.get("hours", 24)

    if not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "facility_id required"}))

    conn = get_db()
    try:
        rows = q(conn,
            "SELECT e.id, e.session_id, e.facility_id, e.resident_id, r.name, "
            "       e.event_type, e.keyword, e.confidence, e.transcript_snippet, "
            "       e.audio_level, e.detected_at, e.acknowledged "
            "FROM public.audio_monitoring_events e "
            "LEFT JOIN public.residents r ON r.id = e.resident_id "
            "WHERE e.facility_id = :fid "
            "AND e.detected_at >= now() - (:h || ' hours')::interval "
            "ORDER BY e.detected_at DESC LIMIT 100",
            fid=facility_id, h=hours)
        return json_response([{
            "id": str(r[0]), "session_id": str(r[1]), "facility_id": str(r[2]),
            "resident_id": str(r[3]) if r[3] else None,
            "resident_name": r[4],
            "event_type": r[5], "keyword": r[6], "confidence": r[7],
            "transcript_snippet": r[8], "audio_level": r[9],
            "detected_at": r[10].isoformat(), "acknowledged": r[11],
        } for r in rows])
    finally:
        conn.close()


@route("/ai/events/<event_id>/acknowledge", method="POST")
def acknowledge_event(event_id):
    """Acknowledge a monitoring event."""
    data = request.json or {}
    staff_id = data.get("staff_id")

    conn = get_db()
    try:
        q(conn,
            "UPDATE public.audio_monitoring_events "
            "SET acknowledged = true, acknowledged_by = :sid "
            "WHERE id = :eid",
            eid=event_id, sid=staff_id)
    finally:
        conn.close()
    return json_response({"status": "acknowledged"})


if __name__ == "__main__":
    print(f"🤖 AgedCare AI Monitor starting on http://localhost:8082")
    print(f"   Database: {DB_NAME}")
    run(host="0.0.0.0", port=8082, debug=True)
