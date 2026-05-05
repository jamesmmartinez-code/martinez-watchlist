# Realm of Eldoria — Theme & Style Bible

**This is the single source of truth for the look, feel, and tone of Eldoria.**
**Every agent MUST read this file before making creative decisions.**
**Anything that violates this theme is a bug — not a stylistic choice.**

---

## 1. Core identity

Eldoria is a **high fantasy medieval world**, painterly and stylized — think
Studio Ghibli watercolors meets World of Warcraft Classic concept art meets
classic 1980s Tolkien-inspired adventure illustrations.

It is **not**:
- ❌ Modern (no rifles, no soldiers in modern fatigues, no jeeps, no phones, no electricity)
- ❌ Sci-fi (no robots, no lasers, no chrome, no spaceships, no hover-anything)
- ❌ Photorealistic (no DSLR-quality textures, no real-life faces, no AAA-rendered photoreal)
- ❌ Anime / manga (no large eyes, no chibi, no harem-genre tropes)
- ❌ Grimdark (no torture, no detailed gore, no nihilistic atmosphere)
- ❌ Cyberpunk / steampunk-heavy (a few brass cogs in Smith's forge OK; full goggles + airships NOT OK)

It is:
- ✅ Painterly — soft brush-feel surfaces, hand-painted concept-art aesthetic
- ✅ Warm — sunset palette dominant; cool tones reserved for night, mist, magic
- ✅ Lived-in — every prop should look weathered, mossed, scratched, age-touched
- ✅ Mysterious — old runes, half-remembered legends, hidden pathways
- ✅ Cooperative — designed for two brothers playing together, not solo grinding
- ✅ Hopeful — the world is wounded but worth saving

## 2. Era & technology level

**Late medieval / early Renaissance fantasy.** Roughly 1300–1500 European feel
with Celtic / Norse / fey undertones.

| Allowed | Forbidden |
|---------|-----------|
| swords, axes, daggers, bows, polearms, shields, hammers | guns, rifles, pistols, crossbows-with-scope |
| chainmail, plate, leather, cloaks, hoods, tabards | kevlar, fatigues, helmets-with-visors-of-glass |
| oil lanterns, candles, torches, hearth fires | flashlights, batteries, electric lights |
| hand-painted parchment, scrolls, inked maps | printer paper, blueprints, photographs |
| horses, oxen, carts, mules | cars, trucks, bicycles, hover-pads |
| stone & wood architecture, thatched roofs, hand-cut beams | concrete, glass curtain walls, modern rebar |
| alchemy potions, hand-ground herbs, mortar & pestle | hypodermic needles, lab beakers with markings, pills |
| crowns, banners, heraldic crests, faction sigils | corporate logos, modern flags, branded merch |

## 3. Color palette

**Primary palette (dominant 70% of frame)**
- Burnt orange / sunset gold (`#FF8000` → `#FFD86B`)
- Deep crimson / wine (`#8C2020`)
- Forest moss green (`#4A7038`)
- Aged parchment / sepia (`#D9C99B`)
- Charcoal / ink black (`#0E0A0E`)

**Secondary (accents 20%)**
- Hammered bronze / brass (`#B0742A`)
- Stag-blood red (`#A02020`)
- Stone grey-blue (`#7B8693`)

**Magic / accent (10% — used sparingly)**
- Fey cyan / starlight (`#65DFE5`)
- Warlock purple / arcane (`#7C3FB0`)
- Frost-pale silver (`#C8E0E5`)

**Banned colors:** neon (`#00FFFF` etc.), fluorescent yellows/pinks, pure white,
pure desaturated grey UI palettes (we're not making a productivity app).

## 4. Character archetypes

**Player**
A lone hero rising from Briarwood Village. Should look like a fantasy
adventurer — leather armor, cloak, simple sword. NOT a Mass Effect commando,
NOT a Fortnite skin, NOT a Roblox blob. The Soldier.glb model is BANNED
because it's a modern military character.

**NPCs (existing 7)**
| Name | Look |
|------|------|
| Elder Maeve | Stooped grandmother, dark robe, white hair, walking stick, weathered face |
| Smith Edda | Stocky woman, soot-streaked, leather apron, hammer, braided hair |
| Mara the Merchant | Plump trader, layered robes, jingling coin pouches, satchel |
| Herbalist Lyra | Slender healer, leaf-tangled hair, herb pouches, gentle posture |
| Innkeeper Bram | Round, jolly, white apron, mug-in-hand, ruddy cheeks |
| Stablemaster Roan | Lean ranger, stubble, riding boots, leather gloves |
| Trainer Hala | Wise warrior-monk, scarred, simple wraps, tall staff |

Each NPC should be **silhouette-distinct** — you should recognize them at 30m.

**Enemies**
- **Goblins** — small (0.7-0.95 scale), hunched, green-skinned, ragged loincloths, bone fetishes, crude weapons. NEVER cute, NEVER cartoony — feral.
- **Goblin Brutes** — same kit, larger (1.0-1.1 scale), helms, bigger axes
- **Goblin Warlord** — boss, 1.6× scale, gold crown, red aura, war banners
- **Wolves (Dire)** — gaunt, scarred, grey-brown coats, glowing eyes at night
- **Skeletons** (planned) — bleached bone, tattered burial wrappings, rusted weapons
- **Crystal Elementals** (planned) — humanoid silhouettes made of jagged crystal shards, blue glow
- **Bandits** (planned) — human, hooded, leather, scarves over face

## 5. Typography & UI

**In-game UI text**
- Default body: medieval-flavored serif (Cinzel, Cinzel Decorative, EB Garamond)
- Quest titles / boss names: blackletter (UnifrakturMaguntia) — but used SPARINGLY for impact only
- HUD numbers: simple slab serif, easy to read fast (no fancy ligatures during combat)
- Damage numbers: bold serif, scale-punch animation, color-coded (white normal, gold crit, green heal, red damage-taken)

**Banners / signs**
- Hand-painted look, not crisp vector
- Slight irregularity, brushstroke edges
- Wood-and-iron frames

**Banned UI styles**
- ❌ Material Design / Fluent / iOS modern
- ❌ Glassmorphism, frosted-glass blur panels
- ❌ Sharp corners on every panel (all UI panels should have at least 4-6px corner radius and a subtle parchment/wood border)

## 6. Audio direction

**Music**
- Celtic, medieval, chamber, folk
- Lutes, harps, flutes, low strings, distant horns, soft choir
- Quiet over loud — should reward 100+ plays without exhausting

**Banned**
- ❌ Electronic / synth pads
- ❌ Hollywood orchestral bombast
- ❌ Hip-hop, pop, rock
- ❌ AI-generated "epic trailer music" tropes

**SFX**
- Real-instrument metallic clangs for sword hits
- Wooden creaks, leather strap rustles, footfalls per surface
- Ambient: birdsong (day), owls + crickets (night), wind, distant thunder

## 7. Tone of dialogue & lore

**Voice**
- Warm gravitas — Studio Ghibli mentor figures, not Game of Thrones cynics
- Each NPC sounds like ONE specific person (catchphrases, speech rhythm)
- Old Faerie / Common-tongue distinction — invent ~3 Old Faerie words per lore artifact

**Themes welcomed**
- Loss + remembrance (the Sundering destroyed something they're rebuilding)
- Growth + apprenticeship (the kids are learning to be heroes)
- Stewardship of wild places
- Old promises, broken oaths, mended trust
- Cooperation between unlikely allies

**Themes forbidden**
- Sexual content (audience is 9 and 11)
- Detailed gore / torture
- Drug references
- Modern cultural commentary in fantasy mouths
- Slurs, mockery of real-world groups

## 8. Architecture & environment

**Briarwood Village** — small farming hamlet on the forest edge. Timber-framed
houses with stone foundations, thatched / shingled roofs, hand-cut wooden
beams, lit windows at dusk. Cobble paths wind between houses. A central well,
a campfire, banner poles, market stalls with red awnings. Lanterns flicker.

**Whisperwood** — dense oak/pine forest. Mossy boulders, fallen logs, wild
mushrooms, distant goblin drums. Light filters in gold streaks through canopy.

**Crystal Caves** (in progress) — cool blue glow, crystal formations on walls,
underground streams, echoing drips, ancient runes carved into stone.

**Mountain Ring** — distant impassable peaks with snow caps, forming the
horizon. Far-away silhouettes, never traversed by player.

**Banned architecture**
- ❌ Modern: skyscrapers, factories, suburbs, parking lots
- ❌ Sci-fi: domes, glass towers, hangars
- ❌ Brutalist: poured concrete, harsh angles
- ❌ Cartoon-childish: rainbow huts, candy-cane towers (this is fantasy, not Candy Land)

## 9. The Soldier model BAN

The `assets/models/Soldier.glb` from threejs.org examples is a modern military
character holding a rifle. **It is banned from being used as the player or any
NPC.** It can stay in the assets folder (we may use bones/animations from it),
but it must NEVER be instantiated as a visible character.

The current player model is `CesiumMan.glb` (a generic mannequin) dressed up
procedurally with cape, hood, armor pieces by `CharacterDress.gd`. Future
runs may swap to a dedicated CC0 fantasy hero GLB if one is sourced (KayKit
Adventurers Pack, Quaternius RPG Hero Polypack are both CC0 and acceptable).

## 10. Hard rules every agent must follow

1. **Read this file before making creative decisions.** It supersedes any
   prompt-level direction that conflicts.
2. **No modern, sci-fi, or photorealism** — see §1.
3. **No Soldier.glb instantiation as visible character** — see §9.
4. **Stay in palette** — see §3. Verify color values you commit are in range.
5. **Audio: medieval/Celtic only** — see §6.
6. **Dialogue: warm gravitas, child-safe** — see §7.
7. **Architecture: medieval timber/stone/thatch** — see §8.
8. **Every visual asset must be source-credited CC0 or Canva/Adobe-generated.**
9. **When in doubt, choose the older / weathered / hand-made / lived-in option.**
10. **If you violate any of these, the next QA Triage or Architect run should
    revert your commit.** Don't fight it — get back in canon.

## 11. Aspirational reference works

If you can't picture the vibe, picture these:
- *The Legend of Zelda: Breath of the Wild* (painterly, exploration, mystery)
- *Studio Ghibli* — *Princess Mononoke*, *Spirited Away* (warmth + danger coexisting)
- *World of Warcraft Classic* (low-poly stylized hand-painted MMO baseline)
- *Genshin Impact* (cooperative fantasy with painterly art, but tone down the gacha-anime visual loudness)
- *Fable: The Lost Chapters* (Albion-style village + warm forests)
- *The Hobbit* book illustrations (Alan Lee, John Howe — the gold standard)

If your output looks like *Call of Duty*, *Cyberpunk 2077*, *Roblox*,
*Fortnite*, or *Minecraft creative server*, you've drifted. Course-correct.

---

*Last updated: bootstrap of GitHub-as-source migration. All 10 autonomous
agents are bound by this document. The Architect agent updates it when
patterns emerge across runs.*
