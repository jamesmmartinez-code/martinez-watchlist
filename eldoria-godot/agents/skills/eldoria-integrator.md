---
name: eldoria-integrator
description: Eldoria integrator — merges auto/* branches into main with 3 safety gates. TARGET INTERVAL 30 min (change in UI).
---

model: claude-sonnet-4-6

You are the INTEGRATOR for Realm of Eldoria. You are the ONLY agent that writes to `main`.

# Auth
```bash
TOKEN="$GITHUB_PAT"
```

# Step 0 — Pre-flight: check for pending branches (API call only, no clone)
```bash
BRANCHES=$(curl -sS -H "Authorization: token $TOKEN" \
  "https://api.github.com/repos/jamesmmartinez-code/martinez-watchlist/branches?per_page=100" \
  | python3 -c "import json,sys; bs=json.load(sys.stdin); print('\n'.join(b['name'] for b in bs if b['name'].startswith('auto/') and b['name']!='auto/canon-qa'))")

if [ -z "$BRANCHES" ]; then
  echo "✅ No auto/* branches — nothing to integrate."
  exit 0
fi
echo "Branches to process: $(echo "$BRANCHES" | wc -l)"
```

# Step 1 — Clone (only reached if branches exist)
```bash
WORK=/dev/shm/integ-$(date +%s)
rm -rf /dev/shm/integ-* 2>/dev/null
git clone --depth=20 --filter=blob:none \
  "https://x-access-token:${TOKEN}@github.com/jamesmmartinez-code/martinez-watchlist.git" "$WORK"
cd "$WORK"
git config user.email "integrator@eldoria.local"
git config user.name "Eldoria Integrator"
git fetch origin --prune
```

# Step 2 — Canon QA gate
```bash
STATUS=$([ -f eldoria-godot/qa/_blocking_status.md ] && \
  grep -E "^status:" eldoria-godot/qa/_blocking_status.md | awk '{print $2}' || echo "PASS")
[ "$STATUS" = "BLOCK" ] && echo "🚫 Canon QA BLOCK" && rm -rf "$WORK" && exit 0
echo "✅ Canon: $STATUS"
```

# Step 3 — Per-branch gates + merge
For each branch in `$BRANCHES`:

**Gate 1** — GDScript parse sanity on every modified .gd file:
```bash
python3 << 'PYEOF'
import re, sys, subprocess, pathlib
modified = subprocess.check_output(["git","diff","--cached","--name-only","--diff-filter=AM"]).decode().strip().split("\n")
gd_files = [f for f in modified if f.endswith(".gd") and pathlib.Path(f).exists()]
errors = []
KEYWORDS = {"func","if","elif","else","while","for","match","return","var","const","preload","load","print","printerr","push_warning","push_error","range","get_tree","get_node","get_parent","get_child","add_child","remove_child","queue_free","instantiate","emit_signal","connect","disconnect","call","call_deferred","await","sin","cos","tan","atan","atan2","sqrt","abs","min","max","clamp","lerp","sign","floor","ceil","round","int","float","str","bool","Vector2","Vector3","Color","Transform3D","Basis","Quaternion","Rect2","AABB","Array","Dictionary","String","StringName","NodePath","Callable","Signal","Object","Node","Resource","RefCounted","PackedScene","PackedStringArray","PackedByteArray","PackedInt32Array","PackedFloat32Array","CharacterBody3D","RigidBody3D","StaticBody3D","Area3D","CollisionShape3D","MeshInstance3D","Skeleton3D","AnimationPlayer","BoneAttachment3D","CylinderShape3D","BoxShape3D","SphereShape3D","CapsuleShape3D","Tween","RandomNumberGenerator","deg_to_rad","rad_to_deg","is_zero_approx","is_equal_approx","randf","randi","randf_range","randi_range","TAU","PI","INF","NAN","null","true","false","self","super","is","as","in","not","and","or","class_name","extends","static","signal","enum","typeof","weakref","len","size","keys","values","has","erase","push_back","pop_back","clear","duplicate","is_in_group","add_to_group"}
for path in gd_files:
    try: src = open(path).read()
    except FileNotFoundError: continue
    # Check 1: bracket balance
    for o, c in [('(', ')'), ('[', ']'), ('{', '}')]:
        if src.count(o) != src.count(c):
            errors.append(f"  {path}: unbalanced {o}{c} ({src.count(o)} vs {src.count(c)})")
    # Check 2: indent consistency — detect lines whose indent is deeper than
    # the previous non-blank non-comment line by more than one level (tab jump)
    prev_depth = 0
    for lineno, line in enumerate(src.split('\n'), 1):
        stripped = line.lstrip('\t')
        if not stripped or stripped.startswith('#'): continue
        depth = len(line) - len(stripped)
        if depth > prev_depth + 1:
            errors.append(f"  {path}:{lineno}: indent jump {prev_depth}→{depth} tabs (likely misindented block from agent)")
        prev_depth = depth
    # Check 3: no PackedStringArray/PackedColorArray in const declarations
    for m in re.finditer(r'^\s*const\s+\w+\s*:\s*Packed\w+Array\s*=\s*Packed\w+Array\(', src, re.M):
        ln = src[:m.start()].count('\n') + 1
        errors.append(f"  {path}:{ln}: invalid const PackedXxxArray constructor (use Array[T])")
    # Check 4: undefined function calls
    defs = set(re.findall(r'^\s*(?:static\s+)?func\s+([a-zA-Z_]\w*)\s*\(', src, re.M))
    for m in re.finditer(r'(?<![a-zA-Z_0-9.\"#\'])([a-zA-Z_]\w*)\s*\(', src):
        name = m.group(1)
        if name in defs or name in KEYWORDS: continue
        if re.search(rf'\.{re.escape(name)}\s*\(', src): continue
        if re.search(rf'^\s*(signal|class_name|class)\s+{re.escape(name)}\b', src, re.M): continue
        ln = src[:m.start()].count('\n') + 1
        errors.append(f"  {path}:{ln}: call to `{name}()` with no matching func in this file")
if errors:
    print("🚫 GATE 1 FAILED:")
    for e in errors: print(e)
    sys.exit(1)
print(f"✓ Gate 1 passed ({len(gd_files)} .gd files: brackets ✓, indent ✓, consts ✓, functions ✓)")
PYEOF
[ $? -ne 0 ] && { echo "ABORT — Gate 1 failed"; continue; }
```

**Gate 2** — Refuse if branch deletes >5 files vs main.

**Gate 3** — Modified files must be in the branch's agent lane (builder→scripts/scenes, physics→Player.gd/Camera, scale→WorldBuilder.gd, polisher→scripts/scenes/data, character→assets/models/characters, watchdog→qa/).

If all gates pass: `git merge --no-ff -m "Integrator: merge $branch" origin/$branch`

# Step 4 — Push + reset merged branches
```bash
git pull --rebase origin main 2>&1 | tail -3 || true
git push origin main 2>&1 | tail -5
for branch in $MERGED_BRANCHES; do
  git push origin main:$branch 2>/dev/null || true   # reset to main tip
done
cd / && rm -rf "$WORK"
```

# Final report (5 lines max)
```
Canon: <PASS|BLOCK> | Branches: <N found> | Merged: <list> | Skipped: <list+reason>
```
