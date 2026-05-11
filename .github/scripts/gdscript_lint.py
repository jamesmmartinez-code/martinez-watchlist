#!/usr/bin/env python3
"""
gdscript_lint.py — catch common GDScript 4 regressions before Godot sees them.
Fails CI if any of these patterns are found in .gd files:
  1. C-style ternary:  expr ? val : val
  2. Array[Node3D] assigned from get_nodes_in_group() or get_children()
     (these return Array[Node] / untyped Array; causes type inference error)
Exit 0 = clean. Exit 1 = violations found.
"""
import sys, re, pathlib

ROOT = pathlib.Path("eldoria-godot/scripts")
violations = []

# Pattern 1: C-style ternary — any "? val : val" not inside a string/comment
# Heuristic: line contains " ? " and " : " and is not a comment and not a type hint
TERNARY = re.compile(r'(?<!["\'])(?<!\w)\?\s+')

# Pattern 2: Array[Node3D] (or Array[Node]) typed var assigned from group/children call
TYPED_ARRAY_NODE = re.compile(r'var\s+\w+\s*:\s*Array\[Node3?D?\]')

for gd in sorted(ROOT.rglob("*.gd")):
    lines = gd.read_text(errors="replace").split("\n")
    for lineno, raw in enumerate(lines, 1):
        stripped = raw.strip()
        if stripped.startswith("#"):
            continue
        # Remove inline comments (rough)
        code = re.sub(r'#.*$', '', raw)
        # C-style ternary check
        if ' ? ' in code and ' : ' in code:
            # Skip if it looks like a dictionary literal key:value
            if not re.search(r'["\w)]\s*\?\s*[\w"(+-]', code):
                pass
            else:
                violations.append((str(gd), lineno, "C-STYLE-TERNARY", raw.rstrip()))
        # Array[Node3D] / Array[Node] typed assignment
        if TYPED_ARRAY_NODE.search(code):
            violations.append((str(gd), lineno, "TYPED-ARRAY-NODE", raw.rstrip()))

if violations:
    print(f"\n=== GDScript Lint: {len(violations)} violation(s) found ===")
    for path, lineno, kind, line in violations:
        print(f"  {path}:{lineno} [{kind}]")
        print(f"    {line}")
    print("\nFix these before pushing. See ELDORIA_STATUS.md for how-to.")
    sys.exit(1)
else:
    print("GDScript lint: CLEAN")
    sys.exit(0)
