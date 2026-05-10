#!/usr/bin/env python3
import json, uuid, hashlib, hmac, base64, time, os
from datetime import datetime, timezone
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


def make_jwt(user_id, email, role):
    header = base64.urlsafe_b64encode(json.dumps({"alg": "HS256", "typ": "JWT"}).encode()).rstrip(b"=").decode()
    payload = base64.urlsafe_b64encode(json.dumps({
        "sub": str(user_id), "email": email, "role": role,
        "iat": int(time.time()), "exp": int(time.time()) + 86400, "aud": "authenticated",
    }).encode()).rstrip(b"=").decode()
    sig = hmac.new(b"dev-secret", f"{header}.{payload}".encode(), hashlib.sha256).digest()
    sig_b64 = base64.urlsafe_b64encode(sig).rstrip(b"=").decode()
    return f"{header}.{payload}.{sig_b64}"


@route("/auth/v1/token", method="POST")
def auth_token():
    body = request.json or {}
    grant_type = body.get("grant_type", "password")
    email = body.get("email", "")
    password = body.get("password", "")

    if grant_type != "password":
        return HTTPResponse(status=400, body=json.dumps({"error": "unsupported_grant_type"}))

    conn = get_db()
    try:
        row = q(conn,
            "SELECT u.id, u.email, u.password_hash, s.role "
            "FROM auth.users u LEFT JOIN public.staff_users s ON s.id = u.id "
            "WHERE u.email = :email", email=email)
        if not row or row[0][2] != password:
            return HTTPResponse(status=401, body=json.dumps({"error": "invalid_credentials"}))

        user_id, email, _, role = row[0]
        token = make_jwt(user_id, email, role or "authenticated")
        return {
            "access_token": token, "token_type": "bearer", "expires_in": 86400,
            "user": {"id": str(user_id), "email": email, "role": role or "authenticated"},
        }
    finally:
        conn.close()


@route("/auth/v1/user", method="GET")
def auth_user():
    token = request.get_header("Authorization", "").replace("Bearer ", "")
    if not token:
        return HTTPResponse(status=401, body=json.dumps({"error": "unauthorized"}))
    try:
        payload_b64 = token.split(".")[1]
        pad = 4 - len(payload_b64) % 4
        if pad != 4:
            payload_b64 += "=" * pad
        payload = json.loads(base64.urlsafe_b64decode(payload_b64.encode()))
        return {"id": payload["sub"], "email": payload["email"], "role": payload["role"]}
    except Exception:
        return HTTPResponse(status=401, body=json.dumps({"error": "invalid_token"}))


def json_response(data, status=200):
    response.content_type = "application/json"
    response.status = status
    return json.dumps(data)


@route("/rest/v1/rpc/<rpc_name>", method="POST")
def rpc_handler(rpc_name):
    body = request.json or {}
    conn = get_db()
    try:
        if rpc_name == "get_open_alerts_for_facility":
            rows = q(conn,
                "SELECT id, resident_id, type, status, priority, created_at, assigned_to "
                "FROM public.alerts WHERE facility_id = :fid AND status IN ('open', 'ack') "
                "ORDER BY priority DESC, created_at DESC",
                fid=body["p_facility_id"])
            return json_response([{
                "id": r[0], "resident_id": str(r[1]), "type": r[2],
                "status": r[3], "priority": r[4], "created_at": r[5].isoformat(),
                "assigned_to": str(r[6]) if r[6] else None,
            } for r in rows])

        elif rpc_name == "create_fall_alert":
            row = q(conn,
                "INSERT INTO public.alerts (facility_id, resident_id, type, status, priority) "
                "VALUES (:fid, :rid, 'fall', 'open', :prio) RETURNING id",
                fid=body["p_facility_id"], rid=body["p_resident_id"], prio=body.get("p_priority", 3))
            return json_response({"alert_id": row[0][0]})

        elif rpc_name == "create_sos_alert":
            row = q(conn,
                "INSERT INTO public.alerts (facility_id, resident_id, type, status, priority) "
                "VALUES (:fid, :rid, 'manualSOS', 'open', 1) RETURNING id",
                fid=body["p_facility_id"], rid=body["p_resident_id"])
            return json_response({"alert_id": row[0][0]})

        elif rpc_name == "acknowledge_alert":
            q(conn,
                "UPDATE public.alerts SET status = 'ack', acknowledged_at = now(), assigned_to = :sid "
                "WHERE id = :aid",
                aid=body["p_alert_id"], sid=body["p_staff_id"])
            response.status = 204
            return ""

        elif rpc_name == "close_alert":
            q(conn,
                "UPDATE public.alerts SET status = 'closed', closed_at = now(), notes = COALESCE(:notes, notes) "
                "WHERE id = :aid",
                aid=body["p_alert_id"], notes=body.get("p_notes", ""))
            response.status = 204
            return ""

        elif rpc_name == "get_residents_for_facility":
            rows = q(conn,
                "SELECT jsonb_agg(jsonb_build_object("
                "'id', id, 'facility_id', facility_id, 'name', name, "
                "'risk_level', risk_level, 'date_of_birth', date_of_birth"
                ") ORDER BY name) FROM public.residents WHERE facility_id = :fid",
                fid=body["p_facility_id"])
            return json_response(rows[0][0] or [])

        elif rpc_name == "get_fall_summary_for_resident":
            row = q(conn,
                "SELECT COUNT(*)::int FROM public.fall_incidents "
                "WHERE resident_id = :rid AND detected_at >= now() - (:days || ' days')::interval",
                rid=body["p_resident_id"], days=body.get("p_days", 7))
            return json_response(row[0][0])

        elif rpc_name == "get_resident_timeline":
            rows = q(conn,
                "SELECT jsonb_agg(sub ORDER BY sub.ts DESC) FROM ("
                "SELECT 'fall' AS kind, detected_at AS ts, 'Fall detected' AS summary "
                "FROM public.fall_incidents WHERE resident_id = :rid "
                "UNION ALL "
                "SELECT 'vital' AS kind, timestamp AS ts, metric || ': ' || (payload->>'value') AS summary "
                "FROM public.sensor_events WHERE resident_id = :rid AND type = 'vital' "
                "ORDER BY ts DESC LIMIT :lim) sub",
                rid=body["p_resident_id"], lim=body.get("p_limit", 50))
            return json_response(rows[0][0] or [])

        elif rpc_name == "get_facility_stats":
            row = q(conn,
                "SELECT jsonb_build_object("
                "'falls_last_7d', (SELECT COUNT(*)::int FROM public.fall_incidents "
                "WHERE facility_id = :fid AND detected_at >= now() - interval '7 days'), "
                "'open_alerts', (SELECT COUNT(*)::int FROM public.alerts "
                "WHERE facility_id = :fid AND status = 'open'), "
                "'avg_acknowledge_minutes', (SELECT COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM (acknowledged_at - created_at)) / 60)), 0)::int "
                "FROM public.alerts WHERE facility_id = :fid AND acknowledged_at IS NOT NULL "
                "AND created_at >= now() - interval '30 days'))",
                fid=body["p_facility_id"])
            return json_response(row[0][0])

        elif rpc_name == "record_vital_event":
            q(conn,
                "INSERT INTO public.sensor_events (facility_id, resident_id, type, subtype, metric, timestamp, payload) "
                "VALUES (:fid, :rid, 'vital', 'snapshot', :metric, to_timestamp(:ts, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'), jsonb_build_object('value', :val::numeric))",
                fid=body["p_facility_id"], rid=body["p_resident_id"],
                metric=body["p_metric"], ts=body["p_timestamp"], val=body["p_value"])
            response.status = 204
            return ""

        elif rpc_name == "get_facility_name":
            row = q(conn,
                "SELECT name FROM public.facilities WHERE id = :fid", fid=body["p_facility_id"])
            return json_response(row[0][0] if row else "")

        elif rpc_name == "get_staff_info":
            row = q(conn,
                "SELECT id, facility_id, role, display_name FROM public.staff_users WHERE id = :uid",
                uid=body["p_user_id"])
            if not row:
                return json_response({"error": "staff not found"}, status=404)
            r = row[0]
            return json_response({
                "id": str(r[0]), "facility_id": str(r[1]),
                "role": r[2], "display_name": r[3],
            })

        else:
            return HTTPResponse(status=404, body=json.dumps({"error": f"unknown rpc: {rpc_name}"}))

    except Exception as e:
        return HTTPResponse(status=500, body=json.dumps({"error": str(e)}))
    finally:
        conn.close()


@route("/health", method="GET")
def health():
    conn = get_db()
    try:
        conn.run("SELECT 1")
        return {"status": "ok", "database": DB_NAME}
    except Exception as e:
        return HTTPResponse(status=500, body=json.dumps({"error": str(e)}))
    finally:
        conn.close()


@route("/", method="GET")
def index():
    return {"service": "AgedCare Local Backend", "version": "1.0.0", "endpoints": [
        "POST /auth/v1/token", "GET /auth/v1/user",
        "POST /rest/v1/rpc/<name>", "GET /health", "GET /facility",
    ]}


@route("/facility", method="GET")
def get_facility():
    conn = get_db()
    try:
        rows = q(conn, "SELECT id, name, code FROM public.facilities LIMIT 1")
        if rows:
            return json_response({"id": str(rows[0][0]), "name": rows[0][1], "code": rows[0][2]})
        return json_response({"error": "no facility"}, status=404)
    finally:
        conn.close()


MEDIA_DIR = os.path.join(os.path.dirname(__file__), "media")
os.makedirs(MEDIA_DIR, exist_ok=True)


@route("/upload", method="POST")
def upload_media():
    data = request.json or {}
    file_b64 = data.get("data_base64", "")
    filename = data.get("filename", f"file_{uuid.uuid4().hex[:12]}")
    attachment_type = data.get("attachment_type", "photo")
    alert_id = data.get("alert_id")

    if not file_b64:
        return HTTPResponse(status=400, body=json.dumps({"error": "missing data_base64"}))

    try:
        file_bytes = base64.b64decode(file_b64)
    except Exception:
        return HTTPResponse(status=400, body=json.dumps({"error": "invalid base64"}))

    ext_map = {"photo": ".jpg", "audio": ".m4a", "video": ".mp4"}
    ext = ext_map.get(attachment_type, ".bin")
    stored_name = f"{uuid.uuid4().hex}{ext}"
    stored_path = os.path.join(MEDIA_DIR, stored_name)

    with open(stored_path, "wb") as f:
        f.write(file_bytes)

    url = f"/media/{stored_name}"
    return json_response({"url": url, "filename": filename})


@route("/media/<filename:path>", method="GET")
def serve_media(filename):
    filepath = os.path.join(MEDIA_DIR, filename)
    if not os.path.exists(filepath):
        return HTTPResponse(status=404, body=json.dumps({"error": "not found"}))
    with open(filepath, "rb") as f:
        data = f.read()
    response.content_type = {
        ".jpg": "image/jpeg",
        ".png": "image/png",
        ".m4a": "audio/mp4",
        ".mp4": "video/mp4",
        ".wav": "audio/wav",
        ".bin": "application/octet-stream",
    }.get(os.path.splitext(filename)[1], "application/octet-stream")
    return data


@route("/alert/<alert_id:int>/attachments", method="GET")
def get_attachments(alert_id):
    conn = get_db()
    try:
        rows = q(conn,
            "SELECT id, attachment_type, file_url, filename, created_at "
            "FROM public.alert_attachments WHERE alert_id = :aid ORDER BY created_at",
            aid=alert_id)
        return json_response([{
            "id": str(r[0]), "type": r[1], "url": r[2],
            "filename": r[3], "created_at": r[4].isoformat(),
        } for r in rows])
    finally:
        conn.close()


@route("/alert/<alert_id:int>/attachments", method="POST")
def add_attachment(alert_id):
    data = request.json or {}
    conn = get_db()
    try:
        row = q(conn,
            "INSERT INTO public.alert_attachments (alert_id, attachment_type, file_url, filename) "
            "VALUES (:aid, :typ, :url, :name) RETURNING id",
            aid=alert_id, typ=data["attachment_type"],
            url=data["file_url"], name=data.get("filename", "unnamed"))
        return json_response({"id": row[0][0]})
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# AI Monitor Endpoints (inline, also available as standalone ai_monitor.py)
# ---------------------------------------------------------------------------

@route("/ai/analyze/media", method="POST")
def ai_analyze_media():
    data = request.json or {}
    file_b64 = data.get("data_base64", "")
    filename = data.get("filename", "unknown")
    media_type = data.get("media_type", "photo")
    facility_id = data.get("facility_id")
    resident_id = data.get("resident_id")
    if not file_b64 or not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "missing data_base64 or facility_id"}))
    try:
        file_bytes = base64.b64decode(file_b64)
    except Exception:
        return HTTPResponse(status=400, body=json.dumps({"error": "invalid base64"}))
    result = {"summary": "Analyzed by AI Monitor", "confidence": 0.85, "insights": [], "sentiment": "neutral", "safety_flags": [], "detected_keywords": []}
    if media_type == "photo":
        size_kb = len(file_bytes) / 1024
        result["insights"].append("Photo reviewed" + (" — large file" if size_kb > 2000 else ""))
        if "fall" in filename.lower() or "injury" in filename.lower():
            result["safety_flags"].append({"type": "potential_injury", "detail": "Filename suggests injury documentation"})
            result["sentiment"] = "concern"
    elif media_type == "audio":
        transcribed = data.get("transcribed_text", "[Simulated transcription]")
        result["insights"].append("Audio reviewed — key terms monitored")
        keywords = [w for w in ["help", "pain", "fall", "nurse", "water"] if w in transcribed.lower()]
        result["detected_keywords"] = keywords
        if keywords:
            result["safety_flags"].append({"type": "keyword_detected", "detail": f"Keywords: {', '.join(keywords[:3])}"})
            result["sentiment"] = "attention"
        result["transcribed_text"] = transcribed
    analysis_id = str(uuid.uuid4())
    now = datetime.now()
    conn = get_db()
    try:
        q(conn,
            "INSERT INTO public.media_analysis (id, facility_id, resident_id, media_url, media_type, analysis_status, summary, confidence, insights, detected_keywords, sentiment, safety_flags, transcribed_text, completed_at) "
            "VALUES (:id, :fid, :rid, :url, :mtype, 'completed', :summary, :conf, :insights, :keywords, :sent, :flags, :transcript, :now)",
            id=analysis_id, fid=facility_id, rid=resident_id, url=data.get("media_url", ""), mtype=media_type,
            summary=result["summary"], conf=result["confidence"],
            insights=json.dumps(result["insights"]), keywords=json.dumps(result["detected_keywords"]),
            sent=result["sentiment"], flags=json.dumps(result["safety_flags"]),
            transcript=result.get("transcribed_text", ""), now=now)
    finally:
        conn.close()
    return json_response({"analysis_id": analysis_id, **result})


@route("/ai/insights", method="POST")
def ai_get_insights():
    data = request.json or {}
    facility_id = data.get("facility_id")
    limit = data.get("limit", 20)
    if not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "facility_id required"}))
    conn = get_db()
    try:
        rows = q(conn,
            "SELECT ma.id, ma.facility_id, ma.resident_id, r.name, ma.media_url, ma.media_type, ma.analysis_status, ma.summary, ma.confidence, ma.insights, ma.detected_keywords, ma.sentiment, ma.safety_flags, ma.transcribed_text, ma.created_at, ma.completed_at "
            "FROM public.media_analysis ma LEFT JOIN public.residents r ON r.id = ma.resident_id "
            "WHERE ma.facility_id = :fid ORDER BY ma.created_at DESC LIMIT :lim", fid=facility_id, lim=limit)
        return json_response([{
            "id": str(r[0]), "facility_id": str(r[1]),
            "resident_id": str(r[2]) if r[2] else None, "resident_name": r[3],
            "media_url": r[4], "media_type": r[5], "analysis_status": r[6],
            "summary": r[7], "confidence": r[8],
            "insights": json.loads(r[9]) if isinstance(r[9], str) else r[9],
            "detected_keywords": json.loads(r[10]) if isinstance(r[10], str) else r[10],
            "sentiment": r[11],
            "safety_flags": json.loads(r[12]) if isinstance(r[12], str) else r[12],
            "transcribed_text": r[13],
            "created_at": r[14].isoformat(), "completed_at": r[15].isoformat() if r[15] else None,
        } for r in rows])
    finally:
        conn.close()


@route("/ai/monitor/start", method="POST")
def ai_start_monitor():
    data = request.json or {}
    facility_id = data.get("facility_id")
    resident_id = data.get("resident_id")
    started_by = data.get("started_by")
    if not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "facility_id required"}))
    session_id = str(uuid.uuid4())
    now = datetime.now()
    conn = get_db()
    try:
        q(conn,
            "INSERT INTO public.audio_monitoring_sessions (id, facility_id, resident_id, started_by, status, started_at) "
            "VALUES (:id, :fid, :rid, :sid, 'active', :now)",
            id=session_id, fid=facility_id, rid=resident_id, sid=started_by, now=now)
    finally:
        conn.close()
    return json_response({"session_id": session_id, "status": "active", "started_at": now.isoformat()})


@route("/ai/monitor/<session_id>/stop", method="POST")
def ai_stop_monitor(session_id):
    now = datetime.now()
    conn = get_db()
    try:
        q(conn, "UPDATE public.audio_monitoring_sessions SET status='stopped', stopped_at=:now WHERE id=:sid",
          sid=session_id, now=now)
    finally:
        conn.close()
    return json_response({"session_id": session_id, "status": "stopped"})


@route("/ai/monitor/<session_id>/event", method="POST")
def ai_report_event(session_id):
    data = request.json or {}
    now = datetime.now()
    conn = get_db()
    try:
        srows = q(conn, "SELECT facility_id FROM public.audio_monitoring_sessions WHERE id=:sid", sid=session_id)
        if not srows:
            return HTTPResponse(status=404, body=json.dumps({"error": "session not found"}))
        facility_id = srows[0][0]
        event_id = str(uuid.uuid4())
        q(conn,
            "INSERT INTO public.audio_monitoring_events (id, session_id, facility_id, resident_id, event_type, keyword, confidence, transcript_snippet, audio_level, detected_at) "
            "VALUES (:eid, :sid, :fid, :rid, :etype, :kw, :conf, :snippet, :level, :now)",
            eid=event_id, sid=session_id, fid=facility_id, rid=data.get("resident_id"),
            etype=data.get("event_type", "unknown"), kw=data.get("keyword"),
            conf=data.get("confidence", 0.0), snippet=data.get("transcript_snippet"),
            level=data.get("audio_level"), now=now)
        q(conn, "UPDATE public.audio_monitoring_sessions SET last_event_at=:now WHERE id=:sid",
          sid=session_id, now=now)
    finally:
        conn.close()
    return json_response({"event_id": event_id, "detected_at": now.isoformat()})


@route("/ai/events/recent", method="POST")
def ai_recent_events():
    data = request.json or {}
    facility_id = data.get("facility_id")
    hours = data.get("hours", 24)
    if not facility_id:
        return HTTPResponse(status=400, body=json.dumps({"error": "facility_id required"}))
    conn = get_db()
    try:
        rows = q(conn,
            "SELECT e.id, e.session_id, e.facility_id, e.resident_id, r.name, e.event_type, e.keyword, e.confidence, e.transcript_snippet, e.audio_level, e.detected_at, e.acknowledged "
            "FROM public.audio_monitoring_events e LEFT JOIN public.residents r ON r.id = e.resident_id "
            "WHERE e.facility_id=:fid AND e.detected_at >= now() - (:h||' hours')::interval "
            "ORDER BY e.detected_at DESC LIMIT 100", fid=facility_id, h=hours)
        return json_response([{
            "id": str(r[0]), "session_id": str(r[1]), "facility_id": str(r[2]),
            "resident_id": str(r[3]) if r[3] else None, "resident_name": r[4],
            "event_type": r[5], "keyword": r[6], "confidence": r[7],
            "transcript_snippet": r[8], "audio_level": r[9],
            "detected_at": r[10].isoformat(), "acknowledged": r[11],
        } for r in rows])
    finally:
        conn.close()


if __name__ == "__main__":
    print(f"🚀 AgedCare backend starting on http://localhost:8081")
    print(f"   Database: {DB_NAME}")
    print(f"   Media directory: {MEDIA_DIR}")
    run(host="0.0.0.0", port=8081, debug=True)
