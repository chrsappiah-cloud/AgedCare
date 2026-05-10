#!/usr/bin/env python3
"""End-to-end test of AgedCare backend API on localhost:8081.

Tests both the requested REST-style URLs and the actual RPC endpoints
that exist on the server, using real facility/resident UUIDs when possible.
"""
import json, urllib.request, urllib.error, sys, traceback, re
from datetime import datetime, timezone

BASE = "http://localhost:8081"
PASS = 0
FAIL = 0
results = []

def req(method, path, body=None):
    url = f"{BASE}{path}"
    data = json.dumps(body).encode() if body else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Content-Type", "application/json")
    try:
        resp = urllib.request.urlopen(r)
        status = resp.status
        raw = resp.read()
        ct = resp.headers.get("Content-Type", "")
        if "application/json" in ct:
            parsed = json.loads(raw)
            return status, parsed, raw
        return status, raw.decode(), raw
    except urllib.error.HTTPError as e:
        raw = e.read()
        ct = e.headers.get("Content-Type", "")
        try:
            parsed = json.loads(raw) if "application/json" in ct else raw.decode()
        except Exception:
            parsed = raw.decode()
        return e.code, parsed, raw
    except Exception as e:
        return 0, {"error": str(e), "traceback": traceback.format_exc()}, b""

def test(name, method, path, body=None):
    global PASS, FAIL
    status, data, raw = req(method, path, body)
    ok = status < 400
    if ok:
        PASS += 1
        verdict = "PASS"
    else:
        FAIL += 1
        verdict = "FAIL"
    summary = json.dumps(data, indent=2, default=str) if isinstance(data, (dict, list)) else str(data)
    # Truncate long HTML error pages
    if len(summary) > 800 and "<!DOCTYPE" in summary:
        m = re.search(r'<pre>(.*?)</pre>', summary, re.DOTALL)
        summary = m.group(1) if m else summary[:200] + "..."

    results.append({
        "name": name, "method": method, "path": path,
        "status": status, "verdict": verdict, "body": data,
    })
    print(f"  [{verdict}] {status} {method} {path}")
    print(f"         {name}")
    print(f"         {summary[:300]}")
    return status, data

def rpc(name, rpc_name, body):
    status, data = test(f"RPC: {name}", "POST", f"/rest/v1/rpc/{rpc_name}", body)
    return status, data, None

def main():
    global PASS, FAIL
    print(f"{'#'*70}")
    print(f"  AgedCare Backend E2E Tests — {BASE}")
    print(f"  Started: {datetime.now(timezone.utc).isoformat()}")
    print(f"{'#'*70}")

    # ── Discover real IDs from the database ─────────────────────────
    print(f"\n--- Discovering facility & resident IDs ---")
    s, fac_data, _ = req("GET", "/facility")
    facility_id = None
    resident_id = None
    if s == 200:
        facility_id = fac_data.get("id")
        print(f"  Facility: {fac_data.get('name')} (id={facility_id})")
    else:
        print(f"  Could not fetch facility: HTTP {s}")

    if facility_id:
        s, rr_data, _ = rpc("get_residents_for_facility", "get_residents_for_facility",
                          {"p_facility_id": facility_id})
        if s < 400 and isinstance(rr_data, list) and len(rr_data) > 0:
            resident_id = rr_data[0].get("id")
            print(f"  Using resident: {rr_data[0].get('name')} (id={resident_id})")
        else:
            print(f"  No residents found or error fetching them")
    else:
        print(f"  Facility ID unknown — RPC tests will likely fail with UUID errors")

    # ── 1. Health ───────────────────────────────────────────────────
    print(f"\n─── 1. Health Check ──────────────────────────────────────")
    test("Health check", "GET", "/health")

    # ── 2. Supabase health (does not exist) ─────────────────────────
    print(f"\n─── 2. Supabase Health ───────────────────────────────────")
    test("Supabase health", "GET", "/health/supabase")

    # ── 3. Record a vital ───────────────────────────────────────────
    print(f"\n─── 3. Record Vital ──────────────────────────────────────")
    test("Record vital (requested URL)", "POST", "/api/vitals/record", {
        "resident_id": resident_id or "test-resident-e2e",
        "vital_type": "heart_rate",
        "value": 72,
        "unit": "bpm",
    })
    if facility_id and resident_id:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        rpc("Record vital", "record_vital_event", {
            "p_facility_id": facility_id,
            "p_resident_id": resident_id,
            "p_metric": "heart_rate",
            "p_value": 72,
            "p_timestamp": ts,
        })
    else:
        test("RPC: Record vital (SKIP - no IDs)", "POST",
             "/rest/v1/rpc/record_vital_event", {})

    # ── 4. Get vitals ───────────────────────────────────────────────
    print(f"\n─── 4. Get Vitals ────────────────────────────────────────")
    rid_path = resident_id or "test-resident-e2e"
    test("Get vitals (requested URL)", "GET", f"/api/vitals/{rid_path}")

    # ── 5. Create handoff request ───────────────────────────────────
    print(f"\n─── 5. Create Handoff Request ────────────────────────────")
    test("Create handoff (requested URL)", "POST", "/api/handoff/request", {
        "facility_id": facility_id or "test-facility-e2e",
        "resident_id": resident_id or "test-resident-e2e",
        "notes": "E2E test handoff",
    })
    if facility_id and resident_id:
        rpc("Create handoff request", "create_handoff_request", {
            "p_facility_id": facility_id,
            "p_resident_id": resident_id,
            "p_notes": "E2E test handoff from e2e_test.py",
        })
    else:
        test("RPC: Create handoff (SKIP - no IDs)", "POST",
             "/rest/v1/rpc/create_handoff_request", {})

    # ── 6. Get pending handoffs ─────────────────────────────────────
    print(f"\n─── 6. Get Pending Handoffs ──────────────────────────────")
    fid_path = facility_id or "test-facility-e2e"
    test("Get pending handoffs (requested URL)", "GET",
         f"/api/handoff/pending/{fid_path}")

    # ── 7. Resolve handoff ──────────────────────────────────────────
    print(f"\n─── 7. Resolve Handoff ───────────────────────────────────")
    test("Resolve handoff (requested URL)", "POST", "/api/handoff/resolve", {
        "request_id": 1,
        "staff_id": "test-staff-e2e",
    })
    rpc("Resolve handoff request", "resolve_handoff_request", {
        "p_alert_id": 1,
    })

    # ── 8. Get alerts ───────────────────────────────────────────────
    print(f"\n─── 8. Get Alerts ────────────────────────────────────────")
    test("Get alerts (requested URL)", "GET", f"/api/alerts/{fid_path}")
    if facility_id:
        rpc("Get open alerts", "get_open_alerts_for_facility", {
            "p_facility_id": facility_id,
        })
    else:
        test("RPC: Get alerts (SKIP - no IDs)", "POST",
             "/rest/v1/rpc/get_open_alerts_for_facility", {})

    # ── 9. Get residents ────────────────────────────────────────────
    print(f"\n─── 9. Get Residents ─────────────────────────────────────")
    test("Get residents (requested URL)", "GET", f"/api/residents/{fid_path}")
    if facility_id:
        rpc("Get residents", "get_residents_for_facility", {
            "p_facility_id": facility_id,
        })
    else:
        test("RPC: Get residents (SKIP - no IDs)", "POST",
             "/rest/v1/rpc/get_residents_for_facility", {})

    # ── Summary ─────────────────────────────────────────────────────
    total = PASS + FAIL
    print(f"\n{'#'*70}")
    print(f"  RESULTS SUMMARY")
    print(f"{'#'*70}")
    print(f"  Passed: {PASS}/{total}  |  Failed: {FAIL}/{total}")
    print()
    for r in results:
        icon = "✅" if r["verdict"] == "PASS" else "❌"
        print(f"  {icon} [{r['verdict']}] {r['status']} {r['method']} {r['path']}")
        print(f"     {r['name']}")
    print()
    if FAIL == 0:
        print(f"  ✅  ALL {total} TESTS PASSED")
    else:
        print(f"  ❌  {FAIL}/{total} TEST(S) FAILED — see details above")
    print(f"{'#'*70}")
    return 0 if FAIL == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
