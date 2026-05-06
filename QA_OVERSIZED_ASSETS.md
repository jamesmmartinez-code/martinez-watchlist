# QA Oversized Assets Tracker

Maintained by the `eldoria-qa-triage` scheduled task (runs every 3 min).
Per OPERATIONS.md §15: 25 MiB hard cap, 20 MiB soft cap on any single
file under `eldoria-godot/assets/`.

This file exists so QA does not re-analyze the same long-standing
violations on every 3-min run. If an asset is listed under
**Owner-override**, future QA runs treat it as a no-op for §15
purposes — the human owner has consciously chosen to exceed the
budget for that file.

If an asset listed here is later re-exported under-budget, QA should
remove it from this file in the same commit that confirms the new
size. If a NEW asset appears over 20 MiB, QA must triage it fresh
(reference-check → delete-if-unreferenced or log to CHANGES.md as
tech debt). This file is for ALREADY-RESOLVED policy decisions only.

---

## Owner-override

These files exceed the 20 MiB soft cap (and possibly the 25 MiB hard
cap), but the human owner explicitly chose the size trade-off. QA
does NOT flag these as §15 violations.

### `eldoria-godot/assets/models/Hero.glb` — ~29 MiB

- **Last sized:** 29 MiB (tree API), commit `23cfbd7` 2026-05-06
- **Override commit:** `23cfbd7` "Char: replace Hero.glb with
  11-year-old fantasy boy hero (Meshy biped, with Walking anim,
  ~30 MB) — actual kid character"
- **Override author:** James Martinez (owner)
- **Architect ratification:** CHANGES.md 2026-05-06T03:00Z audit
  ("Not flagging as §15 violation — owner explicitly chose
  personalization-for-kid over the web-perf budget")
- **References:** `eldoria-godot/scripts/Player.gd`,
  `eldoria-godot/scenes/Main.tscn` (id `8_hero`)
- **Suggested non-blocking follow-up (Char agent):** decimate the
  Meshy mesh (Blender → Decimate to ~5–8k tris) and re-export to
  keep the kid's likeness while restoring perf headroom; LOD0 stays
  detailed, LOD1 swaps in beyond ~15m camera distance.
- **Status:** open — non-blocking, do not remove from tracker
  until re-exported.

---

## Active §15 tech-debt entries (referenced + over-budget, not overridden)

_(none currently — see CHANGES.md "Tech debt" sections for any
new entries QA opens going forward)_

---

## Resolved (historical)

- `eldoria-godot/assets/models/Owen.glb` — 29.4 MiB. Resolved
  2026-05-06 by `cbe88d1` (Player.gd swap to Hero.glb) +
  `f79d020` (asset deletion) + `9703ac4` (.import sidecar
  deletion).
