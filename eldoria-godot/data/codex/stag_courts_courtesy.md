---
id: stag_courts_courtesy
title: The Stag-Court's Courtesy
category: fragments
region: crystal_caves
discover_trigger:
  kind: enter_region
  region: crystal_caves
  first_visit_only: true
gating:
  player_level_gte: 6
  world_flag_required: crystal_caves_unlocked
narrator: in_world_scribe
era: pre_sundering_late
length: short
codex_unlock_announce: "A folded leaf, dry as a moth-wing, falls from a crack in the wall."
icon_glyph: leaf-and-antler
---

# The Stag-Court's Courtesy

*A fragment, found in the Crystal Caves on the lip of the under-stream where
the cave-air smells of cold iron. A leaf of birch-paper, folded twice and
sealed with pine-wax that someone has, more than once, tried to peel open
without breaking. The hand is a Briarwood scribe's — careful, sloping, written
left-to-right but with the older Faerie diacritics. Three centuries old, by
the wax. Older, perhaps, by the words.*

---

## What the leaf says

> *I write this for whoever comes after me at the Vigil candles, and for no
> one else. If you are not of Briarwood, please put this back where you
> found it, and do not read further.*
>
> *On the eleventh evening of Foxthaw I went down to the forest-line because
> the fox-fire was up and my mother had told me to never go, which is reason
> enough at fourteen. I went a quarter-league and no further. The Stag-Court
> was waiting. They had been waiting, I think, since before my mother's
> mother. They were not unkind.*
>
> *They asked me to sit. I sat. They asked me to listen. I listened. They
> said:* ***vael-i-thirren*** *— "we are remembering you." That is what the
> phrase means in the older constructions. It does not mean they had taken
> a memory; it means they had put one down for safe-keeping, the way a
> traveler* kerrithas *a friend's blade at a cairn.*
>
> *I asked what they wanted. The Antler-King answered. He said: nothing. He
> said the Court does not take. He said the Court* ***measures.*** *He said
> there is a courtesy older than the Sundering — that when a mortal walks
> close enough to the forest-line on the right night of the right month,
> the Court will weigh that mortal once, and only once, and offer them a
> seat. Not because the seat is meant for them. Because the offering is
> what they are owed.*
>
> *He called this courtesy* ***ai-mhorren*** *— "the gift that is the
> asking." I have not heard the word before, and the scribes I have written
> to in the south have not heard it either. I think the Court keeps it for
> itself.*
>
> *I asked what the seat would cost. The Antler-King said one mortal year,
> remembered backwards. He said it was not a price. He said it was the
> shape of the door. To sit in the Court is to sit in their season, which
> turns slower than ours; and to come back out is to come back out into a
> Briarwood that has aged faster than your hands.*
>
> *He said most who are offered the seat say no. He said the Court is glad
> when they do. He said this softly, and I believed him. He said the Court
> is older than the Sundering and has watched the smoke-cities rise three
> times and fall twice, and has not, in all that watching, learned to want
> company.*
>
> *I said no. He thanked me. He said:* ***velhain-tor*** *— "go warmly." He
> said the offer was not withdrawn; it was only set down. He said if I
> ever returned on the right night of the right month, the seat would
> still be there. He said it would still be mine.*
>
> *I am sixty-three now. The seat is still mine. I have not gone back.*
>
> *Whoever finds this — the Court is not a danger to Briarwood. The Court
> is a* ***courtesy*** *to Briarwood, in the older sense of the word. It is
> the way the forest remembers us. It is the way the forest puts our
> names down, gently, where the iron crowns and the stone crowns cannot
> reach. Tend the Vigil candles. Tend Erris's lanterns. Tend the herb
> beds. Do not go down to the forest-line on Foxthaw, and if you do, sit
> when you are asked to sit, and listen when you are asked to listen, and
> say no when you are asked to stay.*
>
> *Most do. The Court is glad of it.*
>
> — *written by hand and folded into the under-stream rock, that the cave
> may keep what the village need not. Vellum is patient.*

---

## Three new Old Faerie words enter canon here

Adding to *thirre*, *ai-velin*, *kerrithen* (`world.md`); *vael-tor*,
*thressa-mai* (`elder_maeve.md`); *haethe*, *unnen* (`smith_edda.md`):

- ***vael-i-thirren*** *(VAY-l ee THEER-en)* — "we are remembering you."
  A formal phrase the Stag-Court uses when greeting a mortal it has
  weighed and chosen to speak with. It does **not** mean they have taken
  a memory; it means they have set one down on the mortal's behalf, the
  way one *kerrithas* a friend's blade. Lyra, asked, will say only that
  it is "a courtesy." Maeve, asked, will not answer.
- ***ai-mhorren*** *(eye MOR-en)* — "the gift that is the asking." The
  name the Stag-Court gives to its own custom of offering a seat to a
  mortal who has walked close enough to the forest-line on the right
  night of the right month. The offering itself is the gift; the seat
  need not be taken for the gift to have been given. The word is private
  to the Court and appears in no Common-tongue dictionary.
- ***velhain-tor*** *(VEL-hayn tor)* — "go warmly." A parting blessing
  used by the Stag-Court when releasing a mortal back into the
  human-time. It carries the older sense of *tor* (hearth) and is
  meant as a small protective ward — the Court is wishing the mortal a
  safe return to the gathered hearth they came from. To say
  *velhain-tor* to a mortal is to acknowledge that mortal has a place
  worth returning to.

---

## How the player finds this fragment

The leaf is wedged in a crack on the lip of the under-stream in the
Crystal Caves, on the third turn after the second crystal arch. It is
found by stepping on a loose flagstone, which dislodges the crack-wax,
which lets the leaf fall. The unlock toast reads:

> *A folded leaf, dry as a moth-wing, falls from a crack in the wall.*

Reading the codex unlocks an entry in the Codex panel under
**Fragments → The Stag-Court's Courtesy**.

Builder note: the leaf should not appear before player_level 6. The
Crystal Caves are a *thirre* (`world.md`); time pools here, and the
fragment is older than Briarwood remembers itself being. The drop
trigger should fire on first-visit-after-level-6 and not again. If a
quest system later wires "fragments collected" as a counter, this leaf
is a +1 to that counter under category `fragments`.

---

## What this fragment establishes (and what it does not)

**Establishes (canon, downstream agents may build on this):**

- The Stag-Court's offer to mortals is a recurring, formal **courtesy**
  — *ai-mhorren* — not a trap and not a hostility. It is older than the
  Sundering. The Antler-King's voice in this fragment is the canonical
  voice of the Court for any future writing.
- The cost of the seat is "one mortal year, remembered backwards." This
  is the shape of the door, not a price; it is what passing into the
  Court's slower season costs in human-time. Future writers should keep
  this exact phrasing or a near-paraphrase. Do not invent additional
  costs.
- The offer, once made, is **set down, not withdrawn.** A mortal who has
  been offered the seat carries the offer for life; the Court will
  honor it on any subsequent right-night-right-month visit. This is the
  rule that makes Maeve's situation (`elder_maeve.md`) canonical
  without forcing a resolution.
- The Crystal Caves keep things the village need not. The cave-air
  "smells of cold iron"; the caves are a *thirre* where time pools.
  Future codex fragments seeded in the Caves should share this
  air-quality detail (cold iron, very faint).
- The Court does not want company. The Antler-King is "glad" when
  mortals refuse the seat. This is a deliberate softening of the
  classic fey-trap trope; it is on-theme for warm gravitas
  (`THEME.md` §7).
- The scribe who wrote the leaf was a girl of fourteen on her offering
  night and an old woman of sixty-three when she folded the leaf into
  the rock. She is **not named** in the fragment. Future writers may
  give her a name, but they should not give her one cheaply — she is
  the kind of NPC who is allowed to remain a *thressa-mai*
  (`elder_maeve.md`) in the village's memory.

**Does NOT establish (please do not contradict in future runs):**

- The fragment is not a quest hand-in for Elder Maeve. Maeve does not
  speak the Stag-Court's offer aloud — she will not, ever, per
  `elder_maeve.md`. If a player presents this codex to Maeve, her
  reaction is **silence and one slow nod.** That is the line. If a
  Builder run wires a special dialogue branch for the codex, please
  use the silence-and-nod and an inline gesture (`anim_nod_slow`),
  not a spoken line.
- The fragment does not name the Antler-King. The Antler Crown
  (`world.md`) is canon as the Stag-Court's seat; the *Antler-King* in
  this fragment is the speaking voice of the Court at the moment of
  the offering. Whether there is one Antler-King or many, whether the
  King changes with the seasons, whether the Court has a Queen — none
  of this is settled. Future Lorekeeper runs may shape it; please leave
  it open for now.
- The fragment does not say what the *measuring* measures. This is
  intentional. The Court weighs mortals on a scale we do not get to
  see. Builder may not gate any quest on a "measurement score." Lore
  Keeper has reserved the silence.

---

## Cross-canon references

- **Stag-Court / Antler Crown** *(world.md, Three Crowns)* — the
  fragment's central subject. The Court's seat, the cost of the seat,
  and the courtesy of the offering are all canon now.
- **Crystal Caves as *thirre*** *(world.md, Tongues + The Sundering)* —
  the cave is "the wound itself, still unhealed." This fragment is one
  of the things the wound is keeping.
- **Foxthaw** *(world.md, Calendar)* — the right month for the
  forest-line offering. Foxthaw evenings are the canonical time for
  fox-fire; the Court's courtesies cluster here.
- **Honeysong Eve** *(world.md, Calendar)* — paired in the fragment as
  another rite the village must keep. The fragment names "Erris's
  lanterns" — the midsummer paper-lantern offering — as one of three
  things the next Vigil-keeper should tend (Vigil candles, lanterns,
  herb beds).
- **Vellum the Patient Stone** *(world.md, Wild Pantheon)* — invoked in
  the closing line. *"Vellum is patient"* is now a canonical Briarwood
  closing for any document committed to long-keeping (a will, a deed,
  a folded leaf in a cave).
- **Erris of the Two Roads** *(world.md, Wild Pantheon)* — named by her
  midsummer rite. The Court mentions her obliquely; the Court does not
  speak her name.
- **Elder Maeve's Stag-Court offer** *(elder_maeve.md, "A secret she
  keeps")* — Maeve's situation now has its mythic frame: she is the
  living instance of the rule the fragment names. The fragment does
  **not** confirm or deny that Maeve was offered the seat. It says the
  rule exists. Maeve's specific story remains where Maeve's bible
  keeps it.
- ***kerrithen*** *(world.md)* — the Antler-King's "putting down a
  memory for safe-keeping" is a deliberate echo of *kerrithen*. The
  Court speaks Old Faerie in its own constructions, but the verb-root
  is the same. Lyra would notice.

---

## Hooks for future runs

- **A second fragment** may surface in the Crystal Caves under category
  `fragments` — perhaps a leaf in a different hand, perhaps from the
  Stone Crown's side of the same offering. Suggested name:
  *The Steppe-Rider's Refusal.* It would pair naturally with Maeve's
  brother Cailen (`elder_maeve.md`) but should not name him.
- **A Codex panel** (Builder/UI) is the natural surface for this kind
  of fragment. Suggested layout: a parchment-bound panel with the
  fragment text rendered as the *body*, the YAML-frontmatter rendered
  as a small *found-in* footer, and the "What this establishes / What
  this does not" sections collapsed by default. The Old Faerie words
  could populate a separate "Glossary" tab keyed by fragment.
- **A muted ambient cue** when the fragment drops: a single flute note,
  Celtic-toned, no chord. The leaf falls to silence. Audio agent may
  pick this up.
- **A codex-collected counter** could surface on Maeve's dialogue tree:
  past a threshold of 3 fragments collected, Maeve has one new line
  available — *"You have been listening, traveler. Walk warmly."* Note
  the *velhain-tor* construction in Common — Maeve is letting it through
  without translating. This is the only place she ever does, and the
  player should not be told she did.
- **Festival timing.** A Foxthaw-only line for any NPC who has read this
  codex in their lifetime: *"Mind the forest-line tonight, traveler."*
  Eligible: Maeve (silent on this rule, but the line is in-character),
  Lyra (who suspects), Roan (who walked the High Steppe and has his own
  reasons). Not Bram, not Mara, not Edda, not Hala — they would not say
  it.

---

## Author note for downstream agents

This fragment is one of the load-bearing pieces of *why the Stag-Court
matters*. Please do not introduce a Court-related quest, NPC, or item
that contradicts the rules above (the courtesy is real; the seat is
set down, not withdrawn; the Court is glad when mortals say no). The
softness of the Court is the point. We are not writing a fey-trap. We
are writing a forest that remembers us.

If a future Lorekeeper wishes to harden the Court — make it a
threat, a tempter, a villain — please write a *separate* power under
the older-than-the-Sundering layer (`world.md`: *"There are older
powers under these. They are not named in polite company."*) and let
the Stag-Court remain what this fragment makes it. The world has room
for both.

*Vellum is patient.*
