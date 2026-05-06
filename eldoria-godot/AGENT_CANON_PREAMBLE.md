# Agent Canon Preamble — READ FIRST (every run, before any code change)

> If your run is going to commit to the repo, you MUST cat both of these
> files at the START of your run and apply their rules. Failure to honor
> them = Canon QA flags your commit S1 BLOCK and the integrator refuses
> to merge.

## The two canonical docs

```bash
cat eldoria-godot/SIZE_STANDARDS.md   # all sizes, world dimensions, camera, particles
cat eldoria-godot/PROBLEMS_LOG.md     # every regression we have ever fixed
```

## Quick-reference (do not memorize — re-read SIZE_STANDARDS.md for full context)

| Thing | Value | Source |
|-------|-------|--------|
| Player target height | **1.10m** (kid Alden 9 / Owen 11) | SIZE_STANDARDS §1 |
| Adult NPC height | 1.65m | §1 |
| Pet height | 0.55m | §1 |
| Tree visual cap | **4.50m** (foreground) | §4 |
| Building hut floor | ≥ 2.50m | §3 |
| Gate tower floor | ≥ 10m | §3 |
| Mountain ring radius | ≥ 200m from village center | §6/§7 |
| Camera default distance | 11m (max 35m) | §9 |
| Camera default pitch | 0.45 rad (~26° down) | §9 |

## Rules of engagement

1. **Any commit that changes a value in SIZE_STANDARDS.md must include `[CANON-APPROVED: <reason>]` in the commit message.** Without that tag, Canon QA blocks your work.
2. **If you find a gotcha listed in PROBLEMS_LOG.md §1, do NOT re-introduce it.** Tag your commit `[REGRESSION: <symptom>]` if you're explicitly reverting.
3. **Tool ranking for 2D**: Adobe > Canva > Figma. Figma needs `[FIGMA-EXCEPTION:]` tag.
4. **Parse errors block everything.** Before push, GDScript syntax must be valid. Common Godot 4.6 gotchas:
   - `const X: PackedStringArray = PackedStringArray([...])` is INVALID — use `const X: Array[String] = [...]`
   - `var x := max(a, b) / c` may fail type inference — use `var x: float = ...`
   - Indentation in `for` loops must match exactly (whitespace-sensitive like Python)
5. **Particle GPUParticles3D quads MUST set `albedo_texture = _make_soft_particle_texture()`.** Without it, quads render as opaque rectangles (the white-blob problem).
6. **Equipment Visualizer must attach gear ONLY via `BoneAttachment3D`.** The runtime SCALE GUARD only walks BoneAttachment3D subtrees.

## Files you should never blind-rewrite

These have hand-tuned values that get re-broken every time an agent regenerates them:

- `eldoria-godot/scenes/Main.tscn` — Hero scale, camera defaults, Player spawn position
- `eldoria-godot/scripts/Player.gd` — `_normalize_player_model`, `_force_hero_height_cap`, panic-keys
- `eldoria-godot/scripts/CameraController.gd` — distance/pitch defaults
- `eldoria-godot/scripts/WorldBuilder.gd::TREE_VARIANTS` — scale_min/scale_max ranges
- `eldoria-godot/scripts/WorldBuilder.gd::_clamp_tree_at_spawn` — height cap value
- `eldoria-godot/scripts/Pet.gd::BARK_LINES`/`BARK_COLORS` — must use `Array[String]`/`Array[Color]` not `PackedStringArray`

If you must touch one of these, READ THE COMMENTS at the top of the function — they explain why the values are what they are.

## When in doubt

`cat eldoria-godot/PROBLEMS_LOG.md` and find the section that matches your symptom. Most failure modes have already been fixed once today. If your change re-introduces a fixed bug, you waste a build cycle.
