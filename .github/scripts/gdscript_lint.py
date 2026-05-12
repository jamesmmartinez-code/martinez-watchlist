#!/usr/bin/env python3
"""
gdscript_lint.py — catch GDScript 4 regressions before Godot sees them.
Scans every .gd file under eldoria-godot/ (recursively, excluding addons/).

Patterns checked:
  1. C-style ternary        — expr ? a : b  (must be: a if expr else b)
  2. Array[Node3D] typed var — var x: Array[Node3D] = ...
  3. var := lerp() inference — var x := lerp(...)  (lerp returns Variant; must be var x: float = ...)
  4. Autoload in default param — func f(x = SomeAutoload.CONST)
  5. Mixed tabs/spaces       — leading whitespace contains both \t and space
  6. C++ comments            — // at start of non-string content
  7. var x: Vector3 = Transform3D() — wrong type annotation
  8. var x: float = Basis()         — Basis is not a float
  9. var x: float = vec.lerp()      — lerp on Vector3 returns Vector3
 10. var x: float = vec + dir * ... — vector arithmetic stored as float
 11. Transform3D(float, Vector3)    — wrong constructor (needs Basis, Vector3)
 12. var x: Vector3 = Basis.looking_at() — returns Basis
 13. var x: Vector3 = _make_*()    — maker funcs return Node3D
 14. var x: float = plaza/market   — these are Vector3
 15. var x: int = hubs[...]        — Array[Vector3] element is Vector3
 16. var x: float = "string"       — string stored as float
 17. var x := CONST_ARRAY[i]       — ALL_CAPS typed array element; needs explicit type
 18. var x := dict[key]            — dict lookup returns Variant; needs explicit type
 19. var x: Vector3 = x.dot(...)      — .dot() returns float, not Vector3
     (only flagged when no trailing 'as TypeName' cast, and var name suggests dict not typed array)

Exit 0 = clean. Exit 1 = violations found (CI blocks the push).
"""
import sys, re, pathlib

ROOT = pathlib.Path("eldoria-godot/scripts")
violations = []

# Autoload names registered in project.godot that must not appear in default params
KNOWN_AUTOLOADS = {"ScaleUtils", "EventBus", "GameBrain", "WorldState", "Items"}

for gd in sorted(ROOT.rglob("*.gd")):
    raw_text = gd.read_text(errors="replace")
    lines = raw_text.split("\n")
    for lineno, raw in enumerate(lines, 1):
        stripped = raw.strip()
        # Skip pure comment lines
        if stripped.startswith("#"):
            continue
        # Remove inline comments for pattern matching
        code = re.sub(r'(?<!:)#.*$', '', raw)

        # 1. C-style ternary: has " ? " and " : " and is not a GDScript dict
        if ' ? ' in code and ' : ' in code:
            # Exclude lines that look like type hints (-> Type:) or dict keys
            if re.search(r'\w\s*\?\s*[\w"(]', code) and '->' not in code:
                violations.append((str(gd), lineno, "C-STYLE-TERNARY", raw.rstrip()))

        # 2. Array[Node3D] typed variable
        if re.search(r'var\s+\w+\s*:\s*Array\[Node3D\]', code):
            violations.append((str(gd), lineno, "TYPED-ARRAY-NODE3D", raw.rstrip()))

        # 3. var := lerp() — Variant inference failure
        if re.search(r'\bvar\s+\w+\s*:=\s*lerpf?\s*\(', code):
            violations.append((str(gd), lineno, "LERP-TYPE-INFERENCE", raw.rstrip()))

        # 4. Autoload name used as default parameter value
        for al in KNOWN_AUTOLOADS:
            if re.search(rf'func\s+\w+\s*\(.*=\s*{al}\.', code):
                violations.append((str(gd), lineno, "AUTOLOAD-IN-DEFAULT-PARAM", raw.rstrip()))

        # 5. Mixed tabs/spaces in leading whitespace
        leading = re.match(r'^(\s+)', raw)
        if leading:
            ws = leading.group(1)
            if '\t' in ws and ' ' in ws:
                violations.append((str(gd), lineno, "MIXED-INDENT", raw.rstrip()[:120]))

        # 6. C++ style comment at line start (not inside string)
        if re.match(r'\s*//', raw) and not re.match(r'\s*#', raw):
            violations.append((str(gd), lineno, "CPP-COMMENT", raw.rstrip()))

        # 7. var x: Vector3 = Transform3D(...) — wrong type annotation
        if re.search(r'var\s+\w+\s*:\s*Vector3\s*=\s*Transform3D\(', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-T3D-AS-V3", raw.rstrip()))

        # 8. var x: float = Basis(...) — Basis is not a float
        if re.search(r'var\s+\w+\s*:\s*float\s*=\s*Basis\(', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-BASIS-AS-FLOAT", raw.rstrip()))

        # 9. var x: float = <vec>.lerp(...) — lerp on Vector3 returns Vector3, not float
        if re.search(r'var\s+\w+\s*:\s*float\s*=\s*\w+\.lerp\(', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-LERP-FLOAT", raw.rstrip()))

        # 10. var x: (float|int) = <name> + <vector_component> * — vector arithmetic stored as float
        if re.search(r'var\s+\w+\s*:\s*(float|int)\s*=\s*\w+\s*[\+\-]\s*(side|dir|road_dir|forward|back|outward|facing)\s*\*', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-VEC-AS-FLOAT", raw.rstrip()))

        # 11. Transform3D(float, Vector3(...)) — wrong constructor (should be Transform3D(Basis, Vector3))
        if re.search(r'Transform3D\(\s*[\d\w\.]+\s*,\s*Vector3\(', code) and 'Basis' not in code:
            violations.append((str(gd), lineno, "T3D-WRONG-CONSTRUCTOR", raw.rstrip()))

        # 12. var x: Vector3 = Basis.looking_at(...) — looking_at returns Basis, not Vector3
        if re.search(r'var\s+\w+\s*:\s*Vector3\s*=\s*Basis\.looking_at\(', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-BASIS-AS-V3", raw.rstrip()))

        # 13. var x: Vector3 = _make_*/  _box_prop() — these return Node3D, not Vector3
        if re.search(r'var\s+\w+\s*:\s*Vector3\s*=\s*(_make_|_box_prop|_bw_build)\w*\(', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-NODE3D-AS-V3", raw.rstrip()))

        # 14. var x: (float|int) = plaza/market/craft/gate — these are Vector3, not scalars
        if re.search(r'var\s+\w+\s*:\s*(float|int)\s*=\s*(plaza|market|craft|gate)', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-VEC3-AS-SCALAR", raw.rstrip()))

        # 15. var x: int = hubs[...] — hubs is Array[Vector3], index returns Vector3
        if re.search(r'var\s+\w+\s*:\s*int\s*=\s*\w+\[', code):
            # only flag if it's on a known Vector3 array
            if re.search(r'var\s+\w+\s*:\s*int\s*=\s*(hubs|pts|points|nodes)\[', code):
                violations.append((str(gd), lineno, "TYPE-MISMATCH-VEC3-ARRAY-AS-INT", raw.rstrip()))

        # 16. var x: float = "..." or var x: float = _NAME_ — string stored as float
        if re.search(r'var\s+\w+\s*:\s*float\s*=\s*"', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-STRING-AS-FLOAT", raw.rstrip()))
        if re.search(r'var\s+\w+\s*:\s*float\s*=\s*_NAME_', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-STRING-AS-FLOAT", raw.rstrip()))

        # 17. var x := ALL_CAPS_ARRAY[i] — typed array element lookup on a const returns Variant
        # Only flag ALL_CAPS identifiers (class-level constants). Skip if followed by 'as TypeName'.
        if re.search(r'var\s+\w+\s*:=\s*[A-Z][A-Z_]{2,}\[', code):
            if not re.search(r'\bas\s+\w', code):  # 'as TypeName' cast makes it safe
                violations.append((str(gd), lineno, "VARIANT-INFER-CONST-ARRAY", raw.rstrip()))

        # 18. var x := dict[key] — dict subscript lookup returns Variant; needs explicit type
        # Only flag when:
        #   - subscript variable name ends in _batches/_data/_map/_cache/_table (dict-looking names)
        #   - OR the subscripted name is a known dict-holding member variable
        #   - AND line has no trailing 'as TypeName' cast
        if re.search(r'var\s+\w+\s*:=\s*(\w+)\[', code):
            match = re.search(r'var\s+\w+\s*:=\s*(\w+)\[', code)
            dict_var = match.group(1) if match else ""
            is_known_dict = bool(re.search(
                r'(_batches|_data|_map|_cache|_table|_registry|_index|_lookup|_store|loaded_chunks)$',
                dict_var
            ))
            has_cast = bool(re.search(r'\bas\s+\w', code))
            if is_known_dict and not has_cast:
                violations.append((str(gd), lineno, "VARIANT-INFER-DICT-LOOKUP", raw.rstrip()))


        # 19. var x: Vector3 = something.dot(...) — .dot() returns float, not Vector3
        if re.search(r'var\s+\w+\s*:\s*Vector3\s*=.*\.dot\s*\(', code):
            violations.append((str(gd), lineno, "TYPE-MISMATCH-DOT-AS-V3", raw.rstrip()))


# Bonus: var x := VARIANT_FUNC(...) — Variant inference error
# These functions return Variant in GDScript 4 strict mode
VARIANT_RETURNING = re.compile(
    r'var\s+\w+\s*:=\s*(?:lerp|smoothstep|randf_range|randf|snapped|clamp|sqrt|fmod|'
    r'floor|ceil|round|distance_to|dot|length|lerpf|inverse_lerp|wrapf|pingpong|'
    r'randi_range|randi)\s*\('
)

for gd in sorted(ROOT.rglob("*.gd")):
    lines = gd.read_text(errors="replace").split("\n")
    for lineno, raw in enumerate(lines, 1):
        stripped = raw.strip()
        if stripped.startswith("#"):
            continue
        code = re.sub(r'#.*$', '', raw)
        if VARIANT_RETURNING.search(code):
            violations.append((str(gd), lineno, "VARIANT-INFER", raw.rstrip()))

if violations:
    print(f"\n=== GDScript Lint: {len(violations)} violation(s) ===")
    for path, lineno, kind, line in violations:
        print(f"  {path}:{lineno}  [{kind}]")
        print(f"    {line[:120]}")
    print(f"\n{len(violations)} error(s). Fix before pushing.")
    print("See ELDORIA_STATUS.md -> 'How to Fix Recurring Errors'.")
    sys.exit(1)
else:
    print(f"GDScript lint: CLEAN ({sum(1 for _ in ROOT.rglob('*.gd'))} files)")
    sys.exit(0)
