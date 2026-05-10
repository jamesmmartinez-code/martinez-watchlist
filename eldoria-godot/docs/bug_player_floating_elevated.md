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

## Follow-on Bug: SAFE_SPAWN too close to windmill cylinder (current fix)
`SAFE_SPAWN = Vector3(0, 1, 10)` placed the player only **0.2 m** from the windmill
collision cylinder (center (0, 2.5, 12), radius 1.4 → south edge at Z=10.6).
On scene load Godot's physics engine resolves the near-overlap by briefly applying
a large separation impulse that launches the player upward. The player lands on
the cylinder top (Y=5.0) and appears to be "standing on an elevated wooden structure."
`_do_floor_snap_unstick()` then raycasts from that elevated position and settles the
player at Y=5.5 instead of the ground — making it worse.

Fix applied:
- `SAFE_SPAWN = Vector3(0, 1, 3)` — open village plaza, 9 m from windmill, well clear.
- Player scene transform changed to match.
- Windmill GLB collision radius reduced from 1.4 → 1.1.
- Procedural windmill path given its own collision body (was missing).
- Added 0.05 s deferred `_do_floor_snap_unstick()` in `Player._ready()` so the
  player always starts on actual ground regardless of scene Y value.

## Follow-on Bug: floor-snap +0.5 m offset (commit `tbd`)
`_do_floor_snap_unstick()` was using `hit.position + Vector3(0, 0.5, 0)` as the
snap target.  With the CharacterBody3D capsule setup (CollisionShape3D at y=+0.9,
capsule half-height 0.9 → bottom = body.y + 0.9 − 0.9 = body.y) the body origin IS
the capsule bottom.  So the +0.5 m offset placed the capsule bottom 0.5 m ABOVE the
hit surface on every snap — including spawn and the 2-second jam timer.

Result: player visually floated 0.5 m above the ground after every snap.  Worse, if
the ray hit a building roof (y=3.4) the player landed at y=3.9 and stayed there
because the next jam-timer snap also hit the roof.

Fix: changed offset to +0.02 m so the capsule is flush against the surface and
`floor_snap_length` (0.3 m) latches immediately.

## Rule of Thumb for Future Code
**Never adjust `global_position.y` upward as a stuck-recovery.**
It feels like "give the player room to move" but it accumulates silently.
Always raycast to the floor or teleport to a known safe position instead.

**The floor-snap offset must be near-zero, not 0.5 m.**
`_do_floor_snap_unstick()` places the CharacterBody3D origin AT `hit.position`.
Because the capsule bottom equals the body origin (ColShape +0.9 - half-height 0.9 = 0),
adding any large offset just elevates the player above the surface.
Use `hit.position + Vector3(0, 0.02, 0)` — enough for `floor_snap_length` to latch.

**SAFE_SPAWN must be verified against the actual world layout.**
Check it against the BUILDINGS array AND all prop colliders whenever anything moves.
Use Y=0 (capsule bottom on floor) or at most Y=0.5.
**Leave at least 1.5 m clearance from any collision cylinder (player capsule radius +
0.4 m buffer + 0.7 m physics-impulse margin).**
**SAFE_SPAWN = Vector3(0, 0, 0)** is the verified-clear village centre: no collision
body within 4 m (verified 2026-05-10).

**Building collision boxes must be taller than any reachable jump height.**
If the box top is below the player's max jump apex, it becomes a walkable ledge.
Set height generously (7 m+) so there is no accessible flat surface on the roof.
