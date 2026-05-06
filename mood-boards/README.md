# Eldoria — Mood Boards

**Single source of visual canon for every agent.** Cite a panel here in your run notes
instead of describing the look from scratch each time. THEME.md governs; these boards
are the *visual* derivative — same canon, easier to consult mid-run.

---

## What's in here

| File | Cite when | THEME.md anchor |
|------|-----------|-----------------|
| [`palette.png`](palette.png) | choosing a color, picking a tint, sourcing a stock asset, tuning a Godot light/material | §3 Color palette |
| [`era_window.png`](era_window.png) | sourcing a prop, evaluating a model from CC0 marketplaces, judging "is this 1300–1500?" | §1, §2 Core identity / era |
| [`silhouette_check.png`](silhouette_check.png) | picking or commissioning an NPC mesh, dressing the player, judging whether two villagers read distinct from across the square | §4 Character archetypes |
| [`enemy_silhouettes.png`](enemy_silhouettes.png) | scaling enemies, deciding glow/aura intensity, comparing relative size for boss reveals | §4 Enemies |
| [`lighting_compass.png`](lighting_compass.png) | picking a time-of-day, tuning a sky/HDRI, choosing a banner/material that has to read in dusk lighting | §1, §3 Warm sunset dominant |
| [`prop_sheet.png`](prop_sheet.png) | sourcing or modeling a Briarwood prop (well, banner pole, cart, woodpile, market stall, lantern, signpost), checking same-scale read between props + player + Maeve + goblin | §1 lived-in, §3 palette, §8 timber-stone-thatch |

## How to cite

In your run notes (`CHANGES.md`), add a "Mood board panel" line under the THEME §X cited
section, naming which board you used. Example:

```markdown
### THEME §X cited
- §1 (painterly), §3 (sunset gold dominant), §4 (silhouette-distinct).

### Mood board panel
mood-boards/silhouette_check.png — Maeve's stoop + staff is the read I targeted.
mood-boards/palette.png — sampled #B0742A (hammered bronze) for the buckle.
```

This closes the loop the Builder run-17 entry called out: *"mood-boards/ directory
not present. Cited THEME.md §1, §2, §4, §6, §7 directly per the THEME-gate
fallback."* The fallback is no longer needed — name a board.

## What's NOT in here (yet)

These are the next priority panels for a future Art run; pick one if you're
re-running this agent and want a high-leverage addition.

- `architecture_palette.png` — Briarwood timber-frame house elevations (4 variants),
  Smithy, Inn, Whisperwood goblin tent, Crystal Caves entrance arch.
- ~~`prop_sheet.png`~~ — **shipped 2026-05-06.** See entry above and `mood-boards/prop_sheet.png`.
- `magic_glow_reference.png` — fey cyan, warlock purple, frost silver auras at three
  intensities each, against a dusk background.
- `ui_chrome.png` — parchment panel + wood frame + ornate divider + button states
  composited together, so UI agents see the assembled look not just isolated atlas pieces.
- `world_map_sketch.png` — Eldoria on a hand-painted parchment, Briarwood / Whisperwood /
  Crystal Caves / Mountain Ring spatially arranged. Tolkien-style.

## Provenance

All five panels in this run were generated procedurally with Pillow from the THEME.md
canon — no external models, no stock sourcing, no AI image generation. They're
intentionally schematic (palette swatches and primitive silhouettes, not painterly
art) so that:

1. The boards never drift from THEME.md — re-running the script regenerates them.
2. Other agents see structure, not aesthetic noise. The painterly look is in the
   actual `assets/` content (icons, portraits, banners); the boards exist to point
   at decisions, not to inspire by mood.

Painterly *reference* art (vista_briarwood_dusk.png, npc_portrait_painted.png, etc.)
belongs under `concept/` per `ARTIST_AGENT.md` — separate, parallel surface, not
overlapping with this directory.

## Changelog

- 2026-05-05 — auto/art bootstrap. Five panels: palette, era window,
  silhouette check (NPCs), enemy silhouettes, lighting compass. README + this changelog.
- 2026-05-06 — auto/art. Added `prop_sheet.png` (Briarwood props at unified
  scale: well, banner pole, cart, woodpile, market stall, lantern, signpost,
  + player/Maeve/goblin scale reference). Procedural Pillow, seed 73,
  byte-stable on re-run. THEME.md anchor: §1, §3, §8. `_generate.py` updated
  to include `render_prop_sheet()`; `palette.png` left at its 2026-05-05
  bootstrap hash so this run is purely additive.
