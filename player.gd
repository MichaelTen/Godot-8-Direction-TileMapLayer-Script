# Player.gd — RMB-hold 8-way stepping on a 3×3 sub-grid; player stays centered
extends Node2D

# ---- Geometry (2:1 dimetric) ----
@export var tile_w_px: float = 88.0                       # diamond width
@export var tile_h_px: float = 88.0 / sqrt(2.0)           # ≈62.23 (square rotated 45°)
@export var sub_divisions: int = 3                        # 3×3 sub-grid per tile (steps of 1/3)

# ---- Motion ----
@export var subcells_per_sec: float = 8.0                 # speed measured in subcells/second
@export var stop_threshold_px: float = 6.0                # deadzone around mouse (screen px)

# ---- Sprite sheet & animation ----
# Your 4×4 sheet rows are: top→bottom = N, E, S, W
@export_file("*.png") var spritesheet_path: String = "res://assets/player/male425.png"
@export var frames_per_walk: int = 4
@export var fps_walk: float = 8.0

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
@onready var cam: Camera2D = $Camera2D

# Grid position (in tile units; can be fractional). We step by 1/3 each move.
var _grid_pos: Vector2 = Vector2.ZERO
var _target_grid_pos: Vector2 = Vector2.ZERO
var _moving: bool = false

# Precomputed world-pixel distance for one subcell step along cardinals
var _px_per_subcell: float

# 8-way unit vectors in grid-space (gx, gy). Order matches dir8 indices used below.
const DIRS8: Array[Vector2] = [
	Vector2(1, 0),   # 0: E
	Vector2(1, 1),   # 1: SE
	Vector2(0, 1),   # 2: S
	Vector2(-1, 1),  # 3: SW
	Vector2(-1, 0),  # 4: W
	Vector2(-1, -1), # 5: NW
	Vector2(0, -1),  # 6: N
	Vector2(1, -1)   # 7: NE
]

# Map each of the 8 grid directions (above) to the sheet row index:
# rows: 0=N (top), 1=E, 2=S, 3=W (bottom)
# Desired usage:         N/NW -> row0,              E/NE -> row1,               S/SE -> row2,                     W/SW -> row3
const DIR8_TO_ROW: PackedInt32Array = [1, 2, 3, 3, 3, 0, 1, 1]

# Names used when we build animations for each row, in top→bottom order.
const DIR_NAMES: PackedStringArray = ["N","E","S","W"]

func _ready() -> void:
	# Godot 4.x: Camera2D uses 'enabled', not 'current'
	cam.enabled = true

	# Ensure the player draws above the tilemap
	z_index = 100

	# Build frames first
	_build_spriteframes_grid(spritesheet_path)

	# Show a default idle frame immediately (S row, or first available)
	if spr.sprite_frames != null and spr.sprite_frames.get_animation_names().size() > 0:
		var default_anim := "S"  # face player initially
		if spr.sprite_frames.has_animation(default_anim):
			spr.animation = default_anim
		else:
			var names := spr.sprite_frames.get_animation_names()
			if names.size() > 0:
				spr.animation = names[0]
		spr.frame = 0
		spr.stop()

	_target_grid_pos = _grid_pos
	position = iso_to_world(_grid_pos)
	_px_per_subcell = _world_distance_for_subcell()

func _process(delta: float) -> void:
	var rmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if not _moving and rmb:
		var dir8: int = _mouse_to_8way_dir()  # -1 means "no direction"
		if dir8 != -1:
			var g_dir: Vector2 = DIRS8[dir8]
			var step := 1.0 / float(sub_divisions)
			_target_grid_pos = _grid_pos + g_dir * step
			_set_anim_for_dir(dir8, true)
			_moving = true
	elif not rmb and not _moving:
		_set_anim_idle()

	if _moving:
		var world_to := iso_to_world(_target_grid_pos)
		var to_vec := world_to - position
		var px_per_sec := subcells_per_sec * _px_per_subcell
		if to_vec.length() <= px_per_sec * delta:
			position = world_to
			_grid_pos = _target_grid_pos
			_moving = false
		else:
			position += to_vec.normalized() * px_per_sec * delta

# ----------------- Input → 8-way direction from mouse -----------------
# Returns index 0..7 of DIRS8; returns -1 when inside deadzone.
func _mouse_to_8way_dir() -> int:
	var v := get_global_mouse_position() - position
	if v.length() < stop_threshold_px:
		return -1
	var g := screenvec_to_gridvec(v)  # convert to grid-space vector
	var gnorm := g.normalized()
	var best_i := -1
	var best_dot := -1e9
	for i in range(DIRS8.size()):
		var d := gnorm.dot(DIRS8[i].normalized())
		if d > best_dot:
			best_dot = d
			best_i = i
	return best_i

# ----------------- Animation helpers -----------------
func _set_anim_for_dir(dir8: int, moving: bool) -> void:
	var row: int = DIR8_TO_ROW[dir8]
	var anim_name: String = DIR_NAMES[row]
	if moving:
		if spr.animation != anim_name:
			spr.play(anim_name)
	else:
		spr.animation = anim_name
		spr.frame = 0
		spr.stop()

func _set_anim_idle() -> void:
	if spr.animation != "":
		spr.frame = 0
		spr.stop()

# ----------------- Iso mapping -----------------
func iso_to_world(g: Vector2) -> Vector2:
	# screen_x = (gx - gy) * (tile_w/2)
	# screen_y = (gx + gy) * (tile_h/2)
	return Vector2((g.x - g.y) * (tile_w_px * 0.5),
				   (g.x + g.y) * (tile_h_px * 0.5))

func screenvec_to_gridvec(v: Vector2) -> Vector2:
	# Inverse of iso_to_world for vectors (no translation term)
	var a := tile_w_px * 0.5
	var b := tile_h_px * 0.5
	var gx := (v.x / a + v.y / b) * 0.5
	var gy := (v.y / b - v.x / a) * 0.5
	return Vector2(gx, gy)

func _world_distance_for_subcell() -> float:
	var step := 1.0 / float(sub_divisions)
	var delta := iso_to_world(Vector2(step, 0.0)) - iso_to_world(Vector2.ZERO)
	return delta.length()

# ----------------- Build SpriteFrames from a 4×4 sheet -----------------
# Handles non-integer cell sizes (e.g., 425/4) by distributing rounding.
func _build_spriteframes_grid(path: String) -> void:
	var tex: Texture2D = load(path)
	if tex == null:
		push_warning("Spritesheet not found: %s" % path)
		return

	var w := tex.get_width()
	var h := tex.get_height()
	var cols := 4
	var rows := 4

	var xs: Array[int] = []
	var ys: Array[int] = []
	for c in range(cols + 1):
		xs.append(int(round(float(w) * float(c) / float(cols))))
	for r in range(rows + 1):
		ys.append(int(round(float(h) * float(r) / float(rows))))

	var frames := SpriteFrames.new()
	spr.sprite_frames = frames
	spr.centered = true
	spr.offset = Vector2.ZERO

	# Build in top→bottom order matching DIR_NAMES = ["N","E","S","W"]
	for row in range(rows):
		var anim_name: String = DIR_NAMES[row]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps_walk)
		for col in range(cols):
			var rect := Rect2i(Vector2i(xs[col], ys[row]),
							   Vector2i(xs[col+1] - xs[col], ys[row+1] - ys[row]))
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = rect
			frames.add_frame(anim_name, at)
