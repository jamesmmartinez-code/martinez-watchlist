# Bug: NPC Collision Capsule Launches Player Into the Air

## Symptom

Players walking near any NPC are abruptly deflected upward — the same floating
symptom described in `bug_player_floating_elevated.md`. The player appears to
"ride" the NPC's collision shape and ends up elevated several metres above the
ground.

## Root Cause

`NPC._lift_npc_to_ground()` in `scripts/NPC.gd` was adjusting the root node's
position to sink NPCs into the terrain at spawn:

```gdscript
# BAD — moves the physics root, floating the collision capsule off the ground
global_position.y += lift
```

The NPC scene is a **StaticBody3D** root with a **CollisionShape3D** child
(CapsuleShape3D, radius=0.4, height=1.8, centred at local Y=0.9 — so the
capsule runs from Y=0 to Y=1.8 in local space).

When the root node was lifted, the CollisionShape3D moved with it. The capsule's
curved dome then sat above the ground surface rather than flush with it. Any
player who walked within capsule radius was caught by that curved top and
deflected upward, exactly replicating the player-floating bug.

## The Fix (commit `4443884`)

Instead of lifting the root, lift only the **visual model child** — the first
`Node3D` child that is not a `CollisionShape3D`, `Label3D`, `Area3D`, or
`AudioStreamPlayer3D`:

```gdscript
# Good — only the GLB mesh moves; the collision shape stays at its authored position
func _lift_npc_to_ground(lift: float) -> void:
    for child in get_children():
        if child is Node3D \
                and not child is CollisionShape3D \
                and not child is Label3D \
                and not child is Area3D \
                and not child is AudioStreamPlayer3D:
            child.position.y += lift
            break
```

The CollisionShape3D remains at its authored local position (centre Y=0.9, feet
at Y=0, head at Y=1.8), flush with the ground. The GLB mesh rises to sit on top
of the ground surface. Players now pass beside NPCs without any upward deflection.

## Rule of Thumb

**When fixing NPC pivot or burial issues, always lift the MODEL child — never
the physics root.**

The collision shape is the source of truth for ground contact. Moving the root
floats the capsule; moving only the mesh keeps physics correct while the visual
appears grounded.
