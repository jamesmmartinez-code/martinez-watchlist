# Realm of Eldoria — Game Design Document

**This is the north star.** Every feature shipped by every agent must explicitly advance one of the **seven progression pillars** below. Commit messages must cite the pillar.

The pitch in one sentence:
> **Minecraft's build-what-you-imagine + World of Warcraft's earn-power-and-fight-epic-things, wrapped around a restoration story for two brothers.**

---

## 1. The premise

The **Sundering** shattered Eldoria 200 years ago. Most regions are abandoned, ruined, monster-claimed. The Three Crowns are hollow. The Wild Pantheon's shrines are dark. **Briarwood is the last lit village.**

The brothers (player characters) arrive — chosen by Elder Maeve, who saw them in a stag-priest's vision. Their job is not to conquer Eldoria. It is to **restore** it. Not as kings. As stewards.

Each region they bring back is a chapter. Each chapter unlocks new NPCs, professions, dungeons, mounts, lore, and **building blocks**.

## 2. The two protagonists

Designed for **Alden (9, frog 🐸)** and **Owen (11, race car 🏎️)**, brothers who play together.

### Alden — **Pathfinder**
Patient, exploration-leaning, loves animals. Subclass tree:
- **Companions** — more pet slots (start with Ember, end with ~6 active)
- **Nature Magic** — heal, grow, soothe wild creatures
- **Discovery** — finds hidden paths, rare codex pages, secret blocks (Minecraft-style hidden ore veins, fey-glade entrances)

### Owen — **Vanguard**
Fast, challenge-leaning, loves speed and gadgets. Subclass tree:
- **Mounts** — faster + more variety (horse → stag → wolf-rider → dragonling)
- **Combat** — combo chains, charge attacks, parry-counter (WoW-style ability rotations)
- **Engineering** — gadgets (grappling hook, smoke bomb, signal flare, redstone-equivalent contraptions)

**~30% of content is co-op-required.** Most quests have one path easier per class. Boss telegraphs reward role coordination.

## 3. The core loop

```
   GATHER   →   CRAFT   →   EXPLORE   →   CLEAR   →   RESTORE   →   BUILD   →   UNLOCK   →   GATHER deeper
```

Each cycle:
- **Gather** — chop wood, mine ore, harvest herbs, hunt for hides (Minecraft-style resource collection)
- **Craft** — turn raw materials into gear, food, building blocks, contraptions (Smithing/Alchemy/Cooking professions)
- **Explore** — push into a new region or dungeon, unlock map fog
- **Clear** — combat encounters, dungeon bosses (WoW-style mechanics with telegraphs)
- **Restore** — repair the region (rebuild bridges, replant trees, light shrines) using crafted/gathered resources
- **Build** — decorate Briarwood with the player's own hand-placed blocks
- **Unlock** — new NPCs move to Briarwood, new professions, new dungeons, new building blocks, new tameable creatures

## 4. The six regions (the campaign)

1. **Whisperwood** — clear Goblin Warlord, replant Druid's Heart Tree, earn deer-folk trust → unlocks Druidcraft profession + 5 new building blocks (mossy stone, oak plank, leaf canopy, wildflower bed, rune stone)
2. **Crystal Caves** — break Crystal Guardian's binding, restore the pilgrim road → unlocks Gemcrafting + crystal blocks + glowing crystal lamp + the Astronomer's Tower archetype
3. **Sunken Harbor** — rebuild docks, befriend merfolk, unlock ocean travel → unlocks Fishing + boats + coral blocks + sea-glass windows
4. **Iron Crown Citadel** — restore kingdom seat, choose between three claimants → unlocks Royal Architecture pack (banners, tapestries, gilded stone, marble)
5. **The Frostmarch** — reach Pale Wyrm's grave, decide if it stays sleeping → unlocks Frost magic + ice blocks + dragon-bone furniture
6. **The Veil** — find what survived the Sundering → unlocks the endgame Memorial Garden block set

## 5. The seven progression pillars

These are the lanes agents must align their work to. Pick one per feature.

### Pillar 1 — **Combat power** (Owen's lane, WoW-style)
WoW-derived: levels 1-50, talent trees (3 specs per class), gear with rarity tiers (already in Items.gd), dungeon-drop loot, raid bosses with telegraphed mechanics, ability rotations with cooldowns. Owner files: `Player.gd` (combat half), `Enemy.gd`, `Boss.gd`, `Items.gd` (weapons), `Talents.gd` (NEW).

### Pillar 2 — **Companions & taming** (Alden's lane)
Pets, mounts, animal sanctuary, druid grove. Each pet has multi-stage bonding (feed → brush → walk → play → name). Up to 6 active pets long-term. Mount stable holds 12+ steeds. Owner files: `Pet.gd`, `Mount.gd`, `Sanctuary.gd`, `BondingMinigame.gd` (NEW).

### Pillar 3 — **City-building** (joint lane, the LONG game) — **MINECRAFT-STYLE**
**This is the long-term progression.** Briarwood is THE long-running protagonist of this game. It starts as 6 timber houses. It grows into a player-built fantasy capital.

Mechanics — explicitly Minecraft-derived:
- **Block placement on a free grid** — kids decorate Briarwood AND their personal plot of land
- **Building blocks unlocked via region restoration** (see §4)
- **Crafting recipes** for blocks (`stone_block` = 4 stone, `oak_plank` = 1 log, etc.)
- **Mining + chopping + harvesting** to gather raw materials
- **Furniture blocks** for interiors (chairs, tables, beds, bookshelves, paintings)
- **Decoration blocks** (banners, tapestries, lanterns, fireplaces)
- **Functional blocks** that do things (workbench → crafts gear, alchemy table → brews potions, well → restores HP, signpost → sets respawn)
- **Player-designed dungeons** (late-game) — the kids design rooms, set monster spawns, friends visit

Each region restoration funds new building unlocks AND new BLOCKS:
- Restore Whisperwood → +5 nature blocks + Druid Grove building unlocked
- Restore Crystal Caves → +6 crystal blocks + Crystal Forge unlocked
- Restore Sunken Harbor → +7 sea blocks + Harbor + boat workshop
- Restore Iron Crown → +8 royal blocks + Palace
- Restore Frostmarch → +6 frost blocks + Astronomer's Tower
- Restore the Veil → +final-region memorial blocks

Owner files: `BuildingPlacement.gd` (NEW — block grid system), `Crafting.gd` (NEW — recipe book), `Inventory.gd` (extend with raw materials), `WorldBuilder.gd` (extended for dynamic Briarwood layout).

### Pillar 4 — **Knowledge / lore**
Codex entries (collectible), faction reputations, dialogue trees, learned languages (Old Faerie, Goblin-Cant). Owner files: `lore/**`, `data/dialogue/**`, `data/codex/**`, `NPC.gd`.

### Pillar 5 — **Skill professions**
Each NPC teaches a profession with its own progression:
- **Smithing** (Smith Edda) — forge weapons, upgrade gear, gem-socket
- **Alchemy** (Lyra) — brew potions, mix elixirs, gather herbs
- **Cartography** (Roan) — map regions, find hidden paths
- **Wayfinding** (Hala) — meditate at shrines for stat boons
- **Cooking** (Bram) — prepare buff foods, host feasts
- **Druidcraft** (NEW NPC, unlocks after Whisperwood) — grow plants, befriend animals, weather magic
- **Fishing** (NEW NPC, unlocks after Sunken Harbor)
- **Gemcrafting** (Smith Edda extended after Crystal Caves)

### Pillar 6 — **Permanent consequence**
World reacts to player choices, lasting forever. Defended a road = bandits weaker. Saved a village = +3 NPCs there permanently. Killed a faction leader = that faction shifts politics. Owner files: `WORLD_STATE.md`, `data/factions.json`, `NPC.gd` memory hooks.

### Pillar 7 — **Daily life (the Sims layer)**
When players aren't questing, the world should feel inhabited:
- NPCs do day jobs at scheduled times (Maeve gardens at dawn, Smith hammers all day, Bram serves dinner at evening)
- Festivals trigger on calendar dates (Brigid's Feast = double-XP weekend; Sunderingday = solemn lore unlock)
- Weather follows seasons; spring brings butterflies, autumn falling leaves, winter snow
- Pet bonding rituals (brush Ember once a day to raise affinity)
- Briarwood gossip propagates between NPCs based on player actions
- Players can sit at tavern, fish at pond, sleep in their built bed

Owner files: `NPC.gd` schedules, `Calendar.gd` (NEW), `Weather.gd`, `AmbientLife.gd`.

## 6. The endgame

Restoring all 6 regions unlocks **The Veil**. Inside is the truth of the Sundering and a choice:
1. **Restore Eldoria fully** — pre-Sundering state. Loses the Wild Pantheon and goblins.
2. **Leave the wild magic intact** — keeps goblins, fey, ancient creatures.
3. **Reshape it** — built from cumulative player choices throughout the campaign.

Choice is **permanent**, saved to `PLAYER_MODEL.md`, read on every reload thereafter. Their world reflects who they became.

After endgame, the loop continues:
- New procedural dungeons unlock weekly
- Briarwood building can continue indefinitely
- Pet collection completes ~50 creatures
- Player-built dungeons sharable with friends
- Late-game raids that require fully-built Briarwood (need infirmary + barracks + smithy levels)

## 7. What makes Eldoria unique (no one else does this)

Every agent should be aware:

1. **Designed FOR two specific kids.** Class system maps to their personalities. Dynamic difficulty per-player calibrated to age 9 vs 11.
2. **Minecraft + WoW combination, not either alone.** You can't grind raids in Minecraft. You can't decorate your hometown brick by brick in WoW. Eldoria does both.
3. **City-building as primary progression**, not optional fluff. Briarwood is THE long-term character.
4. **Permanent consequence without grimdark.** No save scumming. Choices stick.
5. **Pet bonding deeper than any MMO** — multi-stage growth, daily rituals.
6. **Co-op REQUIRED for ~30% of content.** Brothers must play together.
7. **World keeps living when offline** — NPCs do day jobs, factions shift, weather progresses, festivals come and go.
8. **Shared diary** — every discovery, named pet, beaten boss, built building gets a hand-painted journal entry. Re-readable like a storybook for years.
9. **Real-world tie-in (optional)** — completed quests can unlock IRL parent-controlled reward cards.
10. **Dad-narrated quests (future)** — agents generate audio in dad's voice via voice cloning.
11. **No subscription, no microtransactions, no FOMO loops, no dark patterns.** This respects THEME §6 (child-safe) absolutely.

## 8. Commit-message convention

Every agent commit must cite which **pillar** it advances:

`<PREFIX>: <feature> (Pillar N: <name>) — <details>`

Examples:
- `Auto: Charge attack combo chain (Pillar 1: Combat) — adds 3-hit combo with crit on 3rd`
- `Char: Mount bonding minigame (Pillar 2: Companions) — feed/brush/play with Horse.glb`
- `Auto: Free-grid block placement (Pillar 3: City-building) — Minecraft-style decoration`
- `Lore: Old Faerie language primer (Pillar 4: Knowledge) — unlocks fey-court NPCs`
- `Auto: Cooking profession at Bram's (Pillar 5: Professions) — recipe book + buff foods`
- `Auto: Bandit boldness reacts to road defense (Pillar 6: Consequence)`
- `Auto: NPC daily schedules (Pillar 7: Daily life) — Smith hammers 9-5, Bram serves dinner`

This makes the agents' work cumulative + auditable. The Architect agent's hourly review tracks total work-per-pillar so we see what's underbuilt.

## 9. The Minecraft-style building system (Pillar 3 deep dive)

This is the unique core. Worth its own section.

**Block grid:** Briarwood has a designated build zone (~80×80 tiles, 1m per tile, 12 tiles vertical). Players can place/remove blocks freely there. The 6 starter houses are pre-built but editable.

**Block types unlocked by progression:**
- Tier 0 (start) — wood plank, stone, thatch, dirt, glass, fence, door, window
- Tier 1 (post-Whisperwood) — mossy stone, oak plank, leaf canopy, wildflower bed, rune stone
- Tier 2 (post-Crystal) — crystal block, glowing crystal lamp, polished gem
- Tier 3 (post-Harbor) — coral, sea-glass, treated dock plank
- Tier 4 (post-Iron Crown) — gilded stone, marble, banner, tapestry
- Tier 5 (post-Frostmarch) — ice block, dragon-bone, frost-glass
- Tier 6 (post-Veil) — memorial blocks

**Crafting:** Workbench → recipe book. Recipes unlock by gathering materials at least once. Pattern-based (Minecraft-style 3×3 grid) OR list-based (simpler for younger Alden). Dual UI mode toggleable per player.

**Mining + chopping:** Trees can be chopped (axe required, drops logs). Rocks can be mined (pickaxe required, drops stone/ore). Ore types: copper, iron, silver, gold, gemstone, frost-iron (post-Frostmarch). Ore is needed for higher-tier gear and blocks.

**Functional blocks:**
- **Workbench** (crafts gear)
- **Alchemy table** (brews potions)
- **Bed** (set respawn point)
- **Storage chest** (extra inventory slots)
- **Signpost** (label your buildings)
- **Anvil** (upgrade gear)
- **Loom** (banner/tapestry crafting)
- **Stove** (cook food)

**Player-built dungeons (late-game):** Place monsters as spawners, set boss arena, decorate, share with friends.

---

*This document is the north star for all 10 agents. Read this BEFORE THEME.md, BEFORE CHANGES.md. Updated 2026-05-05.*
