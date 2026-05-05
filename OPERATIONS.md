# Eldoria — Operational Notes for Autonomous Agents

**Read this BEFORE you `git clone`.** The cloud sandboxes accumulate orphan
checkouts from prior agent runs that this user can't delete (owned by
`nobody:nogroup`). Defensive cloning is required.

## The disk problem

- `/tmp` fills to 100% with un-cleaned `eldoria-*` directories from past runs
- These directories' files are owned by another sandbox's user; current run
  cannot `rm` them
- A naive `git clone` to `/tmp/eldoria-...` hits "no space left on device"

## The fix — defensive clone strategy

Use this exact pattern in your workflow block:

```bash
# 1. Pick a clone location your sandbox CAN write to
WORK="/sessions/$(hostname | tr -d '\n')/tmp/eldoria-$(basename $0)-$(date +%s)"
mkdir -p "$WORK"
# Fall back to /dev/shm (RAM-backed, 2GB) if /sessions path fails
[ ! -d "$WORK" ] && WORK="/dev/shm/eldoria-$(basename $0)-$(date +%s)" && mkdir -p "$WORK"

# 2. Partial clone — skip binary blobs by default
git clone --filter=blob:none --depth=1 \
  "https://x-access-token:${TOKEN}@github.com/jamesmmartinez-code/martinez-watchlist.git" "$WORK"
cd "$WORK"

# 3. Sparse-checkout — only fetch the directories you need to edit
git sparse-checkout init --cone
git sparse-checkout set \
  eldoria-godot/scripts \
  eldoria-godot/scenes \
  THEME.md GAME_DESIGN.md WORLD_STATE.md CHANGES.md OPERATIONS.md
# Add more paths as needed for your specialty (e.g. assets/models for Character)

# 4. ALWAYS cleanup after, even on failure
trap "rm -rf '$WORK'" EXIT
```

### Sparse-checkout paths by agent

| Agent | Paths to checkout |
|-------|-------------------|
| Builder | `eldoria-godot/scripts`, `eldoria-godot/scenes`, all `*.md` ledgers |
| Polisher | Same as Builder |
| Character | + `eldoria-godot/assets/models` (need to read what exists) |
| Environment | + `eldoria-godot/assets/models/trees`, `props` |
| Art | + `eldoria-godot/assets/icons`, `portraits`, `banners`, `ui` |
| Lore | + `eldoria-godot/lore`, `data/dialogue`, `data/codex` |
| Audio | + `eldoria-godot/assets/audio` |
| QA | Full checkout (no sparse) — needs to debug whatever broke |
| Integrator | Full checkout — needs to merge everything |
| Architect | + all ledger files, exclude binary asset folders |

### Why this works
- `--filter=blob:none` defers binary downloads until file access (LFS-like)
- `--depth=1` skips git history beyond HEAD
- `sparse-checkout` only materializes files in listed paths
- Result: clone size drops from ~120MB to ~5MB for code-only agents
- /sessions sandbox path is per-session so no orphan collision

## If you DO need a binary asset

For Character / Environment / Art agents that need to read existing GLBs:

```bash
# After sparse-checkout, fetch a single binary on demand
git read-tree -mu HEAD -- eldoria-godot/assets/models/Boss.glb
# OR
git checkout HEAD -- eldoria-godot/assets/models/Boss.glb
```

## Cleanup after every run

```bash
# At end of run (or in trap):
cd /
rm -rf "$WORK" 2>/dev/null
# Don't try to clean other sandboxes' orphans — you can't, and you'll fail loudly
```

## Reporting back

If you encounter a NEW operational issue (lock contention, network flake, API
outage, etc.), add a brief entry to this file under `## Known issues` BEFORE
your run ends. Future agents will read it and adapt.

## Known issues

- 2026-05-05: `/tmp` orphan accumulation from cross-session checkouts. Mitigation: clone into `/sessions/$HOSTNAME/tmp/` or `/dev/shm/`, use sparse-checkout, always cleanup.

## ⚠️ HARD RULE: NEVER PUSH TO `main` DIRECTLY

As of 2026-05-05, agents that push directly to `main` cause CI race conditions
that fail the Build Eldoria deploy and pile up failed runs in the Actions UI
(78 failures in one batch was the trigger). The Integrator workflow now exists
to merge agent work in batches.

**Every agent MUST:**

1. Create a feature branch: `git checkout -b auto/<agent-name>`
   - Examples: `auto/builder`, `auto/character`, `auto/qa`, `auto/architect`
2. Commit + push to that branch: `git push origin auto/<agent-name>`
3. NEVER push to main. The Integrator workflow merges auto/* branches into
   main every 2 minutes automatically.

**Why this works:**
- N agent pushes → 1 batched merge → 1 build → no races
- Conflict on a branch is handled gracefully — Integrator skips that branch and
  reports the conflict; agent rebases on next run.
- Branches are auto-deleted after successful merge (no stale branch buildup).

**If your branch shows up in the Integrator log as "merge conflict":**
- Pull main, rebase, resolve, push again. Don't force-push to main.

**Exception:** the Build Eldoria workflow itself pushes the built `/eldoria/`
folder to main. That's the ONLY allowed direct main push, and it now has
rebase-retry built in.
