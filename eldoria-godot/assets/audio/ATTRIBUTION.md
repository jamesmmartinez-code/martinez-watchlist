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

`boss_intro.wav` — placeholder WAV pending replacement; queued for a future
audio pass to convert to OGG and source from a CC0 brass-stinger pack
(candidate: artisticdude "Trumpet/Horn Sound Effects" or Sonniss GDC bundles).

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
