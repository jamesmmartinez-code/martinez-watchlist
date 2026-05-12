#!/usr/bin/env python3
"""
Blank-world audit v2: scans WorldBuilder.gd for ALL patterns that silently
abort an async coroutine in Godot 4, leaving the world blank (grass only).

GDScript coroutine-abort rules:
  Any runtime error inside a callv() call that runs WITHIN an await-containing
  coroutine kills the entire coroutine with no exception, no try/catch, no log.
  The game continues running (player, HUD, terrain visible) but every builder
  that would have run after the crash is skipped.

Patterns caught by this audit
──────────────────────────────
1. ORPHAN_GLOBAL_POSITION
   Node3D.new() used, then .global_position assigned before add_child().
   Godot 4 requires a node to be in the scene tree before global_position works.
   If it isn't, the assignment silently raises an internal error that aborts the
   coroutine. Fix: call add_child() BEFORE .global_position, or use .position.

2. ASSERT_IN_BUILDER
   assert(...) inside a _build_* / _scatter_* / _init_* / _spawn_* function.
   If the assertion fires at runtime the coroutine is silently killed.
   Fix: replace assert() with a guarded if+return or push_error()+return.

3. NULL_CALL
   Pattern: some_var.method() where some_var was assigned from a load()/get_node()
   or similar call without an is_instance_valid() / != null guard.
   The most common trigger is: var inst = load(path).instantiate() — if load()
   returns null (asset missing), .instantiate() crashes.
   Fix: null-check the result of load() before calling .instantiate().

4. UNGUARDED_LOAD
   var x = load("res://...") used directly without checking for null before
   calling methods on x (e.g. x.instantiate(), x.duplicate(), x.get_*).
   Fix: if x == null: push_error(...); return — before any method call on x.

5. ARRAY_OOB_CONSTANT
   arr[literal_integer] on a variable not known to be that length at compile time,
   inside a builder function. A static index on a runtime array is a common OOB.
   Fix: guard with if arr.size() > idx before indexing.

6. UNCHECKED_CALLV
   callv(method_name, args) where method_name is a variable (not a literal),
   without has_method(method_name) guard. If the method doesn't exist the
   coroutine aborts. Fix: if has_method(method_name): callv(...)

7. MISSING_SAFE_CALL_NOW (WorldBuilder-specific)
   Direct call to a _build_*/_scatter_*/_init_* method from inside
   _build_world_async() rather than via _safe_call_now(). Direct calls run
   in the coroutine frame; if they error the whole coroutine dies.
   Fix: always route through _safe_call_now("_build_foo", []).
"""

import re, pathlib, sys, textwrap

GD = pathlib.Path("eldoria-godot/scripts/WorldBuilder.gd")
if not GD.exists():
    print("WorldBuilder.gd not found — skipping audit")
    sys.exit(0)

src   = GD.read_text(errors="replace")
lines = src.splitlines()
total = len(lines)

# ── helpers ──────────────────────────────────────────────────────────────────

def func_at(i):
    """Return the name of the enclosing function for line index i."""
    for j in range(i, -1, -1):
        m = re.match(r"^func\s+(\w+)", lines[j])
        if m:
            return m.group(1)
    return "<top>"

def in_builder_func(i):
    """True if line i is inside a _build_*, _scatter_*, _init_*, _spawn_* func."""
    name = func_at(i)
    return bool(re.match(r"(_build_|_scatter_|_init_|_spawn_)", name))

def in_async_func(i):
    """True if line i is inside _build_world_async."""
    return func_at(i) == "_build_world_async"

# ── rule 1: orphan global_position (original rule, unchanged) ────────────────

NODE_RE = re.compile(r"^\s*var\s+(\w+)\s*(?::[^=]*)?\s*:?=\s*[\w\.]+\.new\(\)")
GP_RE   = re.compile(r"^\s*(\w+)\.global_position\s*=")
AC_RE   = re.compile(r"add_child\s*\(\s*(\w+)")
NODE_TYPES = {
    "Node3D","MeshInstance3D","CSGBox3D","CSGSphere3D","StaticBody3D",
    "CollisionShape3D","OmniLight3D","SpotLight3D","Area3D",
    "GPUParticles3D","CPUParticles3D","AnimatedSprite3D","Label3D",
}

orphans    = {}
violations = []

for i, line in enumerate(lines):
    lineno = i + 1
    s = line.strip()
    if s.startswith("#"):
        continue
    if s.startswith("func "):
        orphans = {}
    m = NODE_RE.match(line)
    if m and (any(t in line for t in NODE_TYPES) or "3D" in line or "Instance" in line):
        orphans[m.group(1)] = lineno
    m2 = AC_RE.search(line)
    if m2:
        orphans.pop(m2.group(1), None)
    m3 = GP_RE.match(line)
    if m3 and m3.group(1) in orphans:
        violations.append({
            "rule":    "ORPHAN_GLOBAL_POSITION",
            "line":    lineno,
            "text":    s,
            "detail":  "var created line %d, add_child not yet called" % orphans[m3.group(1)],
        })

# ── rule 2: assert() inside builder functions ─────────────────────────────────

ASSERT_RE = re.compile(r"^\s*assert\s*\(")
for i, line in enumerate(lines):
    lineno = i + 1
    s = line.strip()
    if s.startswith("#"):
        continue
    if ASSERT_RE.match(line) and in_builder_func(i):
        violations.append({
            "rule":   "ASSERT_IN_BUILDER",
            "line":   lineno,
            "text":   s,
            "detail": "assert() in %s — fires at runtime → coroutine abort" % func_at(i),
        })

# ── rule 3 + 4: unguarded load().instantiate() ───────────────────────────────

LOAD_ASSIGN_RE = re.compile(r"^\s*var\s+(\w+)\s*(?::[^=]*)?\s*:?=\s*(?:_safe_load_glb|load)\s*\(")
METHOD_ON_RE   = re.compile(r"^\s*(\w+)\.(instantiate|duplicate|get_surface_override_material|get_mesh)\s*\(")

# track vars set via load() within each function scope
load_vars = {}  # varname -> lineno

for i, line in enumerate(lines):
    lineno = i + 1
    s = line.strip()
    if s.startswith("#"):
        continue
    if s.startswith("func "):
        load_vars = {}
        continue
    m = LOAD_ASSIGN_RE.match(line)
    if m:
        load_vars[m.group(1)] = lineno
        continue
    # remove from tracking if guarded: "if x == null" or "if not x" or "if x:"
    guard_m = re.match(r"^\s*if\s+(not\s+)?(\w+)\s*(==\s*null|!=\s*null|:|\s*$)", line)
    if guard_m:
        load_vars.pop(guard_m.group(2), None)
        continue
    # also remove if is_instance_valid(x) check
    iv_m = re.search(r"is_instance_valid\s*\(\s*(\w+)\s*\)", line)
    if iv_m:
        load_vars.pop(iv_m.group(1), None)
        continue
    m2 = METHOD_ON_RE.match(line)
    if m2 and m2.group(1) in load_vars and in_builder_func(i):
        violations.append({
            "rule":   "UNGUARDED_LOAD",
            "line":   lineno,
            "text":   s,
            "detail": "var '%s' assigned from load() at line %d with no null-check before .%s()" % (
                      m2.group(1), load_vars[m2.group(1)], m2.group(2)),
        })

# ── rule 5: array constant index without size guard ──────────────────────────

ARR_IDX_RE = re.compile(r"(\w+)\[(\d+)\]")
for i, line in enumerate(lines):
    lineno = i + 1
    s = line.strip()
    if s.startswith("#"):
        continue
    if not in_builder_func(i):
        continue
    for m in ARR_IDX_RE.finditer(line):
        varname = m.group(1)
        idx     = int(m.group(2))
        # skip obvious false positives: ALL_CAPS constants, Vector2/3 swizzle
        if varname.isupper():
            continue
        # only flag if index > 0 (index 0 is common and lower risk)
        if idx < 2:
            continue
        # check that there's no size guard in the preceding 5 lines
        context = "\n".join(lines[max(0,i-5):i])
        if ".size()" in context or "len(" in context:
            continue
        violations.append({
            "rule":   "ARRAY_OOB_CONSTANT",
            "line":   lineno,
            "text":   s,
            "detail": "%s[%d] with no size() guard in preceding lines — possible OOB" % (varname, idx),
        })

# ── rule 6: unchecked callv() ─────────────────────────────────────────────────

CALLV_RE = re.compile(r"^\s*callv\s*\(\s*(\w+)\s*,")
for i, line in enumerate(lines):
    lineno = i + 1
    s = line.strip()
    if s.startswith("#"):
        continue
    m = CALLV_RE.match(line)
    if not m:
        continue
    varname = m.group(1)
    # If the method name is a LITERAL string (not a variable), it's fine
    # A variable callv is dangerous without has_method() guard
    if re.match(r'^"', varname):
        continue  # literal — safe
    # Check preceding ~5 lines for has_method guard
    context = "\n".join(lines[max(0,i-5):i])
    if "has_method" in context:
        continue
    violations.append({
        "rule":   "UNCHECKED_CALLV",
        "line":   lineno,
        "text":   s,
        "detail": "callv(%s, ...) without has_method(%s) guard" % (varname, varname),
    })

# ── rule 7: direct builder calls from _build_world_async ─────────────────────

DIRECT_BUILD_RE = re.compile(r"^\t\t(_build_|_scatter_|_init_|_spawn_)(\w+)\s*\(")
for i, line in enumerate(lines):
    lineno = i + 1
    s = line.strip()
    if s.startswith("#"):
        continue
    if not in_async_func(i):
        continue
    m = DIRECT_BUILD_RE.match(line)
    if m:
        # Make sure it's not already inside a _safe_call_now call
        violations.append({
            "rule":   "MISSING_SAFE_CALL_NOW",
            "line":   lineno,
            "text":   s,
            "detail": "direct call to %s%s() in _build_world_async — use _safe_call_now()" % (
                      m.group(1), m.group(2)),
        })

# ── report ────────────────────────────────────────────────────────────────────

RULE_DOCS = {
    "ORPHAN_GLOBAL_POSITION": "Add add_child() BEFORE .global_position, or use .position",
    "ASSERT_IN_BUILDER":      "Replace assert() with if+push_error()+return",
    "UNGUARDED_LOAD":         "Add 'if x == null: push_error(...); return' after load()",
    "ARRAY_OOB_CONSTANT":     "Guard with 'if arr.size() > N:' before arr[N]",
    "UNCHECKED_CALLV":        "Add 'if has_method(name):' before callv()",
    "MISSING_SAFE_CALL_NOW":  "Wrap in _safe_call_now('_build_foo', []) instead of direct call",
}

if violations:
    # Group by rule
    by_rule = {}
    for v in violations:
        by_rule.setdefault(v["rule"], []).append(v)

    print("=" * 72)
    print("BLANK-WORLD AUDIT: %d violation(s) found" % len(violations))
    print("=" * 72)
    for rule, items in by_rule.items():
        print("\n[%s] — %d occurrence(s)" % (rule, len(items)))
        print("  Fix: " + RULE_DOCS[rule])
        for v in items[:10]:  # cap at 10 per rule to avoid wall of text
            print("  Line %5d: %s" % (v["line"], v["text"][:80]))
            print("             → %s" % v["detail"][:100])
        if len(items) > 10:
            print("  ... and %d more" % (len(items) - 10))
    print()
    sys.exit(1)

print("Blank-world audit v2 passed — no coroutine-killing patterns found. (%d lines checked)" % total)
