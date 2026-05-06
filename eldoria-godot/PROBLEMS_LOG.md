# Realm of Eldoria — Problems Log (LOCKED, agent-mandatory reading)

> **All agents must read this file before making any commit that touches:**
> - Player.gd, CameraController.gd, WorldBuilder.gd, Pet.gd, NPC.gd
> - Main.tscn or any scene under scenes/realms/
> - Any TREE_VARIANTS or *_VARIANTS array
> - Any scale/distance/pitch numeric value
>
> If your intended change re-introduces any pattern listed below, your
> commit will be rejected by Canon QA with a `[REGRESSION:]` flag.

Last updated: **2026-05-06** by james-via-claude

---

## §1 — Patterns that have ALREADY broken the game and must NOT come back

### §1.1 GDScript parse errors (fail entire script load → empty world)

| Anti-pattern | Why it fails | Correct form |
|--------------|--------------|--------------|
| `const X: PackedStringArray = PackedStringArray([...])` | Constructor calls aren't constant expressions in Godot 4.6 | `const X: Array[String] = [...]` |
| `const X: PackedColorArray = PackedColorArray([...])` | Same | `const X: Array[Color] = [...]` |
| `var x := some_func() / max(a, b)` | `max()` returns Variant — type inference fails | `var x: float = some_func() / max(a, b)` |
| Off-by-one tab indent in `for` loop body | GDScript is whitespace-sensitive like Python | Match indent of surrounding statements exactly |
| Trailing comma in inline `# comment` after dict close `}` | Comments eat the array-separator | Put `},` BEFORE the `# comment`, not after |

### §1.2 Visual scale violations (game becomes unplayable)

| Symptom | Cause | Fix |
|---------|-------|-----|
| Giant brown wall blocking view | Tree GLB scale_max × source-GLB-meters > 14m | Cap with `_clamp_tree_at_spawn` (currently 4.5m) and keep TREE_VARIANTS scale_max ≤ 1.05 |
| Player towering over buildings | `_normalize_player_model(1.8)` (adult height) | LOCKED at 1.10m — kid-sized. See SIZE_STANDARDS.md §1 |
| Mountains in face of player | Mountain ring radius < 200m | Inner ring 220m+, outer 320m+. SIZE_STANDARDS.md §6/§7 |
| Giant boot/helmet/cape | Equipment GLB rendered at native scale, ignoring player scale | Player.gd `_clamp_all_attachments_scale()` walks BoneAttachment3D subtrees and shrinks any mesh > 1.5m |
| Camera shows only sky | Camera pitch > 0.65 rad → looking up | Pitch locked at 0.45 rad, distance 11m. SIZE_STANDARDS.md §9 |
| WASD doesn't move player | Camera pitch too steep, "forward" maps below ground | Same — pitch ≤ 0.55 |

### §1.3 Particle effect blowouts (white/orange rectangles everywhere)

| Symptom | Cause | Fix |
|---------|-------|-----|
| Solid bright orange rectangles around campfire | `emission_energy_multiplier=6.0` + no `albedo_texture` | Energy ≤ 1.5, ALWAYS set `albedo_texture = _make_soft_particle_texture()` |
| White puffy blobs filling village (smoke) | StandardMaterial3D quad with no texture → opaque white-tint rectangles | Same — soft particle texture is mandatory |
| Disabled effects keep coming back | Agents re-enable `_build_falling_leaves` / `_build_firefly_particles` without proper textures | Don't re-enable until you've added `_make_soft_particle_texture()` AND verified scale ≤ 0.4m |

### §1.4 Spawn / collision (player ends up below ground)

| Symptom | Cause | Fix |
|---------|-------|-----|
| Player falls forever | Spawn Y too low + raycast max_drop too small to find ground | SAFE_SPAWN Y = 5, snap raycast max_drop = 50m |
| Player half-buried in ground | Hero.glb pivot at center not feet | `_normalize_player_model` lifts so visible bottom = body-local Y=0 |
| Below-Y=-2 stuck state | No rescue path from below-world | New rescue: any time `global_position.y < -2`, teleport to Y=5 |

### §1.5 Equipment Visualizer + scale interaction

| Symptom | Cause | Fix |
|---------|-------|-----|
| Boots fill the screen | BoneAttachment3D inherits bone transform but child gear GLB has world-scale | `_clamp_all_attachments_scale()` walks `BoneAttachment3D` subtrees only, shrinks any mesh > 1.5m |
| Player body shrinks too | Earlier name-based exemption ("body"/"hero") didn't match Meshy's "Beta_Surface" naming | NOW: scope strictly to BoneAttachment3D — body mesh sits under Skeleton3D directly, never touched |

---

## §2 — Theme tool ranking (locked)

For 2D content (UI, quest cards, NPC portraits, item icons, banners, mood boards):

1. **Adobe** — Firefly / Express / Photoshop / Illustrator / Substance / Stock — primary
2. **Canva** — secondary
3. **Figma** — last resort. Commit message MUST include `[FIGMA-EXCEPTION: <reason>]`. Without that tag, Canon QA blocks the merge.

3D pipeline (meshes, materials, animations) is unaffected — Substance/Meshy/Sketchfab/Mixamo/ActorCore are fine.

---

## §3 — Commit message conventions

| Tag | When to use | Effect |
|-----|-------------|--------|
| `[CANON-APPROVED: <reason>]` | Changing any value listed in SIZE_STANDARDS.md or PROBLEMS_LOG.md | Bypasses Canon QA's auto-block on those values. Reason must be specific. |
| `[FIGMA-EXCEPTION: <reason>]` | Used Figma for a 2D asset because no Adobe/Canva path worked | Bypasses Canon QA's tool-compliance check |
| `[REGRESSION: <symptom>]` | Reverting an agent commit that re-introduced a fixed bug | Documents why the revert was needed |
| `[PARSE-FIX: <file>:<line>]` | Fixing a GDScript parse error | Triggers a follow-up audit of the file's siblings |

---

## §4 — Today's full audit (2026-05-06)

In order of fix:

1. **Char-Select-Bot reverted main_scene** to CharacterSelect.tscn (broken). Reverted to Main.tscn. Commit `2a486732`.
2. **Trees rendered at 14-17m** (oak/pine scale_max too high × 8m GLB). Capped TREE_VARIANTS, then runtime cap 14m → 4.5m. Commit `5681982d`.
3. **Player normalized to 1.80m (adult)**. Locked to 1.10m kid-size. Multiple commits.
4. **Equipment boots/helmets at world scale**. Added `_clamp_all_attachments_scale()` scoped to BoneAttachment3D. Commit `3d0f0e6e`.
5. **Pet.gd parse error** — `const BARK_LINES: PackedStringArray = PackedStringArray([...])` not a constant expression. Commit `90959643`.
6. **WorldBuilder.gd parse error** — TREE_VARIANTS commas eaten by inline comments from sloppy regex replace. Commit `48daedaf`.
7. **NPC.gd $Label3D / $InteractArea spam** — those nodes don't exist on programmatically-built NPCs. Switched to `get_node_or_null`. Commit `36da4bfd`.
8. **Mountain ring at 90m / 160m** (way too close). Pushed to 220m / 320m. Commit `4c30a5d8`.
9. **WorldBuilder.gd:1494 indent error** — agent re-enabled fireflies with broken indent. Commit `18cf9419`.
10. **SIZE_STANDARDS.md rebuilt** as canonical doc. Commit `3f8c36e4`.
11. **Campfire blowout** — emission energy 6.0 + no soft texture = solid orange rectangles. Reduced energy, scale, particle count, ADDED soft texture. Commit `e69aaca9`.
12. **Falling leaves + fireflies re-enabled by agent without soft textures**. Re-disabled. Same commit.
13. **Worker cache-control too short** (5min for everything including 90MB pck). Deployed v1.3.0-cache with per-extension TTLs (HTML 60s, JS 1h, WASM/PCK 24h+swr 7d).
14. **Player spawning below ground**. SAFE_SPAWN Y=3→5, snap raycast 4m→50m, below-Y=-2 rescue. Commit `9a34b1f9`.
15. **Character native AABBs ranged from 1.0m to 433m** — runtime normalizers always corrected, but first frame flashed giant before deferred call. Char-Specialist 2026-05-06 added `nodes/root_scale=` clamps to every .import file, created the four missing ones (`maeve`, `smith_edda`, `goblin`, `wolf`), and recorded native AABB + root_scale in `CHARACTER_AUDIT.md`. See that file for the table; bulk source-AABB approval logged there.

---

## §5 — Open follow-ups (not blockers, just queued)

- White-particle re-enable: requires `_make_soft_particle_texture()` to be wired into ALL particle materials before the methods can run again
- NPC interactivity: WorldBuilder doesn't add Label3D/InteractArea children to programmatic NPCs (so no name labels, no E-to-talk). Track in qa/_canon_flags.md
- Workers AI agent migration: item-designer done, recipe + bestiary + polisher pending
- Multi-Mac swarm: Mac mini #2 + MBP setup queued

---

When in doubt, READ THIS FILE FIRST.
