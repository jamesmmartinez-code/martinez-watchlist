# Realm of Eldoria — Gear Assets

Owned by: **Equipment Visualizer agent** (see `<repo-root>/AGENTS_README` ↦ Equipment Visualizer).

## Convention

Each gear piece lives at:

    assets/gear/<slot>/<item_id>.glb

Where `<slot>` is one of:

| Slot         | Bone attached to                      | Items                              |
| ------------ | ------------------------------------- | ---------------------------------- |
| `right_hand` | RightHand (palm grip)                 | swords, axes, daggers, staves, bows|
| `left_hand`  | LeftHand                              | shields, off-hand daggers, focus   |
| `head`       | Head                                  | helmets, hoods, crowns             |
| `chest`      | Spine/Chest (vertex-skinned)          | armor pieces (skinned to body rig) |
| `chest_back` | Spine (offset behind ribcage)         | capes, cloaks, quivers, wing-packs |
| `hip`        | Hips (offset on belt-line)            | sheathed weapons, scabbards, pouches|

`<item_id>` MUST match the key in `scripts/Items.gd` exactly (e.g. `iron_sword.glb`
for the `iron_sword` item entry).

## Authoring rules

1. **No procedural primitives.** No BoxMesh sword, no CylinderMesh helmet. The
   asset must be a real authored mesh (Sketchfab CC-BY, Meshy, hand-modeled).
2. **Size budget:** every gear GLB MUST be under **5 MiB** (preferably under
   2 MiB). OPERATIONS §15 still in force — Cloudflare Pages 25 MiB hard cap on
   any single deployable file.
3. **Pose:** grip / origin at world (0,0,0). For weapons, blade points along
   the bone's +Y axis (i.e. up out of the palm). Player.gd applies a 90° X
   rotation so the blade extends forward when held.
4. **Cross-character compatibility:** the same gear GLB must attach cleanly to
   ALL hero GLBs (Alden's, Owen's, the 7 NPC bodies). Don't bake hand
   geometry into the gear scene — only the gear itself.
5. **Tier variants are a runtime tint, not a separate file.** `iron_sword.glb`
   serves both the common drop AND its rare/epic re-skins; Player.gd reads
   the equipped item's `rarity` field and applies a Color overlay
   (see `_apply_tier_tint` in Player.gd).

## Fallback behavior

Until a GLB exists for a given `<slot>/<item_id>`, Player.gd falls back to
procedural primitives (the legacy `_build_sword` / `_build_axe` / `_build_dagger`
path). This keeps the kid's hero visibly armed during the asset pipeline ramp,
even though `THEME.md` flags procedural primitives as "stop-gap only — replace
with authored GLBs ASAP." Do not commit new procedural fallbacks for new slots
— if there's no GLB, the slot stays empty until one ships.

## How to add a new gear piece

1. Drop `<item_id>.glb` into `assets/gear/<slot>/`.
2. If it's a brand-new item, add the matching entry to `scripts/Items.gd`.
3. Commit. No code changes needed — Player.gd auto-detects the file via
   `ResourceLoader.exists()` at equip time.
