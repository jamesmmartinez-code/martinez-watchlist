extends Node3D
class_name WorldBuilder
# Procedurally builds Briarwood Village with REAL PBR textures (PolyHaven CC0).
# Houses, timber-framed walls, thatched/tiled roofs, bark trees, mountain rock
# faces with snow caps, cobble paths, market stalls, lanterns, banners, NPCs.

@export var npc_scene: PackedScene = preload("res://assets/models/CesiumMan.glb")
@export var npc_script: Script = preload("res://scripts/NPC.gd")

var _buildings_built: bool = false

# ─── PBR material cache ──────────────────────────────────────────────────────
var _mat_cache: Dictionary = {}

func _pbr_mat(albedo_path: String, normal_path: String = "", rough_path: String = "",
		uv_scale: Vector3 = Vector3(1, 1, 1), tint: Color = Color(1, 1, 1)) -> StandardMaterial3D:
	var key := albedo_path + "|" + normal_path + "|" + rough_path + "|" + str(uv_scale) + "|" + str(tint)
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(albedo_path):
		m.albedo_texture = load(albedo_path)
	m.albedo_color = tint
	if normal_path != "" and ResourceLoader.exists(normal_path):
		m.normal_enabled = true
		m.normal_texture = load(normal_path)
		m.normal_scale = 1.0
	if rough_path != "" and ResourceLoader.exists(rough_path):
		m.roughness_texture = load(rough_path)
	else:
		m.roughness = 0.85
	m.uv1_scale = uv_scale
	m.metallic = 0.0
	m.metallic_specular = 0.4
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mat_cache[key] = m
	return m

# Convenience accessors
func MAT_GRASS(uv := 30.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/grass/grass_diff.jpg",
		"res://assets/textures/grass/grass_norm.jpg",
		"res://assets/textures/grass/grass_rough.jpg",
		Vector3(uv, uv, 1))

func MAT_WOOD(uv := 1.5) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/wood/wood_diff.jpg",
		"res://assets/textures/wood/wood_norm.jpg",
		"res://assets/textures/wood/wood_rough.jpg",
		Vector3(uv, uv, 1), Color(0.85, 0.66, 0.45))

func MAT_DARK_WOOD(uv := 1.5) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/wood/wood_diff.jpg",
		"res://assets/textures/wood/wood_norm.jpg",
		"res://assets/textures/wood/wood_rough.jpg",
		Vector3(uv, uv, 1), Color(0.35, 0.22, 0.13))

func MAT_ROOF(uv := 2.5) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/thatch/shingle_diff.jpg",
		"res://assets/textures/thatch/shingle_norm.jpg",
		"",
		Vector3(uv, uv, 1), Color(0.7, 0.42, 0.32))

func MAT_STONE(uv := 2.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/stone/stone_diff.jpg",
		"res://assets/textures/stone/stone_norm.jpg",
		"res://assets/textures/stone/stone_rough.jpg",
		Vector3(uv, uv, 1))

func MAT_BARK(uv := 2.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/bark/bark_diff.jpg",
		"res://assets/textures/bark/bark_norm.jpg",
		"",
		Vector3(uv, uv, 1))

func MAT_ROCK(uv := 1.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/rock/rock_diff.jpg",
		"res://assets/textures/rock/rock_norm.jpg",
		"",
		Vector3(uv, uv, 1))

func MAT_SNOW(uv := 1.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/snow/snow_diff.jpg",
		"res://assets/textures/snow/snow_norm.jpg",
		"",
		Vector3(uv, uv, 1), Color(0.95, 0.96, 1.0))

func MAT_LEAF(tint: Color) -> StandardMaterial3D:
	# Stylized leaves — slight subsurface look
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = 0.78
	m.metallic = 0.0
	# Simulate sub-surface scattering with rim emission
	m.rim_enabled = true
	m.rim = 0.4
	m.rim_tint = 0.6
	return m

# ─── Village NPCs ────────────────────────────────────────────────────────────
# REFINE: each NPC now carries 4 mood-dependent dialogue variants
# (morning / midday / evening / night). The single `line` is kept as a
# fallback for systems that haven't been taught the variant lookup yet.
# Personality details: Maeve fears the wolves, Edda wishes the dew lasted,
# Mara grudges miscounters, Lyra remembers her mother's garden, Bram has a
# catchphrase about three valleys, Roan trusts horses over men, Hala says
# strength is loud and mastery is quiet.
const NPCS = [
	{"name":"Elder Maeve",       "role":"quest",   "pos":Vector3(  6,  0,  3), "tint":Color(0.6,0.4,0.85),
	 "line":"Trouble brews in the Whisperwood. Seek out the Goblin Warlord.",
	 "lines":[
		"Ah, traveler. Trouble brews in the Whisperwood — seek out the Goblin Warlord.",
		"You smell of pine. Good. Goblins do not. Mind the Warlord.",
		"I sleep poorly when wolves howl. I hope your blade keeps mine quiet.",
		"You should be inside. Even my whispers travel further after dark.",
	 ]},
	{"name":"Smith Edda",        "role":"smithy",  "pos":Vector3( -6,  0,  3), "tint":Color(0.7,0.25,0.18),
	 "line":"Bring me ore and I'll forge you a blade.",
	 "lines":[
		"Bring me ore. I forge best when the dew's still on the iron.",
		"*hammer-clang* — Steel won't shape itself. Got ore, or just standing there?",
		"Forge cools by sundown. Last orders, friend.",
		"Coals are banked. Come back when you've slept.",
	 ]},
	{"name":"Mara the Merchant", "role":"shop",    "pos":Vector3(  3,  0, -5), "tint":Color(0.7,0.5,0.25),
	 "line":"There's a bounty on goblin raiders — bring me proof of six and I'll pay handsome.",
	 "lines":[
		"Six goblin ears, that's the bounty. I keep tally; I never miscount. Never.",
		"Trade me proof of six raiders and you'll walk out richer than you walked in.",
		"Hurry — I count my coin twice before bed and I dislike being interrupted.",
		"Shop's shut. Knock again at sunrise unless your purse has wings.",
	 ]},
	{"name":"Herbalist Lyra",    "role":"alchemy", "pos":Vector3( -3,  0, -5), "tint":Color(0.4,0.7,0.35),
	 "line":"I need 4 wolf pelts for a healing salve. Bring them, and the salve is yours.",
	 "lines":[
		"Four wolf pelts for a healing salve — wolves are bolder at dawn, mind.",
		"Smell that? Marshmint. Brings me back to my mother's garden — long lost now.",
		"Bring me pelts before the moss closes. It only opens by daylight.",
		"Owls are louder than wolves tonight. Bad sign. Travel close to lanterns.",
	 ]},
	{"name":"Innkeeper Bram",    "role":"inn",     "pos":Vector3( 10,  0, -2), "tint":Color(0.8,0.55,0.30),
	 "line":"Pull up a stool. Rest your bones.",
	 "lines":[
		"*polishes a mug* — Stew's on. Pull up a stool, rest your bones.",
		"Bards lie about half their songs. The other half are mine.",
		"Best ale in three valleys. The other two valleys have no ale, mind.",
		"Bed's warm. Fire's banked. Stay if you've nowhere safer.",
	 ]},
	{"name":"Stablemaster Roan", "role":"stable",  "pos":Vector3(-10,  0, -2), "tint":Color(0.55,0.45,0.25),
	 "line":"Faster mounts mean fewer ambushes. Pick your steed.",
	 "lines":[
		"Faster mounts, fewer ambushes. Pick your steed before sun's up.",
		"I trust my horses more than most men. They've never lied to me.",
		"Sun's down — saddle up only if your errand can't wait.",
		"Riding by moonlight? Bold. Or fool. Or both. Take the gray mare.",
	 ]},
	{"name":"Trainer Hala",      "role":"trainer", "pos":Vector3(  0,  0, -10), "tint":Color(1.0,0.65,0.20),
	 "line":"Each level, your spirit grows. Pour it into what you trust.",
	 "lines":[
		"Each level, your spirit grows. Pour it into what you trust.",
		"Strength is loud. Mastery is quiet. Choose.",
		"Tired? Train tired. The road won't ask if you slept.",
		"Even shadow needs practice. Feet on the boards, breathe.",
	 ]},
]

const BUILDINGS = [
	Vector3( 6, 0,  6), Vector3(-6, 0,  6),
	Vector3(10, 0,  0), Vector3(-10, 0,  0),
	Vector3( 6, 0, -8), Vector3(-6, 0, -8),
]

func _ready() -> void:
	if _buildings_built: return
	_buildings_built = true
	_build_ground_overlay()
	_build_path_network()
	_build_village()
	_scatter_trees(140)
	_scatter_rocks(36)
	_build_mountain_ring()
	_build_market_stalls()
	_build_windmill()
	_build_lanterns()
	_build_banners()
	_build_npcs()
	_build_grass_tufts(220)
	_build_well()
	_build_pond()
	_build_firefly_particles()
	_build_smoke_chimneys()
	_build_campfire()
	_build_enemies()
	_build_pet()
	_build_loot_chests()
	_build_crystal_caves(Vector3(-50, 0, -40))

# ============================================================================
# A textured ground patch is added on TOP of the existing flat ground so the
# Main.tscn ground stays as a collider while we get a real PBR look.
# ============================================================================
func _build_ground_overlay() -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(220, 220)
	pm.subdivide_width = 80
	pm.subdivide_depth = 80
	ground.mesh = pm
	ground.material_override = MAT_GRASS(40)
	ground.position.y = 0.01  # avoid z-fighting with the existing ground
	ground.name = "GroundPBR"
	add_child(ground)

# ============================================================================
# Cobble paths between buildings — a few intersecting plane strips
# ============================================================================
func _build_path_network() -> void:
	var paths = [
		{"from": Vector3(-12, 0, 0),  "to": Vector3(12, 0, 0),  "w": 1.6},
		{"from": Vector3(0, 0, -12),  "to": Vector3(0, 0, 12),  "w": 1.6},
		{"from": Vector3(-9, 0, -8),  "to": Vector3(9, 0, -8),  "w": 1.2},
		{"from": Vector3(-9, 0,  8),  "to": Vector3(9, 0,  8),  "w": 1.2},
	]
	for p in paths:
		var dir = p.to - p.from
		var length = dir.length()
		var center = (p.from + p.to) * 0.5
		var path := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(p.w, length)
		path.mesh = pm
		path.material_override = MAT_STONE(length / 2)
		path.position = center + Vector3(0, 0.02, 0)
		path.rotation.y = atan2(dir.x, dir.z)
		path.name = "Path"
		add_child(path)

# ============================================================================
# Buildings — timber-framed wood walls, shingled roof, lit window, chimney
# ============================================================================
func _build_village() -> void:
	for pos in BUILDINGS:
		_make_building(pos)

func _make_building(pos: Vector3) -> void:
	var house := Node3D.new()
	house.position = pos
	house.add_to_group("buildings")
	add_child(house)

	# Stone foundation (1m tall around the base)
	var foundation := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(4.0, 0.5, 4.0)
	foundation.mesh = fm
	foundation.material_override = MAT_STONE(2)
	foundation.position.y = 0.25
	house.add_child(foundation)

	# Walls (wood planks)
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(3.6, 2.6, 3.6)
	wall.mesh = wall_mesh
	wall.material_override = MAT_WOOD(2)
	wall.position.y = 1.3 + 0.5
	house.add_child(wall)

	# Wall collision so player can't walk through
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.6, 3.1, 3.6)
	col.shape = box
	col.position.y = 1.55
	body.add_child(col)
	house.add_child(body)

	# Corner timber beams (dark wood)
	for dx in [-1.7, 1.7]:
		for dz in [-1.7, 1.7]:
			var beam := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.22, 2.6, 0.22)
			beam.mesh = bm
			beam.material_override = MAT_DARK_WOOD(0.5)
			beam.position = Vector3(dx, 1.3 + 0.5, dz)
			house.add_child(beam)
	# Horizontal cross beams
	for dy in [0.5 + 0.6, 0.5 + 1.6, 0.5 + 2.5]:
		for dx in [0.0]:
			for dz in [-1.81, 1.81]:
				var crossbeam := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(3.6, 0.16, 0.16)
				crossbeam.mesh = bm
				crossbeam.material_override = MAT_DARK_WOOD(0.5)
				crossbeam.position = Vector3(dx, dy, dz)
				house.add_child(crossbeam)

	# Eave
	var eave := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(4.0, 0.18, 4.0)
	eave.mesh = em
	eave.material_override = MAT_DARK_WOOD(0.5)
	eave.position.y = 3.18
	house.add_child(eave)

	# Roof — pyramid (tiled shingle)
	var roof := MeshInstance3D.new()
	var pyr := PrismMesh.new()
	pyr.left_to_right = 0.5
	pyr.size = Vector3(4.4, 1.9, 4.4)
	roof.mesh = pyr
	roof.material_override = MAT_ROOF(2.0)
	roof.position.y = 4.13
	house.add_child(roof)

	# Window with warm light
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.95, 0.6, 0.25)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.7, 0.3)
	win_mat.emission_energy_multiplier = 1.2
	win_mat.metallic = 0.0
	win_mat.roughness = 0.4
	var win := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.7, 0.6)
	win.mesh = qm
	win.material_override = win_mat
	win.position = Vector3(0, 2.1, 1.81)
	house.add_child(win)

	# Window frame
	var fr_mat := MAT_DARK_WOOD(0.4)
	for off in [Vector2(-0.4, 0), Vector2(0.4, 0), Vector2(0, 0.35), Vector2(0, -0.35)]:
		var f := MeshInstance3D.new()
		var fm2 := BoxMesh.new()
		if abs(off.x) > 0:
			fm2.size = Vector3(0.06, 0.7, 0.05)
		else:
			fm2.size = Vector3(0.85, 0.06, 0.05)
		f.mesh = fm2
		f.material_override = fr_mat
		f.position = Vector3(off.x, 2.1 + off.y, 1.83)
		house.add_child(f)

	# Door
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.9, 1.6, 0.08)
	door.mesh = dm
	door.material_override = MAT_DARK_WOOD(0.6)
	door.position = Vector3(-1.0, 1.3, 1.85)
	house.add_child(door)

	# Chimney
	var chim := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.5, 1.5, 0.5)
	chim.mesh = cm
	chim.material_override = MAT_STONE(1)
	chim.position = Vector3(1.2, 4.6, 1.0)
	chim.name = "Chimney"
	house.add_child(chim)

# ============================================================================
# Trees — bark-textured trunk + multi-tier stylized foliage with rim lighting
# ============================================================================
func _scatter_trees(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(18, 70)
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		_make_tree(pos, rng)

func _make_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var tree := Node3D.new()
	tree.position = pos
	tree.rotation.y = rng.randf() * TAU
	tree.add_to_group("trees")
	add_child(tree)
	var h := rng.randf_range(0.85, 1.7)

	# Trunk with bark texture
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.28; tm.bottom_radius = 0.46
	tm.height = 1.8 * h
	trunk.mesh = tm
	trunk.material_override = MAT_BARK(2.0)
	trunk.position.y = (1.8 * h) / 2
	tree.add_child(trunk)

	# Tree collision
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.55; cyl.height = 1.8 * h
	col.shape = cyl
	col.position.y = (1.8 * h) / 2
	body.add_child(col)
	tree.add_child(body)

	# Foliage — irregular cluster of jittered spheres around a central crown.
	# This avoids the obvious cone-stack look. Each tree gets 12-18 small leaf
	# blobs at random positions inside an oblate ellipsoid centered on the crown.
	var base_h: float = rng.randf_range(0.30, 0.46)
	var leaf_palette = [
		Color(base_h - 0.08, 0.38 + rng.randf() * 0.10, 0.14),
		Color(base_h - 0.02, 0.48 + rng.randf() * 0.10, 0.18),
		Color(base_h + 0.02, 0.42 + rng.randf() * 0.10, 0.20),
		Color(base_h + 0.06, 0.32 + rng.randf() * 0.10, 0.12),
	]
	var crown_y: float = 1.8 * h + 1.4 * h
	var crown_radius_x: float = 1.6 * h
	var crown_radius_y: float = 1.2 * h
	var blob_count: int = rng.randi_range(14, 20)
	for bi in blob_count:
		# Random point inside an oblate ellipsoid (wider than tall)
		var u: float = rng.randf() * TAU
		var v: float = acos(2.0 * rng.randf() - 1.0)
		# Random radius bias toward outer shell for crown shape
		var rad_norm: float = pow(rng.randf(), 0.7)
		var bx: float = sin(v) * cos(u) * crown_radius_x * rad_norm
		var bz: float = sin(v) * sin(u) * crown_radius_x * rad_norm
		var by: float = cos(v) * crown_radius_y * rad_norm
		var blob := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var br: float = rng.randf_range(0.45, 0.85) * h
		sm.radius = br
		sm.height = br * rng.randf_range(1.4, 1.9)
		sm.radial_segments = 8
		sm.rings = 5
		blob.mesh = sm
		blob.material_override = MAT_LEAF(leaf_palette[bi % 4])
		blob.position = Vector3(bx, crown_y + by, bz)
		blob.scale = Vector3(rng.randf_range(0.85, 1.15), rng.randf_range(0.85, 1.15), rng.randf_range(0.85, 1.15))
		blob.rotation = Vector3(rng.randf() * 0.6, rng.randf() * TAU, rng.randf() * 0.6)
		tree.add_child(blob)
	# Add a few drooping low branches with leaf clusters at trunk mid-height
	var branch_count: int = rng.randi_range(2, 4)
	for bri in branch_count:
		var ang2: float = rng.randf() * TAU
		var off_r: float = rng.randf_range(0.7, 1.1) * h
		var by2: float = 1.8 * h * rng.randf_range(0.55, 0.85)
		var blob := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var br: float = rng.randf_range(0.40, 0.65) * h
		sm.radius = br
		sm.height = br * 1.5
		sm.radial_segments = 6
		sm.rings = 4
		blob.mesh = sm
		blob.material_override = MAT_LEAF(leaf_palette[bri % 4])
		blob.position = Vector3(cos(ang2) * off_r, by2, sin(ang2) * off_r)
		tree.add_child(blob)

# ============================================================================
# Rocks — stone-textured with random rotation
# ============================================================================
func _scatter_rocks(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(20, 70)
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		var size := rng.randf_range(0.7, 1.8)
		var rock := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = size; sm.height = size * 1.4
		sm.radial_segments = 8
		sm.rings = 5
		rock.mesh = sm
		rock.material_override = MAT_ROCK(0.6)
		rock.position = pos + Vector3(0, size * 0.5, 0)
		rock.rotation = Vector3(rng.randf() * 0.4, rng.randf() * TAU, rng.randf() * 0.4)
		rock.scale = Vector3(1.0, 0.6, 1.0)
		add_child(rock)

# ============================================================================
# Mountain ring with rock texture + snow caps (snow texture)
# ============================================================================
func _build_mountain_ring() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Inner ring
	for i in 36:
		var ang := (float(i) / 36.0) * TAU + rng.randf_range(-0.05, 0.05)
		var r := 90.0 + rng.randf_range(-8, 8)
		var pos := Vector3(cos(ang) * r, 0, sin(ang) * r)
		var h := rng.randf_range(20, 40)
		var base_r := rng.randf_range(8, 14)
		var mt := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = base_r
		cm.height = h
		cm.radial_segments = 8
		mt.mesh = cm
		mt.material_override = MAT_ROCK(2.0)
		mt.position = pos + Vector3(0, h/2 - 2, 0)
		mt.rotation.y = rng.randf() * TAU
		add_child(mt)
		# Snow cap
		if rng.randf() < 0.7:
			var cap := MeshInstance3D.new()
			var ccm := CylinderMesh.new()
			ccm.top_radius = 0.0
			ccm.bottom_radius = base_r * 0.55
			ccm.height = h * 0.32
			ccm.radial_segments = 8
			cap.mesh = ccm
			cap.material_override = MAT_SNOW(1.0)
			cap.position = pos + Vector3(0, h - h*0.16 - 2, 0)
			cap.rotation.y = mt.rotation.y
			add_child(cap)
	# Outer ring (taller, further)
	for i in 28:
		var ang := (float(i) / 28.0) * TAU + rng.randf_range(-0.1, 0.1)
		var r := 160.0 + rng.randf_range(-15, 15)
		var pos := Vector3(cos(ang) * r, 0, sin(ang) * r)
		var h := rng.randf_range(45, 80)
		var base_r := rng.randf_range(15, 25)
		var mt := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = base_r
		cm.height = h
		cm.radial_segments = 7
		mt.mesh = cm
		mt.material_override = MAT_ROCK(3.5)
		mt.position = pos + Vector3(0, h/2 - 5, 0)
		mt.rotation.y = rng.randf() * TAU
		add_child(mt)
		# Snow cap on outer ring (always)
		var cap := MeshInstance3D.new()
		var ccm := CylinderMesh.new()
		ccm.top_radius = 0.0
		ccm.bottom_radius = base_r * 0.6
		ccm.height = h * 0.42
		ccm.radial_segments = 7
		cap.mesh = ccm
		cap.material_override = MAT_SNOW(1.5)
		cap.position = pos + Vector3(0, h - h*0.21 - 5, 0)
		cap.rotation.y = mt.rotation.y
		add_child(cap)

# ============================================================================
# Market stalls
# ============================================================================
func _build_market_stalls() -> void:
	var spots = [Vector3(2.5, 0, 0), Vector3(-2.5, 0, 0)]
	for spot in spots:
		_make_stall(spot)

func _make_stall(pos: Vector3) -> void:
	var stall := Node3D.new()
	stall.position = pos
	add_child(stall)
	var counter := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 0.8, 0.8)
	counter.mesh = bm
	counter.material_override = MAT_DARK_WOOD(1.5)
	counter.position.y = 0.4
	stall.add_child(counter)
	for dx in [-0.8, 0.8]:
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.05; pm.bottom_radius = 0.05; pm.height = 1.6
		post.mesh = pm
		post.material_override = MAT_DARK_WOOD(0.5)
		post.position = Vector3(dx, 1.2, -0.3)
		stall.add_child(post)
	# Awning (red striped cloth)
	var awn_mat := StandardMaterial3D.new()
	awn_mat.albedo_color = Color(0.78, 0.22, 0.18)
	awn_mat.roughness = 0.7
	awn_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var awn := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(2.2, 0.05, 1.2)
	awn.mesh = am
	awn.material_override = awn_mat
	awn.position = Vector3(0, 2.0, -0.1)
	awn.rotation.x = 0.4
	stall.add_child(awn)
	# Wares (potions)
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var ware_colors = [Color(0.95, 0.3, 0.25), Color(0.95, 0.85, 0.3), Color(0.3, 0.75, 0.4), Color(0.65, 0.3, 0.85)]
	for i in 4:
		var ware_mat := StandardMaterial3D.new()
		ware_mat.albedo_color = ware_colors[i]
		ware_mat.roughness = 0.25
		ware_mat.metallic = 0.1
		ware_mat.emission_enabled = true
		ware_mat.emission = ware_colors[i]
		ware_mat.emission_energy_multiplier = 0.25
		var w := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.10
		w.mesh = sm
		w.material_override = ware_mat
		w.position = Vector3(-0.65 + i * 0.4, 0.92, 0)
		stall.add_child(w)

# ============================================================================
# Windmill
# ============================================================================
func _build_windmill() -> void:
	var pos := Vector3(0, 0, 12)
	var mill := Node3D.new()
	mill.position = pos
	add_child(mill)
	# Stone tower base
	var base := MeshInstance3D.new()
	var bcm := CylinderMesh.new()
	bcm.top_radius = 0.85; bcm.bottom_radius = 1.1
	bcm.height = 2.0
	base.mesh = bcm
	base.material_override = MAT_STONE(1.5)
	base.position.y = 1.0
	mill.add_child(base)
	# Wood upper tower
	var tower := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.7; cm.bottom_radius = 0.85
	cm.height = 2.5
	tower.mesh = cm
	tower.material_override = MAT_WOOD(2)
	tower.position.y = 3.25
	mill.add_child(tower)
	# Roof
	var roof := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0; cone.bottom_radius = 0.85
	cone.height = 1.2
	roof.mesh = cone
	roof.material_override = MAT_ROOF(1.5)
	roof.position.y = 5.1
	mill.add_child(roof)
	# Blade hub
	var blades := Node3D.new()
	blades.name = "Blades"
	blades.position = Vector3(0, 4.0, 1.0)
	mill.add_child(blades)
	for i in 4:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.18, 2.6, 0.5)
		b.mesh = bm
		b.material_override = MAT_DARK_WOOD(0.4)
		var ang := (float(i) / 4.0) * TAU
		b.rotation.z = ang
		b.position = Vector3(cos(ang + PI/2) * 1.3, sin(ang + PI/2) * 1.3, 0)
		blades.add_child(b)
		# Sail cloth
		var cloth_mat := StandardMaterial3D.new()
		cloth_mat.albedo_color = Color(0.92, 0.88, 0.78)
		cloth_mat.roughness = 0.85
		cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var cloth := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.85, 2.4)
		cloth.mesh = qm
		cloth.material_override = cloth_mat
		cloth.rotation.z = ang
		cloth.position = Vector3(cos(ang + PI/2) * 1.3, sin(ang + PI/2) * 1.3, 0.05)
		blades.add_child(cloth)
	blades.add_to_group("windmill_blades")

# ============================================================================
# Lanterns
# ============================================================================
func _build_lanterns() -> void:
	var positions = [Vector3(8, 0, 8), Vector3(-8, 0, 8), Vector3(8, 0, -8), Vector3(-8, 0, -8),
					 Vector3(12, 0, 0), Vector3(-12, 0, 0), Vector3(0, 0, 12), Vector3(0, 0, -12)]
	for p in positions:
		_make_lantern(p)

func _make_lantern(pos: Vector3) -> void:
	var lan := Node3D.new()
	lan.position = pos
	lan.add_to_group("lanterns")
	add_child(lan)
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05; cm.bottom_radius = 0.07; cm.height = 2.4
	post.mesh = cm
	post.material_override = MAT_DARK_WOOD(0.4)
	post.position.y = 1.2
	lan.add_child(post)
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.32, 0.42, 0.32)
	box.mesh = bm
	box.material_override = MAT_DARK_WOOD(0.3)
	box.position.y = 2.5
	lan.add_child(box)
	# Glowing glass
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 0.65, 0.20)
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(1.0, 0.55, 0.18)
	glass_mat.emission_energy_multiplier = 1.8
	glass_mat.metallic = 0.0
	glass_mat.roughness = 0.2
	var glass := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.22, 0.30, 0.22)
	glass.mesh = gm
	glass.material_override = glass_mat
	glass.position.y = 2.5
	glass.name = "Glow"
	lan.add_child(glass)
	# Light
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.62, 0.28)
	light.light_energy = 1.6
	light.omni_range = 8.0
	light.position.y = 2.5
	light.shadow_enabled = false
	lan.add_child(light)

# ============================================================================
# Banner flags
# ============================================================================
func _build_banners() -> void:
	for x in [-14, 14]:
		var pole := Node3D.new()
		pole.position = Vector3(x, 0, 0)
		add_child(pole)
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06; cm.bottom_radius = 0.06; cm.height = 4.5
		post.mesh = cm
		post.material_override = MAT_DARK_WOOD(0.3)
		post.position.y = 2.25
		pole.add_child(post)
		# Banner cloth
		var ban_mat := StandardMaterial3D.new()
		ban_mat.albedo_color = Color(0.78, 0.22, 0.18)
		ban_mat.roughness = 0.8
		ban_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var ban := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.4, 0.85)
		ban.mesh = qm
		ban.material_override = ban_mat
		ban.position = Vector3(0.7, 3.9, 0)
		pole.add_child(ban)

# ============================================================================
# Stone well
# ============================================================================
func _build_well() -> void:
	var well := Node3D.new()
	well.position = Vector3(0, 0, 6)
	add_child(well)
	# Base ring
	var ring := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.1; cm.bottom_radius = 1.2
	cm.height = 1.0
	ring.mesh = cm
	ring.material_override = MAT_STONE(1.5)
	ring.position.y = 0.5
	well.add_child(ring)
	# Water
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.05, 0.18, 0.28)
	water_mat.metallic = 0.3
	water_mat.roughness = 0.2
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.1, 0.3, 0.5)
	water_mat.emission_energy_multiplier = 0.15
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.0, 2.0)
	water.mesh = pm
	water.material_override = water_mat
	water.position.y = 0.85
	well.add_child(water)
	# Posts + crossbeam (the rope and bucket frame)
	for dx in [-1.0, 1.0]:
		var p := MeshInstance3D.new()
		var pcm := CylinderMesh.new()
		pcm.top_radius = 0.08; pcm.bottom_radius = 0.08; pcm.height = 1.8
		p.mesh = pcm
		p.material_override = MAT_DARK_WOOD(0.4)
		p.position = Vector3(dx, 1.9, 0)
		well.add_child(p)
	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.4, 0.16, 0.16)
	beam.mesh = bm
	beam.material_override = MAT_DARK_WOOD(0.5)
	beam.position.y = 2.85
	well.add_child(beam)

# ============================================================================
# Pond — small reflective water plane
# ============================================================================
func _build_pond() -> void:
	var pond := Node3D.new()
	pond.position = Vector3(-18, 0, 14)
	add_child(pond)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.08, 0.22, 0.30)
	water_mat.metallic = 0.65
	water_mat.roughness = 0.08
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.15, 0.40, 0.55)
	water_mat.emission_energy_multiplier = 0.18
	var w := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8.0, 6.0)
	w.mesh = pm
	w.material_override = water_mat
	w.position.y = 0.04
	pond.add_child(w)
	# Reeds along edge
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in 24:
		var ang := rng.randf() * TAU
		var rx := cos(ang) * (3.5 + rng.randf() * 0.5)
		var rz := sin(ang) * (2.5 + rng.randf() * 0.5)
		var reed := MeshInstance3D.new()
		var rcm := CylinderMesh.new()
		rcm.top_radius = 0.0; rcm.bottom_radius = 0.04
		rcm.height = 0.6 + rng.randf() * 0.4
		reed.mesh = rcm
		var rm := StandardMaterial3D.new()
		rm.albedo_color = Color(0.35, 0.5, 0.18)
		rm.roughness = 0.85
		reed.material_override = rm
		reed.position = Vector3(rx, 0.3, rz)
		pond.add_child(reed)

# ============================================================================
# Floating fireflies — GPUParticles3D
# ============================================================================
func _build_firefly_particles() -> void:
	var spots = [Vector3(0, 0, 0), Vector3(15, 0, 12), Vector3(-15, 0, -12), Vector3(0, 0, 18)]
	for s in spots:
		var p := GPUParticles3D.new()
		p.position = s + Vector3(0, 1.5, 0)
		p.amount = 60
		p.lifetime = 4.0
		p.preprocess = 2.0
		p.visibility_aabb = AABB(Vector3(-12, -2, -12), Vector3(24, 6, 24))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(8, 1.5, 8)
		pm.gravity = Vector3(0, 0.05, 0)
		pm.initial_velocity_min = 0.1
		pm.initial_velocity_max = 0.6
		pm.scale_min = 0.6
		pm.scale_max = 1.4
		pm.color = Color(1.0, 0.85, 0.35)
		p.process_material = pm
		var qm := QuadMesh.new()
		qm.size = Vector2(0.06, 0.06)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = Color(1.0, 0.9, 0.5)
		dm.emission_enabled = true
		dm.emission = Color(1.0, 0.75, 0.25)
		dm.emission_energy_multiplier = 4.0
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		qm.material = dm
		p.draw_pass_1 = qm
		add_child(p)

# ============================================================================
# Chimney smoke from each building
# ============================================================================
func _build_smoke_chimneys() -> void:
	for b in get_tree().get_nodes_in_group("buildings"):
		var chim = b.get_node_or_null("Chimney")
		if not chim: continue
		var smoke := GPUParticles3D.new()
		smoke.position = chim.position + Vector3(0, 0.9, 0)
		smoke.amount = 24
		smoke.lifetime = 5.0
		smoke.preprocess = 3.0
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.12
		pm.gravity = Vector3(0.05, 0.4, 0)
		pm.initial_velocity_min = 0.2
		pm.initial_velocity_max = 0.4
		pm.scale_min = 0.4
		pm.scale_max = 1.6
		pm.color = Color(0.7, 0.65, 0.6, 0.4)
		smoke.process_material = pm
		var qm := QuadMesh.new()
		qm.size = Vector2(0.5, 0.5)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = Color(0.85, 0.8, 0.75, 0.45)
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		dm.no_depth_test = false
		qm.material = dm
		smoke.draw_pass_1 = qm
		b.add_child(smoke)

# ============================================================================
# NPCs
# ============================================================================
func _build_npcs() -> void:
	for n in NPCS:
		_make_npc(n)

func _make_npc(data: Dictionary) -> void:
	var npc := StaticBody3D.new()
	npc.position = data.pos
	npc.set_script(npc_script)
	npc.npc_name = data.name
	npc.npc_role = data.role
	npc.dialogue = data.line
	# REFINE: feed mood-dependent variants if this NPC has them defined.
	npc.dialogue_variants = PackedStringArray(data.get("lines", []))
	add_child(npc)

	var col := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.4; caps.height = 1.8
	col.shape = caps
	col.position.y = 0.9
	npc.add_child(col)

	var model := npc_scene.instantiate()
	model.scale = Vector3(1.2, 1.2, 1.2)
	npc.add_child(model)
	model.call_deferred("propagate_call", "set", ["modulate", data.tint])

	var label := Label3D.new()
	label.text = data.name
	label.font_size = 28
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0)
	label.modulate = Color(1, 0.85, 0.4)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.4, 0)
	label.name = "Label3D"
	npc.add_child(label)

	var area := Area3D.new()
	area.name = "InteractArea"
	npc.add_child(area)
	var acol := CollisionShape3D.new()
	var ashape := SphereShape3D.new()
	ashape.radius = 2.5
	acol.shape = ashape
	acol.position.y = 1.0
	area.add_child(acol)

# ============================================================================
# Grass tufts — plane cards (cull_mode disabled, lit)
# ============================================================================
func _build_grass_tufts(count: int) -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.42, 0.62, 0.22)
	grass_mat.roughness = 0.85
	grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass_mat.rim_enabled = true
	grass_mat.rim = 0.5
	for i in count:
		var pos := Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-60, 60))
		if pos.length() < 4: continue
		var tuft := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0; cm.bottom_radius = 0.08
		cm.height = 0.5 + rng.randf() * 0.3
		cm.radial_segments = 4
		tuft.mesh = cm
		tuft.material_override = grass_mat
		tuft.position = pos + Vector3(0, cm.height / 2, 0)
		tuft.add_to_group("grass")
		add_child(tuft)

# ============================================================================
# Enemies — Whisperwood goblin camps + scattered wolves
# ============================================================================
const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")
const BOSS_SCRIPT  = preload("res://scripts/Boss.gd")
const PET_SCRIPT   = preload("res://scripts/Pet.gd")
const CHEST_SCRIPT = preload("res://scripts/Chest.gd")

func _build_enemies() -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	# Three goblin camps in the Whisperwood (outside the village)
	var camp_centers = [
		Vector3(35, 0, 35),
		Vector3(-40, 0, 30),
		Vector3(20, 0, -45),
	]
	for camp in camp_centers:
		# 4 goblins per camp, scattered around a campfire prop
		_make_goblin_camp(camp)
		for i in 4:
			var ang: float = rng.randf() * TAU
			var r: float = rng.randf_range(2.5, 6.0)
			var pos: Vector3 = camp + Vector3(cos(ang) * r, 0, sin(ang) * r)
			_spawn_enemy("goblin", pos, "Goblin Scout", 28, 6, 18, 4)

	# A pair of stronger goblins (Brutes) per camp
	for camp in camp_centers:
		_spawn_enemy("goblin", camp + Vector3(2, 0, 0), "Goblin Brute", 56, 11, 36, 9,
			Color(0.30, 0.55, 0.20), 0.95, 1.0)

	# A few wolves wandering between camps
	var wolf_spots = [
		Vector3(15, 0, 25), Vector3(-25, 0, -25), Vector3(50, 0, -10), Vector3(-15, 0, 50)
	]
	for w in wolf_spots:
		_spawn_enemy("wolf", w, "Dire Wolf", 40, 9, 28, 6,
			Color(0.55, 0.50, 0.45), 0.8, 1.05)

	# Goblin Warlord — boss in the deepest part of the Whisperwood
	_build_boss_arena(Vector3(60, 0, 60))

func _spawn_enemy(kind: String, pos: Vector3, ename: String, hp: int, dmg: int,
		xp: int, gold: int, tint: Color = Color(0.45, 0.85, 0.30),
		movespd: float = 2.6, chasespd: float = 4.6) -> void:
	var e := CharacterBody3D.new()
	e.set_script(ENEMY_SCRIPT)
	e.position = pos + Vector3(0, 1.0, 0)
	e.enemy_kind = kind
	e.enemy_name = ename
	e.max_hp = hp
	e.damage = dmg
	e.xp_reward = xp
	e.gold_reward = gold
	e.tint = tint
	e.move_speed = movespd
	e.chase_speed = chasespd
	add_child(e)

func _build_pet() -> void:
	# Spawn the player's fox companion next to the spawn point
	var pet := CharacterBody3D.new()
	pet.set_script(PET_SCRIPT)
	pet.position = Vector3(2, 1.0, 2)
	add_child(pet)

func _build_loot_chests() -> void:
	# Common chests scattered around the wilds, plus a rare chest deeper in
	var spots = [
		{"pos": Vector3( 22, 0,  10), "pool":"chest_common", "items":2},
		{"pos": Vector3(-18, 0,  22), "pool":"chest_common", "items":2},
		{"pos": Vector3( 28, 0, -30), "pool":"chest_common", "items":3},
		{"pos": Vector3(-32, 0, -18), "pool":"chest_common", "items":3},
		{"pos": Vector3( 45, 0,  20), "pool":"chest_rare",   "items":4},
		{"pos": Vector3(-45, 0,  45), "pool":"chest_rare",   "items":4},
	]
	for s in spots:
		var c := StaticBody3D.new()
		c.set_script(CHEST_SCRIPT)
		c.position = s.pos + Vector3(0, 0.0, 0)
		c.loot_pool = s.pool
		c.item_count = s.items
		if s.pool == "chest_rare":
			c.glow_color = Color(0.55, 0.45, 1.0)  # purple glow for rare chests
		c.rotation.y = randf() * TAU
		add_child(c)

func _build_boss_arena(center: Vector3) -> void:
	# A circular arena with stone monoliths around the perimeter
	var arena := Node3D.new()
	arena.position = center
	add_child(arena)
	# Stone monoliths in a ring
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in 8:
		var ang := (float(i) / 8.0) * TAU
		var r := 9.0
		var stone := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 4.5 + rng.randf() * 1.5, 1.2)
		stone.mesh = bm
		stone.material_override = MAT_STONE(1.5)
		stone.position = Vector3(cos(ang) * r, bm.size.y * 0.5, sin(ang) * r)
		stone.rotation.y = rng.randf() * 0.4
		arena.add_child(stone)
	# Skull pile in the center
	for i in 5:
		var skull := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.18; sm.height = 0.28
		skull.mesh = sm
		var sklm := StandardMaterial3D.new()
		sklm.albedo_color = Color(0.85, 0.80, 0.72)
		sklm.roughness = 0.85
		skull.material_override = sklm
		skull.position = Vector3(rng.randf_range(-0.6, 0.6), 0.1 + i * 0.05, rng.randf_range(-0.6, 0.6))
		arena.add_child(skull)
	# Banner pole behind boss
	var pole := Node3D.new()
	pole.position = Vector3(0, 0, -2)
	arena.add_child(pole)
	var post := MeshInstance3D.new()
	var pcm := CylinderMesh.new()
	pcm.top_radius = 0.06; pcm.bottom_radius = 0.06; pcm.height = 5.5
	post.mesh = pcm
	post.material_override = MAT_DARK_WOOD(0.4)
	post.position.y = 2.75
	pole.add_child(post)
	var ban_mat := StandardMaterial3D.new()
	ban_mat.albedo_color = Color(0.18, 0.32, 0.10)
	ban_mat.roughness = 0.85
	ban_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ban := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.2, 1.4)
	ban.mesh = qm
	ban.material_override = ban_mat
	ban.position = Vector3(1.1, 4.3, 0)
	pole.add_child(ban)
	# Spawn the boss
	var boss := CharacterBody3D.new()
	boss.set_script(BOSS_SCRIPT)
	boss.position = center + Vector3(0, 1.0, 0)
	add_child(boss)

func _make_goblin_camp(center: Vector3) -> void:
	# Small fire pit (no particles to keep perf — just a glowing log)
	var pit := Node3D.new()
	pit.position = center
	add_child(pit)
	# Stone ring
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in 6:
		var ang := (float(i) / 6.0) * TAU
		var stone := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.18; sm.height = 0.28
		stone.mesh = sm
		stone.material_override = MAT_STONE(0.5)
		stone.position = Vector3(cos(ang) * 0.7, 0.12, sin(ang) * 0.7)
		stone.scale = Vector3(1.0, 0.7, 1.0)
		pit.add_child(stone)
	# Glowing ember log
	var log := MeshInstance3D.new()
	var lcm := CylinderMesh.new()
	lcm.top_radius = 0.10; lcm.bottom_radius = 0.10; lcm.height = 0.9
	log.mesh = lcm
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(0.20, 0.06, 0.04)
	em.emission_enabled = true
	em.emission = Color(1.0, 0.40, 0.10)
	em.emission_energy_multiplier = 1.8
	log.material_override = em
	log.rotation = Vector3(0, 0, PI / 2)
	log.position.y = 0.18
	pit.add_child(log)
	# Warm flickering point light
	var lt := OmniLight3D.new()
	lt.name = "GoblinFireLight"
	lt.light_color = Color(1.0, 0.45, 0.18)
	lt.light_energy = 1.4
	lt.omni_range = 8.0
	lt.position.y = 0.5
	pit.add_child(lt)
	pit.add_to_group("goblin_fires")

# ============================================================================
# Campfire — stone ring, charred logs, fire particles, warm point light
# ============================================================================
func _build_campfire() -> void:
	var fire := Node3D.new()
	fire.position = Vector3(0, 0, -2)
	fire.add_to_group("campfires")
	add_child(fire)

	# Stone ring (8 small rocks in a circle)
	for i in 8:
		var ang := (float(i) / 8.0) * TAU
		var r := 0.9
		var stone := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.18; sm.height = 0.28
		stone.mesh = sm
		stone.material_override = MAT_STONE(0.5)
		stone.position = Vector3(cos(ang) * r, 0.12, sin(ang) * r)
		stone.scale = Vector3(1.0, 0.7, 1.0)
		fire.add_child(stone)

	# Charred logs (3 crossing each other)
	for i in 3:
		var log := MeshInstance3D.new()
		var lcm := CylinderMesh.new()
		lcm.top_radius = 0.10; lcm.bottom_radius = 0.10
		lcm.height = 1.4
		log.mesh = lcm
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(0.10, 0.06, 0.04)
		lm.roughness = 0.95
		log.material_override = lm
		log.rotation = Vector3(0, (float(i) / 3.0) * TAU, PI / 2)
		log.position.y = 0.25
		fire.add_child(log)

	# Fire particles
	var p := GPUParticles3D.new()
	p.position.y = 0.45
	p.amount = 80
	p.lifetime = 1.6
	p.preprocess = 1.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.25
	pm.gravity = Vector3(0, 1.2, 0)
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.2
	pm.scale_min = 0.5
	pm.scale_max = 1.6
	pm.color = Color(1.0, 0.55, 0.10)
	pm.color_ramp = _make_fire_gradient()
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.4, 0.4)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(1.0, 0.75, 0.30)
	dm.emission_enabled = true
	dm.emission = Color(1.0, 0.45, 0.10)
	dm.emission_energy_multiplier = 6.0
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.no_depth_test = false
	qm.material = dm
	p.draw_pass_1 = qm
	fire.add_child(p)

	# Smoke particles above the fire
	var smoke := GPUParticles3D.new()
	smoke.position.y = 1.4
	smoke.amount = 40
	smoke.lifetime = 4.0
	smoke.preprocess = 2.0
	var smpm := ParticleProcessMaterial.new()
	smpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smpm.emission_sphere_radius = 0.2
	smpm.gravity = Vector3(0.05, 0.6, 0)
	smpm.initial_velocity_min = 0.2
	smpm.initial_velocity_max = 0.4
	smpm.scale_min = 0.6
	smpm.scale_max = 2.0
	smpm.color = Color(0.55, 0.50, 0.45, 0.5)
	smoke.process_material = smpm
	var sqm := QuadMesh.new()
	sqm.size = Vector2(0.5, 0.5)
	var sdm := StandardMaterial3D.new()
	sdm.albedo_color = Color(0.7, 0.65, 0.6, 0.55)
	sdm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sdm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sqm.material = sdm
	smoke.draw_pass_1 = sqm
	fire.add_child(smoke)

	# Warm flickering light
	var light := OmniLight3D.new()
	light.name = "FireLight"
	light.light_color = Color(1.0, 0.55, 0.20)
	light.light_energy = 3.0
	light.omni_range = 12.0
	light.position.y = 0.7
	light.shadow_enabled = false
	fire.add_child(light)

func _make_fire_gradient() -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.55, 1.0))    # bright yellow at start
	g.set_color(1, Color(0.6, 0.10, 0.05, 0.0))    # fade to dark red transparent
	g.add_point(0.4, Color(1.0, 0.45, 0.10, 0.95)) # orange middle
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt

# ============================================================================
# Frame update — windmill, lantern flicker, gentle tree sway, fire flicker
# ============================================================================
var _t: float = 0.0
func _process(delta: float) -> void:
	_t += delta
	for b in get_tree().get_nodes_in_group("windmill_blades"):
		b.rotate_object_local(Vector3.FORWARD, 0.5 * delta)
	for lan in get_tree().get_nodes_in_group("lanterns"):
		var light: OmniLight3D = lan.get_node_or_null("OmniLight3D")
		if light:
			light.light_energy = 1.4 + sin(_t * 5.0 + lan.position.x) * 0.35
	# Subtle tree sway
	for tree in get_tree().get_nodes_in_group("trees"):
		var s = sin(_t * 0.8 + tree.position.x * 0.3) * 0.015
		tree.rotation.z = s
	# Campfire light flicker
	for f in get_tree().get_nodes_in_group("campfires"):
		var fl: OmniLight3D = f.get_node_or_null("FireLight")
		if fl:
			fl.light_energy = 2.4 + sin(_t * 17.0) * 0.4 + sin(_t * 31.0) * 0.25


# ============================================================================
# Treasure chests — scattered through the Whisperwood and one near the well
# (CHEST_SCRIPT already declared at top of file alongside other preloads)
# ============================================================================
const CHEST_SPOTS = [
	{"pos":Vector3( 18.0,  0,  -22.0), "pool":"chest_common", "count":3, "color":Color(1.0, 0.85, 0.30)},
	{"pos":Vector3(-25.0,  0,  -16.0), "pool":"chest_common", "count":3, "color":Color(1.0, 0.85, 0.30)},
	{"pos":Vector3(  6.0,  0,  -32.0), "pool":"chest_rare",   "count":2, "color":Color(0.55, 0.85, 1.00)},
	{"pos":Vector3(-12.0,  0,  -38.0), "pool":"chest_rare",   "count":2, "color":Color(0.85, 0.45, 1.00)},
	{"pos":Vector3( 28.0,  0,    8.0), "pool":"chest_common", "count":2, "color":Color(1.0, 0.85, 0.30)},
]

func _build_chests() -> void:
	for spot in CHEST_SPOTS:
		var chest := StaticBody3D.new()
		chest.set_script(CHEST_SCRIPT)
		chest.position = spot.pos
		chest.loot_pool = spot.pool
		chest.item_count = spot.count
		chest.glow_color = spot.color
		# Random small rotation so chests don't all face the same way
		chest.rotation.y = randf_range(-PI, PI) * 0.3
		add_child(chest)

# ============================================================================
# CRYSTAL CAVES DUNGEON
# Dark cavern NW of the village. Glowing blue crystal formations, ambient
# blue light, undead + crystal-elemental encounters, boss room with the
# Crystal Guardian. Reuses Items.gd `crystal_shard` material drop.
# ============================================================================
func _make_crystal_cluster(pos: Vector3, base_scale: float, color: Color, parent: Node3D, rng: RandomNumberGenerator) -> void:
	# A cluster of 3–6 elongated emissive shards radiating from a base point.
	var cluster := Node3D.new()
	cluster.position = pos
	parent.add_child(cluster)
	var shard_count: int = rng.randi_range(3, 6)
	for i in shard_count:
		var shard := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.45 * base_scale, rng.randf_range(1.2, 2.6) * base_scale, 0.45 * base_scale)
		shard.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.4
		mat.metallic = 0.20
		mat.roughness = 0.18
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.85
		shard.material_override = mat
		var ang: float = (float(i) / float(shard_count)) * TAU + rng.randf_range(-0.4, 0.4)
		var r_off: float = rng.randf_range(0.0, 0.4) * base_scale
		shard.position = Vector3(cos(ang) * r_off, pm.size.y * 0.5, sin(ang) * r_off)
		shard.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0, TAU), rng.randf_range(-0.3, 0.3))
		cluster.add_child(shard)
	# Pulsing omni light at the heart of the cluster
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.6
	light.omni_range = 7.0 * base_scale
	light.position.y = 1.0
	cluster.add_child(light)

func _make_stalagmite(pos: Vector3, height: float, parent: Node3D, point_down: bool = false) -> void:
	var sm := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.7, height, 0.7)
	sm.mesh = pm
	sm.material_override = MAT_ROCK(1.0)
	sm.position = pos
	if point_down:
		sm.position.y = pos.y - height * 0.5
		sm.rotation.x = PI
	else:
		sm.position.y = pos.y + height * 0.5
	sm.rotation.y = randf() * TAU
	parent.add_child(sm)

func _build_crystal_caves(entrance: Vector3) -> void:
	var caves := Node3D.new()
	caves.name = "CrystalCaves"
	caves.position = entrance
	add_child(caves)
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var crystal_blue: Color = Color(0.45, 0.80, 1.00)
	var crystal_violet: Color = Color(0.70, 0.55, 1.00)
	var crystal_teal: Color = Color(0.45, 1.00, 0.85)

	# ── Cavern dome (inverted) — the dark interior shell ──
	# Done as a downward-scaled half-sphere shell offset upward so it caps the
	# play area without blocking the camera too aggressively.
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 24.0; dm.height = 22.0
	dome.mesh = dm
	var dome_mat := StandardMaterial3D.new()
	dome_mat.albedo_color = Color(0.06, 0.08, 0.14)
	dome_mat.roughness = 0.95
	dome_mat.cull_mode = BaseMaterial3D.CULL_FRONT  # render the inside
	dome.material_override = dome_mat
	dome.position = Vector3(0, 4.0, 0)
	caves.add_child(dome)

	# ── Entrance arch (two stone columns + capstone) ──
	for sx in [-3.2, 3.2]:
		var col := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.7; cm.bottom_radius = 0.95; cm.height = 5.5
		col.mesh = cm
		col.material_override = MAT_ROCK(1.5)
		col.position = Vector3(sx, 2.75, 22.0)
		caves.add_child(col)
	var cap := MeshInstance3D.new()
	var capm := BoxMesh.new()
	capm.size = Vector3(8.4, 1.2, 1.6)
	cap.mesh = capm
	cap.material_override = MAT_ROCK(1.5)
	cap.position = Vector3(0, 6.1, 22.0)
	caves.add_child(cap)
	# Glowing entrance crystal above the arch — a beacon from the village
	var beacon := MeshInstance3D.new()
	var bm := PrismMesh.new()
	bm.size = Vector3(1.0, 2.4, 1.0)
	beacon.mesh = bm
	var beacon_mat := StandardMaterial3D.new()
	beacon_mat.albedo_color = crystal_blue
	beacon_mat.emission_enabled = true
	beacon_mat.emission = crystal_blue
	beacon_mat.emission_energy_multiplier = 3.0
	beacon.material_override = beacon_mat
	beacon.position = Vector3(0, 8.0, 22.0)
	caves.add_child(beacon)
	var beacon_light := OmniLight3D.new()
	beacon_light.light_color = crystal_blue
	beacon_light.light_energy = 2.5
	beacon_light.omni_range = 14.0
	beacon_light.position = Vector3(0, 8.0, 22.0)
	caves.add_child(beacon_light)

	# ── Ambient blue cave light ──
	var amb := OmniLight3D.new()
	amb.light_color = crystal_blue
	amb.light_energy = 0.85
	amb.omni_range = 28.0
	amb.position = Vector3(0, 9.0, 0)
	caves.add_child(amb)
	# Secondary deep-violet light at the boss room end
	var boss_amb := OmniLight3D.new()
	boss_amb.light_color = crystal_violet
	boss_amb.light_energy = 1.6
	boss_amb.omni_range = 18.0
	boss_amb.position = Vector3(0, 4.0, -16.0)
	caves.add_child(boss_amb)

	# ── Stone floor disc — a darker rocky ground inside the cave ──
	var floor_mesh := MeshInstance3D.new()
	var pm_floor := CylinderMesh.new()
	pm_floor.top_radius = 22.0; pm_floor.bottom_radius = 22.0; pm_floor.height = 0.4
	floor_mesh.mesh = pm_floor
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.18, 0.20, 0.26)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	floor_mesh.position = Vector3(0, 0.05, 0)
	caves.add_child(floor_mesh)

	# ── Glowing crystal formations scattered through the cave ──
	var crystal_spots: Array = [
		{"p": Vector3(-8, 0, 14), "s": 1.4, "c": crystal_blue},
		{"p": Vector3( 9, 0, 11), "s": 1.2, "c": crystal_blue},
		{"p": Vector3(14, 0,  4), "s": 1.6, "c": crystal_teal},
		{"p": Vector3(-12,0,  2), "s": 1.5, "c": crystal_blue},
		{"p": Vector3(  4,0, -4), "s": 1.0, "c": crystal_teal},
		{"p": Vector3(-6, 0, -8), "s": 1.3, "c": crystal_violet},
		{"p": Vector3( 12,0, -10),"s": 1.4, "c": crystal_violet},
		{"p": Vector3(-14,0,-12), "s": 1.1, "c": crystal_blue},
		{"p": Vector3(  0,0, -18),"s": 2.2, "c": crystal_violet},  # giant central crystal in boss room
	]
	for spot in crystal_spots:
		var p: Vector3 = spot["p"]
		var s: float = spot["s"]
		var c: Color = spot["c"]
		_make_crystal_cluster(p, s, c, caves, rng)

	# ── Stalagmites (floor) and stalactites (ceiling) ──
	for i in 18:
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(6.0, 19.0)
		var pos: Vector3 = Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		var h: float = rng.randf_range(1.2, 3.0)
		_make_stalagmite(pos, h, caves, false)
	for i in 12:
		var ang2: float = rng.randf() * TAU
		var r2: float = rng.randf_range(4.0, 18.0)
		var pos2: Vector3 = Vector3(cos(ang2) * r2, 11.5, sin(ang2) * r2)
		var h2: float = rng.randf_range(1.5, 3.5)
		_make_stalagmite(pos2, h2, caves, true)

	# ── Boss room divider — a stone arch separating the entry chamber from the boss room ──
	for sx2 in [-6.0, 6.0]:
		var pillar := MeshInstance3D.new()
		var pillm := CylinderMesh.new()
		pillm.top_radius = 0.6; pillm.bottom_radius = 0.9; pillm.height = 7.0
		pillar.mesh = pillm
		pillar.material_override = MAT_ROCK(1.5)
		pillar.position = Vector3(sx2, 3.5, -10.0)
		caves.add_child(pillar)

	# ── Skull pile in front of the boss crystal — ominous ──
	for i in 6:
		var skull := MeshInstance3D.new()
		var sm2 := SphereMesh.new()
		sm2.radius = 0.20; sm2.height = 0.32
		skull.mesh = sm2
		var sklm := StandardMaterial3D.new()
		sklm.albedo_color = Color(0.85, 0.80, 0.72)
		sklm.roughness = 0.85
		skull.material_override = sklm
		skull.position = Vector3(rng.randf_range(-1.4, 1.4), 0.18, -16.0 + rng.randf_range(-1.4, 1.4))
		caves.add_child(skull)

	# ── ENEMY SPAWNS ──
	# Skeletons (use enemy_kind="skeleton", bone-white tint)
	var skel_color: Color = Color(0.95, 0.95, 0.92)
	var skel_spots: Array = [
		Vector3(-6, 0, 12), Vector3( 7, 0, 8), Vector3(11, 0, -2),
		Vector3(-10, 0, -4), Vector3( 4, 0, -8),
	]
	for sp in skel_spots:
		var pos3: Vector3 = caves.position + sp
		_spawn_enemy("skeleton", pos3, "Restless Skeleton", 36, 8, 24, 7, skel_color, 2.4, 4.4)

	# Crystal Elementals — slower, hard-hitting, glowing
	var elem_color: Color = Color(0.55, 0.85, 1.00)
	var elem_spots: Array = [
		Vector3(-12, 0, 0), Vector3(13, 0, -6), Vector3(-4, 0, -12),
	]
	for ep in elem_spots:
		var pos4: Vector3 = caves.position + ep
		_spawn_enemy("crystal_elemental", pos4, "Crystal Elemental", 70, 14, 55, 14, elem_color, 1.8, 3.2)

	# Boss: Crystal Guardian — beefy crystal_guardian with massive HP and big drops
	var guardian_pos: Vector3 = caves.position + Vector3(0, 0, -16.0)
	_spawn_enemy("crystal_guardian", guardian_pos, "Crystal Guardian",
		420, 26, 480, 200, Color(0.65, 0.85, 1.00), 1.8, 3.4)
