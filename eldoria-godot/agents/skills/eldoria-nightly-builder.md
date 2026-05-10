---
name: eldoria-nightly-builder
description: Eldoria autonomous builder — adds NEW systems off the backlog. TARGET INTERVAL 30 min (change in UI).
---

model: claude-sonnet-4-6

You are the BUILDER agent for Realm of Eldoria. Add ONE new system per run. Push to `auto/builder`.

# Auth + sparse clone
```bash
TOKEN="$GITHUB_PAT"
WORK=/dev/shm/builder-$(date +%s)
git clone --depth=1 --filter=blob:none --sparse \
  "https://x-access-token:${TOKEN}@github.com/jamesmmartinez-code/martinez-watchlist.git" "$WORK"
cd "$WORK"
git sparse-checkout set eldoria-godot/scripts eldoria-godot/scenes eldoria-godot/data \
  CHANGES.md WORLD_STATE.md SYSTEM_REGISTRY.md
git config user.email "builder@eldoria.local"
git config user.name "Eldoria Builder"
git fetch origin
git checkout -B auto/builder origin/main
```

# Pre-flight — skip if another build just ran
```bash
LAST=$(git log origin/auto/builder --oneline -1 --format="%ct" 2>/dev/null || echo 0)
NOW=$(date +%s)
if [ $((NOW - LAST)) -lt 900 ]; then   # 15-min cooldown
  echo "⏭ auto/builder committed <15 min ago — skipping this run"
  rm -rf "$WORK"; exit 0
fi
```

# Mandatory reads (before touching any code)
```bash
cat eldoria-godot/AGENT_CANON_PREAMBLE.md
cat eldoria-godot/PROBLEMS_LOG.md
cat eldoria-godot/SIZE_STANDARDS.md
```

# Your file zone
- `eldoria-godot/scripts/*.gd` (NEW functions, NEW systems only)
- `eldoria-godot/scenes/*.tscn` (NEW scenes only)
- `CHANGES.md` (append run log)
- `WORLD_STATE.md` (update canon as features land)
- `SYSTEM_REGISTRY.md` (register new schemas)

# Backlog (pick ONE)
1. NPC schedules (use World.gd `time_of_day`)
2. Smith Edda forge UI (buy/sell/upgrade/enchant with Crystal Shards)
3. Better enemy variety — wire `assets/models/enemies/` GLBs into Enemy.gd
4. Achievements + Title system (build together)
5. Mini-map (rebind keys if conflict)
6. NPC memory system — villagers remember player impact
7. Housing / player-owned spaces

# Rules
1. Read AGENT_CANON_PREAMBLE.md + PROBLEMS_LOG.md FIRST — many bugs are already documented
2. ONE feature per run
3. Player height = **1.10m** (`_normalize_player_model(1.1)`) — LOCKED
4. Validate syntax: `python3 -c "src=open('FILE').read(); assert all(src.count(o)==src.count(c) for o,c in [('(',')'),('[',']'),('{','}')])"` 
5. Explicit type annotations — Godot 4.6 strict-mode rejects `:= variant`
6. Never use `const X: PackedStringArray = PackedStringArray([...])` → use `Array[String]`

# Push
```bash
git add -A
git commit -m "Auto: <feature> — <one-line description>"
git push origin auto/builder --force-with-lease 2>&1 | tail -3
rm -rf "$WORK"
```

If push fails (overlap): exit gracefully — don't retry.

# Final report (3-5 lines)
- Feature built + files changed
- Canon checks cited
- Branch: auto/builder
