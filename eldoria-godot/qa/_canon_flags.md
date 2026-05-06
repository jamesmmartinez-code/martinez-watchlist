# Canon Flags — per-file inline issues, sorted by severity

*Cycle 2026-05-05 — first audit. All flags below are NEW.*
*See `_canon_audit_2026-05-05.md` for the run summary and `cross_ref_graph.json` for the id graph.*

---

## [S1] 2026-05-05 — eldoria-godot/data/items_flavor.json (#frost_saber)

- ISSUE: `frost_saber` is attributed to "Smith Edda" with origin "Briarwood forge, wyrm-touched ore" and the flavor text says *"Edda has only forged two of these in her life, and laid the second one down at a cairn before it could be named."*
- CONTEXT: `lore/npcs/smith_edda.md` (which is in this file's own `_meta.canon_anchors_used`) explicitly states: *"She has never named a blade Frost. That is a southern name, and the Pale Wyrm — per the Sundering canon — is kept asleep by silence, not by speeches."* The "laid the second one down at a cairn" detail also collides with `lore/npcs/trainer_hala.md`, where the saber Hala laid on a cairn three days' ride above the valley is **Tarric's southern saber**, not Edda's work — *"a southern saber he had brought back from a brokering-walk among the Iron Crown's outlying captains."* Frost-on-the-cairn is Hala's reusable hook, not Edda's. The current item attribution unmakes both NPC backstories.
- OWNER: @item-designer (primary), @lore-keeper (secondary review)
- SUGGESTED-FIX: Re-attribute `frost_saber` to `narrator` with origin "southern Iron Crown make; smith uncertain" and rewrite flavor to remove the Edda forging / cairn-laying claims; reassign cairn-laying narrative to a future Hala-side codex page (`Frost on the Cairn`, Yorick-narrator candidate per `trainer_hala.md` hooks).

## [S1] 2026-05-05 — eldoria-godot/lore/npcs/innkeeper_bram.md

- ISSUE: Bram's stated arrival window ("He arrived eleven years ago, on a cart he did not own") + the 3-year on-the-road span before Caedr's disappearance places his earliest possible Long Lantern setup at ~7.5 years ago. This is contradicted by:
  (a) `lore/npcs/herbalist_lyra.md`: Lyra is 29; her mother Wennet died when Lyra was 8 (= 21 years ago); Bram *"kept her two winters at the inn"* — Bram had to be running the Long Lantern at least 21 years ago.
  (b) `lore/npcs/herbalist_lyra.md`: when Lyra was 15 (= 14 years ago), Aenwyn arrived and *"Bram poured."* Bram was already innkeeping 14+ years ago.
  (c) `lore/npcs/trainer_hala.md`: Hala arrived in Briarwood 11 years ago and was greeted by Bram at the Long Lantern that night. Bram was running the inn 11+ years ago.
- CONTEXT: This is a load-bearing canon contradiction. Bram's friendships with Lyra (raised her as a child), Hala (the nine-year argument), and Roan (Roan was Bram's horse-boy nine years ago — itself difficult under Bram's stated arrival) all rest on a tenure considerably longer than 11 years. The current arrival year is the outlier; the cross-NPC references are mutually reinforcing.
- OWNER: @lore-keeper (primary), @character-specialist (secondary)
- SUGGESTED-FIX: Revise Bram's arrival from "eleven years ago" to "twenty-one years ago" (or similar) so that (a) Bram could raise child-Lyra at the inn after Wennet's death, (b) Bram is established at the Long Lantern when Hala arrives 11 years ago, and (c) the timeline of "9 years no signpost" remains consistent. Update Caedr's disappearance window to match (Caedr would then have walked into the Whisperwood ~10 years ago — consistent with Lyra's "ten years later" line in `herbalist_lyra.md`).

---

## [S2] 2026-05-05 — eldoria-godot/lore/npcs/innkeeper_bram.md

- ISSUE: Internal arithmetic of Bram's tenure does not close. Bio says: arrived 11 years ago + walked 3 years with Caedr + Caedr disappeared 8 years ago (these three are consistent: 11 - 3 = 8). Then "Bram waited at the forest's edge for two seasons" before reaching Briarwood, putting his Briarwood arrival at ~7.5 years ago. Same bio: *"He has not stepped past the Briarwood signpost in nine years."* (= 9 years). 7.5 vs 9 is ~1.5 years apart.
- CONTEXT: Subordinate to CQ-S1-02 — fixing the larger arrival contradiction will also reset this internal arithmetic. Logged separately so the fix is verified at both scales.
- OWNER: @lore-keeper
- SUGGESTED-FIX: Pick one anchor ("nine years no signpost" or the 11/3/8 chain) and recompute the others against it.

## [S2] 2026-05-05 — eldoria-godot/lore/npcs/innkeeper_bram.md <-> eldoria-godot/lore/npcs/herbalist_lyra.md

- ISSUE: Caedr's disappearance dating disagrees across files. `innkeeper_bram.md`: *"On a midsummer Honeysong Eve, eight years ago now, Caedr followed a song deeper into the Whisperwood."* `herbalist_lyra.md` (Lyra → Bram, "not gone" line): *"she has not since said it again because she does not, ten years later, fully believe it."* Eight ≠ ten.
- CONTEXT: Two-year gap. Resolves trivially if CQ-S1-02 is fixed by extending Bram's tenure (Caedr goes from 8 yrs ago → ~10 yrs ago).
- OWNER: @lore-keeper
- SUGGESTED-FIX: Settle on 10 years ago for Caedr's Honeysong Eve walk; update Bram's bio's "eight years ago now" accordingly.

## [S2] 2026-05-05 — eldoria-godot/lore/npcs/elder_maeve.md <-> eldoria-godot/lore/npcs/mara_merchant.md <-> eldoria-godot/lore/npcs/innkeeper_bram.md

- ISSUE: The water-stained returned letter has three different dates. `elder_maeve.md`: *"one came back unopened three years ago, water-stained and addressed in a hand not Aelis's."* `mara_merchant.md`: *"Two springs ago, on a Greenshield morning, the same trade-rider returned with a letter in his pouch."* `innkeeper_bram.md`: *"and he saw, two springs ago, a single water-stained letter slip from Mara the Merchant's coat pocket onto the bar."*
- CONTEXT: Mara and Bram agree on "two springs ago"; Maeve says "three years ago." Maeve is the outlier. The withholding ledger in `mara_merchant.md` and `elder_maeve.md` makes this letter a load-bearing future-quest beat (`water_stained_letter_kept` flag) — a wrong year here will surface in dialogue later.
- OWNER: @lore-keeper, @character-specialist
- SUGGESTED-FIX: Settle on "two springs ago" (Mara + Bram agree, and Mara is the carrier — she is the natural source of truth for letter dates). Edit `elder_maeve.md` to read "two springs ago" as well.

## [S2] 2026-05-05 — eldoria-godot/lore/npcs/mara_merchant.md

- ISSUE: Internal contradiction in the same file about when Maeve first gave Mara a letter. *"Eight years into her Briarwood life, on a Lambmoon morning, Mara accepted a sealed letter from Elder Maeve"* (Mara has been in Briarwood 12 years, so 8 years in = 4 years ago). Same file, later: *"since Maeve pressed the first sealed envelope into Mara's hand twelve Lambmoons ago"* (= 12 years ago). Same event, two different dates.
- CONTEXT: Either Mara has been carrying letters for 4 years OR 12 years; both can't be true. Affects the timeline of how many southbound letters have been sent (Maeve writes one per Lambmoon).
- OWNER: @lore-keeper
- SUGGESTED-FIX: Settle on one timeline (likely "twelve Lambmoons ago" since it pairs more naturally with "stopped writing in eleven [years]" from `elder_maeve.md`). Edit the "Eight years into her Briarwood life" line accordingly.

## [S2] 2026-05-05 — eldoria-godot/lore/npcs/elder_maeve.md

- ISSUE: Maeve's age does not close. Bio: *"She left Briarwood herself at nineteen... She walked for eleven years... That was forty-two years ago. Maeve is sixty-eight."* Math: 19 + 11 + 42 = 72, not 68. Off by 4 years.
- CONTEXT: Slow-burn inconsistency. Maeve's age is also load-bearing for the hawthorn-stick rule (CQ-S2-09).
- OWNER: @lore-keeper
- SUGGESTED-FIX: Either bump Maeve to seventy-two, or shorten "walked for eleven years" to seven, or shorten "forty-two years ago" to thirty-eight. Pick the one that least disturbs neighboring canon (Cailen's lost-Steppe arc, Aelis at seventeen, Halsa as midwife-charge).

## [S2] 2026-05-05 — eldoria-godot/data/dialogue/trainer_hala.json <-> eldoria-godot/data/items_flavor.json

- ISSUE: Hala's `after_first_quest_complete` line and her hooks reference a *hand-bound practice cudgel from the row of six* as the canonical reward. No `practice_cudgel` (or similarly-keyed) entry exists in `data/items_flavor.json`.
- CONTEXT: `data/items_flavor.json#_meta.canon_anchors_used` doesn't list `lore/npcs/trainer_hala.md`, so the omission is a generation-order artifact. The cudgel-triangle (Hala / Mara / Roan) is closed canon now and the cudgel needs a flavor entry.
- OWNER: @item-designer (write entry), @lore-keeper (secondary — voice for Hala-attributed flavor)
- SUGGESTED-FIX: Add a `practice_cudgel` entry to `items_flavor.json#items` with attribution "Trainer Hala", origin "Briarwood, Hala-bound", and flavor that respects `vethran` (the lesson taught against the hand) and the `cudgel_acknowledged` reciprocal bridge.

## [S2] 2026-05-05 — eldoria-godot/data/dialogue/stablemaster_roan.json <-> eldoria-godot/data/items_flavor.json

- ISSUE: Roan's `after_first_quest_complete` line ships a *Steppe-pattern halter, my own work* and the `roan_halter_gifted` flag is reserved. No matching item entry in `data/items_flavor.json`.
- CONTEXT: Same generation-order artifact as CQ-S2-06. The Steppe-Patterned Halter is also the prerequisite for the warmed-tier "cradle" line shape per `stablemaster_roan.md` hooks.
- OWNER: @item-designer (write entry), @lore-keeper (secondary)
- SUGGESTED-FIX: Add a `steppe_halter` entry to `items_flavor.json#items` with attribution "Stablemaster Roan", origin "Briarwood stable, Roan-made; Steppe pattern", and flavor that uses the `*(adjusts a strap.)*` tic and references *ostren* without naming Maeve or Cailen.

## [S2] 2026-05-05 — eldoria-godot/concept/ (root)

- ISSUE: No concept reference plates exist for any of:
  - 7 NPCs (Edda, Maeve, Bram, Mara, Lyra, Roan, Hala) — `THEME.md` §4 mandates each be silhouette-distinct at 30m
  - Regions: Briarwood Village, Whisperwood, Crystal Caves, Mountain Ring (and the Steppe-side cairn referenced in `trainer_hala.md`)
  - Creatures: Goblin, Goblin Brute, Goblin Warlord, Wolves (Dire), Skeletons (planned), Crystal Elementals (planned), Bandits (planned)
  - Props: Long Lantern sign, Maeve's hawthorn knot-stick, Edda's anvil with Brigid mark, Mara's stall awning + bronze fox-coin, Roan's gate-lantern, Hala's staff with three Stone-Tongue oaths
- CONTEXT: `concept/` and `mood-boards/` each contain only a README.md. `THEME.md` §4 + the seven NPC bios constrain the silhouette shapes tightly (Bram round + apron, Edda stocky + soot-streaked, Roan lean + stubble, etc.); without plates, Builder/Polisher/Art are free-styling.
- OWNER: @art-director (primary), @character-specialist (secondary review)
- SUGGESTED-FIX: Open seven `CONCEPT_NEEDED` flags (one per NPC) plus four region plates and a creature-roster plate. Recommend a single Canva or Adobe Firefly batch for the seven NPC silhouettes first — that's the highest visual-coherence win.

## [S2] 2026-05-05 — eldoria-godot/lore/npcs/elder_maeve.md <-> eldoria-godot/lore/npcs/herbalist_lyra.md <-> eldoria-godot/lore/npcs/smith_edda.md

- ISSUE: Maeve's hawthorn-stick rule says: *"Maeve has carved a small ringed knot for each child born in Briarwood since she became Elder."* (Maeve has been Elder 22 years.) But:
  - Halsa (Edda's mother) is the **37th knot**. Halsa was a working smith with Edda already in adolescence by ~24 years ago, so Halsa was born ~50+ years ago — well before Maeve's Eldership.
  - Edda is the **62nd knot**. Edda taught child-Lyra at age 19 about 20 years ago, so Edda was born ~39 years ago — also before Maeve's Eldership.
  - Lyra is the **89th knot**. Lyra is 29. Born 29 years ago, 7 years before Maeve became Elder.
  All three named knots violate the "since she became Elder" rule.
- CONTEXT: One of the rule statements is wrong, or all three of the named-knot positions are wrong. The bios make heavy emotional use of *Maeve named both [Halsa and Edda]* — this is the canonical bridge between Maeve and the forge, and unsticking the rule is preferable to unpicking the bridge.
- OWNER: @lore-keeper
- SUGGESTED-FIX: Soften the rule in `elder_maeve.md` from *"since she became Elder"* to *"since she came back to Briarwood"* (= 42 years per Maeve's bio, which would cover all three named knots). Cross-check Wennet's, Bram's-non-existent, and other named knots in future cycles.

## [S2] 2026-05-05 — eldoria-godot/lore/npcs/trainer_hala.md

- ISSUE: Hala's age does not close. Bio: *"In the Wolfwake Hala turned twenty-six, the High Steppe took a frost..."* (Aurel burned). *"She walked four moons. She came down out of the foothills in early Lambmoon."* *"That was eleven years ago. She has not gone back to Aurel and will not."* *"She is forty-two."* Math: 26 + 4 moons (= ~⅓ year) + 11 years ≈ 37–38, not 42.
- CONTEXT: ~4-year gap. Hala is also "the youngest of the seven Briarwood NPCs by a decade" only if Lyra is 29 and Hala is in her late 30s/early 40s — the current 42 leaves Hala close to Edda's 39.
- OWNER: @lore-keeper
- SUGGESTED-FIX: Either bump *"in the Wolfwake Hala turned twenty-six"* to thirty (closes to 41–42), or split the walk longer (a "four years" rather than "four moons"), or shorten "eleven years ago" to seven. Consult `lore/npcs/herbalist_lyra.md` for Hala's appearance in Lyra's youth — Lyra (now 29) learned hold-breaks from Hala "twice in ten years", so Hala has been teaching Lyra since at least ~10 years ago, fitting any of the candidate fixes.

---

## [S3] 2026-05-05 — eldoria-godot/recipes/ (missing)

- ISSUE: Check 4 (item ↔ recipe integrity) cannot run. No recipes directory exists; no `acquired_via:craft` field exists in `items_flavor.json`.
- CONTEXT: Crafting hasn't shipped. This is future-debt; flagging so the gap is visible.
- OWNER: @item-designer (when crafting ships)
- SUGGESTED-FIX: When the crafting system ships, create `eldoria-godot/recipes/` with one `.json` (or `.tres`) per recipe; pull into the canon-qa sparse-checkout list.

## [S3] 2026-05-05 — eldoria-godot/data/items/_catalog.csv (missing)

- ISSUE: Check 7 (catalog reconciliation) cannot run. No catalog CSV; no `.tres` set.
- CONTEXT: Future-debt. The 25 entries in `items_flavor.json` are the only structured registry today.
- OWNER: @item-designer
- SUGGESTED-FIX: When `Items.gd` is migrated to a `data/items/*.tres` set, ship a generated `_catalog.csv` so canon-qa can reconcile.

## [S3] 2026-05-05 — eldoria-godot/quests/ (missing)

- ISSUE: No formal quest manifest; check 5 (quest ↔ reward) reduced to scanning dialogue `consequence_hooks` and bio `Hooks for future runs` sections.
- CONTEXT: Future-debt. Quest rewards are currently scattered across NPC files.
- OWNER: @quest-writer
- SUGGESTED-FIX: When a quest manifest format is chosen, ship `eldoria-godot/quests/*.json` with `id`, `kind`, `target`, `needed`, `issuer`, `reward[]`, `consequence`, `level_band`. Pull into canon-qa sparse-checkout.

## [S3] 2026-05-05 — eldoria-godot/lore/world.md + eldoria-godot/lore/npcs/trainer_hala.md

- ISSUE: Stone-Tongue lexicon is partially formal. World.md names Stone-Tongue as a tongue but lists no words. The Steppe-rider's-refusal codex formally seeds 3 Stone-Tongue words (`korthain`, `thrunn`, `korr`) under a clearly-headed lexicon section. `trainer_hala.md` introduces 3 more Stone-Tongue words (`aei`, `thurra`, `kel-vethran`) but only in narrative prose — Hala's "Old Faerie words seeded by this file" lexicon header lists *torrest* and *vethran* (Old Faerie), not the Stone-Tongue triple.
- CONTEXT: Audit can't programmatically pick up the Stone-Tongue triple from Hala's prose; cross-ref graph harvested only 1 Stone-Tongue word automatically. The Stone-Tongue 10-word ceiling (per the Steppe codex author note) is unverifiable until the lexicon header is regular.
- OWNER: @lore-keeper
- SUGGESTED-FIX: Add a "Stone-Tongue words seeded by this file" sub-section to `trainer_hala.md` listing `aei`, `thurra`, `kel-vethran` with pronunciation + sense, mirroring the codex's bullet-list shape. Same for any other file that introduces Stone-Tongue narratively.

## [S3] 2026-05-05 — eldoria-godot/data/dialogue/innkeeper_bram.json + stablemaster_roan.json + trainer_hala.json

- ISSUE: The Longnight stew round size is implicit and inconsistent. `innkeeper_bram.md` describes a two-stop round (Edda → Maeve). `stablemaster_roan.md` adds Roan as a third stop (*"Bram brings him a bowl of stew at the third hour"*). `trainer_hala.md` adds Hala as a fourth (*"Bram brings her stew"*). The dialogue files line up the Vigil quintet/sextet/septet for *co-firing on the same Longnight tick*, but the **stew-round subset** of that ring is not formalized.
- CONTEXT: Composability concern, not contradiction. If Builder ever wires the Longnight tick to fire Bram's `longnight_vigil` line per stew-stop, the count of stops needs to be canonical (2? 3? 4?).
- OWNER: @event-designer (composability), @lore-keeper (canon)
- SUGGESTED-FIX: Pick canonical stew-round size = 4 (Edda → Maeve → Roan → Hala) since all four NPCs explicitly receive Bram's bowl in their bios. Add a one-line note in `innkeeper_bram.md` Vigil-round canon bullet listing the four stops in order.

## [S3] 2026-05-05 — eldoria-godot/data/items_flavor.json#_meta.canon_anchors_used

- ISSUE: The `canon_anchors_used` list omits two NPC bios that are now load-bearing for items: `lore/npcs/innkeeper_bram.md` (Bram-coded `vethar`, `breos`, the road-knife hook) and `lore/npcs/trainer_hala.md` (the cudgel triangle, `vethran`, `torrest`).
- CONTEXT: Generation-order artifact. The list will get progressively more out of date if not maintained.
- OWNER: @item-designer
- SUGGESTED-FIX: When CQ-S2-06 / CQ-S2-07 are fixed (cudgel + halter items added), refresh `_meta.canon_anchors_used` to include all 7 NPC bios, both codex fragments, and `THEME.md`.
