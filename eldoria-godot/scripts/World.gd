extends Node3D
class_name World

# Realm of Eldoria — World root.
# Owns: dialogue UI, HUD, day/night cycle, quest UI, death overlay,
# toast helper, full inventory + paperdoll panel, quest catalog (kill + fetch),
# runtime affix-item registry.

@onready var dialogue_panel: Panel = $UI/DialoguePanel
@onready var dialogue_name_label: Label = $UI/DialoguePanel/MarginContainer/VBox/NameLabel
@onready var dialogue_text_label: RichTextLabel = $UI/DialoguePanel/MarginContainer/VBox/TextLabel
@onready var dialogue_close_btn: Button = $UI/DialoguePanel/MarginContainer/VBox/CloseBtn
@onready var sun: DirectionalLight3D = $WorldEnvironment/Sun
# REFINE: visual — outdoor — grab the moon-fill light + WorldEnvironment so the
# day/night cycle can breathe atmosphere (fog, glow, moon energy) — not just
# rotate the sun. THEME §3 calls for sunset-warm dominance with cool tones
# reserved for night/mist; modulating these per-frame lets the same scene
# read warm at dusk and cool/blue at midnight without re-authoring assets.
@onready var moon_fill: DirectionalLight3D = $WorldEnvironment/MoonFill
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var hud: Control = $UI/HUD
@onready var hp_bar: ProgressBar = $UI/HUD/HPBar
@onready var mp_bar: ProgressBar = $UI/HUD/MPBar
@onready var xp_bar: ProgressBar = $UI/HUD/XPBar
@onready var level_label: Label = $UI/HUD/LevelLabel
@onready var gold_label: Label = $UI/HUD/GoldLabel
@onready var renown_label: Label = $UI/HUD/RenownLabel
@onready var quest_panel: Panel = $UI/QuestPanel
@onready var quest_label: Label = $UI/QuestPanel/QuestLabel
@onready var death_overlay: ColorRect = $UI/DeathOverlay
@onready var death_label: Label = $UI/DeathOverlay/DeathLabel

var time_of_day: float = 11.0
# Run 16 (Builder): integer day-counter that increments every time `time_of_day`
# wraps from late night back through dawn. Read by `npc_memory` so NPCs know
# "first met you on day 0, last spoke day 4" (= "you've been gone four days").
# Pure derivation from time_of_day — `_prev_tod` witnesses the wrap in _process.
var world_day: int = 0
var _prev_tod: float = 11.0
var _current_npc_role: String = ""
var _current_npc_name: String = ""


# Inventory UI — built lazily on first open
var inventory_panel: Panel = null
var paperdoll_slots: Dictionary = {}    # slot_name -> Button
var bag_buttons: Array = []             # Array of Button for each bag slot
var stats_label: RichTextLabel = null
var inv_tooltip: Label = null

# Runtime registry for affix-generated items (keys begin with "@")
var _runtime_items: Dictionary = {}

# ────────────────────────────────────────────────────────────────────────
# World-engine runtime state (consequence resolver targets)
# Populated/mutated by apply_consequence(). Read by NPCs, dialogue, quests.
# ────────────────────────────────────────────────────────────────────────
var factions: Dictionary = {
	"briarwood": {"disposition": "friendly", "pressure": 0.0},
	"whisperwood_goblins": {"disposition": "hostile", "pressure": 1.0},
	"dire_wolves": {"disposition": "hostile", "pressure": 0.5},
	"crystal_caves": {"disposition": "hostile", "pressure": 0.0},
	# COMPOUND (run 21 — Builder): bandits faction. Inverse-driven: when
	# the goblin/wolf threats subside, opportunistic bandits creep onto
	# the road. `pressure` here measures BANDIT BOLDNESS (0.0 dormant →
	# 1.0 brazen), not threat-to-be-cleared like the others. Starts at
	# 0.0 because at fresh-save the woods are dangerous enough that the
	# bandits stay hidden; `update_bandit_pressure()` derives the live
	# value from goblin+wolf pressure and writes it back here. THREE
	# existing consumers light up automatically the moment a bandit
	# enemy spawns and KIND_TO_FACTION resolves "bandit" → "bandits":
	# Enemy.gd cooldown band (run 7), Enemy.gd chase-speed band (run 8),
	# WorldBuilder spawn density (run 5/6 patterns). The 4th consumer
	# (NPC dialogue tier) is wired by Roan's new `warm_world_flag`:
	# "bandits_emergent" lines in WorldBuilder.NPCS this run — Roan is
	# the road-traveler, so he speaks the emergence first.
	"bandits": {"disposition": "hostile", "pressure": 0.0},
}
var world_flags: Dictionary = {}      # flag_name -> Variant (usually bool/int)
var npc_flags: Dictionary = {}        # npc_name -> Array[String]
# Run 16 (Builder) — npc_memory: per-NPC visit ledger. Schema:
#   npc_memory[npc_name] = {
#     "visits":         int,   # total times the player triggered this NPC's
#                              # _on_interact (incremented by record_npc_visit)
#     "first_day":      int,   # world_day on first visit (-1 = never met)
#     "last_day":       int,   # world_day on most recent visit (-1 = never)
#     "first_tod":      float, # time_of_day on first visit
#     "last_tod":       float, # time_of_day on most recent visit
#   }
# WRITES: `record_npc_visit(name)` only — invoked by NPC.gd at the top of
# _on_interact BEFORE any tier resolution, so visit-count includes the
# triggering call.
# READS: `npc_visits()`, `npc_first_visit_day()`, `npc_last_visit_day()`,
# `npc_days_since_last_visit()`. The tier-resolution path in NPC.gd
# (warmed_memory_visits_min) is the first reader; future quest predicates,
# achievement triggers ("Visited every villager"), and dialogue conditions
# all enter through the same accessor surface.
var npc_memory: Dictionary = {}

# Run 20 (Builder) — npc_seen: per-NPC "have we ever met?" ledger.
# Schema: { npc_name -> bool }. An entry of `true` means the player has
# completed at least one full _on_interact tick with this NPC (i.e. dialogue
# was actually shown — recorded inside `show_dialogue`, AFTER DialogueDB has
# already chosen its line, so the FIRST hello fires the JSON `stranger` key).
#
# WRITES: `mark_npc_seen(name)` only — invoked from `show_dialogue` AFTER
# the line is set on the panel. Calling it earlier would race with
# DialogueDB.choose_line and the `stranger` predicate would never fire.
# Idempotent: re-marking an already-seen NPC is a no-op.
#
# READS:
#   * DialogueDB.gd `stranger` predicate (5th tier — see DialogueDB.gd
#     priority list). Fail-soft contract was already in place: when the
#     field didn't exist, the predicate skipped silently; now that it
#     does, every NPC's `stranger` JSON key fires on first encounter
#     and only on first encounter. All 7 NPC JSONs already author this
#     key (lore agent, 2026-05-04), so wiring this field lights up
#     7 already-on-disk lines with no JSON edit required.
#   * `is_stranger(name)` accessor — symmetry with `npc_visits()` /
#     `has_world_flag()` / `npc_has_flag()`. Future quest predicates
#     keyed on "first meeting" route through here, not the raw dict.
#
# Distinct from `npc_memory.visits` because:
#   * `visits` increments at the TOP of _on_interact (run 16) — by the
#     time DialogueDB resolves, visits is already ≥ 1 for the current
#     visit, so the first-visit window is invisible to a `visits == 0`
#     predicate.
#   * `npc_seen` flips at the END of dialogue display, so the `stranger`
#     check during DialogueDB resolution sees the OLD (false) value on
#     the first call and the NEW (true) value from the second onward.
var npc_seen: Dictionary = {}

# Achievement / Title state — read-only externally; mutated only by
# `_check_achievements()` which is invoked at the end of `apply_consequence`
# and once at `_ready` (so a fresh world boot picks up any pre-existing
# state — currently always empty since faction/flag state is per-session,
# but keeps the contract sound for future persistence work).
#   `unlocked_achievements`: Dictionary[String, bool] — keys are IDs in
#       `Achievements.ACHIEVEMENTS`. Bool value is always `true`; the
#       dict shape (rather than Array) makes lookup O(1) and avoids
#       duplicate-detection logic on the unlock path.
#   `current_title`: String — auto-equipped title text drawn above the
#       player's head as a Label3D. "" means no title (default).
var unlocked_achievements: Dictionary = {}
var current_title: String = ""

# Player renown — first-class integer that DialogueDB.choose_line() reads via
# the `high_renown` predicate (defaults to threshold 100). Granted by
# `gain_renown(amount, source)` and automatically credited from
# `_check_achievements()` (each newly-unlocked achievement awards renown
# equal to its `title_priority` so tier-1 achievements grant 10, tier-3
# Wolf-Friend grants 30, Goblin-Bane 40, Trusted 50, Warden 100 — the tier
# ladder doubles as the renown ladder, no new tuning surface).
#
# READS:
#   * DialogueDB.gd via `"player_renown" in world_node` (was fail-soft until
#     this field landed; now lights up `high_renown` keys in
#     elder_maeve.json, smith_edda.json, innkeeper_bram.json, herbalist_lyra.json)
#   * HUD `RenownLabel` (visible feedback in the same gold palette as Gold)
#
# WRITES:
#   * `gain_renown(amount, source)` — only PUBLIC mutator. Toasts on positive
#     gains so Owen + Alden see the number rising.
#   * `_check_achievements()` — internal call into gain_renown when a new
#     achievement unlocks. Source string is "<icon> <name>".
#
# By making renown achievement-derived rather than quest-derived, the renown
# integer is the FIRST value in this class that's a pure FUNCTION of
# `unlocked_achievements`. That keeps it idempotent under any future save/load
# pass — `_recompute_renown_from_achievements()` rebuilds it from scratch.
var player_renown: int = 0


# ────────────────────────────────────────────────────────────────────────
# Quest catalog — every quest available in the realm
# ────────────────────────────────────────────────────────────────────────
const QUEST_CATALOG := {
	"whisperwood_cleansing": {
		"giver": "Elder Maeve",
		"actor": "Elder Maeve",
		"role": "quest",
		"kind": "kill",
		"target": "goblin",
		"needed": 5,
		"title": "Whisperwood Cleansing",
		"text": "Slay 5 goblins in the Whisperwood",
		"xp_reward": 80,
		"gold_reward": 60,
		"motivation": "duty",
		"location": "Whisperwood",
		"urgency": "rising",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "whisperwood_goblins",
			"pressure_delta": -0.2,
			"npc_flag": ["Elder Maeve", "first_quest_done"],
			"world_flag": "whisperwood_safer",
			"toast": "🌿 The Whisperwood feels a little safer.",
		},
	},
	"pelt_for_lyra": {
		"giver": "Herbalist Lyra",
		"actor": "Herbalist Lyra",
		"role": "alchemy",
		"kind": "fetch",
		"item": "wolf_pelt",
		"needed": 4,
		"title": "Pelts for the Salve",
		"text": "Bring 4 Wolf Pelts to Herbalist Lyra",
		"xp_reward": 70,
		"gold_reward": 45,
		"reward_item": "hp_potion_l",
		"reward_item_qty": 2,
		"motivation": "craft",
		"location": "Briarwood",
		"urgency": "calm",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "dire_wolves",
			"pressure_delta": -0.1,
			"npc_flag": ["Herbalist Lyra", "trusts_player"],
			"world_flag": "lyra_potion_brew",
			"toast": "🌱 Lyra trusts you with rarer reagents now.",
		},
	},
	"ears_for_mara": {
		"giver": "Mara the Merchant",
		"actor": "Mara the Merchant",
		"role": "shop",
		"kind": "fetch",
		"item": "goblin_ear",
		"needed": 6,
		"title": "Bounty on Goblin Ears",
		"text": "Mara pays well for proof of slain goblins — bring 6 ears",
		"xp_reward": 60,
		"gold_reward": 90,
		"motivation": "greed",
		"location": "Briarwood",
		"urgency": "calm",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "whisperwood_goblins",
			"pressure_delta": -0.15,
			"npc_flag": ["Mara the Merchant", "good_customer"],
			"world_flag": "mara_bounty_paid",
			"toast": "🪙 Word spreads: Mara pays for goblin trophies.",
		},
	},
	# COMPOUND (run 17 — Builder): Roan-issued wolf-bounty quest. SECOND
	# `dire_wolves` reducer (after `pelt_for_lyra` -0.1). Mirrors `ears_for_mara`
	# as Mara's second-goblin-reducer pattern. Drops fang fetch onto Wolf's
	# DROP_TABLE (Items.gd run-17 rebalance). Lights up:
	#   * Roan dialogue tier 2 (warm_flag `first_bounty_done`, 4 lines added
	#     in WorldBuilder run 17). Roan goes from faction-only to faction +
	#     warm_flag — same depth as Mara/Lyra/Maeve.
	#   * Wolf spawn density: 0.5 → 0.4 (after Lyra) → 0.3 (after this) trips
	#     the run-6 second cliff (3 wolves → 2). Standalone (no Lyra) hits
	#     0.5 → 0.4 trips the FIRST cliff (4 → 3) — also visible.
	#   * Adaptive cooldown (run 7) and chase speed (run 8) both lerp another
	#     step on the same scalar. Surviving wolves get ⚡-tagged faster.
	#   * Roan faction-tier (warm_faction_below 0.5 from run 8) stays lit;
	#     warm_flag tier above takes priority once `first_bounty_done` is set.
	#   * `roan_bounty_paid` world_flag joins `mara_bounty_paid` /
	#     `lyra_potion_brew` / `whisperwood_safer` as the FOURTH quest-issued
	#     world flag — future systems (e.g. evening tavern toasts, achievement
	#     "Tamer of the Wolfwoods") can consume without code changes.
	# Reward economy: 50 gold (between Mara's 90 and Lyra's 45) + 65 xp.
	# `needed: 5` deliberately under Lyra's 4-pelt grind so back-to-back run
	# is satisfying rather than punitive (5 wolves = 5 pelts + 5 fangs at the
	# rebalanced drop weights ≈ ~85% expected on a single 5-kill grind).
	"wolf_fang_for_roan": {
		"giver": "Stablemaster Roan",
		"actor": "Stablemaster Roan",
		"role": "stable",
		"kind": "fetch",
		"item": "wolf_fang",
		"needed": 5,
		"title": "Bounty on Dire Wolves",
		"text": "Roan pays for fanged proof — bring 5 Wolf Fangs",
		"xp_reward": 65,
		"gold_reward": 50,
		"motivation": "duty",
		"location": "Whisperwood",
		"urgency": "rising",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "dire_wolves",
			"pressure_delta": -0.1,
			"npc_flag": ["Stablemaster Roan", "first_bounty_done"],
			"world_flag": "roan_bounty_paid",
			"toast": "🐎 The road feels safer. Roan tips his hat.",
		},
	},
	# COMPOUND (run 18 — Builder): Hala-issued wolf-defense kill quest. THIRD
	# `dire_wolves` reducer (after `pelt_for_lyra` -0.1 and
	# `wolf_fang_for_roan` -0.1). This is the missing keystone — the previous
	# Builder run wired Hala's WorldBuilder pitch line, warm_flag, and
	# warm_lines AND wired the `wolf_tamer` Achievements predicate referencing
	# `wolf_form_taught` on Hala — but never added the QUEST_CATALOG entry
	# that ACTUALLY sets the flag. Result: Hala's pitch promised a quest the
	# engine could never deliver, and the wolf_tamer achievement could never
	# trip. This entry closes both holes in a single edit.
	#
	# Lights up:
	#   * Hala dialogue tier 2 (warm_flag `wolf_form_taught`, 4 lines already
	#     authored in WorldBuilder run 18). Quest completion sets the flag,
	#     which immediately flips Hala's tone from "prove yourself" to
	#     "I saw it in you" — the rarest flavor for a teacher who never
	#     gushes. Tier 2 (warm_flag) ranks above tier 5 (memory) so once the
	#     quest is in, returning trains read the warm lines first.
	#   * Wolf spawn density: 0.3 (after Lyra + Roan) → 0.2 trips the run-6
	#     SECOND CLIFF (3 wolves → 2). With all three reducers stacked
	#     player-side the wolf pack visibly thins to 2 surviving wolves —
	#     a major Whisperwood quietening beat. The run-6 third cliff
	#     (< 0.15) is one more reducer away (single mid-run hook for
	#     downstream).
	#   * Adaptive cooldown (run 7) and chase speed (run 8) both lerp
	#     another step on the same scalar. The 2 surviving wolves are now
	#     ~21% faster and attack ~28% slower than fresh-save wolves — a
	#     "older, wiser, hungrier" feel that's mechanical, not narrative.
	#   * `wolf_tamer` Achievement (Achievements.gd:wolf_tamer) was wired
	#     in run 18 but unreachable until now. Predicate
	#     `all_npc_flags: [Lyra/trusts_player, Roan/first_bounty_done,
	#     Hala/wolf_form_taught]` finally resolves to TRUE on this quest's
	#     completion (assuming the prior two are done). Title "the
	#     Wolf-Tamer" (priority 35) auto-equips above "Wolf-Friend" (30).
	#   * `hala_wolf_form_taught` world_flag joins `mara_bounty_paid` /
	#     `lyra_potion_brew` / `whisperwood_safer` / `roan_bounty_paid`
	#     as the FIFTH quest-issued world flag — future systems (e.g.
	#     evening tavern toasts, cross-NPC dialogue references) can
	#     consume without code changes.
	# Reward economy: kill quest like Maeve's `whisperwood_cleansing`, but
	# scaled to wolves (rarer drops, 4 needed instead of 5). 75 xp + 40 gold
	# matches the pattern: Hala teaches more than she pays. `needed: 4` is
	# from Hala's authored pitch ("Take down 4 — you'll learn the form by
	# doing"); changing it would desync the dialogue.
	"wolf_form_with_hala": {
		"giver": "Trainer Hala",
		"actor": "Trainer Hala",
		"role": "trainer",
		"kind": "kill",
		"target": "wolf",
		"needed": 4,
		"title": "Wolf Form, Hala's Drill",
		"text": "Trainer Hala wants 4 wolves felled — learn the form by doing",
		"xp_reward": 90,
		"gold_reward": 35,
		"motivation": "duty",
		"location": "Whisperwood",
		"urgency": "rising",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "dire_wolves",
			"pressure_delta": -0.1,
			"npc_flag": ["Trainer Hala", "wolf_form_taught"],
			"world_flag": "hala_wolf_form_done",
			"toast": "🥋 Hala nods. The form holds.",
		},
	},
	# COMPOUND (run 20 — Builder): Bram-issued wolf-heart bounty quest. FOURTH
	# `dire_wolves` reducer (after `pelt_for_lyra` -0.1, `wolf_fang_for_roan`
	# -0.1, and `wolf_form_with_hala` -0.1). Trips the run-6 THIRD CLIFF
	# (< 0.15 → packs of 1) — at fresh-save 0.5, all four reducers stack to
	# 0.1, which is the lowest a player can drive the wolf scalar without a
	# fifth quest existing. From here the only wolf left in the Whisperwood
	# is the apex/scarred survivor — a "she's the one who got away" beat
	# that downstream lore can name. Bram is the village rumor-exchange
	# (THEME §4 silhouette: "Round, jolly, white apron, mug-in-hand"); his
	# nightly bards stop singing when wolves howl on the road, so a heart-
	# trade is the inn-flavored slot in the wolf reducer chain — different
	# motive (peace for the songhouse) than Lyra (medicine), Roan (mares),
	# or Hala (mastery). Lights up:
	#   * Bram dialogue tier 2 (warm_flag `nights_quiet`, 4 lines added in
	#     WorldBuilder run 19). Bram goes from a memory-only NPC (run 16)
	#     to a full warm_flag + memory NPC — same dialogue depth as Maeve.
	#   * Bram's role `inn` was QUEST-BLANK before this entry — the existing
	#     `_quest_for_role("inn")` resolver returned `{}`, the Accept Quest
	#     button never appeared on Bram's dialogue panel. Now matches every
	#     other major NPC in dialogue depth + questgiver behavior.
	#   * Wolf spawn density: 0.2 (after the prior three) → 0.1 trips the
	#     run-6 THIRD CLIFF (2 wolves → 1). The single surviving wolf reads
	#     as "the alpha that wouldn't be hunted" — pacing-wise, at pressure
	#     0.1 cooldown lerps to ~1.07s and chase_speed lifts ~+15%, so the
	#     last wolf is *the* fastest, *the* hungriest. A boss-feeling fight
	#     without a boss-spawn — pure compound on existing scalars.
	#   * Achievement "wolf_tamer" (Achievements.gd, run 18 wire) still
	#     fires on Lyra+Roan+Hala without Bram — Bram is purely additive
	#     to the curve, not a fourth flag in the predicate. Keeps the
	#     "Wolf-Tamer" title attainable on the main three-trade arc.
	#   * `bram_nights_quiet` world_flag joins `mara_bounty_paid` /
	#     `lyra_potion_brew` / `whisperwood_safer` / `roan_bounty_paid` /
	#     `hala_wolf_form_done` as the SIXTH quest-issued world flag —
	#     future systems (e.g. evening tavern toasts, cross-NPC mentions
	#     of Bram's bounty in Maeve's warm_world tier) can consume without
	#     code changes.
	# Reward economy: 70 xp + 55 gold. Sits between Roan (65/50) and Lyra
	# (70/45 + 2x hp_potion_l) on the wolf-quest reward curve. `needed: 3`
	# wolf_hearts at drop weight 8/100 ≈ ~12.5 wolf kills — same wolf-time
	# as Roan's 5-fang grind (~13.9 kills), so back-to-back-to-back-to-back
	# (Lyra + Roan + Hala + Bram) is satisfying rather than punitive. The
	# Heartwood Mead consumable is a future Polisher hook (a strong heal +
	# brief mp regen) that Bram pours on completion; for run 19 the reward
	# is the gold + xp + the world-state cascade.
	"wolf_heart_for_bram": {
		"giver": "Innkeeper Bram",
		"actor": "Innkeeper Bram",
		"role": "inn",
		"kind": "fetch",
		"item": "wolf_heart",
		"needed": 3,
		"title": "Quiet Nights at the Long Lantern",
		"text": "Bram trades the deep barrel for 3 Wolf Hearts — proof the howling has thinned",
		"xp_reward": 70,
		"gold_reward": 55,
		"motivation": "duty",
		"location": "Whisperwood",
		"urgency": "rising",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "dire_wolves",
			"pressure_delta": -0.1,
			"npc_flag": ["Innkeeper Bram", "nights_quiet"],
			"world_flag": "bram_nights_quiet",
			"toast": "🍻 The Long Lantern's bards play through to dawn now.",
		},
	},
	# COMPOUND (run 23 — Builder): Roan-issued bandit-clear kill quest. The
	# FIRST quest to consume the run-21/22 bandit infrastructure as PLAYER
	# AGENCY — until now bandits could spawn (run 22), Roan could WARN about
	# them (run 21 `bandits_emergent` warm_world tier), but the player had
	# no verb. This entry closes the loop. Pulls the inverse-pressure
	# direction the bandits faction was authored against:
	#   * Bandits go from EMERGENT (pressure ≥ 0.40) toward HIDDEN (< 0.20).
	#   * `pressure_delta: -0.20` is double Lyra/Roan/Hala/Bram's wolf-quest
	#     deltas because bandits are MEANT to be reduced fast — they are a
	#     "you tamed too much, opportunists arrived" beat, not a recurring
	#     fauna. One clean clear visibly empties the camp.
	#   * `prerequisite_npc_flag: ["Stablemaster Roan", "first_bounty_done"]`
	#     uses the new run-23 quest-resolver field — Roan's wolf bounty must
	#     finish FIRST, so this quest unlocks ONLY after the player has
	#     proved they answer the road. Authoring intent: bandit-clear is
	#     Roan's "second errand," not his opening pitch.
	#   * `npc_flag: ["Stablemaster Roan", "road_warden"]` is Roan's THIRD
	#     personal flag (after `first_bounty_done` and the existing memory
	#     chain). Lights up future Roan tier-2 dialogue (warm_lines tied to
	#     `road_warden` are a Lore Keeper hook for next run; until then the
	#     existing first_bounty_done warm_lines stay correct because tier-2
	#     resolves on the FIRST flag in npc_flags, see NPC.gd::npc_flag tier).
	#   * `world_flag: roan_bandit_road_clear` joins the SEVENTH quest-issued
	#     world flag (after mara/lyra/whisperwood/roan_bounty/hala/bram).
	#     New Achievement `road_warden` (Achievements.gd run 23) reads it.
	# Reward economy: 80 xp + 75 gold matches Maeve's `whisperwood_cleansing`
	# (kill quest, 5 needed) — Roan's "second errand" sits at the same tier
	# as Maeve's "first errand" because by run 23 the player has earned that
	# weight. `needed: 4` matches the bandit-camp population at the highest
	# pressure threshold (≥0.70 → 4 bandits) so the quest is satisfiable in
	# a single visit to the south-road camp once the captain spawn is also
	# included on the same `needed` counter (kill-quest target "bandit"
	# matches both regular bandits AND the captain — see Enemy.gd
	# KIND_TO_FACTION mapping; the captain's kill counts as "bandit" for
	# faction-pressure and quest-progress purposes).
	"bandit_road_for_roan": {
		"giver": "Stablemaster Roan",
		"actor": "Stablemaster Roan",
		"role": "stable",
		"kind": "kill",
		"target": "bandit",
		"needed": 4,
		"title": "Hooded Figures, South Road",
		"text": "Roan asks: take down 4 bandits camped on the south road",
		"xp_reward": 80,
		"gold_reward": 75,
		"motivation": "duty",
		"location": "South Road",
		"urgency": "rising",
		"world_trigger": {"kind": "player_level", "value": 1},
		"prerequisite_npc_flag": ["Stablemaster Roan", "first_bounty_done"],
		"consequence": {
			"faction": "bandits",
			"pressure_delta": -0.20,
			"npc_flag": ["Stablemaster Roan", "road_warden"],
			"world_flag": "roan_bandit_road_clear",
			"toast": "🛡️ The south road is yours. Roan tips his hat.",
		},
	},
	# COMPOUND (run 24 — Builder): Maeve's SECOND quest. The first cross-NPC
	# application of run-23's `prerequisite_npc_flag` schema — Roan's wolf
	# bounty unlocks Roan's bandit-road quest (run 23, intra-NPC chain), which
	# unlocks Maeve's seal quest (this run, INTER-NPC chain). Tests that the
	# resolver scales beyond a single-role chain into village-wide narrative
	# sequencing. Author intent: the captain's seal is a political artifact,
	# not a faction tilt — Maeve takes it onto her hut mantle and the road's
	# name is hers to remember (THEME §7 stewardship; Wardens of the Mark
	# canon: Maeve = the keeping-vigil). Pure flag work — NO faction
	# pressure_delta because:
	#   1. Bandits faction is INVERTED + DERIVED (run-21 `update_bandit_pressure`
	#      is the SOLE writer; any bandits pressure_delta in a quest gets
	#      overwritten by Step 5a). Adding one would be cosmetic noise.
	#   2. Whisperwood goblins / dire wolves are unrelated to the seal —
	#      delta on those would mis-attribute Maeve's memorial gesture to a
	#      faction-warfare beat.
	# So the quest delivers world_flag + npc_flag + toast + xp/gold ONLY —
	# canonically the same shape as a memorial errand. The `seal_keeper`
	# Achievement (Achievements.gd run 24) reads the world_flag.
	#
	# Lights up:
	#   * The `prerequisite_npc_flag` schema's CROSS-NPC scaling proof. Roan
	#     issues the bandit clear; Maeve unlocks AFTER Roan's flag fires.
	#     A single role (`quest`) now chains TWO authored quests for Maeve
	#     (`whisperwood_cleansing` then `captain_seal_for_maeve`) AND honors
	#     a prereq from a DIFFERENT NPC. This is the schema's most ambitious
	#     contract — if it scales here, it scales everywhere.
	#   * Maeve becomes the SECOND multi-quest NPC (Roan was 1st in run 23).
	#   * `maeve_seal_kept` is the EIGHTH quest-issued world flag (after
	#     mara/lyra/whisperwood/roan_bounty/hala/bram/roan_bandit_road).
	#     Future cross-NPC dialogue tiers (Edda/Mara/Bram's open
	#     warm_world_flag slots) can read it without code changes.
	#   * `seal_kept` is Maeve's SECOND personal flag (after `first_quest_done`
	#     from `whisperwood_cleansing`). NPC.gd's tier-2 resolver picks the
	#     FIRST flag in npc_flags (LIFO append on `apply_consequence` Step 3),
	#     so the existing `first_quest_done` warm_lines stay correct until a
	#     future Lore Keeper run authors `seal_kept` warm_lines that outrank
	#     them via authoring order.
	#
	# Reward economy: 90 xp + 50 gold. Higher xp than `wolf_fang_for_roan` (65)
	# or `ears_for_mara` (60) because this is a LATE-GAME quest (gated behind
	# Roan's bandit clear, which itself is gated behind Roan's wolf bounty).
	# Lower gold than `ears_for_mara` (90) because Maeve doesn't pay — she
	# keeps the seal, the gold is purse-money offered by the village. Mid-tier
	# fetch reward, fitting a memorial errand. `needed: 1` because the seal
	# is unique-feel (one captain, one seal — the table's 16% drop weight
	# makes it a 1–2-captain grind on average).
	"captain_seal_for_maeve": {
		"giver": "Elder Maeve",
		"actor": "Elder Maeve",
		"role": "quest",
		"kind": "fetch",
		"item": "captain_seal",
		"needed": 1,
		"title": "The Captain's Seal",
		"text": "Bring the south-road captain's seal to Elder Maeve — she will keep it",
		"xp_reward": 90,
		"gold_reward": 50,
		"motivation": "duty",
		"location": "Briarwood",
		"urgency": "calm",
		"world_trigger": {"kind": "player_level", "value": 1},
		"prerequisite_npc_flag": ["Stablemaster Roan", "road_warden"],
		"consequence": {
			"npc_flag": ["Elder Maeve", "seal_kept"],
			"world_flag": "maeve_seal_kept",
			"toast": "🕯️ Maeve takes the seal. The road's name is hers to remember.",
		},
	},
}


# Returns the role->quest mapping for fast NPC lookup.
#
# COMPOUND (run 23 — Builder): the resolver now honors two new optional
# fields on a QUEST_CATALOG entry, so a single role can issue a SEQUENCE
# of quests gated by player progress without authoring duplicate roles
# or rewriting NPCs:
#   * `prerequisite_npc_flag: ["NPC Name", "flag_name"]` — skip this
#     quest unless the named flag is set on the named NPC. The role's
#     FIRST quest typically has no prereq; later ones cite the prior
#     quest's `consequence.npc_flag` so they unlock in narrative order.
#   * The quest is skipped if its own `consequence.world_flag` is
#     already set on `world_flags` — i.e. once completed, the role
#     hands out the NEXT in the chain, not the same quest twice.
# Iteration order is dict-insertion order, which matches the authored
# QUEST_CATALOG layout — first-defined wins. Quests without these fields
# behave identically to runs 1-22 (the existing wolf/goblin chains have
# no prereq AND set distinct world_flags, so they pass through unchanged).
# Fail-soft: bad/empty NPC names or missing factions just skip the quest
# silently rather than crashing — same contract as the rest of the world
# state readers.
func _quest_for_role(role: String) -> Dictionary:
	for k in QUEST_CATALOG:
		var q: Dictionary = QUEST_CATALOG[k]
		if q.get("role", "") != role:
			continue
		# Skip if the prerequisite NPC flag is missing.
		var prereq: Variant = q.get("prerequisite_npc_flag", null)
		if prereq is Array and prereq.size() >= 2:
			var prereq_npc: String = String(prereq[0])
			var prereq_flag: String = String(prereq[1])
			if not npc_has_flag(prereq_npc, prereq_flag):
				continue
		# Skip if this quest's completion world_flag has already fired.
		var consequence: Dictionary = q.get("consequence", {})
		var done_flag: String = String(consequence.get("world_flag", ""))
		if done_flag != "" and bool(world_flags.get(done_flag, false)):
			continue
		return q
	return {}

# ────────────────────────────────────────────────────────────────────────
# Consequence resolver — single entry point that mutates world state when
# a quest completes. Per QUEST_GRAMMAR.md: faction pressure, world flags,
# npc flags, and an optional toast. This is THE compound multiplier — every
# downstream system (dialogue, spawning, difficulty) reads the state it
# writes.
# ────────────────────────────────────────────────────────────────────────
func apply_consequence(consequence: Dictionary) -> void:
	if consequence.is_empty():
		return
	# Step 1: faction pressure, clamped to [0.0, 1.0].
	var faction_id: String = consequence.get("faction", "")
	if faction_id != "" and factions.has(faction_id):
		var delta: float = float(consequence.get("pressure_delta", 0.0))
		var faction_entry: Dictionary = factions[faction_id]
		var current: float = float(faction_entry.get("pressure", 0.0))
		faction_entry["pressure"] = clamp(current + delta, 0.0, 1.0)
		factions[faction_id] = faction_entry
	# Step 2: world flag, defaults to true.
	var world_flag: String = consequence.get("world_flag", "")
	if world_flag != "":
		world_flags[world_flag] = consequence.get("world_flag_value", true)
	# Step 3: NPC flag, appended not overwritten so dialogue can stack memories.
	var npc_flag: Variant = consequence.get("npc_flag", null)
	if npc_flag is Array and npc_flag.size() >= 2:
		var npc_name: String = String(npc_flag[0])
		var flag_name: String = String(npc_flag[1])
		var existing: Array = npc_flags.get(npc_name, [])
		if not existing.has(flag_name):
			existing.append(flag_name)
		npc_flags[npc_name] = existing
	# Step 4: optional toast.
	var toast: String = consequence.get("toast", "")
	if toast != "":
		_show_toast(toast)
	# Step 5a (run 21 — Builder): re-derive bandit boldness BEFORE
	# achievements evaluate, so any "bandits emergent" achievement / world
	# flag visible to _check_achievements is consistent with the just-
	# committed faction state. Pure read of goblin+wolf pressure → write
	# of bandits pressure + `bandits_emergent` world flag.
	update_bandit_pressure()
	# Step 5b: re-evaluate achievements against the freshly-mutated state.
	# Pure read of factions/world_flags/npc_flags — no further mutation.
	# Owen + Alden see toast on unlock, and the auto-equipper updates the
	# title floating above the player's head.
	_check_achievements()

# COMPOUND (run 21 — Builder): bandit-boldness derivation. Inverse of the
# road-threat scalars: when goblin AND wolf pressure are both LOW, the road
# becomes a tempting target for opportunistic bandits. Formula picks the
# average of the two road-threat factions and inverts with a 0.20 buffer
# (so bandits don't emerge until BOTH factions are noticeably reduced —
# avoids flicker on a single first-quest pressure drop). The 0.40 emergence
# threshold sets `bandits_emergent` world flag for dialogue/quest tiers to
# read; below that the flag clears. Idempotent and read-only against the
# inputs — safe to call from apply_consequence after every faction write.
# At fresh-save (goblin 1.0 + wolf 0.5, avg 0.75 → bandit 0.05) bandits stay
# dormant. After Mara's bounty (goblin 0.85 + wolf 0.5, avg 0.675 → bandit
# 0.125) still dormant. After Mara + Lyra + Roan + Hala + Bram (goblin 0.85,
# wolf ~0.20, avg ~0.525 → bandit 0.275) still dormant. Player needs to
# also dent goblins (whisperwood_cleansing -0.2 puts goblins at 0.65, avg
# 0.425 → bandit 0.375 — close to the 0.4 threshold but not over). After
# the cleansing AND a hypothetical second goblin reducer (-0.1 → 0.55, avg
# 0.375 → bandit 0.425), bandits cross the threshold and become emergent.
# That's exactly the fourth-quest moment the canon expects: the kids have
# tamed the woods, the world responds with a NEW class of threat.
func update_bandit_pressure() -> void:
	if not factions.has("bandits"):
		return
	var goblin_p: float = faction_pressure("whisperwood_goblins")
	var wolf_p: float = faction_pressure("dire_wolves")
	var road_threat_avg: float = (goblin_p + wolf_p) * 0.5
	var raw: float = 1.0 - road_threat_avg - 0.20
	var bandit_p: float = clamp(raw, 0.0, 1.0)
	var entry: Dictionary = factions["bandits"]
	entry["pressure"] = bandit_p
	factions["bandits"] = entry
	# `bandits_emergent` is a single world flag — set it when the derived
	# pressure crosses the 0.4 boldness threshold, clear it otherwise. NPCs
	# (Roan first; future runs add Maeve/Mara) read this flag in their
	# warm_world_flag tier. Goal: dialogue PRECEDES enemy spawn — players
	# hear about the emerging threat before they see it on the road.
	if bandit_p >= 0.40:
		world_flags["bandits_emergent"] = true
	elif world_flags.has("bandits_emergent"):
		world_flags.erase("bandits_emergent")

# Read accessors used by dialogue/spawning/difficulty (queryable schema)
func faction_pressure(faction_id: String) -> float:
	if not factions.has(faction_id):
		return 0.0
	var entry: Dictionary = factions[faction_id]
	return float(entry.get("pressure", 0.0))

func has_world_flag(name: String) -> bool:
	return world_flags.has(name) and bool(world_flags[name])

func npc_has_flag(npc_name: String, flag_name: String) -> bool:
	var arr: Array = npc_flags.get(npc_name, [])
	return arr.has(flag_name)

# ────────────────────────────────────────────────────────────────────────
# NPC visit memory (run 16 — Builder)
# ────────────────────────────────────────────────────────────────────────
# `record_npc_visit` is the ONLY public mutator of `npc_memory`. NPC.gd
# calls it at the top of `_on_interact` so the visit count INCLUDES the
# triggering call (which matters for the warmed_memory_visits_min predicate
# downstream — a threshold of 3 fires on the third hello, not the fourth).
# Idempotency: repeated calls with the same name in the same frame each
# count as a visit; the InteractArea + KEY_E debounce in NPC.gd is what
# prevents accidental machine-gun increments.
func record_npc_visit(npc_name: String) -> void:
	if npc_name == "":
		return
	var entry: Dictionary = npc_memory.get(npc_name, {
		"visits": 0, "first_day": -1, "last_day": -1,
		"first_tod": -1.0, "last_tod": -1.0,
	})
	entry["visits"] = int(entry.get("visits", 0)) + 1
	if int(entry.get("first_day", -1)) < 0:
		entry["first_day"] = world_day
		entry["first_tod"] = time_of_day
	entry["last_day"] = world_day
	entry["last_tod"] = time_of_day
	npc_memory[npc_name] = entry

# Read accessors — fail-soft for never-met NPCs (return 0 / -1).
func npc_visits(npc_name: String) -> int:
	var entry: Dictionary = npc_memory.get(npc_name, {})
	return int(entry.get("visits", 0))

func npc_first_visit_day(npc_name: String) -> int:
	var entry: Dictionary = npc_memory.get(npc_name, {})
	return int(entry.get("first_day", -1))

func npc_last_visit_day(npc_name: String) -> int:
	var entry: Dictionary = npc_memory.get(npc_name, {})
	return int(entry.get("last_day", -1))

# Days since last visit. Returns -1 if the NPC has never been visited so
# the caller can distinguish "never met" from "talked to today" (which
# returns 0). Co-fires with warmed_memory_visits_min in NPC.gd: a future
# tier could fire on "you've been gone 3+ days" without changing this API.
func npc_days_since_last_visit(npc_name: String) -> int:
	var last: int = npc_last_visit_day(npc_name)
	if last < 0:
		return -1
	return max(0, world_day - last)

# Run 20 (Builder) — `mark_npc_seen` is the SOLE writer of `npc_seen`.
# Called from `show_dialogue` AFTER the dialogue panel has been updated, so
# DialogueDB.choose_line (which runs BEFORE show_dialogue, inside NPC.gd's
# _on_interact) sees the OLD npc_seen state — i.e. on the very first hello
# the entry is still missing/false and the JSON `stranger` key fires.
# Idempotent: re-marking an already-seen NPC is a no-op (Dictionary
# overwrite, no event side effects).
func mark_npc_seen(npc_name: String) -> void:
	if npc_name == "":
		return
	npc_seen[npc_name] = true

# Symmetric read accessor for the rest of the engine. Returns true the
# FIRST time it's called for a never-met NPC — quest predicates and
# achievement triggers should consume this rather than reaching into the
# raw dict so future schema changes (e.g. tracking *which day* you first
# met them, or *what tier* they were warmed at on first contact) can
# extend the entry from `bool` to `Dictionary` without breaking callers.
func is_stranger(npc_name: String) -> bool:
	if npc_name == "":
		return true
	return not bool(npc_seen.get(npc_name, false))

# Direct world-flag write — sister to apply_consequence's flag step but with
# no faction / npc / toast side-effects. Used when an emergent runtime event
# (e.g. Boss.gd's intro sting firing for the first time, Boss._die landing the
# kill) needs to mark a world fact that downstream READERS consume — today
# DialogueDB's `boss_alive` / `boss_slain` / future seasonal calendar keys.
# Re-runs `_check_achievements()` so any future "Met the Warlord" or
# "Warlord Slain" achievement keyed on world_flags lights up automatically
# the moment the flag flips. Same fail-soft pattern as the rest of this
# class — value defaults to true so the common-case write is one token shorter
# at the callsite (`world.set_world_flag("seen_warlord")`).
func set_world_flag(name: String, value: Variant = true) -> void:
	if name == "":
		return
	world_flags[name] = value
	_check_achievements()

# Runtime item registry helpers ────────────────────────────────────────────
func register_runtime_item(item: Dictionary) -> String:
	if not item.has("runtime_id"):
		return ""
	_runtime_items[item.runtime_id] = item
	return item.runtime_id

func get_runtime_item(id: String) -> Dictionary:
	return _runtime_items.get(id, {})

# ────────────────────────────────────────────────────────────────────────
# Achievements & Title — pure read of world state; on diff, toast and
# auto-equip the highest-priority unlocked title. Safe to call any time;
# fail-soft if `Achievements.gd` ever fails to load (returns no unlocks,
# no crash).
# ────────────────────────────────────────────────────────────────────────
func _check_achievements() -> void:
	var unlocked_now: Array = Achievements.evaluate(self)
	# Diff against `unlocked_achievements` to find newly-unlocked IDs.
	var newly_unlocked: Array[String] = []
	for id_variant in unlocked_now:
		var id: String = String(id_variant)
		if not unlocked_achievements.has(id):
			unlocked_achievements[id] = true
			newly_unlocked.append(id)
	# Stash the most-recently-unlocked id so the AchievementsPanel can
	# pulse the matching card on next open. Highest title_priority wins
	# when multiple unlock on the same tick — lines up with which entry
	# the player most likely just saw the title-equip toast for.
	if newly_unlocked.size() > 0:
		var pulse_pick: String = newly_unlocked[0]
		var pulse_pri: int = int(Achievements.ACHIEVEMENTS.get(pulse_pick, {}).get("title_priority", 0))
		for nid in newly_unlocked:
			var p: int = int(Achievements.ACHIEVEMENTS.get(nid, {}).get("title_priority", 0))
			if p > pulse_pri:
				pulse_pri = p
				pulse_pick = nid
		_last_achievement_unlocked = pulse_pick
	# Toast each newly-unlocked achievement with its icon + name + desc.
	# Spaces them out by 0.6s if multiple unlock at once so kids can read
	# each one (rare but happens at run-end "warden" trip).
	var stagger: float = 0.0
	for id in newly_unlocked:
		var entry: Dictionary = Achievements.ACHIEVEMENTS.get(id, {})
		if entry.is_empty():
			continue
		var icon: String = String(entry.get("icon", "🏆"))
		var aname: String = String(entry.get("name", id))
		var adesc: String = String(entry.get("desc", ""))
		var msg: String = "🏆 %s %s — %s" % [icon, aname, adesc]
		if stagger <= 0.0:
			_show_toast(msg)
		else:
			# Defer subsequent toasts so they do not stomp each other.
			get_tree().create_timer(stagger).timeout.connect(_show_toast.bind(msg))
		stagger += 0.6
		# Renown award — title_priority doubles as the renown grant. Tier-1
		# starter quest = 10, Wolf-Friend = 30, Goblin-Bane = 40, Trusted = 50,
		# Warden of Eldoria = 100. Reaching Warden tips the player past the
		# default `high_renown` threshold (100) on the same tick the title
		# equips, lighting up four authored JSON lines (Maeve, Edda, Bram,
		# Lyra) the next time those NPCs are spoken to. Pure compound on the
		# achievement chain — no new tuning surface.
		var grant: int = int(entry.get("title_priority", 0))
		if grant > 0:
			# Defer slightly so the renown toast lands AFTER the achievement
			# toast (kid-readability — they parse the achievement first, then
			# see the number rise).
			var src_label: String = "%s %s" % [icon, aname]
			get_tree().create_timer(stagger).timeout.connect(
				gain_renown.bind(grant, src_label))
	# Auto-equip the highest-priority unlocked title. Stable across runs.
	var new_title: String = Achievements.best_title(unlocked_achievements.keys())
	if new_title != current_title:
		current_title = new_title
		_apply_title_to_player(new_title)
		# A separate, smaller toast for title changes so they read as a
		# distinct event from achievement unlocks (which often fire on the
		# same frame).
		if new_title != "":
			get_tree().create_timer(0.3).timeout.connect(
				_show_toast.bind("✨ Title equipped: %s" % new_title))

# Read-only external accessor — UI panels and future autoload achievements
# panel can call this without poking the dict directly.
func has_achievement(id: String) -> bool:
	return unlocked_achievements.has(id)

# Pushes the current title down to the Player node, if present and ready.
# Player.gd builds a Label3D nameplate at _ready; this just calls its
# `set_title` method. Safe before player exists (no-op).
func _apply_title_to_player(t: String) -> void:
	var player := get_node_or_null("Player")
	if player and player.has_method("set_title"):
		player.set_title(t)

# ────────────────────────────────────────────────────────────────────────
# Renown — public mutator. Adds `amount` to `player_renown`, refreshes the
# HUD, and toasts the gain so Owen + Alden see the number rising. `source`
# names the contributing event ("🐺 Pack Thinner") so the toast reads
# "✨ +30 Renown — 🐺 Pack Thinner". Negative grants are clamped to 0
# (renown never goes below zero — there is no infamy track in this realm).
#
# Called from:
#   * `_check_achievements()` — automatic credit on each unlock (deferred
#     so the achievement toast paints first).
#   * Future quest hooks — any `apply_consequence(...)` payload could add a
#     `"renown": int` field that calls this. Not wired yet (achievements
#     are the only renown source today), but the API is shaped for it so
#     QUEST_GRAMMAR can extend without touching this class.
#
# THEME §12 motion-and-life: the renown HUD label briefly pulses scale on
# every gain (1.0 → 1.18 → 1.0 over 0.45s) so the eye catches it without
# needing to read text. Same scale-punch grammar as damage numbers, in the
# same burnt-gold palette as Gold (§3) and the title nameplate.
func gain_renown(amount: int, source: String) -> void:
	if amount == 0:
		return
	var before: int = player_renown
	player_renown = max(0, player_renown + amount)
	var delta: int = player_renown - before
	if delta == 0:
		return
	if renown_label:
		renown_label.text = "Renown: %d" % player_renown
		# Brief scale-punch — same grammar as damage numbers (DamageNumber.gd).
		# Pivot center so the label grows symmetrically.
		renown_label.pivot_offset = renown_label.size * 0.5
		var pulse: Tween = create_tween()
		pulse.tween_property(renown_label, "scale", Vector2(1.18, 1.18), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_property(renown_label, "scale", Vector2(1.0, 1.0), 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if delta > 0:
		_show_toast("✨ +%d Renown — %s" % [delta, source])
	# Re-evaluate achievements — future renown-gated achievements (e.g.
	# "Renowned" at 100, "Legend of Eldoria" at 250) would unlock the moment
	# the threshold is crossed without needing a separate tick. Today's
	# Achievements.gd has no renown predicate but the call is cheap and the
	# pattern matches every other state mutator in this class.
	_check_achievements()

# Pure recomputation from achievement state — idempotent. Used at boot once
# `unlocked_achievements` is populated (today always empty on fresh boot;
# future save/load fills it pre-_ready). Keeps the renown integer a strict
# function of the achievement set so there's no drift between runs.
func _recompute_renown_from_achievements() -> void:
	var total: int = 0
	for id in unlocked_achievements.keys():
		var entry: Dictionary = Achievements.ACHIEVEMENTS.get(id, {})
		total += int(entry.get("title_priority", 0))
	player_renown = total
	if renown_label:
		renown_label.text = "Renown: %d" % player_renown

func _ready() -> void:
	add_to_group("world")
	add_to_group("audio_listeners")
	# UITheme self-test — logs whether the parchment/iron/wood frames are
	# importable. Doesn't throw on miss; UITheme falls back to bare panels.
	var _ut: Array = UITheme.self_test()
	print("[UITheme] ", _ut[1])
	if dialogue_panel: dialogue_panel.visible = false
	if death_overlay: death_overlay.visible = false
	if quest_panel: quest_panel.visible = false
	if dialogue_close_btn: dialogue_close_btn.pressed.connect(close_dialogue)
	# Hook up player stats + inventory listeners
	var player := get_node_or_null("Player")
	if player:
		player.stats_changed.connect(_refresh_hud)
		if player.inventory:
			player.inventory.inventory_changed.connect(_refresh_inventory_ui)
			player.inventory.equipment_changed.connect(_refresh_inventory_ui)
		_refresh_hud()
	_setup_dialogue_actions()
	# Start village ambient theme
	call_deferred("play_music", "village")
	# Bootstrap achievement check — empty on a fresh world, but means future
	# persistence work (saving factions / flags) "just works" without a
	# special-case load path. Also pushes any pre-loaded title onto the
	# player nameplate after a single frame, once Player._ready ran.
	call_deferred("_check_achievements")
	# Builder run 14 — Minimap + WorldMap. Created here (not in Main.tscn)
	# so the system is purely script-spawned — designers can wipe the scene
	# and the HUD comes back. Both nodes are added to UI/HUD so they layer
	# above the gameplay 3D viewport but BELOW the dialogue/inventory panels.
	call_deferred("_build_map_system")

func _build_map_system() -> void:
	# Idempotent — safe if Main.tscn ever gets a hand-placed Minimap node.
	if minimap == null:
		minimap = Minimap.new()
		minimap.name = "Minimap"
		if hud != null:
			hud.add_child(minimap)
		else:
			# Fallback: attach to the UI CanvasLayer if HUD is missing
			var ui_layer: Node = get_node_or_null("UI")
			if ui_layer != null:
				ui_layer.add_child(minimap)
	if world_map == null:
		world_map = WorldMap.new()
		world_map.name = "WorldMap"
		var ui_layer2: Node = get_node_or_null("UI")
		if ui_layer2 != null:
			ui_layer2.add_child(world_map)
		world_map.bind_minimap(minimap)

func toggle_world_map() -> void:
	# Player.gd KEY_N → call_group("world", "toggle_world_map").
	# Idempotent (open → close → open). Mutually exclusive with the
	# inventory + achievements panels — opening the map closes them.
	if world_map == null:
		_build_map_system()
	if world_map == null:
		return
	if inventory_panel != null and inventory_panel.visible:
		inventory_panel.visible = false
	if achievements_panel != null and achievements_panel.visible:
		achievements_panel.visible = false
	world_map.toggle()

func ping_minimap(world_pos: Vector3, color: Color = Color(0.396, 0.875, 0.898)) -> void:
	# Public hook so quest scripts can drop a hint ring on the minimap.
	if minimap == null:
		return
	minimap.ping(world_pos, color)

func _setup_dialogue_actions() -> void:
	if not dialogue_panel: return
	var vbox := dialogue_panel.get_node_or_null("MarginContainer/VBox")
	if not vbox: return
	if not vbox.has_node("Actions"):
		var actions := HBoxContainer.new()
		actions.name = "Actions"
		actions.alignment = BoxContainer.ALIGNMENT_END
		var accept := Button.new()
		accept.name = "AcceptQuestBtn"
		accept.text = "Accept Quest"
		accept.visible = false
		accept.pressed.connect(_on_accept_quest)
		actions.add_child(accept)
		var turn_in := Button.new()
		turn_in.name = "TurnInQuestBtn"
		turn_in.text = "Turn In Quest"
		turn_in.visible = false
		turn_in.pressed.connect(_on_turn_in_quest)
		actions.add_child(turn_in)
		# COMPOUND (run 12): Smith Edda forge button. Visible only on role==smithy
		# (set in show_dialogue → _refresh_reforge_button). Disabled with a
		# reason-string label when player has no weapon, is at max tier, or
		# lacks the Crystal Shard cost — the button itself teaches the system.
		var reforge := Button.new()
		reforge.name = "ReforgeBtn"
		reforge.text = "🔨 Reforge"
		reforge.visible = false
		reforge.pressed.connect(_on_reforge_pressed)
		actions.add_child(reforge)
		vbox.add_child(actions)
		var close_btn := vbox.get_node_or_null("CloseBtn")
		if close_btn:
			vbox.move_child(close_btn, vbox.get_child_count() - 1)


var _zone_check_timer: float = 0.0

func _process(delta: float) -> void:
	# Zone music check (every 1.5 sec)
	_zone_check_timer -= delta
	if _zone_check_timer <= 0:
		_zone_check_timer = 1.5
		_check_zone_music()
	# Day/night — full cycle in ~6 minutes
	time_of_day = fposmod(time_of_day + delta * (24.0 / 360.0), 24.0)
	# Run 16 (Builder): increment world_day when time_of_day wraps. The
	# fposmod above means a forward step of `delta * 24/360` (~0.067 sec
	# of in-game time per real second) NEVER overshoots a full day in one
	# tick, so a strict "prev was big, current is small" wrap detector is
	# correct. world_day feeds npc_memory's first_day/last_day; nothing
	# else reads it yet, which is fine — the field exists so future
	# season/festival predicates (DialogueDB has a "festival" key already)
	# have a single integer to key off.
	if _prev_tod > 22.0 and time_of_day < 2.0:
		world_day += 1
	_prev_tod = time_of_day
	if sun:
		var elev := sin((time_of_day - 6.0) * PI / 12.0)
		var azim := (time_of_day - 6.0) / 24.0 * TAU
		sun.rotation = Vector3(-elev * 0.9, azim, 0)
		sun.light_energy = clamp(0.2 + elev * 1.6, 0.05, 1.9)
		# REFINE: visual — outdoor — smooth tri-band sun color instead of the old
		# three-state if/elif "snap". `dusk_w` peaks near horizon (sunrise + sunset),
		# `night_w` peaks below horizon, `day_w` is the remainder. The old code
		# popped between three discrete colors as elev crossed 0.18 / -0.05; the
		# blended weights produce a continuous sunset-orange→day-cream→twilight-blue
		# arc. THEME §3: sunset gold/wine dominant with cool tones reserved for
		# night — the LERP keeps us in palette through the transition instead of
		# punching through a "wrong" intermediate hue.
		var dusk_w: float = clamp(1.0 - abs(elev) / 0.30, 0.0, 1.0)        # peaks at horizon
		var night_w: float = clamp(-elev / 0.30, 0.0, 1.0)                 # below horizon
		var day_w: float = clamp(1.0 - dusk_w - night_w, 0.0, 1.0)
		var dusk_color := Color(1.00, 0.62, 0.30)   # sunset gold/orange (THEME §3 burnt orange)
		var day_color := Color(1.00, 0.95, 0.78)    # warm cream daylight
		var night_color := Color(0.30, 0.45, 0.80)  # cool stone-blue twilight (THEME §3 stone grey-blue accent)
		sun.light_color = dusk_color * dusk_w + day_color * day_w + night_color * night_w
		# REFINE: visual — outdoor — gentle dusk dimmer. Pure geometric energy was
		# fine for noon but still felt "lit" at sunset; multiplying by 0.92+0.08*day_w
		# at the horizon shaves ~8% off the sun output during the warm-color band so
		# the painterly sky panorama (eldoria_sunset_sky_2k) reads as the dominant
		# light source, not the directional lamp. Effect at noon: zero (day_w≈1).
		sun.light_energy *= 0.92 + 0.08 * day_w
	# REFINE: visual — outdoor — moon-fill breathes with the cycle. Main.tscn
	# parks MoonFill at a flat 0.50 energy 24/7 which produced a "lit by 2 suns"
	# look at noon. Tying it to night_w lets the cool blue fill take over when
	# the warm sun is below horizon (THEME §3: cool tones reserved for night).
	if moon_fill:
		var mw: float = clamp(-(sin((time_of_day - 6.0) * PI / 12.0)) / 0.30, 0.0, 1.0)
		moon_fill.light_energy = 0.10 + mw * 0.55     # 0.10 day → 0.65 deep night
	# REFINE: visual — outdoor — atmospheric breathing. Density and glow drift
	# with elevation so dawn/dusk gets a slightly heavier painterly haze (god-ray
	# friendly), midday is crisp, and night is moody-blue. THEME §1 painterly +
	# §11 BotW-style watercolor mood. Conservative deltas (~±25%) so no scene
	# disappears into pea soup; the value bands stay inside the Main.tscn baseline.
	if world_env and world_env.environment:
		var e := world_env.environment
		var elev2: float = sin((time_of_day - 6.0) * PI / 12.0)
		var dusk_w2: float = clamp(1.0 - abs(elev2) / 0.30, 0.0, 1.0)
		var night_w2: float = clamp(-elev2 / 0.30, 0.0, 1.0)
		# Fog: thicker at horizon (dusk haze), thinner at midday, slightly thicker
		# at night for distance-blue. Baseline in tscn = 0.0032.
		e.fog_density = 0.0028 + dusk_w2 * 0.0014 + night_w2 * 0.0006
		# Volumetric fog energy — pop the warm emission glow at sunset, fade at noon
		# (so direct sun reads cleanly) and at deep night (so it doesn’t over-warm
		# a cool scene). Baseline tscn emission_energy = 0.16.
		e.volumetric_fog_emission_energy = 0.10 + dusk_w2 * 0.18

# ════════════════════════════════════════════════════════════════════════
# Dialogue
# ════════════════════════════════════════════════════════════════════════
func show_dialogue(speaker: String, text: String, role: String = "") -> void:
	if not dialogue_panel: return
	dialogue_name_label.text = speaker
	dialogue_text_label.text = "[i]\"%s\"[/i]" % text
	_current_npc_role = role
	_current_npc_name = speaker
	var accept_btn = dialogue_panel.get_node_or_null("MarginContainer/VBox/Actions/AcceptQuestBtn")
	var turn_in_btn = dialogue_panel.get_node_or_null("MarginContainer/VBox/Actions/TurnInQuestBtn")
	var player = get_node_or_null("Player")
	var has_active_quest = player and player.active_quest.size() > 0
	var npc_quest = _quest_for_role(role)
	var npc_offers_quest = not npc_quest.is_empty()
	# Show accept if this NPC offers a quest and we don't have one
	if accept_btn:
		accept_btn.visible = (npc_offers_quest and not has_active_quest)
	# Show turn-in if active quest's giver matches this NPC and it's ready
	if turn_in_btn:
		var ready_to_turn_in = false
		if has_active_quest:
			var q = player.active_quest
			if q.get("giver", "") == speaker and player.is_quest_ready_to_turn_in():
				ready_to_turn_in = true
		turn_in_btn.visible = ready_to_turn_in
	# COMPOUND (run 12): Smith Edda forge button — only visible when role=="smithy".
	# `_refresh_reforge_button` handles enabled/disabled + label string from
	# the player's current weapon/shard state, so the player learns the cost
	# from the button itself without needing a separate UI panel.
	var reforge_btn = dialogue_panel.get_node_or_null("MarginContainer/VBox/Actions/ReforgeBtn")
	if reforge_btn:
		_refresh_reforge_button(reforge_btn, role, player)
	dialogue_panel.visible = true
	# COMPOUND (run 20 — Builder): mark this NPC seen AFTER the panel is
	# populated. show_dialogue is called from NPC.gd::_on_interact AFTER
	# DialogueDB.choose_line has already resolved the line, so the `stranger`
	# predicate in DialogueDB sees the OLD npc_seen state on the first hello
	# and the NEW state on every subsequent hello. Pure post-condition: the
	# moment a player has ACTUALLY heard a line from this NPC, they are no
	# longer a stranger. Fail-soft on bare/empty speaker names.
	mark_npc_seen(speaker)

func close_dialogue() -> void:
	if dialogue_panel:
		dialogue_panel.visible = false

# ════════════════════════════════════════════════════════════════════════
# Quests
# ════════════════════════════════════════════════════════════════════════
func _on_accept_quest() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	var npc_quest = _quest_for_role(_current_npc_role)
	if npc_quest.is_empty(): return
	player.accept_quest(npc_quest)
	play_sfx("quest_accept")
	close_dialogue()


func _on_turn_in_quest() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	var quest_title: String = player.active_quest.get("title", "Quest")
	var gold_r: int = int(player.active_quest.get("gold_reward", 0))
	var xp_r: int = int(player.active_quest.get("xp_reward", 0))
	# Capture consequence BEFORE complete_quest_if_done() wipes active_quest.
	var consequence_dict: Dictionary = player.active_quest.get("consequence", {})
	if player.complete_quest_if_done():
		_show_toast("✨ %s complete! +%d gold, +%d XP" % [quest_title, gold_r, xp_r])
		quest_panel.visible = false
		# Apply downstream world-state mutations (factions, flags, NPC memory)
		apply_consequence(consequence_dict)
	close_dialogue()

# ════════════════════════════════════════════════════════════════════════
# Smith Edda Forge — reforge UI (run 12)
# ════════════════════════════════════════════════════════════════════════
# Crystal Caves drop crystal_shards; Smith Edda is the sink. Pressing the
# 🔨 Reforge button in her dialogue panel calls
# `Inventory.attempt_reforge(world)` which validates the shard cost, bumps
# `forge_tiers[weapon_id]` by one, and sets the world flag
# `first_reforge_done` (which lights up the new "first_forge" achievement
# in Achievements.gd → +25 renown via the run-11 ladder).
#
# THEME §12 motion-and-life: the toast (handled by `_show_toast`) already
# fades in/out; the existing `play_sfx("sword_hit")` + the renown-label
# scale-pulse from run 11 fire on the same tick (achievement → renown
# chain), so the forge moment lands as a layered feedback beat without any
# new tween code.
#
# The button is its own self-teaching label. When the player can't afford
# the cost, it reads "🔨 Reforge Iron Sword → +1  (need 5 💎, have 2)" so
# Alden sees the gap rather than getting a silent no-op. When at max tier,
# it reads "🔨 Iron Sword +3 already — peerless work" so Owen knows the
# upgrade ladder ends.

func _refresh_reforge_button(btn: Button, role: String, player) -> void:
	# Smith Edda only. Visible whenever we're talking to her so the player
	# learns the anvil exists; disabled with a reason string when the action
	# can't proceed.
	btn.visible = (role == "smithy")
	btn.disabled = true
	if role != "smithy":
		return
	if not (player and player.inventory):
		btn.text = "🔨 Reforge — (anvil cooling)"
		return
	var inv = player.inventory
	var weapon_id: String = inv.equipped_weapon_id()
	if weapon_id == "":
		btn.text = "🔨 Reforge — equip a weapon first"
		return
	var tier: int = inv.weapon_forge_tier(weapon_id)
	var bn: String = String(Items.get_item(weapon_id).get("name", weapon_id))
	if tier >= Items.REFORGE_MAX_TIER:
		btn.text = "🔨 %s already — peerless work" % Items.forged_name(weapon_id, tier)
		return
	var cost: int = Items.forge_next_tier_cost(tier)
	var shards: int = inv.count_item("crystal_shard")
	if shards < cost:
		btn.text = "🔨 Reforge %s → +%d  (need %d 💎, have %d)" % [bn, tier + 1, cost, shards]
		return
	btn.text = "🔨 Reforge %s → +%d  (%d 💎)" % [bn, tier + 1, cost]
	btn.disabled = false

func _on_reforge_pressed() -> void:
	var player := get_node_or_null("Player")
	if not (player and player.inventory):
		return
	var result: Dictionary = player.inventory.attempt_reforge(self)
	if result.get("ok", false):
		var weapon_id: String = String(result.get("weapon_id", ""))
		var new_tier: int = int(result.get("new_tier", 0))
		var nm: String = Items.forged_name(weapon_id, new_tier)
		var dmg: int = int(result.get("new_damage", 0))
		_show_toast("🔨 Edda hammers the steel — %s sings (%d dmg)" % [nm, dmg])
		play_sfx("sword_hit")
		# Refresh the dialogue button immediately so the new state is visible
		# without re-talking to Edda. _refresh_reforge_button is pure read of
		# the inv state we just mutated.
		var reforge_btn = null
		if dialogue_panel:
			reforge_btn = dialogue_panel.get_node_or_null("MarginContainer/VBox/Actions/ReforgeBtn")
		if reforge_btn:
			_refresh_reforge_button(reforge_btn, _current_npc_role, player)
		# Damage HUD readout (player.stats_changed → _refresh_hud).
		player.stats_changed.emit()
	else:
		var reason: String = String(result.get("reason", "unknown"))
		match reason:
			"no_weapon":
				_show_toast("🔨 Equip a weapon before bringing it to the anvil.")
			"max_tier":
				_show_toast("🔨 Already +%d — Edda nods. \"This is as far as steel goes.\"" % int(result.get("tier", 3)))
			"not_enough_shards":
				_show_toast("🔨 Need %d Crystal Shards (you have %d)." % [int(result.get("need", 0)), int(result.get("have", 0))])
			_:
				_show_toast("🔨 The anvil rings hollow.")

func on_quest_accepted(quest: Dictionary) -> void:
	if quest_panel:
		quest_panel.visible = true
	_update_quest_label()
	_show_toast("📜 New quest: %s" % quest.get("title", ""))

func on_quest_progress(_quest: Dictionary) -> void:
	_update_quest_label()

func _update_quest_label() -> void:
	var player := get_node_or_null("Player")
	if not player or player.active_quest.size() == 0:
		if quest_panel: quest_panel.visible = false
		return
	var q = player.active_quest
	var done: bool = player.is_quest_ready_to_turn_in()
	var status = " ✓ READY TO TURN IN" if done else ""
	var progress_text = ""
	match q.get("kind", "kill"):
		"kill":
			progress_text = "%d/%d" % [q.get("killed", 0), q.get("needed", 0)]
		"fetch":
			var have: int = 0
			if player.inventory:
				have = player.inventory.count_item(q.get("item", ""))
			progress_text = "%d/%d" % [have, q.get("needed", 0)]
	quest_label.text = "%s\n%s — %s%s" % [q.get("title", ""), q.get("text", ""), progress_text, status]

# ════════════════════════════════════════════════════════════════════════
# HUD
# ════════════════════════════════════════════════════════════════════════
func _refresh_hud() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	var hp_extra = 0; var mp_extra = 0
	if player.inventory:
		hp_extra = player.inventory.bonus_hp()
		mp_extra = player.inventory.bonus_mp()
	if hp_bar:
		hp_bar.max_value = player.max_hp + hp_extra
		hp_bar.value = player.hp
	if mp_bar:
		mp_bar.max_value = player.max_mp + mp_extra
		mp_bar.value = player.mp
	if xp_bar:
		xp_bar.max_value = player.xp_for_next_level()
		xp_bar.value = player.xp
	if level_label:
		level_label.text = "Lv " + str(player.level)
	if gold_label:
		gold_label.text = "Gold: %d" % player.gold
	if renown_label:
		renown_label.text = "Renown: %d" % player_renown
	_update_quest_label()

# ════════════════════════════════════════════════════════════════════════
# Death overlay
# ════════════════════════════════════════════════════════════════════════
func show_death_overlay() -> void:
	if death_overlay:
		death_overlay.visible = true
	if death_label:
		death_label.text = "You have fallen.\nReturning to Briarwood…"

func hide_death_overlay() -> void:
	if death_overlay:
		death_overlay.visible = false


# ════════════════════════════════════════════════════════════════════════
# Audio (music + SFX)
# ════════════════════════════════════════════════════════════════════════
const MUSIC_TRACKS = {
	"village":     "res://assets/audio/music/village_theme.wav",
	"whisperwood": "res://assets/audio/music/whisperwood_theme.wav",
	"battle":      "res://assets/audio/music/battle_theme.wav",
}
const SFX = {
	"sword_swing":   "res://assets/audio/sfx/sword_swing.wav",
	"sword_hit":     "res://assets/audio/sfx/sword_hit.wav",
	"damage_taken":  "res://assets/audio/sfx/damage_taken.wav",
	"enemy_death":   "res://assets/audio/sfx/enemy_death.wav",
	"loot_pickup":   "res://assets/audio/sfx/loot_pickup.wav",
	"level_up":      "res://assets/audio/sfx/level_up.wav",
	"quest_accept":  "res://assets/audio/sfx/quest_accept.wav",
	"chest_open":    "res://assets/audio/sfx/chest_open.wav",
	"player_death":  "res://assets/audio/sfx/player_death.wav",
	"boss_intro":    "res://assets/audio/sfx/boss_intro.wav",
}
var _current_music: String = ""

func play_music(zone: String) -> void:
	var path = MUSIC_TRACKS.get(zone, "")
	if path == "" or _current_music == zone:
		return
	if not ResourceLoader.exists(path):
		return
	var mp = get_node_or_null("Audio/MusicPlayer")
	if not mp: return
	var stream = load(path)
	mp.stream = stream
	if stream and "loop" in stream:
		stream.loop = true
	mp.play()
	_current_music = zone

func play_sfx(name: String) -> void:
	var path = SFX.get(name, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var sp = get_node_or_null("Audio/SFXPlayer")
	if not sp: return
	sp.stream = load(path)
	sp.play()

# Auto-switch zone music based on player location
func _check_zone_music() -> void:
	var player = get_node_or_null("Player")
	if not player: return
	var dist = player.global_position.length()
	# In a boss fight? Check for any active boss in range
	for boss in get_tree().get_nodes_in_group("bosses"):
		if boss.has_method("get") and boss.global_position.distance_to(player.global_position) < 30.0:
			play_music("battle")
			return
	if dist > 22.0:
		play_music("whisperwood")
	else:
		play_music("village")

# ════════════════════════════════════════════════════════════════════════
# Generic toast
# ════════════════════════════════════════════════════════════════════════
var _toast: Label = null
func _show_toast(text: String) -> void:
	# Theme via UITheme.make_toast_label (palette §3 gold, ink-outline,
	# OL_TOAST=6). Behavior unchanged: 2.0s hold, 1.0s fade, queue_free.
	if _toast and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = UITheme.make_toast_label(text)
	$UI.add_child(_toast)
	var t: Tween = create_tween()
	t.tween_interval(2.0)
	t.tween_property(_toast, "modulate:a", 0.0, 1.0)
	t.tween_callback(_toast.queue_free)

# ════════════════════════════════════════════════════════════════════════
# Inventory & Paperdoll UI — built lazily on first toggle.
# Uses click-to-equip semantics (kid-friendly). Keys: I = toggle.
# ════════════════════════════════════════════════════════════════════════
const SLOT_LAYOUT := [
	{"slot":"weapon",  "label":"⚔ Weapon",  "x":24,  "y":36},
	{"slot":"armor",   "label":"🛡 Armor",   "x":24,  "y":120},
	{"slot":"trinket", "label":"💍 Trinket", "x":24,  "y":204},
]

# ─── PX panic-key helper — closes every UI panel that could be eating input ───
# Called by Player.gd when Backspace / F1 / F2 / ']' is pressed.
# Safe to call repeatedly; missing nodes are skipped.
func _force_close_all_panels() -> void:
	if dialogue_panel and is_instance_valid(dialogue_panel):
		dialogue_panel.visible = false
	if inventory_panel and is_instance_valid(inventory_panel) and inventory_panel.visible:
		inventory_panel.visible = false
	for m in get_tree().get_nodes_in_group("world_maps"):
		if is_instance_valid(m):
			m.visible = false
	var ach := get_node_or_null("UI/AchievementsPanel")
	if ach and ach.visible:
		ach.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("[World] _force_close_all_panels: all UI panels hidden")

func toggle_inventory() -> void:
	if inventory_panel == null:
		_build_inventory_ui()
	inventory_panel.visible = not inventory_panel.visible
	# Free the mouse when the inventory is open so the player can click
	if inventory_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_inventory_ui()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # camera uses right-drag, so keep visible
		if inv_tooltip and is_instance_valid(inv_tooltip):
			inv_tooltip.visible = false


func _build_inventory_ui() -> void:
	# Root panel — centered, 720 x 460
	inventory_panel = Panel.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.anchor_left = 0.5; inventory_panel.anchor_right = 0.5
	inventory_panel.anchor_top = 0.5;  inventory_panel.anchor_bottom = 0.5
	inventory_panel.offset_left = -360
	inventory_panel.offset_right = 360
	inventory_panel.offset_top = -240
	inventory_panel.offset_bottom = 240
	inventory_panel.visible = false
	$UI.add_child(inventory_panel)
	# THEME §3 parchment 9-slice background — replaces default Godot grey
	UITheme.style_panel_parchment(inventory_panel)

	# Title bar
	var title := Label.new()
	title.text = "🎒  Inventory & Equipment"
	UITheme.style_title_label(title)
	title.position = Vector2(20, 8)
	title.size = Vector2(700, 32)
	inventory_panel.add_child(title)

	# Close button
	var close := Button.new()
	close.text = "✕"
	close.position = Vector2(680, 8)
	close.size = Vector2(36, 30)
	UITheme.style_iron_button(close)
	close.pressed.connect(toggle_inventory)
	inventory_panel.add_child(close)

	# Paperdoll column (left side, 200px wide)
	var pd_title := Label.new()
	pd_title.text = "— Equipped —"
	pd_title.position = Vector2(20, 50)
	pd_title.size = Vector2(220, 24)
	UITheme.style_subtitle_label(pd_title)
	inventory_panel.add_child(pd_title)

	for entry in SLOT_LAYOUT:
		var slot_name = entry.slot
		var btn := Button.new()
		btn.name = "Slot_" + slot_name
		btn.position = Vector2(entry.x, 80 + (84 * SLOT_LAYOUT.find(entry)))
		btn.size = Vector2(220, 76)
		btn.text = entry.label + "\n(empty)"
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_paperdoll_slot_pressed.bind(slot_name))
		btn.mouse_entered.connect(_on_paperdoll_hover.bind(slot_name))
		btn.mouse_exited.connect(_hide_tooltip)
		inventory_panel.add_child(btn)
		paperdoll_slots[slot_name] = btn

	# Stats card below paperdoll
	stats_label = RichTextLabel.new()
	stats_label.position = Vector2(20, 332)
	stats_label.size = Vector2(220, 100)
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	UITheme.style_richtext(stats_label)
	inventory_panel.add_child(stats_label)


	# Bag grid (right side) — 6 cols x 4 rows = 24 slots, slot = 70x70
	var bag_title := Label.new()
	bag_title.text = "— Bag (24 slots) —"
	bag_title.position = Vector2(260, 50)
	bag_title.size = Vector2(440, 24)
	UITheme.style_subtitle_label(bag_title)
	inventory_panel.add_child(bag_title)

	bag_buttons.clear()
	var slot_size := 70
	var pad := 4
	for i in 24:
		var col := i % 6
		var row := i / 6
		var btn := Button.new()
		btn.name = "Bag_%d" % i
		btn.position = Vector2(260 + col * (slot_size + pad), 80 + row * (slot_size + pad))
		btn.size = Vector2(slot_size, slot_size)
		btn.text = ""
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_bag_slot_pressed.bind(i))
		btn.mouse_entered.connect(_on_bag_slot_hover.bind(i))
		btn.mouse_exited.connect(_hide_tooltip)
		inventory_panel.add_child(btn)
		bag_buttons.append(btn)

	# Footer hint
	var hint := Label.new()
	hint.text = "Click bag item to use/equip  •  Click equipped slot to unequip  •  I to close  •  Q to drink potion"
	hint.position = Vector2(20, 432)
	hint.size = Vector2(700, 24)
	UITheme.style_hint_label(hint)
	inventory_panel.add_child(hint)

	# Tooltip (single shared label, follows mouse)
	inv_tooltip = Label.new()
	inv_tooltip.name = "InvTooltip"
	inv_tooltip.visible = false
	UITheme.style_tooltip_label(inv_tooltip)
	inv_tooltip.add_theme_constant_override("outline_size", 4)
	inv_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inv_tooltip.size = Vector2(320, 100)
	inv_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$UI.add_child(inv_tooltip)


# ── Click handlers ───────────────────────────────────────────────────────
func _on_paperdoll_slot_pressed(slot_name: String) -> void:
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return
	if player.inventory.equipped.get(slot_name, "") != "":
		player.inventory.unequip(slot_name)

func _on_bag_slot_pressed(idx: int) -> void:
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return
	if idx < 0 or idx >= player.inventory.bag.size():
		return
	player.inventory.use_item(idx, player)

# ── Hover / tooltip ──────────────────────────────────────────────────────
func _on_paperdoll_hover(slot_name: String) -> void:
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return
	var id = player.inventory.equipped.get(slot_name, "")
	if id == "":
		_hide_tooltip()
		return
	var item = Items.get_item(id)
	if item.is_empty():
		item = get_runtime_item(id)
	_show_tooltip_for(item)

func _on_bag_slot_hover(idx: int) -> void:
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return
	if idx < 0 or idx >= player.inventory.bag.size():
		_hide_tooltip()
		return
	var slot = player.inventory.bag[idx]
	var item = Items.get_item(slot.id)
	if item.is_empty():
		item = get_runtime_item(slot.id)
	_show_tooltip_for(item)

func _show_tooltip_for(item: Dictionary) -> void:
	if item.is_empty() or inv_tooltip == null: return
	var rarity = item.get("rarity", "common")
	var rcol: Color = Items.RARITY_COLORS.get(rarity, Color.WHITE)
	var lines: Array = []
	lines.append("[color=#%s][b]%s[/b][/color]" % [rcol.to_html(false), item.get("name", "?")])
	lines.append("[i]%s · %s[/i]" % [item.get("type", ""), rarity])
	if item.has("damage"):    lines.append("⚔ +%d damage" % item.damage)
	if item.has("armor"):     lines.append("🛡 +%d armor" % item.armor)
	if item.has("hp_bonus"):  lines.append("❤ +%d max HP" % item.hp_bonus)
	if item.has("mp_bonus"):  lines.append("✦ +%d max MP" % item.mp_bonus)
	if item.has("crit_bonus"):lines.append("✦ +%d%% crit" % int(item.crit_bonus * 100))
	if item.has("heal"):      lines.append("Heals %d HP" % item.heal)
	if item.has("mana"):      lines.append("Restores %d MP" % item.mana)
	if item.has("value"):     lines.append("[color=#cccccc]Worth %d gold[/color]" % item.value)
	# Use a RichTextLabel-style tooltip via Label is awkward; we'll use plain text
	var plain := ""
	plain += item.get("name", "?") + "\n"
	plain += "%s · %s\n" % [item.get("type", ""), rarity]
	if item.has("damage"):    plain += "⚔ +%d damage\n" % item.damage
	if item.has("armor"):     plain += "🛡 +%d armor\n" % item.armor
	if item.has("hp_bonus"):  plain += "❤ +%d max HP\n" % item.hp_bonus
	if item.has("mp_bonus"):  plain += "✦ +%d max MP\n" % item.mp_bonus
	if item.has("crit_bonus"):plain += "✦ +%d%% crit\n" % int(item.crit_bonus * 100)
	if item.has("heal"):      plain += "Heals %d HP\n" % item.heal
	if item.has("mana"):      plain += "Restores %d MP\n" % item.mana
	if item.has("value"):     plain += "Worth %d gold" % item.value
	inv_tooltip.text = plain
	inv_tooltip.add_theme_color_override("font_color", rcol)
	inv_tooltip.position = get_viewport().get_mouse_position() + Vector2(16, 16)
	inv_tooltip.visible = true

func _hide_tooltip() -> void:
	if inv_tooltip:
		inv_tooltip.visible = false


# ── Refresh ──────────────────────────────────────────────────────────────
func _refresh_inventory_ui() -> void:
	if inventory_panel == null or not inventory_panel.visible:
		# Still refresh HUD totals
		_refresh_hud()
		return
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return

	# Paperdoll
	for entry in SLOT_LAYOUT:
		var slot_name = entry.slot
		var btn: Button = paperdoll_slots.get(slot_name)
		if btn == null: continue
		var id = player.inventory.equipped.get(slot_name, "")
		if id == "":
			btn.text = entry.label + "\n(empty)"
			btn.modulate = Color(1, 1, 1, 0.85)
		else:
			var item = Items.get_item(id)
			if item.is_empty():
				item = get_runtime_item(id)
			var icon = item.get("icon", "?")
			var name = item.get("name", id)
			btn.text = "%s  %s\n%s" % [icon, entry.label, name]
			var rarity = item.get("rarity", "common")
			btn.modulate = Items.RARITY_COLORS.get(rarity, Color.WHITE)

	# Bag
	for i in bag_buttons.size():
		var btn: Button = bag_buttons[i]
		if i < player.inventory.bag.size():
			var slot = player.inventory.bag[i]
			var item = Items.get_item(slot.id)
			if item.is_empty():
				item = get_runtime_item(slot.id)
			var icon = item.get("icon", "?")
			var qty_txt = "" if slot.qty <= 1 else ("×%d" % slot.qty)
			btn.text = "%s\n%s" % [icon, qty_txt]
			var rarity = item.get("rarity", "common")
			btn.modulate = Items.RARITY_COLORS.get(rarity, Color.WHITE)
		else:
			btn.text = ""
			btn.modulate = Color(1, 1, 1, 0.40)

	# Stats card
	var dmg = player.attack_damage_base + int(player.level * 1.5) + player.inventory.bonus_damage()
	var arm = player.inventory.bonus_armor()
	var hpb = player.inventory.bonus_hp()
	var mpb = player.inventory.bonus_mp()
	var crit = int((player.crit_chance + player.inventory.bonus_crit()) * 100)
	stats_label.text = "[b]Stats[/b]\n⚔ Damage: [color=#ffce5e]%d[/color]\n🛡 Armor: [color=#9bd0ff]%d[/color]\n❤ Max HP: %d (+%d)\n✦ Max MP: %d (+%d)\n✦ Crit: [color=#ffd66b]%d%%[/color]" % [dmg, arm, player.max_hp, hpb, player.max_mp, mpb, crit]

	# Refresh top HUD too (HP/MP cap may have changed)
	_refresh_hud()


# Tooltip follows mouse while visible
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and inv_tooltip and inv_tooltip.visible:
		inv_tooltip.position = get_viewport().get_mouse_position() + Vector2(16, 16)

# Mount toggle stub (Phase 2 item 6 — wire here when Horse.glb mount is added)
func toggle_mount() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	# Simple speed-buff toggle until 3D mount is wired
	if player.mounted:
		player.mounted = false
		player.walk_speed = 5.5
		player.run_speed = 9.0
		_show_toast("🐎 Dismounted")
	else:
		player.mounted = true
		player.walk_speed = 13.0
		player.run_speed = 22.0
		_show_toast("🐎 Mounted! Speed boost engaged")


# ════════════════════════════════════════════════════════════════════════
# Achievements & Titles Panel — built lazily on first toggle. Key: J.
#
# PURPOSE — Backlog #6 (Achievements + Title system) finally gets a
# rendering surface. The Achievements.gd evaluator + ACHIEVEMENTS dict has
# shipped (run 11), the title auto-equipper has shipped (run 11), Art has
# shipped 6 painterly 128×128 PNG crests (assets/icons/achievements/), and
# `_check_achievements()` toasts unlocks. But until this run there was NO
# way for the player to BROWSE the catalog — to see what's locked, see
# what's unlocked, and see the descriptions that hint at how to earn the
# rest. The integrator has flagged this gap on FOUR consecutive runs as
# "the painterly crests sit on disk waiting for one builder run to ship
# the achievement panel UI."
#
# THIS PANEL — closes that gap. It is the FIRST UI surface in the game
# that calls `load(icon_path) -> Texture2D -> TextureRect`. The pattern
# replicates 1:1 to NPC portraits (13 unrendered PNGs), enemy portraits
# (8 unrendered PNGs), item icons (~40 unrendered PNGs), and achievement
# crests are the canonical first instance because:
#   (a) the catalog is small (6 entries — the panel fits in one screen),
#   (b) the schema (Achievements.ACHIEVEMENTS) already carries icon_path,
#   (c) the unlock state is computable from world state with no new
#       primitive (per Achievements.gd authoring rule §1).
#
# 5-OUTPUT RULE
#   (i)  INTEGRATION — calls Achievements.evaluate(self) for live unlock
#        state, reads `self.unlocked_achievements` for persisted unlocks,
#        reads `self.current_title` for the equipped-title strip, reads
#        `assets/icons/achievements/*.png` painterly crests via
#        ResourceLoader-guarded load. Adds zero new world primitives.
#   (ii) SCHEMA — registers an `ach_card_widgets[id]` Dictionary with the
#        shape `{root: PanelContainer, crest: TextureRect, name: Label,
#        desc: Label, lock: Label, pulse: Tween|null}`. Documented in
#        SYSTEM_REGISTRY.md so future panels can replicate the layout.
#   (iii) FEEDBACK — every entry shows a 96×96 painterly crest (vs the
#        emoji-only fallback today), name in palette §3 burnt gold, desc
#        in parchment cream, locked entries dimmed to 0.45 modulate with
#        a 🔒 overlay, equipped title prominent at the top, "Earned X /
#        N" count below it, animated pulse on the most-recently-unlocked
#        card so the player's eye lands on the new entry first (THEME §12
#        — every visible thing must move).
#   (iv) EVAL — _refresh_achievements_ui re-runs Achievements.evaluate()
#        on every open, so unlocking-then-immediately-opening shows the
#        fresh state. Unit-testable: the same `is_unlocked` predicate
#        used at render time is `unlocked_achievements.has(id) or
#        Achievements.evaluate(self).has(id)`, both pure functions of
#        existing world primitives.
#   (v)  2+ HOOKS —
#        (1) Player.gd KEY_J → call_group("world", "toggle_achievements"),
#        (2) world.unlocked_achievements → unlocked_set rendering,
#        (3) world.current_title → equipped-title strip,
#        (4) Achievements.ACHIEVEMENTS.icon_path → TextureRect (UNBLOCKS
#            the same pattern for portraits + item icons in future runs),
#        (5) world._last_achievement_unlocked → animated pulse on most
#            recent unlock (NEW state field; written by _check_achievements
#            in addition to the existing unlock toast).
# ════════════════════════════════════════════════════════════════════════

const ACH_CARD_SIZE: Vector2 = Vector2(330, 132)
const ACH_CREST_SIZE: Vector2 = Vector2(96, 96)
const ACH_GOLD: Color = Color(1.0, 0.85, 0.4)            # palette §3 burnt gold
const ACH_PARCHMENT_CREAM: Color = Color(0.92, 0.85, 0.65)
const ACH_DIM_GREY: Color = Color(0.65, 0.6, 0.55)
const ACH_LOCK_MOD: Color = Color(0.45, 0.45, 0.45, 0.85)

var achievements_panel: Panel = null

# Mini-map + World-Map (Builder run 14). Lazily built in _ready(); the
# Minimap is always visible HUD and the WorldMap toggles via N (handled
# in Player.gd → call_group("world", "toggle_world_map")).
var minimap: Minimap = null
var world_map: WorldMap = null
var ach_grid_container: GridContainer = null
var ach_title_label: Label = null
var ach_count_label: Label = null
var ach_card_widgets: Dictionary = {}    # id (String) -> Dictionary widget bundle
var _last_achievement_unlocked: String = ""    # consumed by panel pulse, written by _check_achievements

func toggle_achievements() -> void:
	if achievements_panel == null:
		_build_achievements_ui()
	achievements_panel.visible = not achievements_panel.visible
	if achievements_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_achievements_ui()
	else:
		# Clear the pulse highlight so the next open doesn't re-fire on a stale id
		_last_achievement_unlocked = ""

# Stable priority-ordered ID list. Lower title_priority renders first
# (top-left), highest renders last (bottom-right) — mirrors the title
# ladder so kids see the journey from "the Apprentice" to "Warden of
# Eldoria" left-to-right, top-to-bottom.
func _achievements_in_priority_order() -> Array:
	var ids: Array = []
	for k in Achievements.ACHIEVEMENTS.keys():
		ids.append(String(k))
	ids.sort_custom(func(a, b) -> bool:
		var pa: int = int(Achievements.ACHIEVEMENTS[String(a)].get("title_priority", 0))
		var pb: int = int(Achievements.ACHIEVEMENTS[String(b)].get("title_priority", 0))
		if pa != pb:
			return pa < pb
		return String(a) < String(b)
	)
	return ids

func _build_achievements_ui() -> void:
	achievements_panel = Panel.new()
	achievements_panel.name = "AchievementsPanel"
	achievements_panel.anchor_left = 0.5
	achievements_panel.anchor_right = 0.5
	achievements_panel.anchor_top = 0.5
	achievements_panel.anchor_bottom = 0.5
	achievements_panel.offset_left = -370
	achievements_panel.offset_right = 370
	achievements_panel.offset_top = -290
	achievements_panel.offset_bottom = 290
	achievements_panel.visible = false
	$UI.add_child(achievements_panel)
	# THEME §3 parchment background — replaces default Godot grey
	UITheme.style_panel_parchment(achievements_panel)

	# Header — "Achievements & Titles" in palette §3 burnt gold
	var header := Label.new()
	header.text = "📜  Achievements & Titles"
	UITheme.style_title_label(header)
	header.position = Vector2(20, 10)
	header.size = Vector2(640, 32)
	achievements_panel.add_child(header)

	# Close button (mirror inventory panel layout)
	var close := Button.new()
	close.text = "✕"
	close.position = Vector2(700, 10)
	close.size = Vector2(36, 30)
	UITheme.style_iron_button(close)
	close.pressed.connect(toggle_achievements)
	achievements_panel.add_child(close)

	# Equipped-title strip — shows whatever the auto-equipper picked
	ach_title_label = Label.new()
	ach_title_label.position = Vector2(20, 50)
	ach_title_label.size = Vector2(700, 26)
	UITheme.style_subtitle_label(ach_title_label)
	achievements_panel.add_child(ach_title_label)

	# Earned X of N
	ach_count_label = Label.new()
	ach_count_label.position = Vector2(20, 78)
	ach_count_label.size = Vector2(700, 22)
	UITheme.style_count_label(ach_count_label)
	achievements_panel.add_child(ach_count_label)

	# Grid — 2 cols × 3 rows for the current 6 achievements; GridContainer
	# auto-flows so a 7th/8th land on row 4 without code changes.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.position = Vector2(16, 110)
	grid.size = Vector2(708, 440)
	achievements_panel.add_child(grid)
	ach_grid_container = grid

	for id_v in _achievements_in_priority_order():
		_build_one_achievement_card(String(id_v))

	# Footer hint — kid-readable instructions (THEME §7 warm gravitas, §5 UI text rules)
	var hint := Label.new()
	hint.text = "J to close  •  Earn titles by exploring the realm  •  Highest priority equips automatically"
	hint.position = Vector2(20, 558)
	hint.size = Vector2(700, 22)
	UITheme.style_desc_label(hint)
	achievements_panel.add_child(hint)

func _build_one_achievement_card(id: String) -> void:
	var entry: Dictionary = Achievements.ACHIEVEMENTS.get(id, {})
	if entry.is_empty():
		return
	var root := PanelContainer.new()
	root.custom_minimum_size = ACH_CARD_SIZE
	ach_grid_container.add_child(root)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	root.add_child(hbox)

	# Crest column — TextureRect loads icon_path; fail-soft if missing.
	# This is THE callsite that closes the four-run integrator gap.
	var crest_wrap := Control.new()
	crest_wrap.custom_minimum_size = ACH_CREST_SIZE
	hbox.add_child(crest_wrap)

	var crest := TextureRect.new()
	crest.name = "Crest"
	crest.custom_minimum_size = ACH_CREST_SIZE
	crest.size = ACH_CREST_SIZE
	crest.position = Vector2(0, 6)
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path: String = String(entry.get("icon_path", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path) as Texture2D
		if tex != null:
			crest.texture = tex
	crest_wrap.add_child(crest)

	# Lock overlay — dim 🔒 over the crest. Visibility flips in _refresh.
	var lock_lbl := Label.new()
	lock_lbl.name = "Lock"
	lock_lbl.text = "🔒"
	UITheme.style_lock_label(lock_lbl)
	lock_lbl.position = Vector2(30, 30)
	lock_lbl.size = Vector2(40, 40)
	crest_wrap.add_child(lock_lbl)

	# Right column — name, desc, awarded-title hint
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)

	var name_lbl := Label.new()
	name_lbl.name = "AName"
	name_lbl.text = "%s %s" % [String(entry.get("icon", "🏆")), String(entry.get("name", id))]
	UITheme.style_name_label(name_lbl)
	right.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.name = "ADesc"
	desc_lbl.text = String(entry.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(200, 56)
	UITheme.style_desc_label(desc_lbl)
	right.add_child(desc_lbl)

	# Title hint line — "Grants: ✨ the Apprentice" so the player can see
	# WHICH title each achievement unlocks. Empty for entries that grant none.
	var title_hint := Label.new()
	title_hint.name = "ATitle"
	var t_text: String = String(entry.get("title_text", ""))
	if t_text != "":
		title_hint.text = "✨ Grants: \"%s\"" % t_text
	else:
		title_hint.text = ""
	UITheme.style_micro_hint_label(title_hint)
	right.add_child(title_hint)

	ach_card_widgets[id] = {
		"root": root,
		"crest": crest,
		"name": name_lbl,
		"desc": desc_lbl,
		"title_hint": title_hint,
		"lock": lock_lbl,
	}

# Pure read-and-render. Pulls live unlock state from Achievements.evaluate
# AND persisted unlocks from `unlocked_achievements`, so a player who
# unlocks something then opens the panel sees fresh state regardless of
# whether `_check_achievements` happened to fire on this exact tick.
func _refresh_achievements_ui() -> void:
	if achievements_panel == null:
		return
	var unlocked_set: Dictionary = {}
	# Persisted unlocks (the canonical source — written by _check_achievements)
	for k in unlocked_achievements.keys():
		unlocked_set[String(k)] = true
	# Live re-eval (fail-soft if Achievements.evaluate ever returns junk;
	# evaluate() returns [] on duck-type miss per its own contract)
	var live: Array = Achievements.evaluate(self)
	for id_v in live:
		unlocked_set[String(id_v)] = true

	var unlocked_count: int = 0
	var total_count: int = Achievements.ACHIEVEMENTS.size()

	for id_variant in ach_card_widgets.keys():
		var id: String = String(id_variant)
		var w: Dictionary = ach_card_widgets[id]
		var is_unlocked: bool = unlocked_set.has(id)
		if is_unlocked:
			unlocked_count += 1
		var crest_node = w.get("crest", null)
		var name_node = w.get("name", null)
		var lock_node = w.get("lock", null)
		var root_node = w.get("root", null)
		if crest_node is TextureRect:
			(crest_node as TextureRect).modulate = (Color(1, 1, 1, 1) if is_unlocked else ACH_LOCK_MOD)
		if name_node is Label:
			(name_node as Label).add_theme_color_override("font_color",
				(ACH_GOLD if is_unlocked else ACH_DIM_GREY))
		if lock_node is Label:
			(lock_node as Label).visible = not is_unlocked
		# THEME §12 — animated pulse on the most-recently-unlocked card
		if is_unlocked and id == _last_achievement_unlocked and root_node is Control:
			_pulse_card(root_node as Control)

	if ach_title_label != null:
		var t: String = current_title if current_title != "" else "—"
		ach_title_label.text = "Equipped Title:  ✨ %s" % t
	if ach_count_label != null:
		ach_count_label.text = "Earned: %d of %d" % [unlocked_count, total_count]

# Soft 0.5→1.1→1.0 modulate pulse, two cycles. Uses Tween, parallel-safe.
# Identifies the just-unlocked card so the player's eye lands on it first
# when they open the panel right after a toast.
func _pulse_card(node: Control) -> void:
	if node == null or not is_instance_valid(node):
		return
	var base_mod: Color = node.modulate
	var pulse_mod: Color = Color(1.25, 1.15, 0.85, base_mod.a)
	var tw: Tween = create_tween().set_loops(2)
	tw.tween_property(node, "modulate", pulse_mod, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "modulate", base_mod, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
