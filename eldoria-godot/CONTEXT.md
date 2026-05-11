# Realm of Eldoria — Master Context Doc

**Last updated:** 2026-05-11 (updated by session that shipped Phases 24–26)

This doc is the source-of-truth handoff for any new chat picking up the Eldoria + Watchlist projects. Read top to bottom. Then check the `agents/` folder for the 18 specialist agent specs, and read the repo's `GAME_DESIGN.md` / `THEME.md` / `BRIARWOOD_SCOPE.md` for game canon.

---

## ⚠️ CRITICAL — REPO LOCATION (read this first, every session)

**The Godot source lives in ONE repo only:**

| Thing | Repo | Path |
|---|---|---|
| All `.gd` scripts | `jamesmmartinez-code/martinez-watchlist` | `eldoria-godot/scripts/` |
| All scenes | `jamesmmartinez-code/martinez-watchlist` | `eldoria-godot/scenes/` |
| All assets | `jamesmmartinez-code/martinez-watchlist` | `eldoria-godot/assets/` |
| Web export (deployed HTML/JS/PCK) | `jamesmmartinez-code/martinez-watchlist` | `eldoria/` |

**`realm-of-eldoria` is the Cloudflare Worker repo only** — it does NOT contain Godot source.
Never push `.gd` files there. Always push to `martinez-watchlist/eldoria-godot/`.

Local project folder: `/Users/jamesmartinez/Documents/Claude/Projects/Realm of Eldoria/`
When editing locally and pushing, use the GitHub API (`gh api --method PUT`) targeting `martinez-watchlist`.

---

## TL;DR
James Martinez is building two apps for his kids:
1. **Martinez Family Watchlist** — single HTML file, live, working, kids use daily.
2. **Realm of Eldoria** — Godot 4.6.2 fantasy MMORPG, autonomously developed by ~16 scheduled agents committing to GitHub. Live but rough.

Both live on GitHub Pages under `jamesmmartinez-code/martinez-watchlist`.

The kids are **Alden** (girl, 9, frog 🐸, mint, Pathfinder class) and **Owen** (boy, 11, race car 🏎️ McLaren orange #FF8000, Vanguard class). Family password: `martinez`. Parent PIN: `100811`.

---

## Live URLs
- **Watchlist landing:** https://jamesmmartinez-code.github.io/martinez-watchlist/
- **Eldoria 3D game:** https://jamesmmartinez-code.github.io/martinez-watchlist/eldoria/
- **GitHub commits feed:** https://github.com/jamesmmartinez-code/martinez-watchlist/commits/main
- **GitHub Actions feed:** https://github.com/jamesmmartinez-code/martinez-watchlist/actions
- **Godot scripts (browse on GitHub):** https://github.com/jamesmmartinez-code/martinez-watchlist/tree/main/eldoria-godot/scripts

---

## What was happening when chat locked

1. **Mid-migration to private repo.** `realm-of-eldoria` was created (private, GitHub Pro). Push of 216 source files (~106MB) was at ~93% (188/202 transferred). Need to finish the push, enable Pages, retrigger first build, update agent prompts, add redirect on old `/eldoria/`.

2. **25+ Meshy GLBs in `/Users/jamesmartinez/Documents/Claude/Projects/Realm of Eldoria/`** that James generated using prompts I gave him near end of chat. NOT yet moved to canonical asset paths in the Godot project. See "Assets backlog" section below.

3. **User's last visible complaints:**
   - "im stuck and cant walk" (sent unstick controls: Backspace/F1/F2; auto-recover added)
   - "this realm is not gorgeous enough. we need the main city to have way more than what we have now. this is where it needs to wow them."
   - Player still appears tiny next to giant trees/houses (scale sweep added but flaky)
   - Pixelation in background (texture streaming hiccup in WASM)

---

## Project folder layout (this folder)

```
Realm of Eldoria/
├── CONTEXT.md          ← this file (master handoff)
├── agents/             ← 18 agent spec files (already exists, see _README.md)
├── Meshy_AI_*.glb      ← 25+ GLBs James generated; NEEDS to be moved into eldoria-godot/assets/
└── Realm of Eldoria Chat.1.rtfd/  ← archived chat transcript (chat that just closed)
```

**Godot source** is NOT here — it lives in the conversation outputs folder + the GitHub repo at `eldoria-godot/`. To inspect it, clone the repo or open the outputs folder.

---

## Action plan for next conversation

### Priority 0 — Verify state
1. Check `gh repo view jamesmmartinez-code/realm-of-eldoria` to see if migration completed.
2. Hit https://jamesmmartinez-code.github.io/martinez-watchlist/eldoria/ in Incognito to see current playable state.
3. Check `mcp__scheduled-tasks__list_scheduled_tasks` to confirm which of the 16 agents are still firing.

### Priority 1 — Move Meshy assets into the project
James worked hard generating these. They MUST be wired in.

For each `Meshy_AI_*.glb` in this folder, identify what it is from the filename, copy it into the right canonical path in `eldoria-godot/assets/models/`, rename to a clean name. Then push as a single batched commit.

Mapping (from filename → canonical path):
- `Meshy_AI_A_massive_medieval_hi_*` → `architecture/briarwood_vista.glb`
- `Meshy_AI_The_best_mid_evel_cit_*` → `architecture/briarwood_vista_alt.glb`
- `Meshy_AI_A_dense_oak_and_pine_*` → `architecture/whisperwood_chunk.glb`
- `Meshy_AI_Underground_cavern_*` → `architecture/crystal_caves_chamber.glb`
- `Meshy_AI_A_3_4_close_portrait_*` → `npcs/maeve.glb` (was prompted as Elder Maeve portrait — but Meshy makes 3D, not 2D portraits, so this is a 3D Maeve)
- `Meshy_AI_A_vast_jagged_tear_*` → `architecture/sundering_crack.glb`
- `Meshy_AI_A_hand_painted_fantas_*` → `props/world_map_object.glb`
- `Meshy_AI_An_eleven_year_old_fa_*` → `heroes/owen_vanguard.glb`
- `Meshy_AI_Animation_Walking_*` + `Meshy_AI_Meshy_Merged_Animations*` → likely the rigged character base — investigate which child it represents (Alden or Owen)
- `Meshy_AI_Minecraft_*` → unsure, inspect

After moving, edit `WorldBuilder.gd` to instance these GLBs instead of placeholder/procedural geometry.

### Priority 2 — Wire character select scene
GAME_DESIGN.md §10 calls for a parchment-scroll character picker at game start. Currently kids both play as `Hero.glb` (Lange). After Alden's + Owen's GLBs are in place, build `scenes/CharacterSelect.tscn` so each kid picks their own.

### Priority 3 — Massive Briarwood
Per BRIARWOOD_SCOPE.md: 6 districts, 40+ buildings, 15+ named ambient NPCs, walls + 4 gates, lanterns at dusk, smoke from every chimney, dogs/chickens, banners. Currently far below this floor. Architect agent + Concept Artist agent (when Lorekeeper canon lands) own this.

### Priority 4 — Kick the Lorekeeper + Concept Artist agents
They were created late in chat but hadn't shipped first batches when chat locked. Their work blocks downstream content agents. Force-run them via `mcp__scheduled-tasks__run_now` (or wait for next tick).

---

## Where to find everything

- **All API keys + repo URLs + deploy script paths:** `memory/eldoria_infra_keys.md`
- **Game design canon summary:** `memory/eldoria_game_design.md` + repo's `GAME_DESIGN.md` / `THEME.md`
- **Known bugs + escape hatches:** `memory/eldoria_known_issues.md`
- **What's already done in the watchlist app:** `memory/watchlist_app.md`
- **Project + agent state:** `memory/eldoria_project_state.md` + `memory/eldoria_agent_roster.md`
- **Asset backlog (this folder's Meshy GLBs):** `memory/eldoria_assets_backlog.md`
- **18 agent specs:** `agents/*.md` (already in this project folder)
- **User preferences / how to work with James:** `memory/cowork_tooling.md` + `memory/martinez_family.md`

---

## Critical user requirements (NEVER violate)
1. **Kids never lose progress on death.** Save system writes to localStorage every 30s + on level-up + on quest accept. Death = -15% gold, NEVER level/XP/inventory.
2. **No leaving the app for the kids.** Trailers play inline with YouTube end-screen blocked. Streaming deep-links open NATIVE apps (Disney+/Netflix), never new tabs to YouTube etc.
3. **Theme is sacred.** Painterly fantasy, sunset palette. NO sci-fi, modern, photoreal, anime big-eyes, chibi, gore, sexual content, modern political commentary. Soldier model is BANNED.
4. **One URL for the kids.** Watchlist + Eldoria are reachable from the same landing page. Kids never type URLs.
5. **Both kids equal.** Per-user logins, private favorites/watched/heart lists. Don't gate content by gender. Alden is a GIRL.

---

## Honest state, not marketing
- The game IS playable but rough. Visuals are CC0-grab-bag aesthetic, not yet "WOW" tier.
- Autonomous agent setup works structurally but needs more hand-holding than the architecture promises. Many agents had not shipped first runs when chat locked.
- The watchlist app is in great shape — kids use it daily. Don't refactor unless asked.
- James is patient but not infinitely. He notices when promises don't materialize. When something is genuinely impossible (I can't generate images, can't run Godot in cloud sandbox), say so plainly and offer the next-best thing.

---

## Quick commands for next session

```bash
# Check live game
open "https://jamesmmartinez-code.github.io/martinez-watchlist/eldoria/"

# Check current commits
gh repo view jamesmmartinez-code/martinez-watchlist --web

# Check Actions
gh run list --repo jamesmmartinez-code/martinez-watchlist --limit 10

# Local export + deploy (if outputs/full-deploy.sh still exists)
bash "/Users/jamesmartinez/Library/Application Support/Claude/local-agent-mode-sessions/.../outputs/full-deploy.sh"
```

---

End of handoff. Read `memory/MEMORY.md` to navigate the rest of the saved context.
