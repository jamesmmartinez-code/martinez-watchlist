#!/usr/bin/env python3
"""
Post-deploy smoke test for Realm of Eldoria.
Fetches the live Worker URL and verifies it's serving the real Godot game shell.
Fails CI with a clear message if:
  - HTTP status is not 200
  - Response looks like the redirect page (contains "location.replace" or "Cloudflare server")
  - Response doesn't contain expected Godot shell markers (canvas, index.js)
  - Response is too short to be a real game shell (<2000 bytes)
"""
import urllib.request, urllib.error, sys, time

GAME_URL = "https://eldoria-api.james-m-martinez.workers.dev/eldoria/"
REQUIRED  = ["canvas", "index.js"]          # must be present
FORBIDDEN = ["location.replace", "Cloudflare server", "http-equiv=\"refresh\""]  # redirect markers
MIN_BYTES  = 2000
MAX_RETRIES = 4
RETRY_DELAY = 8  # seconds between retries (cache flush time)

def check(attempt):
    try:
        req = urllib.request.Request(GAME_URL, headers={
            "User-Agent": "eldoria-smoketest/1.0",
            "Cache-Control": "no-cache",
        })
        with urllib.request.urlopen(req, timeout=20) as resp:
            status = resp.status
            body   = resp.read().decode(errors="replace")

        if status != 200:
            return False, f"HTTP {status} (expected 200)"

        if len(body) < MIN_BYTES:
            return False, f"Response too short: {len(body)} bytes (expected >{MIN_BYTES}) — probably a redirect or error page"

        for marker in FORBIDDEN:
            if marker in body:
                return False, f"Redirect marker found in response: '{marker}' — Worker is serving redirect page, not game"

        for marker in REQUIRED:
            if marker not in body:
                return False, f"Required marker '{marker}' missing — response doesn't look like the Godot game shell"

        return True, f"OK ({len(body):,} bytes, all markers present)"

    except urllib.error.HTTPError as e:
        return False, f"HTTP error {e.code}: {e.reason}"
    except Exception as e:
        return False, f"Request failed: {e}"

print(f"Smoke test: {GAME_URL}")
last_error = ""
for attempt in range(1, MAX_RETRIES + 1):
    ok, msg = check(attempt)
    if ok:
        print(f"  ✅ Attempt {attempt}: {msg}")
        sys.exit(0)
    last_error = msg
    print(f"  ❌ Attempt {attempt}: {msg}")
    if attempt < MAX_RETRIES:
        print(f"     Retrying in {RETRY_DELAY}s...")
        time.sleep(RETRY_DELAY)

print()
print("SMOKE TEST FAILED after %d attempts: %s" % (MAX_RETRIES, last_error))
print("Live URL: " + GAME_URL)
print("This means the Worker is NOT serving the real game. Check:")
print("  1. R2 bucket eldoria-game — does game.html contain the Godot shell?")
print("  2. Worker logs at https://dash.cloudflare.com")
print("  3. Last build's R2 sync step output")
sys.exit(1)
