@tool
extends Node3D
##
## Eldoria realm — Terrain3D pilot driver.
##
## Pilot scope (auto/terrain/eldoria-pilot):
## - Verifies the Terrain3D addon loads and renders in-engine + Web export.
## - Generates a procedural heightmap matching Eldoria's geography:
##     * Briarwood plateau: gentle flat at world origin (village hub)
##     * Whisperwood hills: rolling perlin terrain everywhere else
##     * Crystal Caves dip: bowl-shaped depression NE of Briarwood
##
## Generation is idempotent and runs once on _ready() at runtime only.
## Editor-hint guard prevents re-running every time the scene is opened.
##
## Per THEME.md §13: "NEVER place geometry half-buried in ground" — terrain
## settles below SAFE_SPAWN before NPC/building placement runs.
##
## TODO follow-up commit:
##   - Wire Terrain3DAssets with the locked palette texture layers
##   - Add Crystal Caves cave-mouth markers
##   - Hook into WorldBuilder so Briarwood props snap to terrain height

const REGION_SIZE_M := 1024.0          ## Terrain3D default region size (meters)
const HEIGHT_AMPLITUDE := 18.0         ## Whisperwood rolling-hill amplitude
const BRIARWOOD_RADIUS := 220.0        ## Plateau radius (m) around origin
const BRIARWOOD_HEIGHT := 4.0
const CAVES_CENTER := Vector2(720.0, -380.0)
const CAVES_RADIUS := 260.0
const CAVES_DEPTH := -11.0
const NOISE_SEED := 42                 ## Reproducible across CI builds

@export var force_regenerate: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var terrain: Node = get_node_or_null("Terrain3D")
	if terrain == null:
		push_warning("[EldoriaTerrain] No Terrain3D child node — pilot inert.")
		return
	# Terrain3D class may not be registered if the GDExtension failed to load
	# (e.g. unsupported platform). Fail gracefully so the rest of the game
	# keeps booting.
	if not terrain.has_method("get_data"):
		push_warning("[EldoriaTerrain] Terrain3D extension not loaded; skipping.")
		return
	print("[EldoriaTerrain] Terrain3D detected — pilot scene OK.")
	# Procedural generation is left for a follow-up commit; we want this first
	# pass to verify only that the addon ships in the Web build without
	# disturbing the existing world. See TODO above.
