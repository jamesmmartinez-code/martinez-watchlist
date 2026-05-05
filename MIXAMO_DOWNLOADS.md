# MIXAMO_DOWNLOADS.md — Animation Sourcing Checklist

James has a Mixamo account (Adobe-owned, free, mixamorig:* compliant per RIGGING_STANDARD.md). This file tracks which animations have been downloaded vs. still pending.

## Download settings (use for ALL anims)
- Format: **FBX for Unity (.fbx)**
- Frame Rate: **30**
- Keyframe Reduction: **None**
- Skin: **With Skin** (first anim per session); subsequent can be "Without Skin"
- Pose: **T-Pose**

## Drop folder
`/Users/jamesmartinez/Documents/Claude/Projects/Realm of Eldoria/mixamo/`
(Animation Sourcer agent reads from there, converts FBX → GLB via fbx2gltf, packs into `eldoria-godot/assets/animations/humanoid_base.tres`)

## Canonical 12 (P0 — every humanoid needs these)
- [ ] idle ← Mixamo: "Breathing Idle"
- [ ] walk ← Mixamo: "Walking"
- [ ] run ← Mixamo: "Running"
- [ ] attack_1 ← Mixamo: "Sword And Shield Slash"
- [ ] attack_2 ← Mixamo: "Sword Attack 2" or "Standing Melee Combo Attack"
- [ ] attack_3 ← Mixamo: "Spin Attack"
- [ ] hurt ← Mixamo: "Standing React Small From Front"
- [ ] die ← Mixamo: "Standing React Death Forward"
- [ ] victory ← Mixamo: "Victory" or "Cheering"
- [ ] wave ← Mixamo: "Waving"
- [ ] yes ← Mixamo: "Yes"
- [ ] no ← Mixamo: "Shaking Head No"

## P1 — Adds life to NPCs and ambient world
- [ ] jump_up ← Mixamo: "Jumping Up"
- [ ] jump_loop ← Mixamo: "Falling Idle"
- [ ] jump_land ← Mixamo: "Falling To Roll"
- [ ] gather ← Mixamo: "Picking Fruit"
- [ ] sit ← Mixamo: "Sitting Idle"
- [ ] smith_hammer ← Mixamo: "Hammering"

## P2 — Class flair (Pillar 1 combat character)
**Pathfinder (Alden):**
- [ ] bow_draw ← Mixamo: "Standing Aim And Draw"
- [ ] bow_release ← Mixamo: "Standing Aim Recoil"
- [ ] kneel ← Mixamo: "Kneeling Pointing"

**Vanguard (Owen):**
- [ ] two_hand_swing ← Mixamo: "Great Sword Slash"
- [ ] shield_bash ← Mixamo: "Bouncing Fight Idle"
- [ ] charge ← Mixamo: "Charging"
- [ ] salute ← Mixamo: "Salute"

## How agent processes them
1. `Animation Sourcer` agent runs every 20 min
2. On run: scans `mixamo/` folder for new `.fbx`
3. Converts to `.glb` via `fbx2gltf`
4. Strips the redundant skin (we want anim tracks only)
5. Loads tracks via Godot headless tool, builds `assets/animations/humanoid_base.tres`
6. Updates `Player.gd` and `NPC.gd` to load the library on `_ready()`
7. Updates this file's checkboxes
8. Commits to `auto/animation` branch

## Why this exists
Without this checklist, James has no clear next-action when he opens Mixamo. With it, he can pull a few in 5 min and see immediate results in-game.
