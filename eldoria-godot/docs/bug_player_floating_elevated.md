# Bug: Player Floating / Stuck Elevated

## Symptom
Player character ends up floating above the ground — sometimes above rooftops.
Moving feels normal but the player is several metres in the air.
Getting more stuck makes it worse.

## Root Cause
The stuck-recovery code in `Player.gd` (`_physics_process`) was doing:

```gdscript
# BAD — cumulative, launches player into the air
global_position.y += 1.5
```

This ran every second the player was pressing a movement key but not moving
horizontally (e.g. pushing against a wall, corner, or ledge).
Each episode added 1.5 m of height. A few wall brushes → floating above buildings.

A second contributor: `SAFE_SPAWN` was at `Y = 5`, so after any respawn the
player started 5 m off the ground.

## The Fix (applied in commit `24ef063`)

### 1. Replace `y += 1.5` with a floor-snap raycast

```gdscript
# Player.gd — _do_floor_snap_unstick()
func _do_floor_snap_unstick() -> void:
    velocity = Vector3.ZERO
    var space  := get_world_3d().direct_space_state
    var origin := global_position + Vector3(0,  2.0, 0)
    var target := global_position + Vector3(0, -8.0, 0)
    var query  := PhysicsRayQueryParameters3D.create(origin, target)
    query.exclude        = [self]
    query.collision_mask = 1   # terrain / static bodies only
    var hit := space.intersect_ray(query)
    if hit:
        global_position = hit.position + Vector3(0, 0.5, 0)
    else:
        global_position = SAFE_SPAWN   # fallback if nothing below
```

Raycast finds the actual floor and snaps the player to it.
Falls back to `SAFE_SPAWN` only when there is genuinely nothing below.

### 2. Lower SAFE_SPAWN

```gdscript
# Before
const SAFE_SPAWN := Vector3(0, 5, 10)

# After
const SAFE_SPAWN := Vector3(0, 1, 10)
```

`Y = 1` is enough to clear thin geometry without leaving the player airborne.

### 3. Increase the jam timer threshold

```gdscript
# Before: triggered after 1 second of not moving
if _jam_timer > 1.0:

# After: 2 seconds — normal wall-slides no longer trigger it
if _jam_timer > 2.0:
```

### 4. Unify all panic-key escape positions

BACKSPACE, F1, and `]` all previously used `Vector3(0, 2, 0)`.
Changed to `SAFE_SPAWN` so every escape route lands in the same place.

## Manual Escape (always works in-game)
- **BACKSPACE** — full unstick: clears all state, teleports to spawn
- **F1** — soft unstick: teleports to spawn
- **`]`** — alias for F1 (for keyboards with locked function keys)

## Follow-on Bug: SAFE_SPAWN inside a building roof (commit `2612242`)
`SAFE_SPAWN` was briefly set to `Vector3(8, 3, 5)` — Y=3 places the player
inside the roof mesh of the building at `(6,0,6)`. Physics ejected them upward
on every spawn. Fix: move SAFE_SPAWN to `Vector3(0, 1, 10)`, an open area with
no buildings within 6 m, and call `_do_floor_snap_unstick()` after every teleport.

## Follow-on Bug: building wall collision top was a walkable ledge (commit `677a38f`)
Building wall collision box was `height=3.1, centre y=1.55` → top face at Y=3.1,
right at eave level. Any small upward nudge left the player standing on that flat
surface, looking like they were on the roof. Fix: extend to `height=7.0, centre
y=3.5` so the top face is at Y=7 — unreachable by any normal jump.

## Rule of Thumb for Future Code
**Never adjust `global_position.y` upward as a stuck-recovery.**
It feels like "give the player room to move" but it accumulates silently.
Always raycast to the floor or teleport to a known safe position instead.

**SAFE_SPAWN must be verified against the actual world layout.**
Check it against the BUILDINGS array whenever buildings move. Y should be 0–1,
not mid-air. Always follow a teleport with `_do_floor_snap_unstick()`.

**Building collision boxes must be taller than any reachable jump height.**
If the box top is below the player's max jump apex, it becomes a walkable ledge.
Set height generously (7 m+) so there is no accessible flat surface on the roof.
