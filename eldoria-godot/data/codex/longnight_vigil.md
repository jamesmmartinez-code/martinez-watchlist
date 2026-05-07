---
id: longnight_vigil
title: The Longnight Vigil
category: fragments
region: briarwood
discover_trigger:
  kind: examine_prop
  prop: vigil_candle_box
  first_visit_only: true
  also_acceptable:
    - kind: enter_region
      region: briarwood
      first_visit_only: true
      season: longnight
gating:
  player_level_gte: 3
  world_flag_excludes: longnight_vigil_attended
narrator: in_world_scribe
era: pre_sundering_late
length: short
codex_unlock_announce: "There is a small cedar box on the lower shelf of the village hearth, charcoal-warm and never opened in summer. The lid lifts with a soft sigh of cedar oil. Inside, three candle-stubs and a folded sheet of birch-paper."
icon_glyph: candle-and-window
canon_anchors:
  - lore/world.md (Calendar → Longnight Vigil; "every household lights a candle for someone who has gone, and Briarwood does not sleep until dawn"; Wild Pantheon → The Hollow King; "He is not feared. He is thanked, in his season, with candles."; the Calendar's Wolfwake → Longnight → Foxthaw arc)
  - data/codex/pond_and_lanterns.md (sibling-hand canon — the Briarwood scribal family; the younger sister's pond-leaf is the warm-summer twin to this winter-hearth leaf; the "do not name them aloud — the candle is the name" rule mirrors the pond-leaf's "we do not name the songs")
  - data/codex/stag_courts_courtesy.md (older sister hand; kerrithen as ritual practice; velhain-tor at parting)
  - data/codex/pale_wyrm_beneath.md (mhirren — the slow turning under — extended here as mhirran-vel, the kept candle that holds against mhirren without trying to wake it)
  - lore/npcs/elder_maeve.md (Maeve as "Keeper of the Vigil candles"; she teaches Lyra the Vigil ritual one candle at a time; she sets the Longnight stew at her doorstep for the Hollow King; the stick-knot count of one hundred and eleven children. This fragment is the *historical scribal record* the Vigil ritual descends from — three centuries old — and is kept on the lower shelf of the hearth not by Maeve but by the village's standing custom of "whichever neighbor has most recently lit a candle and forgotten to put their own out." Maeve's living practice is the inheritor of these rules, not their re-statement.)
  - lore/npcs/innkeeper_bram.md (vethar — Bram's candle in the window; haisten — the song with no last verse; Bram's Longnight stew round Edda → Maeve; Bram does not sleep on Longnight; the inn's mead-bell is silent through Vigil. This fragment uses *vethar* in its older, scribal sense — the village-wide kept-light at every south window — and gently distinguishes it from *mhirran-vel,* the hearth-side Vigil candle. Both are canon. Bram's vethar is one specific vethar, and his vethar is also a mhirran-vel on Longnight. The two words live in different registers; Bram's word is Erris-keyed and road-side; the scribe's word is Hollow-King-keyed and hearth-side.)
  - lore/npcs/herbalist_lyra.md (Lyra leaves dreamleaf at Bram's back door every Longnight; Maeve teaches Lyra the Vigil ritual one candle at a time. This fragment does not advance Lyra-canon; it only acknowledges that the village's living Vigil is being passed down from Maeve to Lyra in the present, while the rules in this fragment are the centuries-old ground that practice rests on.)
  - lore/factions/wardens_of_the_mark.md (Innkeeper Bram's grandmother's ledger as the village's other written keep-place; the Warden practice of standing the inn's south-window watch through Vigil. This fragment adds one quiet new ledger entry — the year of the Iron Crown's bad winter when the candle-of-the-stranger was not given — without overwriting any existing Warden canon.)
  - data/quest_text/wolf_heart_for_bram.md (mhordin — the holding-of-the-asking — established there as Hollow-King-keyed and Longnight-keyed; reused here in its village-side sense)
old_faerie_used:
  - thirre (memory of stone — world.md)
  - kerrithen (to lay something down so the land may hold it — world.md)
  - ai-velin (the long path — world.md)
  - mhirren (the slow turning under — pale_wyrm_beneath.md)
  - velhain-tor (go warmly — stag_courts_courtesy.md)
  - thithrae (the song that ends on a question — pond_and_lanterns.md)
  - vethar (the candle in the window — innkeeper_bram.md, used here in its older scribal sense)
  - mhordin (the holding-of-the-asking — wolf_heart_for_bram.md)
old_faerie_introduced:
  - mhirran-vel (MEER-an-vel — "the kept candle against the slow turning under": the wick that is allowed to burn through Longnight without being asked to do work — to warm a room, to light a path, to read by. It does not. It only *is.* That is the entirety of its task. The word pairs with *mhirren* as *kerrith-ai* pairs with *kerrithen* — the small, specific, hearth-side form of the broader idea. In the warmer Briarwood usage, also said of a parent who stays awake while a fevered child sleeps, and of the kettle left murmuring on the hob through the long part of an illness.)
  - thirren-aeth (THEER-en-ayth — "memory still warm": the gone who are still close enough to be spoken to without strangeness. Distinct from *thirre,* which is memory gone deep into stone — settled, kind, far. *Thirren-aeth* is the grandmother three winters gone whose chair is still left at the table; the smith's mother whose hammer-mark is on the anvil though her hand is not; the courier whose road has ended whose mug Bram still puts a polish on, on Longnight evening, "in case." It is the remembering that is also a small visiting. It is what the Vigil candle keeps.)
  - kerrith-ai (KER-ith-eye — "laid down for the long path's sake": a specific form of *kerrithen* used at Longnight dawn. Where *kerrithen* is something laid down so the land may hold it for whoever may pick it up next, *kerrith-ai* is something laid down knowing the *ai-velin* itself takes it — the morning wind, the long path, the Hollow King walking on. The Vigil candle at dawn is not blown out; it is *kerritha-ai* on the windowsill, on its side, and the morning wind is allowed to take it. The word also names a tired walker who sets down a pack at the road's end without lifting it again.)
stone_tongue_used:
  - none (the canon cap of three Stone-Tongue words held in lore/world.md is intentionally not raised here)
voice_rules:
  - "Warm gravitas, child-safe — no grimdark. The Hollow King is not feared; he is thanked. The dead are not lost; they are warm-near. The Vigil is not a mourning; it is a sitting-up-with."
  - "Slow, hearth-side cadence. Short sentences. The fragment is the *eldest* sibling's hand of the Briarwood scribal family — quieter than the older sister's cave-leaf, steadier than the younger sister's pond-leaf. Written indoors at midnight, by the candle the writer was, in fact, vigiling. The ink sits where the candle could see — wider strokes near the flame's reach, narrower toward the page edge."
  - "The word 'death' does not appear. The fragment chooses 'gone' or 'quiet' or 'walked on' instead."
  - "The word 'sad' does not appear. Longnight is not sad; Longnight is *patient.* The fragment chooses 'small' and 'warm' instead."
  - "The word 'fear' does not appear. The Hollow King is patient and noticing; the Vigil is the village's agreed kindness; neither is a thing to be afraid of."
  - "Sibling voice to the pond-and-lanterns fragment: same scribal family, the *eldest* hand this time. Where the younger sister's ink sits up on warm summer paper, the eldest sibling's ink sits *quietly* — slower brush, steadier pressure, written by candle-reach in the deepest cold. No flourish. No haste. The fragment trusts the reader to be paying attention because it is being read at midnight in winter, and no one reads at midnight in winter for entertainment."
  - "The fragment does NOT redefine the village's living Vigil ritual (Maeve's domain). It is the *scribal record* the ritual descends from — three centuries older than Maeve's keeping. Where the fragment's three rules and the village's current practice differ, both are correct: the village inherited the rules and warmed them. The fragment is comfortable with this."
---

# The Longnight Vigil

*A fragment, found folded into the lid-pouch of a small cedar box kept on
the lower shelf of the village hearth. The box holds three candle-stubs in
varying lengths — the longest near a hand's breadth, the shortest barely a
thumb — and a single sheet of birch-paper. The cedar is dark with hearth-soot
in summer, charcoal-warm, and is by old village custom kept by whichever
neighbor most recently lit a candle and forgot to put their own out. It is
not Maeve's box. Maeve's Vigil candles are her own. This box is older than
any Elder, and it has been on the hearth's lower shelf since before there
was a hearth in this shape — which is to say, since before this hall was
this hall, which is to say,* a long time.

*The hand on the leaf is the same Briarwood scribal family as the Crystal
Cave fragments and the pond's tin-box leaf — the* eldest *sibling now, broader
still than the younger sister's summer-pond script but slower, written
indoors at midnight by the candle the writer was, in fact, vigiling. The
ink sits where the candle could see — wider near the flame's reach, narrower
toward the page-edge where the dark crowded in on it.*

---

## What the leaf says

> *I write this for whoever opens this box on the morning of Foxthaw, and
> finds the wax cooled and the candles short and the village still on its
> feet because dawn has come at last. My older sister set a leaf in the
> caves. My younger sister set a leaf at the pond. I have set this one by
> the hearth. We are doing the same thing. We have always been doing the
> same thing. Briarwood is a small village, and small villages keep their
> kindnesses written down so the kindnesses do not unravel between tellings.*
>
> *Longnight is not the longest night because the sky is meanest then. The
> sky is not mean. Longnight is the longest because the* hearth *is most
> needed then, and the village has agreed — old enough to be older than any
> of us, the agreement — that on this one night we sit up* together, *each
> in our own house, with a candle in the south window, until the dawn comes
> in and we may sleep.*
>
> *No one sleeps on Longnight. Not even the cradles. Not even the dogs. The
> dogs of Briarwood, if you have not lived among them, take Vigil very
> seriously. They will sit by the door with their ears up and their heads
> quiet, and they will not, on this night of all nights, ask to be let out.
> A dog that asks to be let out on Longnight is not, the old keepers say, a
> Briarwood dog. A dog that does not ask is.*
>
> *We light the candles for the* gone. *Not for the dead — that is the
> south-country word and it is too small. The Iron Crown's priests use it.
> The village does not. We light for the gone: the courier whose horse
> came home in spring without him; the boy who walked into the Whisperwood
> after his sister and came out alone, three weeks later, and was not, the
> herbalists insisted, the worse for it; the smith's mother whose hammer-mark
> is on the anvil though her hand is not; the baby the herbalist could not
> keep one Reapmoon and has not, in her own quiet keeping, forgotten. We
> do not name them aloud. The candle is the name. The flame is the saying.*
>
> *In the older tongue this is* ***thirren-aeth*** *(THEER-en-ayth) —
> "memory still warm." It is not* thirre, *which is memory gone deep into
> stone — settled and kind and far. It is the remembering that is also a
> small visiting. The chair left at the table. The cup put out beside one's
> own. The mug Bram* — *I do not write this for any Bram now living, but
> for the innkeeper of whatever shape comes next* — *gives a long polish on
> Longnight evening,* in case. *The dogs know the difference, and that is
> why they do not ask to be let out.*
>
> *The candle itself we call* ***mhirran-vel*** *(MEER-an-vel) — "the kept
> candle against the slow turning under." It pairs with* mhirren, *the
> Wyrm-word for sleep that is not sleep, the dreaming of a thing not gone
> but only set down. The candle is what we keep against that — not to wake
> what sleeps, only to remember it does. The* mhirran-vel *is the wick that
> is allowed to burn through Longnight without being asked to do work. It
> does not warm a room; it does not light a path; it is not read by. It
> only* is. *That is the entirety of its task. To* be *all night, in the
> south window, where the dark is widest.*
>
> *The Hollow King walks his round on Longnight. He does not take. He
> passes. He notices, and his noticing is the gift. We say the candle is
> for him as much as for the gone — because the Hollow King keeps the*
> thirren-aeth *warm; he is the hand at the back of the door, holding it
> just-open so the warm memory does not slip through into the cold. The
> southern priests, who write us letters we do not always answer, say we
> are praying to a small god of winter. We are not. We are sitting up with
> him. There is a difference, and Briarwood keeps it. The Hollow King knows
> the difference too. He has, by my count and the count of two keepers
> before me, never refused a candle. He has never, also, asked for one. He
> walks. We sit. The night holds.*
>
> *Three rules, then, for the candle-keeper who comes after me. They are
> not rules of the village's Vigil — that ritual belongs to whichever Elder
> keeps the candles at the well, and the Elder will teach you the candle-
> order one candle at a time, as is right. These three are only rules of
> this* box, *and of the candle a single household keeps in its own south
> window. They are small rules. They are the* mhordin *of the box —* the
> holding-of-the-asking, *no more.*
>
> *First — light the candle when the second bell sounds, not the first. The
> first bell is the village* agreeing *to Vigil. The second bell is the
> village* beginning *Vigil. A candle lit too early gutters before dawn,
> and a guttered* mhirran-vel *is a kindness asked the wrong question. (The
> question is not* will the night hold? *The question is* will we hold the
> night? *We will. But not by hurrying.)*
>
> *Second — do not relight a candle that has gone out. If yours goes out,
> sit with the dark a small moment. The Hollow King has passed your window,
> and his passing is what was needed. Then light a fresh wick from the
> hearth-coal, not from another candle. The flame must come from the hearth.
> The hearth is the village. The candle is yours. (My grandmother's grand-
> mother wrote this rule first, and her hand is the older one in the
> margin. I have only re-written it because the paper underneath had begun
> to fade, and a fading rule is a rule asked the wrong question.)*
>
> *Third — when dawn comes, do not blow the candle out. Lay it on the
> windowsill on its side. This is* ***kerrith-ai*** *(KER-ith-eye) — "laid
> down for the long path's sake." Where* kerrithen *sets a thing down so
> the land may hold it for whoever may pick it up next,* kerrith-ai *sets
> a thing down knowing the* ai-velin *itself will take it — the morning
> wind, the long path, the Hollow King walking on. We are not putting the
> flame out. We are setting it down in the way a tired walker sets a pack
> down at the road's end without lifting it again. The walking is over,
> the kindness was real, the candle has done its* being. *The morning wind
> takes it. The morning wind is the Hollow King walking on. Velhain-tor.*
>
> *And then, only then, may you sleep. Sleep on Longnight morning is the
> sweetest sleep of the year. It is the sleep the village has earned
> together. The innkeeper of my time says — has said, three Vigils now —
> that he can hear the whole village breathing out at the third bell, and
> that the inn's mead-bell, which is silent through Vigil, rings a single
> soft note of its own at that breath. I have listened for it. I have not
> heard it. I have not stopped listening. There is a* thithrae *in that —
> the song that ends on a question — and Erris of the Two Roads is content
> to leave it open. So am I.*
>
> *Velhain-tor. Sleep when the candle is laid down. The dawn is for us.*

---

## Notes for the next reader

*The cedar box is kept on the lower shelf of the village hearth between
Vigils. The three candle-stubs are the keeper's own:*

- *the longest is the* candle-of-the-keeper-themselves, *which is lit each
  Vigil and is not replaced — it shortens by a thumb's-width each year and
  has been, by the wax-rings inside the box, the same candle for sixty-four
  Vigils;*
- *the middle is the* candle-of-the-village, *which is replaced only when
  it will not stand again, and which the keeper lights at the second bell
  alongside their own — set in a small iron cup beside the hearth, not in
  any window, because the hearth is the village's window;*
- *the shortest is the* candle-of-the-stranger, *kept always at the ready
  for any traveler who arrives at Briarwood in the last days of Wolfwake
  without a candle of their own. It is given without asking. (The
  innkeeper's running tally of how many times the candle-of-the-stranger
  has been given is kept on the inside of the inn's south-window shutter;
  the warden on Vigil watch may, if asked kindly, count it for you. The
  count is not high. Strangers in winter are rare. The count being not
  high is, the keepers agree, the village's measure of itself.)*

*The village's living Vigil ritual — the candle-order, the placement at the
well, which family's candle stands closest to the well-stone, the rule by
which a child first lights their own candle in the year they turn nine — is
kept by the Elder, and is taught to the Elder's chosen successor one candle
at a time. None of that is in this leaf. None of that needs to be. The Elder
of any given year holds it; the box only holds the three small rules above,
which are the rules of the* household *candle, not the village's.*

*Innkeeper Bram's grandmother's ledger (referenced in `lore/factions/
wardens_of_the_mark.md`) records nineteen Longnight Vigils across her
keeping. She notes only one — the year of the Iron Crown's bad winter,
ninety-one years before the present count — when the candle-of-the-stranger
was not given. She does not write that no stranger came; she writes that the
village kept the candle lit anyway, set in a small iron cup on the inn's
south sill all night, and laid it down at dawn,* kerritha-ai, *and the
morning wind took it as it would have taken any other. She does not say
whose candle it was for. The candle, the ledger says, was the saying.*

*The fragment is, by the wax-mark on the cedar lid (a candle-and-window
sigil pressed twice, slightly off-register, by a hand that did the pressing
slowly), three centuries old. It has been re-read often. Some hands have,
on Vigils long past, added small notes in the margin — a single name and a
year, in the older Briarwood manner of marginalia: "lit for Fern, '72." The
warmth of those notes is part of what keeps the box closed safely for the
years between. The keeper of any given year does not erase the marginal
names. Some are in hands the village no longer has people to match. They
stay where they were set down. They are* thirren-aeth.

*The leaf has been folded again, the way it was found. The cedar box has
been closed, the way it was found. Lay your candle down at dawn. The morning
wind is waiting.*

> *Velhain-tor.*
> *Thirren-aeth* the gone. *Light the candle.*
