#!/usr/bin/env python3
"""
gdscript_autofix.py — auto-fix deterministic GDScript 4 indentation issues.

Safe to run unconditionally. Only modifies lines where it can be certain
the fix is correct. Currently handles:

  - Mixed tabs/spaces: if a line's leading whitespace contains BOTH \t and
    spaces, the spaces are stripped (they're alignment spaces after block
    tabs, not block-level indentation).

Does NOT attempt to fix:
  - C-style ternaries (need semantic understanding)
  - lerp() type inference (need variable type context)
  - Autoload default params (need project config)
  - C++ comments (ambiguous in some contexts)

Prints a summary of changes made.
"""
import re, pathlib, sys

ROOT = pathlib.Path("eldoria-godot")
MIXED_INDENT = re.compile(r'^(\t+) +')   # tabs followed by spaces at line start

fixed_files = 0
fixed_lines = 0

for gd in sorted(ROOT.rglob("*.gd")):
    original = gd.read_text(errors="replace")
    lines = original.split("\n")
    new_lines = []
    file_changed = False
    for lineno, line in enumerate(lines, 1):
        fixed = MIXED_INDENT.sub(r'\1', line)
        if fixed != line:
            file_changed = True
            fixed_lines += 1
        new_lines.append(fixed)
    if file_changed:
        gd.write_text("\n".join(new_lines))
        fixed_files += 1
        print(f"  fixed: {gd}")

if fixed_files:
    print(f"\nauto-fix: {fixed_lines} lines in {fixed_files} files normalized to pure tabs")
else:
    print("auto-fix: nothing to change")