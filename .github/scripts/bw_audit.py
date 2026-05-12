#!/usr/bin/env python3
"""
Blank-world audit: scans WorldBuilder.gd for Node3D.new() followed by
.global_position before add_child(). That pattern silently aborts the
async build coroutine in Godot 4, producing a blank world (grass only).
"""
import re, pathlib, sys

GD = pathlib.Path("eldoria-godot/scripts/WorldBuilder.gd")
if not GD.exists():
    print("WorldBuilder.gd not found - skipping audit")
    sys.exit(0)

lines = GD.read_text(errors="replace").splitlines()

NODE_RE = re.compile(r"^\s*var\s+(\w+)\s*(?::[^=]*)?\s*:?=\s*[\w\.]+\.new\(\)")
GP_RE   = re.compile(r"^\s*(\w+)\.global_position\s*=")
AC_RE   = re.compile(r"add_child\s*\(\s*(\w+)")
NODE_TYPES = {
    "Node3D", "MeshInstance3D", "CSGBox3D", "CSGSphere3D", "StaticBody3D",
    "CollisionShape3D", "OmniLight3D", "SpotLight3D", "Area3D",
    "GPUParticles3D", "CPUParticles3D", "AnimatedSprite3D", "Label3D",
}

orphans = {}
violations = []

for i, line in enumerate(lines, 1):
    s = line.strip()
    if s.startswith("#"):
        continue
    if s.startswith("func "):
        orphans = {}
    m = NODE_RE.match(line)
    if m and (any(t in line for t in NODE_TYPES) or "3D" in line or "Instance" in line):
        orphans[m.group(1)] = i
    m2 = AC_RE.search(line)
    if m2:
        orphans.pop(m2.group(1), None)
    m3 = GP_RE.match(line)
    if m3 and m3.group(1) in orphans:
        violations.append((i, m3.group(1), orphans[m3.group(1)], line.strip()))

if violations:
    print("BLANK-WORLD BUG: %d orphan .global_position assignment(s)" % len(violations))
    for ln, v, c, t in violations:
        print("  Line %d: %s  (var created line %d, add_child not yet called)" % (ln, t, c))
    print("Fix: call add_child() BEFORE .global_position, or use .position on orphan nodes.")
    sys.exit(1)

print("Blank-world audit passed - no orphan global_position assignments.")
