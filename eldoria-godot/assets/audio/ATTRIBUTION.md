# Eldoria Audio — Attribution

All audio assets in this folder tree are released under **CC0 / Public Domain**
or are derivatives of CC0 source material. No legal attribution is required,
but the original artists are credited here as a courtesy and for traceability.

This file mirrors the per-folder `ATTRIBUTION.md` convention used elsewhere in
`eldoria-godot/assets/` (banners, icons, portraits, skies, textures, ui). The
master copy of this list lives in the repo's top-level `CREDITS.md` under the
`Audio — OpenGameArt CC0` heading; if the two ever diverge, `CREDITS.md` wins.

---

## Music — `music/`

| File | Source | Artist | Page |
|------|--------|--------|------|
| `village_theme.ogg`     | OpenGameArt CC0 | alexandr-zhelanov | https://opengameart.org/content/celtic-loop |
| `whisperwood_theme.ogg` | OpenGameArt CC0 | macro13           | https://opengameart.org/content/dark-forest-theme |
| `battle_theme.ogg`      | OpenGameArt CC0 | Komiku — *It's time for adventure vol. 2* | https://opengameart.org/content/battle-theme-3 |

Encoding: stereo 44.1 kHz OGG Vorbis, q=2 (~85–96 kbps).

## Ambient — `ambient/`

| File | Source | Artist | Page |
|------|--------|--------|------|
| `crickets_night.ogg`    | OpenGameArt CC0 | Ted Kerr                    | https://opengameart.org/content/crickets-ambient-noise-loopable |
| `wind_outdoor.ogg`      | OpenGameArt CC0 | Iwan Gabovitch / qubodup    | https://opengameart.org/content/wind1 |
| `dungeon_drips.ogg`     | OpenGameArt CC0 | yd                          | https://opengameart.org/content/loopable-dungeon-ambience |
| `forest_cathedral.ogg`  | OpenGameArt CC0 | (anonymous)                 | https://opengameart.org/content/cathedral-in-the-forest-ambient-loop |

Encoding: mono 22.05 kHz OGG Vorbis, q=0–1 (~30–60 kbps).

## SFX — `sfx/`

From **"RPG Sound Pack"** by artisticdude (CC0) —
https://opengameart.org/content/rpg-sound-pack:
`sword_swing.ogg`, `sword_swing_2.ogg`, `sword_swing_3.ogg`,
`sword_unsheathe.ogg`, `coin_pickup.ogg`, `chest_open.ogg`,
`damage_taken.ogg`, `quest_accept.ogg`, `loot_pickup.ogg`,
`level_up.ogg`, `door_open.ogg`, `enemy_death.ogg`, `player_death.ogg`.

`enemy_death.ogg` and `player_death.ogg` are derivative — reversed and
low-passed variants of the source files. Still CC0 under the original license.

From **"20 Sword Sound Effects (Attacks and Clashes)"** by StarNinjas (CC0) —
https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes:
`sword_hit.ogg`, `sword_hit_2.ogg`, `sword_hit_3.ogg`.

`boss_intro.ogg` — derivative work composited from existing CC0 sources in
this bundle (per the same precedent as `enemy_death.ogg` / `player_death.ogg`):

- Brass/drum swell: 2.5 s slice of `music/battle_theme.ogg` (Komiku, CC0),
  downmixed to mono, low-passed at 2.2 kHz / high-passed at 80 Hz to retain
  horns and timpani while shedding cymbal shimmer, pitched down ~3 semitones,
  fade-in 0.25 s, fade-out 0.5 s.
- Onset cue: full `sfx/sword_unsheathe.ogg` (artisticdude RPG Sound Pack, CC0)
  with a 50 ms pre-roll.
- Boss-arrival impact: `sfx/sword_hit_3.ogg` (StarNinjas, CC0) placed at
  ~1.7 s with a short reverberant tail (`aecho 0.6:0.9:120|220:0.4|0.25`).

The three layers are mixed (weights 1.4 / 0.7 / 1.1), peak-limited at 0.95,
and tail-faded over the final 0.3 s. All three sources are CC0; the derivative
remains CC0. THEME §6 compliant — entirely acoustic-orchestral, no synth.

Replaced the previous `boss_intro.wav` placeholder (110 KiB, PCM 22.05 kHz)
with a 16 KiB OGG Vorbis q=2 mono stream (~7x smaller, identical 2.5 s
duration). The Godot `.import` sidecar uses the same deterministic
`sha1(res-path)[:8]` UID scheme as the rest of the bundle.

Encoding (OGG entries): mono 22.05 kHz OGG Vorbis, q=2.

## Footsteps — `footsteps/`

All from **"Different Steps on Wood, Stone, Leaves, Gravel and Mud"** by
kddekadenz (CC0) —
https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud:
`grass.ogg`, `grass_2.ogg`, `stone.ogg`, `wood.ogg`, `wood_2.ogg`,
`wood_3.ogg`, `gravel.ogg`, `mud.ogg`.

`Audio.gd::play_footstep(surface)` falls back to `grass` when a surface lookup
misses, so any future surface kind works on day-one without a missing-asset
warning.

Encoding: mono 22.05 kHz OGG Vorbis, q=2.

## Voices — `voices/`

NPC barks generated locally via Cloudflare Workers AI **Aura-2** TTS
(commit `0c12885b`, 2026-05-06). Not third-party sourced; license
follows the project's own terms. See top-level `CREDITS.md` for the
full list (Maeve, Edda, Mara, Lyra, Bram greetings + Maeve quest/thanks).

Encoding: mono MP3 (Aura-2 default).

---

## THEME §6 compliance

§6 forbids electronic / synth pads, Hollywood orchestral bombast,
hip-hop / pop / rock, and AI "epic trailer" tropes. Every track above
is acoustic, Celtic / chamber / folk, or real-instrument SFX. Specifically:

- Music — Celtic loop (lutes, harps, flutes), dark-forest strings,
  acoustic-orchestral drums-and-horns battle. No synth, no chiptune.
- SFX — real-instrument metallic clangs, wooden creaks, cloth/leather rustles.
- Ambient — real-recorded field captures (crickets, wind, water drips,
  cathedral reverb).

## Bundle size

Total `eldoria-godot/assets/audio/` is **~4.8 MiB** on disk —
well under the 50 MiB budget set in the audio engineering brief.

---

## Godot import sidecars

As of 2026-05-06 every `.ogg` and `.mp3` in this tree ships with a
matching `.import` sidecar (38 files: 31 OGG + 7 MP3). Without these
sidecars, the headless web export pipeline (`eldoria-godot/EXPORT_TO_WEB.md`)
cannot resolve `res://` paths and `Audio.gd::_load_stream()` falls through
to `push_warning("[Audio] Missing ...")` for every track. The editor
regenerates sidecars on first open, but CI/headless runs need them
checked in.

UIDs are deterministic — `sha1(res://path)[:8]` reduced to Godot's
13-char base32 alphabet — so re-running the generator produces stable
diffs. Loop behaviour is set at runtime by `Audio.gd` (music + ambient
streams toggle `stream.loop = true` after load), so all sidecars import
with `loop=false`.
