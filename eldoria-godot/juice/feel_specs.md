# Game-feel ("Juice") Specs — per-verb feedback

**Owner:** PX. @combat / @anim / @audio implement; PX signs off on numbers.

## Frame

A 9-year-old's brain is reading **bigger** signals than an adult's. Hit-stops should be slightly longer, particle bursts slightly chunkier, and screen shake should hint at the *kind* of impact rather than just confirm one happened. Numbers below are PX targets.

**All effects below MUST gate on `Settings.reduce_motion`.** When that toggle is ON, screen shake is zero, hit-stop is halved, and particle counts are halved.

## Verb 1 — Sword swing (player attack)

| Effect | Value | Notes |
|---|---|---|
| Hit-stop on enemy hit | **80ms** | Pause both the player AND the hit enemy's animation player; resume on the next physics frame |
| Hit-stop on CRIT | **140ms** | Adds a 60ms extra freeze; reads as "that one mattered" |
| Hit-stop on whiff | 0ms | No freeze on miss — the empty swing is its own info |
| Camera shake (hit) | amp **0.05**, dur **120ms** | Tiny. Just enough to say "you connected." |
| Camera shake (CRIT) | amp **0.18**, dur **180ms** | Visibly chunkier than normal hit |
| Particles (hit) | 4–6 sparks, 220ms life | Color: enemy tint (goblin = green, wolf = grey, skeleton = white, crystal = cyan) |
| Particles (CRIT) | 8–12 sparks **plus** a 32px gold flash | Sparks sized 1.4× normal |
| Sound (hit) | sfx `sword_hit.wav` at 1.0× pitch | Already wired |
| Sound (CRIT) | sfx `sword_hit.wav` at **1.18× pitch** + `crit_chime.wav` overlay | Pitch lifts read as "special" without a separate library |
| Sound (whiff) | sfx `sword_whiff.wav` at 0.92× volume | Subtle — don't make whiffs feel like punishment |
| Damage popup | 32pt red `-N`, outline 5 | Already in Player.gd |
| CRIT popup | 56pt gold `CRIT!`, outline 8 | Already in Player.gd, do NOT shrink |

## Verb 2 — Take damage (player gets hit)

| Effect | Value | Notes |
|---|---|---|
| Hit-stop | 60ms | Briefer than dealing damage — keep player feeling agentic |
| Camera shake | amp **0.22**, dur **220ms** | Bigger than dealing damage; punishment must read |
| Vignette pulse | red modulate edge of screen, 240ms | "I'm in trouble" vibe |
| Vignette intensity at <30% HP | red border stays on (subtle) until healed | Critical-HP cue without a number you have to read |
| Sound | sfx `damage_taken.wav` | Already wired |
| Damage popup over player | 32pt red `-N` | Already in Player.gd |
| Controller rumble (future) | 100ms medium | When gamepad lands |

⚠ **Filed:** Vignette + low-HP red-edge effect not implemented today. PX flags @ui-agent.

## Verb 3 — Jump

| Effect | Value | Notes |
|---|---|---|
| Anticipation | none | Animation handles it; no extra particle |
| Apex marker | none | Don't gild a basic verb |
| Land particles | 3 dust puffs (small), 280ms life | Color: ground material tint (grass/stone/sand) |
| Land sound | sfx `footstep_land.wav` | Should exist; if not, alias to footstep |
| Land hit-stop | 0 | Never — kills momentum |
| Camera shake (land from height) | amp 0.08, dur 100ms, **only if fall ≥ 5m** | Communicates "that was a real drop" |

## Verb 4 — Pick up loot / open chest

| Effect | Value | Notes |
|---|---|---|
| Item shimmer | gold sparkle, 240ms | On chest open and on item-pickup |
| Sound | sfx `loot_pickup.wav` | Pitch up 1.05× per rarity tier (common→uncommon→rare→epic→legendary) |
| Popup | "+1 Iron Sword" 28pt, gold | Already in Player.gd |
| Hit-stop | 0 | Pickup is fluid — no pause |
| Camera shake | 0 | Same |
| Rare/Epic/Legendary | screen flash gold (35ms) + chime overlay | The "ooooh" beat for kids |

## Verb 5 — Level up

| Effect | Value | Notes |
|---|---|---|
| Popup | 56pt `LEVEL UP!` gold | Already in Player.gd |
| Hit-stop on player | **220ms** | Long enough to notice — "you EARNED that" |
| Camera radial pulse | gold ring expands from player (360° flat circle), 480ms | New — not implemented |
| Sound | sfx `level_up.wav` | Already wired |
| HP/MP bar pulse | scale 1.0→1.12→1.0 over 360ms | Visual reward for the bar refill |
| Particles | 24 gold sparks rising from feet, 1.2s life | Themed `#FFD86B` per THEME §3 |
| Title-equip toast | if a new title was earned, follow level-up by 1.0s | Already staggered in World.gd |

## Verb 6 — Quest complete

| Effect | Value | Notes |
|---|---|---|
| Toast | gold-bordered, 4s on screen | Already exists |
| Sound | sfx `quest_complete.wav` | If not present, alias to `level_up.wav` at 0.85× pitch |
| Item-reward popup (Lyra's 2× pots) | sequential, 600ms apart | One pot at a time, not stacked |

## Verb 7 — Death

| Effect | Value | Notes |
|---|---|---|
| Hit-stop on death blow | 380ms | Player needs to *see* what killed them |
| Camera dolly | pull back 1.5m from player, settle 600ms | Cinematic moment |
| Death overlay | dark fade, 1.4s in, hold for 1.1s, fade out | Already in World.gd |
| Sound | sfx `player_death.wav` | Already wired |
| Respawn flash | gold burst at SAFE_SPAWN, 240ms | Tells player "you're back" |
| Total time | ≤ 3s end-to-end | PX rule #2 — recoverable |

## Verb 8 — Boss telegraph (charge / slam)

These are NOT player verbs but the player's READ of them is critical.

| Telegraph | Current | PX target |
|---|---|---|
| Charge — red line forward, 0.78s | implemented | ✅ keep |
| Slam — red ring at boss feet, 0.9s | implemented | ✅ keep |
| Add reduced-motion variant | not implemented | flash → steady fill (no modulation) when `Settings.reduce_motion=true` |
| Add audio sting at telegraph start | partial — slam has shout msg | add a low brass cue 200ms before active hit window |

## How to verify (PX checklist)

For any new juice effect being landed:

1. **Test with `Settings.reduce_motion=true`** — does the effect still communicate? If no, the effect was relying purely on shake/flash, not on layered cues. Fix.
2. **Show your 9-year-old.** Within 1 minute of seeing the effect, can she describe what triggered it without you saying anything?
3. **Test stacking.** When 2 hits land in 200ms (multi-target swing), do hit-stops queue or overlap? Should overlap (cap total hit-stop at 200ms regardless of hit count).
4. **Audio + visual independence.** With sound muted, the effect should still read. With visuals minimized (small window), the audio should still read.

## Filed for other agents

- **@combat:** implement camera shake helper (Camera2D-style noise applied to CameraPivot). PX provides amp+dur per effect above.
- **@combat:** hit-stop helper that pauses `AnimationPlayer` and freezes `velocity` for N ms.
- **@ui-agent:** low-HP red vignette + damage vignette pulse.
- **@audio:** confirm `sword_whiff.wav`, `crit_chime.wav`, `loot_pickup.wav`, `quest_complete.wav` exist; alias if not.
