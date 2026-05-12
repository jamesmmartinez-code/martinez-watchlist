#!/usr/bin/env python3
"""
Verifies that game.html in R2 is the real Godot game shell (not a redirect).
Called at the end of the R2 sync step to catch upload failures immediately.
Requires: CF_TOKEN, CF_ACCOUNT_ID env vars.
"""
import urllib.request, urllib.error, sys, os, json

CF_TOKEN      = os.environ.get("CF_TOKEN", "")
CF_ACCOUNT_ID = os.environ.get("CF_ACCOUNT_ID", "")
BUCKET        = "eldoria-game"

if not CF_TOKEN or not CF_ACCOUNT_ID:
    print("CF_TOKEN or CF_ACCOUNT_ID not set — skipping R2 verify")
    sys.exit(0)

REQUIRED  = ["canvas", "index.js"]
FORBIDDEN = ["location.replace", "http-equiv=\"refresh\""]
MIN_BYTES  = 2000

print("Verifying game.html in R2 bucket '%s'..." % BUCKET)

url = "https://api.cloudflare.com/client/v4/accounts/%s/r2/buckets/%s/objects/game.html" % (CF_ACCOUNT_ID, BUCKET)
req = urllib.request.Request(url, headers={
    "Authorization": "Bearer " + CF_TOKEN,
    "User-Agent": "eldoria-r2-verify/1.0"
})

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read().decode(errors="replace")
except urllib.error.HTTPError as e:
    print("ERROR: Could not fetch game.html from R2 — HTTP %d: %s" % (e.code, e.reason))
    print("R2 upload may have failed silently.")
    sys.exit(1)
except Exception as e:
    print("ERROR: R2 fetch failed: %s" % e)
    sys.exit(1)

errors = []
if len(body) < MIN_BYTES:
    errors.append("game.html is only %d bytes — too small to be a real game shell" % len(body))
for m in FORBIDDEN:
    if m in body:
        errors.append("Redirect marker found: '%s' — game.html is a redirect page, not the game" % m)
for m in REQUIRED:
    if m not in body:
        errors.append("Required marker '%s' missing — game.html doesn't look like the Godot shell" % m)

if errors:
    print("R2 VERIFY FAILED:")
    for e in errors:
        print("  ❌ " + e)
    sys.exit(1)

print("  ✅ game.html in R2 looks correct (%d bytes, all markers present)" % len(body))
