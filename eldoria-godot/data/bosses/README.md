# eldoria-godot/data/bosses/

Authored by the **Bestiary Designer** agent. One `.kit.tres` per boss, with
the schema in `_boss_kit.gd`. Boss kits compose phases and telegraphed
mechanics — a boss is **not** a creature with bigger numbers.

## File layout
- `<boss_id>.kit.tres` — the kit (this folder)
- `../creatures/_loot/<boss_id>.tres` — drop table (must sum to 1.0)

## Authoring rules (per agent spec)
1. Every phase must include at least one telegraphed mechanic. Banned:
   phase with zero tells. (Validated by `BossKit.validate_phases()`.)
2. Tell `wind_up_ms` ≥ 700 (kid-readable). On a first-encounter tell,
   ≥ 1000ms.
3. TTK target band: 90–180s at the boss's nominal level, computed
   against `_dmg_curve.gd` with the boss's armor applied.
4. `arena_requirements` must be filled. If the arena does not yet exist,
   file `# NEEDS:arena:<spec>` for the environment-specialist (in a
   header comment block in the kit file).
5. If the mesh does not exist, file `# NEEDS:mesh:<spec>` for the
   character-specialist. Do not silently fall back to a meshless boss.
6. Loot tables MUST reference items already in
   `data/items/_catalog.csv` — the bestiary does not invent items.

## Roster
| id | region | tier | level | status |
|----|--------|------|-------|--------|
| geode_tyrant | crystal_caves | 3 | 8 | authored — first boss kit |
