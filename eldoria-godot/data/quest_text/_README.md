# `data/quest_text/` — quest narrative pages

Per-quest hand-painted dialogue and flavor pages, one Markdown file per
quest id. The runtime can ignore these — `scripts/World.gd ::
QUEST_CATALOG` and the `.tres` registry at `data/quests/_index.tres`
remain the runtime sources of truth. The Builder, Polisher, and
Character agents read these pages for in-character voice when wiring
*offer / in-progress / turn-in / after* dialogue branches.

This directory is the canonical *quest flavor* layer (Lorekeeper skill
priority 4). It sits beside `data/items_flavor.json` (item flavor) and
`data/codex/*.md` (discoverable lore fragments) — three parallel
narrative surfaces, three different rendering styles.

---

## File schema

Each page is named `<quest_id>.md` where `<quest_id>` matches:
- the legacy `World.QUEST_CATALOG` key (e.g. `whisperwood_cleansing`), OR
- the `metadata/quest.id` field of a `data/quests/<region>/<id>.tres`.

The page begins with YAML front-matter:

```yaml
---
quest_id: <snake_case id; matches the catalog>
giver: <NPC display name; matches WorldBuilder.NPCS>
region: <region key; matches QUEST_GRAMMAR fields>
voice: <path to the dialogue/<slug>.json bible whose voice rules apply>
canon_anchors: [list of cross-canon files this page reads against]
old_faerie_used: [list of Old Faerie words the page uses; new ones glossed below]
---
```

The body is six sections, in order, each one short paragraph:

1. **Pitch** — what the giver says when first offering the quest. Must
   match the giver's `default` / morning-tinted / quest-pitch voice in
   `data/dialogue/<slug>.json`. Stage directions in *italics*.
2. **Accept** — the giver's response on player accept. One short line.
3. **In progress** — the giver's revisit-before-completion line.
   Reassuring; never urgent (per THEME §7 "warm gravitas").
4. **Turn-in** — the giver's line on satisfied return. The longest
   section. Stage directions describe the *physical handoff* (where
   they put the item, what their hands are doing). This is where most
   of the canonical character beats land.
5. **After** — the giver's later-dialogue acknowledgement, fired on
   return-visits after turn-in. One short line.
6. **Notes for Builder** — wiring hints, mood-keys, gating reminders,
   withholding flags, cross-NPC handshakes. Builder reads these as
   the authoring contract.

A page MUST populate all six sections. A page MAY add a seventh
section (e.g. "Cross-NPC handshake," "Festival variant") — keep it
short, and only if the canonical content does not fit in *Notes for
Builder*.

---

## Voice rules

Every line in a quest_text page is a line the named NPC could speak
*verbatim* in `dialogue/<slug>.json`. Mood-key compatibility is
preserved: a Pitch line may be reused as a `default` or `morning` line
without rewriting; an After line may be reused as a `high_renown` or
`after_first_quest_complete` line.

Specifically:

- **Stage directions** sit in `*italics*` and are inline (no separate
  blocks). Builder strips the italics for spoken-line use; UI may
  render them as muted descriptive text.
- **Old Faerie words** are also italicized. First use in this artifact
  is glossed in §Glossary below. First use in canon (anywhere) is
  glossed in `lore/world.md` or in the artifact that introduces it.
- **Pronouns and addressing** match the giver's bible: Maeve says
  *traveler* and *child*; Mara says *traveler*; Roan says *traveler*;
  Bram says *traveler* and the player's first name when known; Hala
  says *traveler* and *student*; Lyra says *traveler* and (rarely)
  *little wing*. None say *adventurer* or *hero* — that vocabulary
  belongs to the children-in-the-lane, not the village adults.
- **Catchphrases** are not over-used. A page MAY use one catchphrase
  per giver (e.g. Roan's "ride the leaves," Maeve's "Vellum is
  patient," Bram's "the kettle's always on"). A page MUST NOT use
  more than one — the catchphrase is a *flavor* tool, not a *signature*
  tool.

---

## Glossary

Three new Old Faerie words enter canon in this artifact. Adding to the
existing canon (`thirre`, `ai-velin`, `kerrithen` from `world.md`;
`vael-tor`, `thressa-mai` from `elder_maeve.md`; `haethe`, `unnen`
from `smith_edda.md`; `vael-i-thirren`, `ai-mhorren`, `velhain-tor`
from `codex/stag_courts_courtesy.md`; `haelen`, `mor-vaere`, `thrennen`
from `items_flavor.json`):

### `vael-haerin` *(VAY-l HAYR-in)* — "the homeward leg"

The walk back from the doing of a deed. The moment a quest becomes a
thing-already-done; the part of the work the form does not teach.
Trainer Hala uses it at turn-in (`wolf_form_with_hala.md`) — she is
the canonical first user. Future NPCs may pick it up only if they
have plausibly trained under Hala or a Hala-equivalent (i.e. a
warrior-monk discipline). It is not a Briarwood-village word; a
farmer would not say it. It is teachable — Hala teaches it the way
she teaches the fourth form: by saying it once and waiting for the
student to ask what it meant.

### `mhordin` *(MOR-din)* — "the holding-of-the-asking"

What passes between giver and doer after the deed is taken and before
the deed is finished. Why Mara never asks twice; why Bram leaves a
stew warm; why Lyra does not look up from the marshmint. The word
names the *unhurry* of a waiting that is also a kindness. Innkeeper
Bram is the canonical first user (`wolf_heart_for_bram.md`) — the
inn IS the village's `mhordin` by canon. The word is gentle and
common-tongue-adjacent; herbalists and innkeepers may use it freely.
Smiths and stablemasters do not — their waiting is more impatient by
trade.

### `aen-thirre` *(ayn THEER-uh)* — "stone-of-thanks"

The small unspoken thing that passes at a turn-in. The carved acorn
Maeve gives. The second mug Bram pours without being asked. The way
Roan does not ask where the fang came from. Mara is the canonical
first user (`ears_for_mara.md`) — and the word is reserved for *after*
turn-in, only once per giver per player. The construction is `aen`
("small offering, thing-given") + `thirre` ("memory of stone") — a
gift that lays a memory down. Future writers may use the word in any
NPC's after-line, but only once per NPC, and only after the first
turn-in. The repetition would make it cheap. The word is not cheap.

---

## Withholding ledger preserved by this artifact

- No quest_text names the **bandit captain** (run-23 Hook B, run-24
  Hook D — open). The page for `bandit_road_for_roan` describes him
  as "a captain in a sodden cloak"; `captain_seal_for_maeve` does not
  describe him at all. Maeve will not name him in any future revision.
- No quest_text names **Aelis** or **Cailen** (per
  `dialogue/elder_maeve.json :: withholding`). The Cailen-shaped
  silences in `captain_seal_for_maeve.md` (the leather thong, the
  iron-cast hand) are intentional and do not promote the thong to
  Cailen canon.
- No quest_text speaks for the **Antler-King**, the **Stag-Court**,
  or any voice from `data/codex/*.md`. The codex fragments are
  discoverable; the quest_text is given. The two surfaces stay
  separate by canon.
- No quest_text names a **Stone-Tongue** word. The canonical
  Stone-Tongue surface is the codex fragment
  (`codex/steppe_riders_refusal.md`). Roan's after-line in
  `bandit_road_for_roan.md` deliberately does NOT use *korr* — the
  word is reserved for the codex-paired Foxthaw line.
- No quest_text names what lies **past the Whisperwood forest-line.**

---

## Canon anchors used by this artifact

- `lore/world.md` (the Wild Pantheon, the Calendar, the Tongues)
- `lore/npcs/{elder_maeve, herbalist_lyra, mara_merchant,
  stablemaster_roan, trainer_hala, innkeeper_bram}.md`
- `lore/factions/wardens_of_the_mark.md` (Maeve as the keeping-vigil;
  Roan as the keeping-running)
- `data/dialogue/{slug}.json` for all seven NPC voice bibles
- `data/items_flavor.json` (`ring_focus`, `hp_potion_l`, the
  `haethe` and `thrennen` cadences)
- `data/codex/stag_courts_courtesy.md`,
  `data/codex/steppe_riders_refusal.md`
- `WORLD_STATE.md` run-24 (the maeve_seal_kept flag, the
  eighth-in-the-ledger position, the chain ordering)
- `CHANGES.md` run-23 / run-24 (the prereq chain, the Hook B / Hook D
  withholding-ledger items)
- `QUEST_GRAMMAR.md` (the canonical quest grammar; this directory is
  authoring-side only and does not modify the grammar)

---

## Hooks for future runs

- **Edda's quest_text page.** Smith Edda has no quest yet — she is the
  only Briarwood-7 NPC without one. When Builder authors her first
  quest (`WORLD_STATE.md` Hook B suggests it would compound her into
  the warm-tier club), the corresponding `data/quest_text/<id>.md`
  goes here, in Edda's voice (per `dialogue/smith_edda.json`).
- **`shards_for_mara` quest_text page.** The first `.tres`-format
  quest already has `dialogue_placeholders` embedded in its resource
  file. A future Lore-Keeper may lift those into a quest_text page
  for parity — but the placeholder shape is already strong, so it is
  not urgent.
- **A *bandit-captain naming* page.** Run-23 Hook B / run-24 Hook D
  remain open. If named, the captain's name would update the pitch
  line of `bandit_road_for_roan.md` (still as "a captain in a sodden
  cloak" in the *pitch*, then named in Roan's *after-line* — a man
  is named once he has been buried).
- **Festival variants.** Two seasonal quests are structurally allowed
  but not yet authored: a Honeysong-Eve lantern errand (Lyra-or-Mara
  giver) and a Longnight-Vigil candle errand (Maeve giver). Each
  would be a single short quest_text page; the dialogue surface
  already accommodates the festival mood-keys
  (`longnight_vigil`, `honeysong_eve`).
- **A `quest_text_loaded` UI cue.** When Builder wires the quest
  panel to read these pages, a small parchment-corner glyph in the
  journal entry would signal "this quest has hand-painted dialogue
  available." The glyph is purely Builder/UI territory.

---

## Author note for downstream agents

These pages are the *given* layer of the village. The codex layer is
*found*; the items_flavor layer is *held*; quest_text is *given*. The
three surfaces have different cadences by design. A quest_text line
is the village speaking to the player out loud, in real time, with
their hands on whatever they are doing. Keep it warm. Keep it short.
Keep the catchphrase to one. Keep the Old Faerie sparing.

If a future Lore-Keeper wishes to lengthen these pages — to add long
backstories, to write speeches, to surface the withheld names —
please remember the rule from the items_flavor.json author cadence:
the village speaks the way a smith hammers, a horse breathes, a
kettle steams. None of those go on for a paragraph.

*Vellum is patient.*
