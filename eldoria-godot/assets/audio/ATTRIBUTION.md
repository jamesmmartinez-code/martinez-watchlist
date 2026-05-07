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
| `village_theme.ogg`     | OpenGameArt CC0 | RandomMind — *Medieval: The Bard's Tale* | https://opengameart.org/content/medieval-the-bards-tale |
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
| `birds_day.ogg`         | OpenGameArt CC0 | isaiah658                   | https://opengameart.org/content/ambient-bird-sounds |
| `distant_thunder.ogg`   | OpenGameArt CC0 | WuxiaScrub                  | https://opengameart.org/content/rain-long-thunder |

`village_chatter.ogg` — derivative ambient loop composited from existing
sources in this bundle (boss_intro precedent). 16.6 s loopable mono track:

- 5 NPC greeting voice files (Maeve, Edda, Lyra, Bram, Mara — project-owned
  Aura-2 TTS, see `voices/` below) each independently pitched down
  (`asetrate` factors 0.78–0.92), tempo-stretched (`atempo` 0.85–0.92),
  hard low-passed at 900–1200 Hz to remove word intelligibility, fed
  through `aecho 0.4–0.5 : 0.5–0.6 : 200–340|450–650 : 0.35–0.4 | 0.20–0.25`
  for distance/reverb tail, gained to 0.26–0.32, and time-staggered with
  `adelay` at 0 / 2.7 / 5.8 / 9.1 / 12.3 s so the murmurs overlap rather
  than coincide.
- Soft wind bed: `wind_outdoor.ogg` (Iwan Gabovitch / qubodup, CC0)
  tempo-stretched to 0.85x, low-passed at 600 Hz, gain 0.18 — fills the
  spaces between voice murmurs with breath/airflow rumble.
- Mixed via `amix=inputs=6:normalize=0`, peak-limited at 0.92, faded in
  over 0.6 s and out over 1.2 s for seamless looping.

License: derivative of project-owned voice files + CC0 wind. Voice-file
license follows the project's own terms (see `voices/`); the wind-bed
component remains CC0. THEME §6 compliant — no synth, no Hollywood swell.

Encoding: mono 22.05 kHz OGG Vorbis, q=1 (~25 kbps).

Encoding (other ambient entries): mono 22.05 kHz OGG Vorbis, q=0–1 (~30–60 kbps).

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

Source files from **"Different Steps on Wood, Stone, Leaves, Gravel and Mud"**
by kddekadenz (CC0) —
https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud:
`grass.ogg`, `grass_2.ogg`, `stone.ogg`, `wood.ogg`, `wood_2.ogg`,
`wood_3.ogg`, `gravel.ogg`, `mud.ogg`.

The following are **CC0 derivatives** of the above (same precedent as
`enemy_death.ogg` / `player_death.ogg` / `boss_intro.ogg`) — pitch-shift +
EQ variations of the corresponding base file, generated to give
`Audio.gd::_pick_variant()` real randomization on stone, gravel, and mud
surfaces (which previously had only one file each):

| File | Derivation |
|------|-----------|
| `stone_2.ogg`  | `stone.ogg`  pitched up ~+2 semitones (`asetrate=22050*1.122`), high-pass at 120 Hz, gain 0.95 — drier rock scuff. |
| `stone_3.ogg`  | `stone.ogg`  pitched down ~-2 semitones (`asetrate=22050*0.891`), low-pass at 4.5 kHz, gain 0.90 — softer/heavier step. |
| `gravel_2.ogg` | `gravel.ogg` pitched up ~+1.5 semitones, narrow-band cut at 800 Hz (-3 dB) — smaller-stones character. |
| `gravel_3.ogg` | `gravel.ogg` pitched down ~-1.5 semitones, fade-out tail-clipped at 0.18 s — softer trailing scrape. |
| `mud_2.ogg`    | `mud.ogg`    pitched up ~+2 semitones, low-pass at 2.2 kHz — brighter squelch. |

All derivatives remain CC0 under the original kddekadenz license.

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

Total `eldoria-godot/assets/audio/` is **~5.1 MiB** on disk —
well under the 50 MiB budget set in the audio engineering brief.

---

## Godot import sidecars

As of 2026-05-06 every `.ogg` and `.mp3` in this tree ships with a
matching `.import` sidecar (45 files: 38 OGG + 7 MP3). Without these
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

---

## 2026-05-06 audio engineering pass — auto/audio

**Upgraded `music/village_theme.ogg`:**

Replaced previous 43 s `village_theme.ogg` with RandomMind's *Medieval: The
Bard's Tale* (CC0, https://opengameart.org/content/medieval-the-bards-tale).
The new track is **2 min 38 s** of acoustic medieval lute + flute melody —
on-theme for §6 (Celtic / chamber / folk; lutes, harps, flutes, low strings)
and meets the 2–3 min loop-length target in the audio brief. Tagged on the
source page: *medieval, lute, flute, village, tavern, peaceful, folk*.

- Source download: `The_Bards_Tale.mp3` (3.8 MB, 192 kbps stereo MP3)
- Transcoded to OGG Vorbis q=2 stereo 44.1 kHz (1.6 MB) to match the bundle's
  music encoding profile (`Encoding: stereo 44.1 kHz OGG Vorbis, q=2`).
- `.import` sidecar UID retained — Godot regenerates the imported cache from
  the new source file on first editor open; UIDs are path-derived not
  content-derived, so no diff there.
- Bundle still well under budget: ~6.3 MB / 50 MB.

THEME §6 compliance: track is fully acoustic (lute, flute, soft percussion),
no synth, no Hollywood swell, no AI-trailer tropes — fits the "quiet over
loud, rewards 100+ plays" criterion.

