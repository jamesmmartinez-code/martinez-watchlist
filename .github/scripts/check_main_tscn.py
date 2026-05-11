#!/usr/bin/env python3
"""
Eldoria visual bounds checker — runs in CI before Godot import.
Parses Main.tscn, validates against qa/_visual_constraints.yaml.
Exits 1 with a clear message on the first violation.
Created 2026-05-07 after giant-boot + fog-soup incidents.
"""
import re, sys, os, json, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
TSCN = ROOT / "eldoria-godot" / "scenes" / "Main.tscn"
CONSTRAINTS = ROOT / "eldoria-godot" / "qa" / "_visual_constraints.yaml"

def parse_yaml_simple(path):
    """Tiny indent-based YAML parser — avoids needing PyYAML in CI."""
    out = {}
    stack = [out]
    indents = [-1]
    for raw in path.read_text().splitlines():
        line = raw.split("#",1)[0].rstrip()
        if not line.strip(): continue
        indent = len(line) - len(line.lstrip())
        while indents and indent <= indents[-1]:
            stack.pop(); indents.pop()
        key, _, val = line.strip().partition(":")
        key = key.strip(); val = val.strip()
        target = stack[-1]
        if val == "":
            target[key] = {}; stack.append(target[key]); indents.append(indent)
        else:
            try: target[key] = float(val) if "." in val else int(val)
            except ValueError: target[key] = val
    return out

def main():
    if not TSCN.exists():
        print(f"FATAL: {TSCN} not found"); sys.exit(2)
    if not CONSTRAINTS.exists():
        print(f"FATAL: {CONSTRAINTS} not found"); sys.exit(2)

    c = parse_yaml_simple(CONSTRAINTS)
    text = TSCN.read_text(errors="replace")
    errors = []

    # === fog_density ===
    m = re.search(r"^fog_density\s*=\s*([0-9.]+)", text, re.M)
    if m:
        v = float(m.group(1))
        mx = c["world_environment"]["fog_density_max"]
        if v > mx:
            errors.append(f"fog_density = {v} > MAX {mx} (brown-haze territory)")

    # === volumetric_fog_density ===
    m = re.search(r"^volumetric_fog_density\s*=\s*([0-9.]+)", text, re.M)
    if m:
        v = float(m.group(1))
        mx = c["world_environment"]["volumetric_fog_density_max"]
        if v > mx:
            errors.append(f"volumetric_fog_density = {v} > MAX {mx}")

    # === volumetric_fog_emission_energy ===
    m = re.search(r"^volumetric_fog_emission_energy\s*=\s*([0-9.]+)", text, re.M)
    if m:
        v = float(m.group(1))
        mx = c["world_environment"]["volumetric_fog_emission_energy_max"]
        if v > mx:
            errors.append(f"volumetric_fog_emission_energy = {v} > MAX {mx}")

    # === Hero scale ===
    # Walk transform lines AFTER a "[node name="Hero"" header
    # Scale is the magnitude of column-0 of the basis (handles rotation+scale matrices correctly).
    hero_block = re.search(r'\[node name="Hero".*?(?=\[node )', text, re.S)
    if hero_block:
        block = hero_block.group(0)
        # Transform3D(xx, xy, xz, yx, yy, yz, zx, zy, zz, tx, ty, tz)
        tm = re.search(r"transform\s*=\s*Transform3D\(\s*([\-0-9.e]+)\s*,\s*([\-0-9.e]+)\s*,\s*([\-0-9.e]+)", block)
        if tm:
            import math
            xx, xy, xz = float(tm.group(1)), float(tm.group(2)), float(tm.group(3))
            sx = math.sqrt(xx*xx + xy*xy + xz*xz)  # column-0 magnitude = uniform scale
            mn, mx = c["hero"]["scale_min"], c["hero"]["scale_max"]
            if sx < mn or sx > mx:
                errors.append(f"Hero scale.x = {sx:.3f} OUT OF BOUNDS [{mn}, {mx}] — this is the giant-boot/invisible-hero bug class")

    if errors:
        print("=" * 60)
        print("VISUAL BOUNDS CHECK FAILED")
        print("=" * 60)
        for e in errors: print(f"  ✗ {e}")
        print()
        print(f"Constraints: {CONSTRAINTS.relative_to(ROOT)}")
        print(f"Scene file:  {TSCN.relative_to(ROOT)}")
        print()
        print("If a bound is wrong, edit qa/_visual_constraints.yaml and explain why.")
        print("If the .tscn value is wrong, fix the .tscn.")
        sys.exit(1)

    print("✓ Visual bounds OK (fog, vol-fog, hero scale)")

if __name__ == "__main__":
    main()
