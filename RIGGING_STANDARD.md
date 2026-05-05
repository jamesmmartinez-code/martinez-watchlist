# RIGGING_STANDARD.md — Eldoria Canonical Character Rig Spec

This document defines the SINGLE rig contract every humanoid character in Realm of Eldoria MUST conform to. Without it, gear attachment breaks, animation libraries don't share, and every character is a one-off island.

**Source of truth:** Mixamo's `mixamorig:` bone naming convention. Mixamo is free, Adobe-owned, and the de-facto industry standard for humanoid rigs. Every Meshy auto-rig defaults to it. Sketchfab characters that ship with different rigs MUST be retargeted to it before commit.

## Required bones (humanoid characters: heroes, NPCs, enemies, bosses)

```
mixamorig:Hips                    ← root, auto-orientation Y-up, T-pose at rest
├── mixamorig:Spine
│   ├── mixamorig:Spine1
│   │   ├── mixamorig:Spine2          ← chest_back attachment (capes go here)
│   │   │   ├── mixamorig:Neck
│   │   │   │   └── mixamorig:Head   ← head attachment (helmets, crowns, hoods)
│   │   │   ├── mixamorig:LeftShoulder
│   │   │   │   └── mixamorig:LeftArm
│   │   │   │       └── mixamorig:LeftForeArm
│   │   │   │           └── mixamorig:LeftHand    ← left_hand attachment (shields)
│   │   │   └── mixamorig:RightShoulder
│   │   │       └── mixamorig:RightArm
│   │   │           └── mixamorig:RightForeArm
│   │   │               └── mixamorig:RightHand   ← right_hand attachment (weapons)
├── mixamorig:LeftUpLeg → LeftLeg → LeftFoot
└── mixamorig:RightUpLeg → RightLeg → RightFoot
```

The five GAME-RELEVANT bone attachments Player.gd / NPC.gd reference:
- `right_hand` → `mixamorig:RightHand` (weapons)
- `left_hand` → `mixamorig:LeftHand` (shields, off-hand)
- `head` → `mixamorig:Head` (helmets, hoods, crowns)
- `chest_back` → `mixamorig:Spine2` (capes, backpacks)
- `hip` → `mixamorig:Hips` (belts, holsters — rare)

`Player.gd` keeps a remap dict in case a character's rig prefixes are stripped:
```gdscript
const BONE_ALIASES = {
  "right_hand": ["mixamorig:RightHand", "RightHand", "Hand_R", "hand.R", "Bip01_R_Hand"],
  ...
}
```
On `_ready()`, walk the Skeleton3D and pick the first matching bone for each slot.

## Required animations (every humanoid character ships with these — see `eldoria-godot/assets/animations/humanoid/`)

| Track | Trigger | Loops | Required |
|---|---|---|---|
| `idle` | default state | yes | YES |
| `walk` | speed > 0, < run_threshold | yes | YES |
| `run` | speed > run_threshold | yes | YES |
| `attack_1` | left-click | once | YES |
| `attack_2` | combo follow-up | once | optional |
| `attack_3` | combo finisher | once | optional |
| `hurt` | took damage | once | YES |
| `die` | hp ≤ 0 | once, holds last frame | YES |
| `victory` | combat ended, won | once | optional |
| `wave` | NPC greeting / emote | once | YES (NPCs only) |
| `yes` / `no` | dialogue reactions | once | optional |
| `jump_up` / `jump_loop` / `jump_land` | jump cycle | n/a | optional |

Animations live in `AnimationLibrary` resources at:
- `assets/animations/humanoid_base.tres` — shared across all humanoids
- `assets/animations/humanoid_<class>.tres` — class-specific overrides (Pathfinder bow draw, Vanguard sword swing)

Player.gd / NPC.gd / Enemy.gd load the base library + appropriate override into their AnimationPlayer at startup so EVERY character has the full set, regardless of what the source GLB shipped with.

## Required scale + origin
- Default character height: 1.8 m (Y-axis), measured AABB from foot → top of head
- Origin (0,0,0) at the bottom of the feet (NOT pelvis, NOT navel — feet)
- T-pose at rest: arms stretched outward parallel to ground, legs straight, palms facing down
- Up axis: Y. Forward axis: -Z (Godot convention)

Scale normalizers in `Player.gd::_normalize_to_height(1.8)`, `NPC.gd::_normalize_to_height(1.8)`, etc. enforce this even when an inbound GLB ships with wrong scale (Sketchfab outputs are notoriously inconsistent — some 5m tall, some 0.1m tall).

## How to apply (workflow)

**For Meshy generations:**
- Always use the "Rig & Animate" step after text-to-3D
- Meshy defaults to mixamorig:* bone names, so output is compliant out of the box

**For Sketchfab CC-BY downloads:**
- Inspect the GLB's bone names BEFORE committing (Godot's import dock shows the skeleton)
- If bones aren't `mixamorig:*` → retarget in Blender (5-min job): import GLB, use the Mixamo Auto-Rig add-on or rename bones manually, re-export as GLB
- Add an alias entry to `BONE_ALIASES` in Player.gd if mismatch is one-off

**For new agents touching characters:**
- Character Specialist: enforce this contract at commit time. Reject inbound GLBs that don't conform unless they include a Blender-retargeted variant.
- Equipment Visualizer: trust this contract. Always look up bones via `BONE_ALIASES`.
- Animation Sourcer: pull from Mixamo (already mixamorig:*-compliant). Output AnimationLibrary resources keyed by the canonical animation name list above.

## Why this exists
Without a rig spec, every character GLB is a one-off. Equipment attaches incorrectly. Animations don't share. Adding a new NPC requires a custom controller. Eldoria stays brittle.

With this spec, the moment a new GLB lands in `assets/models/`, the Equipment Visualizer can attach gear correctly, the Animation Sourcer can play the full action set, and the Physics Engineer can validate movement uniformly. The whole pipeline becomes plug-and-play.
