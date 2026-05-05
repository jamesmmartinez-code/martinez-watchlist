# Eldoria Town Asset Manifest

This manifest tells the world-builder / integrate agents what art is ready
for an expanded multi-town world. Each entry includes the banner asset,
suggested signpost asset, suggested NPC portrait, and a one-line trade hook.

## Existing (already wired)
- **Briarwood Village** — `briarwood_village.png` — starter hamlet (existing NPCs)
- **Whisperwood** — `whisperwood_danger.png` — goblin-haunted forest
- **Crystal Caves** — `crystal_caves.png` — magical cavern dungeon

## New towns ready to add (art shipped, code TBD)

### 1. Goldhaven — Capital City
- Banner: `banners/goldhaven_capital.png`
- Signpost: `banners/sign_to_goldhaven.png`
- Trade NPC: `portraits/ledger_thain.png` — banker, deposits/loans/quest rewards
- Specialty: government, royal quests, capital-only legendary vendors
- Palette: gold + crimson; sigil = crown

### 2. Ironhold — Forge City
- Banner: `banners/ironhold_forge.png`
- Signpost: `banners/sign_to_ironhold.png`
- Trade NPC: `portraits/gemcutter_durnak.png` — jeweler, socketing/gem upgrades
- Specialty: weapon/armor crafting, ore trading, dwarven smiths
- Palette: ember + iron; sigil = hammer-and-anvil

### 3. Silverleaf — Elven Grove
- Banner: `banners/silverleaf_grove.png`
- Signpost: `banners/sign_to_silverleaf.png`
- Trade NPC: `portraits/loremaster_aelin.png` — scholar, lore quests / spell scrolls
- Specialty: arcane learning, herb-mage rituals, ranged-weapon vendor
- Palette: jade + moon-silver; sigil = leaf

### 4. Stormwatch Port — Coastal Hub
- Banner: `banners/stormwatch_port.png`
- Signpost: `banners/sign_to_stormwatch.png`
- Trade NPC: `portraits/brine_yorra.png` — fishmonger, exotic cooking ingredients
- Specialty: shipping, fish-cooked consumables, far-shore-only items
- Palette: slate blue + bronze; sigil = anchor

### 5. Embergrove — Desert Oasis
- Banner: `banners/embergrove_oasis.png`
- Signpost: `banners/sign_to_embergrove.png`
- Trade NPC: `portraits/pyra_solenne.png` — fire-mage, fire-rune trinkets
- Specialty: rare exotic goods, fire-magic trainers, sandstorm escort quests
- Palette: sienna + magma orange; sigil = flame

### 6. Frostpeak Keep — Northern Garrison
- Banner: `banners/frostpeak_keep.png`
- Signpost: `banners/sign_to_frostpeak.png`
- Trade NPC: `portraits/ranger_vorn.png` — hunter, pelts/bows/cold-resist gear
- Specialty: ranger trainers, monster-bounty board, frost-themed gear
- Palette: ice blue + steel; sigil = snowflake

## How to wire these up (world-builder agent's job)

In `scripts/WorldBuilder.gd`, expand the `NPCS` const and add town location
entries. Each new NPC should reference `res://assets/portraits/<file>.png`
in its dialogue panel. Banners go on the town gates as Sprite3D billboards
or skybox-style backdrops. Signposts go at crossroads on the world map.

A suggested travel layout (radial from Briarwood):
```
              Frostpeak Keep
                    |
   Silverleaf ── Briarwood ── Stormwatch Port
                    |
              Goldhaven (capital)
                /        \
           Ironhold   Embergrove
```

All assets are PNG, painterly procedural style, sunset-warm palette where
applicable, sized 1024×256 (banners), 512×256 (signposts), 256×256
(portraits) — drop-in compatible with the existing world art pipeline.

---

## Faction crest sigils (added: art-agent run)

Heraldic 256×256 RGBA sigils for each faction, drawn as painterly escutcheons
with hand-painted brushwork. Use as billboard above town gates, inline in
dialogue panels, and as inventory dividers. CC0 procedural — see
`sigils/ATTRIBUTION.md`.

| Sigil | File | Designed for |
|-------|------|--------------|
| Oak leaf over axe | `sigils/briarwood_crest.png` | Briarwood Village |
| Royal crown | `sigils/goldhaven_crest.png` | Goldhaven (capital) |
| Hammer + anvil | `sigils/ironhold_crest.png` | Ironhold (forge city) |
| Elven leaf | `sigils/silverleaf_crest.png` | Silverleaf (elven grove) |
| Anchor | `sigils/stormwatch_crest.png` | Stormwatch Port |
| Flame | `sigils/embergrove_crest.png` | Embergrove (desert oasis) |
| Snowflake | `sigils/frostpeak_crest.png` | Frostpeak Keep |

Re-render: `python3 scripts/art/gen_sigils.py eldoria-godot/assets/banners/sigils/`
