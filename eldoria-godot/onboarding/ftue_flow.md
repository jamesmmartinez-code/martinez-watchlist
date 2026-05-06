# First-Time User Experience (FTUE)

**Owner:** PX. Builder + UI agents implement; PX signs off.

## Frame

Two kids on one couch. The 9-year-old has never played a 3D action RPG. She wants to **swing the sword and see something fall over** within 60 seconds. The 11-year-old wants to **figure out the world** within 5 minutes. Anything the game asks them to read longer than that is a failure.

## Detection (how we know it's a first-time launch)

In `Player.gd`:
```
load_game() returns false  →  no SAVE_PATH file exists  →  this is first launch
```

That's already wired. Add to `World.gd._ready()`:
```
if not _player.load_game():
    _start_ftue()  # PX: first-time hooks
```

## The 10-minute first-time path

| Min | Player sees | Player does | What the engine does |
|---|---|---|---|
| 0:00 | Title fade-in over Briarwood, "Realm of Eldoria" gold-leaf logo | Wait | Skip on any key |
| 0:05 | Spawn at SAFE_SPAWN (0,3,10), back of village, sun warm | Looks around | HelpLabel fades in: WASD: move … (current text is fine) |
| 0:15 | Sword icon "⚔" pulses at bottom-right of HUD | Doesn't know yet | After 5s of any movement input, a small toast: "Try left-click — swing your sword" |
| 0:30 | First Goblin Scout visible 8m east of spawn | Walks toward it OR clicks idle | Auto-aim helps; first hit lands easily |
| 0:45 | Goblin Scout dies (~2 swings at L1) | XP popup, gold drop | "+18 XP" / "+4 gold" floats up |
| 1:00 | Toast: "🌿 Briarwood — talk to Elder Maeve" | Walks to village center | Maeve's nameplate gold-glows when within 6m |
| 1:30 | Maeve dialogue panel opens | Reads / clicks past | Quest panel slides in: "Whisperwood Cleansing — 5 goblins" |
| 2:00 | Quest tracker top-right: "Goblins: 0 / 5" | Walks back east | Spawn density shows 1–2 visible goblins on screen |
| 4:00 | After ~3 kills, level-up popup | LEVEL UP! gold flash | HP refilled to 138, MP to 40 |
| 6:00 | Quest done (5 goblins) | Returns to Maeve | Auto-completes; +80 XP, +60 gold |
| 7:00 | Toast hint: "Try the chest east of the village" | Walks to chest | First chest opens — armor or pot or small weapon |
| 8:00 | Maeve has dialogue refresh; new option: "Where else can I help?" | Hops to next NPC | Lyra, Mara, Roan all have a quest waiting |
| 10:00 | First wolf encounter intentionally placed beyond first chest | Engages | Wolf is a "Standard tier" — 2-hit at L2, satisfying |

## What MUST happen in the first 10 minutes

1. **One enemy dies.** Within 60s of spawn. Guaranteed by goblin spawn placement.
2. **One level-up.** Within 5 min. Guaranteed by quest reward + mob XP.
3. **One full quest cycle (accept → kill → return → reward).** Within 8 min.
4. **One chest opened.** Discovery beat — non-mandatory, but visible from the village edge.

## What MUST NOT happen in the first 10 minutes

- ❌ The player dies. Nothing in band 1–2 should be lethal at full HP.
- ❌ A boss is visible. Warlord arena is gated by Whisperwood depth — keep it that way.
- ❌ A long lore dump. Maeve's default line is currently 1 sentence; KEEP IT.
- ❌ A loading screen. World is one scene; don't add transitions in band 1.
- ❌ Modal blocking UI other than dialogue panel. No tutorial pop-up that requires "Click to continue."

## Tutorial overlays (specced — for `@ui-agent`)

Five tooltip-style overlays, **all skippable with Esc** and **all auto-dismiss after 8s** if ignored:

1. **Spawn (t=2s):** Top-center, "Move with WASD or arrows" — 5 words.
2. **First mob in sight (t=10s of any movement):** "Left-click to swing" — 4 words.
3. **First kill (immediately after):** "Press E to talk to villagers" — 6 words.
4. **First quest accepted:** "Quest log: top-right of screen" — pointer arrow at quest panel.
5. **First level-up:** "You leveled up! Health restored." — celebrate.

Each fires *once per save*; FTUE flag set in save file (`save_data.ftue_done = true`).

## "I'm 9 and I'm stuck" recovery hooks

If the kid is stuck — no XP gained for 90s and no quest accepted — the world should help:
- Ambient toast: "Walk toward the gold ⚔ marker" with a 3D arrow on the closest goblin
- After 180s no XP: a Goblin Scout *walks toward* the player (existing chase AI handles this once aggro range is hit)
- After 300s no quest: Maeve's nameplate pulses (subtle, gold-modulate animation)

Filed for `@npc` and `@hud-agent`: nudge-on-idle behaviors aren't currently in code.

## NEW save vs RETURNING save

- **NEW save** → run FTUE.
- **RETURNING save** → skip FTUE, load player state, fade in HUD silently.
- **NEW save after death-and-restart** → still NEW (FTUE flag is in save file, so no save = no FTUE seen yet).

## What this doc commits to

1. **A kid sees a goblin die within 60 seconds of spawn.** Whatever has to be true for that, gets true.
2. **No reading is mandatory.** Every tooltip is skippable; every dialogue is closable.
3. **Level-up by minute 5.** First reward beat lands fast.
4. **The HelpLabel stays visible for the full first session.** Don't auto-hide it after the FTUE — Alden will forget the controls and need them again.
