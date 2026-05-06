# Procedurally generated icons (Art Director run)

These PNGs were generated procedurally with PIL by the Art Director
agent and are released CC0 / public-domain-equivalent.

Style: painterly hand-painted feel per THEME.md §3 palette
(sunset gold, burnt orange, moss green, wood, parchment) — no AAA
photoreal, no flat-UI vector. 128×128 RGBA, framed circular composition
to match the existing icon set.

## Run history

### Earlier run

| File                     | Item                | Notes |
|--------------------------|---------------------|-------|
| briar_shortbow.png       | weapon, uncommon t2 | thorny green-tinted bow |
| roan_woodbow.png         | weapon, common t1   | plain wood training bow + arrow |
| mossbound_buckler.png    | armor, common t1    | round wooden buckler, mossy rim |

### 2026-05-06 run — coverage gap (6 items)

These items had .tres files but no icon PNG — falling back to category
emojis at runtime. Now covered:

| File                     | Item                  | Notes |
|--------------------------|-----------------------|-------|
| iron_ore.png             | material, common t1   | rough grey-blue ore chunk with iron streaks + amber veins |
| charcoal.png             | material, common t1   | charred logs with glowing ember cracks |
| bone_shard.png           | material, common t1   | angular ivory bone fragment with hairline cracks |
| leather_strip.png        | material, common t1   | coiled brown leather band with stitch detail |
| cavestone_buckler.png    | armor (shield) t3 unc | round stone buckler, iron rim + rivets, rune carving |
| shard_glaive.png         | weapon t6 rare pierce | wooden haft + curved crystal blade w/ arcane glow |

Replaces emoji-fallback `📦 / 🛡 / ⚔` shown when `icon_path` cannot resolve.
Icons are looked up by `res://assets/icons/{item_id}.png` convention; no
`icon` field on ItemResource needed — runtime probes the path.
