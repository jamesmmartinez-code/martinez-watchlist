# Briarwood — Scope Brief (canonical)

**Read this before building anything in Briarwood. Owner: every agent.**

Briarwood is **NOT a small village**. The user's expectation is a *massive*
walled town — the WOW first impression for two kids (Alden, 9 + Owen, 11)
who will spend hundreds of hours here. Build to that bar.

## Hard floor — Briarwood must contain

- **6 districts**, each with its own visual identity:
  1. **Market Plaza** — central fountain, paved cobbles, awnings with red/gold
     fabric, ~12 stalls (fruit, fish, leather, herbs, weapons, scrolls, cloth,
     bread, smoked meat, pottery, jewelry, honey/mead), banner poles, bell
     tower, bards on a corner, well, public notice board.
  2. **Smith Quarter** — Edda's anvil-ringing forge, weaponsmith, armorer,
     tinker, fletcher, jeweler. Soot-streaked timber. Smoke from chimneys.
     Sparks audio loop. Iron racks with display weapons.
  3. **Temple Hill** — chapel of the Old Light, graveyard, memorial stones
     for Sundering dead, Elder Maeve's cottage at the edge, prayer flags,
     candle-lit shrines.
  4. **Stable Yards** — Roan's stables, mount paddock, wagon yard, hay bales,
     blacksmith for horseshoes, training ring. Horses idle here.
  5. **Outer Farms** — windmill, granary, bakery, dairy, herb garden (Lyra's
     plot), chicken coops, fruit orchards, scarecrows, fences.
  6. **Watch Walls** — 4 town gates (N/S/E/W), 6 guard towers, walkable
     parapets, archers on patrol, brazier-lit at night, stone curtain wall
     ringing the inner districts.

- **40+ buildings minimum** (5+ variants per type so it doesn't read as copy-paste):
  - 12+ houses (4 styles × 3 each — large, medium, small timber+thatch)
  - 6+ shops (smithy, weaponsmith, armorer, tailor, leatherworker, jeweler)
  - 4+ public (inn, chapel, market hall, watchtower)
  - 4+ functional (granary, mill, bakery, stable)
  - 6+ guard structures (gates, towers)
  - 8+ misc (sheds, wells, banner poles, market stalls, signposts, fountains)

- **15+ NPCs in motion** (the existing 7 + 8 new ambient citizens):
  - Existing: Maeve, Edda, Mara, Lyra, Bram, Roan, Hala (named, story NPCs)
  - New ambient (background — moving, idle behavior, no quest):
    Town Crier (rings bell at hours), Watchman (patrols walls),
    Baker's Boy (carries bread), Stable Hand, Dock Cooper, two children
    chasing each other in the plaza, an old man feeding pigeons, Beggar at
    the chapel steps. They have routes, not just standing.

- **Living-world details** (the WOW layer):
  - Smoke rising from every chimney at dusk
  - Lanterns lit at sunset; pools of warm light on cobble
  - Banners fluttering in wind
  - Distant church bell on the hour
  - Blacksmith hammer audio loop near Smith Quarter
  - Market chatter ambient layer
  - Birds (sparrows daytime, owls night)
  - Dogs (3 of them with names — Rook, Bramble, Pip)
  - Chickens pecking
  - Cats on rooftops
  - Smoke from forges
  - Steam from the bakery
  - Children's laughter near the fountain

- **Architecture style — STRICT** (THEME §1, §8):
  - Late medieval / early Renaissance European
  - Timber-framed walls with whitewashed plaster
  - Thatched + slate roofs (mix)
  - Hand-cut wooden beams, exposed joinery
  - Stone foundations, mossy where shaded
  - Cobble streets, dirt paths in outer farms
  - NO modern, NO sci-fi, NO neon, NO chrome

## How agents use this

- **Architect**: this is your buildable spec. Build districts in order
  Market → Smith → Temple → Stable → Outer → Walls. Each district is a
  named scene group. Don't ship until your district has minimum count
  AND visible variety (no two adjacent buildings identical).
- **Lorekeeper**: when writing Eldoria realm doc, reference these districts
  by name. NPCs need to belong to districts (Edda → Smith Quarter, Roan →
  Stable Yards, Maeve → Temple Hill).
- **Concept Artist**: Briarwood vista must show ALL six districts visible
  from a high vantage. Per-district close-up paintings come next.
- **Builder**: 8 ambient citizen NPCs need waypoint patrols. Bell ringing
  at noon/dusk is a one-line audio scheduler.
- **QA**: a Briarwood that has fewer than 30 buildings, fewer than 12 NPCs,
  or no district structure is **failing this brief** — flag for re-build.

## Definition of Done for Briarwood v1

✅ All 6 districts placed with district-tagged scene nodes
✅ ≥30 building meshes total, no two adjacent identical
✅ ≥12 NPCs visible (7 named + 5 ambient minimum)
✅ Wall + 4 gates rendered
✅ Cobble paths connecting districts
✅ ≥6 lit lanterns
✅ Smoke particle on ≥4 chimneys
✅ Banner poles in market + temple districts
✅ Audio: market chatter + smith hammer + distant bell

This is the minimum. Push past it.
