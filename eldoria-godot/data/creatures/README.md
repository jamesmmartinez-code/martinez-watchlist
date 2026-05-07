# eldoria-godot/data/creatures/

Authored by the **Bestiary Designer** agent. One `.tres` per creature, with
the schema in `_creature_def.gd`. Loot tables live in `_loot/<id>.tres`.

## Adding a creature
1. Confirm the creature `id` matches an entry in `Items.gd::DROP_TABLE` (or
   coordinate with the item-designer agent to add one — never let an enemy
   ship without loot).
2. Sanity-check TTK against `_dmg_curve.gd`:
   - Trash mob @ band: 5–9s
   - Elite @ band: 18–30s
3. Reference an existing mesh; if absent, file `# NEEDS:mesh:<spec>` for the
   character-specialist (do NOT silently fall back to `worker_girl.glb`).
4. Cross-check `regions[]` against `data/spawn_tables/<region>.tres`.

## Bans (per agent spec)
- ❌ NO behavior-tree code in `.tres` — only `behavior_tags` (strings).
- ❌ NO new damage types without pinging item-designer.
- ❌ NO bosses with zero telegraphed mechanics.
- ❌ NO loot tables that don't sum to 1.0.

## Telegraph windows
- First-encounter creatures: `wind_up_ms ≥ 700` (kid-readable).
- Caves are level-6+ content — Alden's reaction window is the gate.
