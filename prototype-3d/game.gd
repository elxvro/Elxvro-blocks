extends Node3D

const GRID_SIZE := 8
const CELL := 1.0
const BOARD_Z := -1.15
const BOARD_Y := 0.0
const BLOCK_Y := 0.55
const TRAY_Z := 5.25

var camera: Camera3D
var key_light: DirectionalLight3D
var fill_light: OmniLight3D
var world_env: WorldEnvironment

var score_label: Label
var combo_label: Label
var theme_label: Label
var game_over_layer: Control

var score := 0
var combo := 0
var current_theme := 0
var selected_piece: Node3D
var selected_pointer := -1
var active_pieces: Array[Node3D] = []
var occupied := {}
var wells: Array[MeshInstance3D] = []
var board_mesh: MeshInstance3D
var background_floor: MeshInstance3D
var ghost_nodes: Array[Node3D] = []
var elapsed := 0.0
var camera_home := Vector3(0.0, 10.6, 11.4)

var rng := RandomNumberGenerator.new()

var theme_names := [
	"CAM",
	"TAŞ",
	"AHŞAP",
	"YAPRAK",
	"KRİSTAL",
	"MERMER"
]

var theme_data := [
	{
		"base": Color(0.24, 0.66, 0.95, 0.62),
		"top": Color(0.63, 0.90, 1.0, 0.48),
		"accent": Color(0.38, 0.86, 1.0, 1.0),
		"board": Color(0.055, 0.11, 0.16, 1.0),
		"well": Color(0.03, 0.055, 0.08, 1.0),
		"bg": Color(0.015, 0.035, 0.06, 1.0),
		"rough": 0.08,
		"metal": 0.12,
		"alpha": true,
		"emit": 0.16
	},
	{
		"base": Color(0.37, 0.39, 0.42, 1.0),
		"top": Color(0.56, 0.58, 0.61, 1.0),
		"accent": Color(0.86, 0.72, 0.48, 1.0),
		"board": Color(0.12, 0.115, 0.11, 1.0),
		"well": Color(0.055, 0.052, 0.05, 1.0),
		"bg": Color(0.035, 0.032, 0.03, 1.0),
		"rough": 0.92,
		"metal": 0.02,
		"alpha": false,
		"emit": 0.0
	},
	{
		"base": Color(0.43, 0.22, 0.09, 1.0),
		"top": Color(0.68, 0.38, 0.16, 1.0),
		"accent": Color(1.0, 0.66, 0.27, 1.0),
		"board": Color(0.14, 0.07, 0.035, 1.0),
		"well": Color(0.07, 0.034, 0.018, 1.0),
		"bg": Color(0.045, 0.022, 0.012, 1.0),
		"rough": 0.64,
		"metal": 0.0,
		"alpha": false,
		"emit": 0.02
	},
	{
		"base": Color(0.20, 0.58, 0.24, 1.0),
		"top": Color(0.46, 0.82, 0.38, 1.0),
		"accent": Color(0.65, 1.0, 0.49, 1.0),
		"board": Color(0.045, 0.12, 0.06, 1.0),
		"well": Color(0.02, 0.065, 0.03, 1.0),
		"bg": Color(0.012, 0.045, 0.022, 1.0),
		"rough": 0.55,
		"metal": 0.0,
		"alpha": false,
		"emit": 0.04
	},
	{
		"base": Color(0.48, 0.22, 0.92, 0.94),
		"top": Color(0.82, 0.57, 1.0, 0.96),
		"accent": Color(0.78, 0.42, 1.0, 1.0),
		"board": Color(0.085, 0.035, 0.15, 1.0),
		"well": Color(0.04, 0.016, 0.08, 1.0),
		"bg": Color(0.028, 0.01, 0.055, 1.0),
		"rough": 0.16,
		"metal": 0.28,
		"alpha": false,
		"emit": 0.72
	},
	{
		"base": Color(0.91, 0.91, 0.94, 1.0),
		"top": Color(1.0, 0.985, 0.94, 1.0),
		"accent": Color(0.92, 0.71, 0.30, 1.0),
		"board": Color(0.14, 0.14, 0.16, 1.0),
		"well": Color(0.065, 0.065, 0.075, 1.0),
		"bg": Color(0.035, 0.035, 0.045, 1.0),
		"rough": 0.22,
		"metal": 0.08,
		"alpha": false,
		"emit": 0.035
	}
]

var shapes := [
	[Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
]


func _ready() -> void:
	rng.randomize()
	_build_environment()
	_build_board()
	_build_ui()
	_spawn_piece_set()
	_apply_theme(0)


func _process(delta: float) -> void:
	elapsed += delta
	if fill_light:
		fill_light.position.x = sin(elapsed * 0.42) * 4.8
		fill_light.position.z = BOARD_Z + cos(elapsed * 0.42) * 3.4
	for i in range(active_pieces.size()):
		var p := active_pieces[i]
		if is_instance_valid(p) and p != selected_piece:
			var home: Vector3 = p.get_meta("home")
			p.position.y = home.y + sin(elapsed * 2.1 + float(i) * 1.7) * 0.055
			p.rotation.y = sin(elapsed * 0.75 + float(i)) * 0.025


func _build_environment() -> void:
	world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = theme_data[0]["bg"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.66, 0.78, 1.0)
	env.ambient_light_energy = 0.7
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	world_env.environment = env
	add_child(world_env)

	camera = Camera3D.new()
	camera.position = camera_home
	camera.fov = 44.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.25, BOARD_Z + 0.3), Vector3.UP)

	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	key_light.light_energy = 2.15
	key_light.shadow_enabled = true
	add_child(key_light)

	fill_light = OmniLight3D.new()
	fill_light.position = Vector3(-3.6, 5.5, 1.5)
	fill_light.omni_range = 16.0
	fill_light.light_energy = 5.0
	fill_light.shadow_enabled = false
	add_child(fill_light)

	background_floor = _make_box(Vector3(18.0, 0.28, 22.0), Vector3(0.0, -0.62, 0.3), "background")
	background_floor.add_to_group("background")


func _build_board() -> void:
	board_mesh = _make_box(Vector3(8.95, 0.42, 8.95), Vector3(0.0, -0.16, BOARD_Z), "board")
	board_mesh.add_to_group("board_base")

	var rim_outer := _make_box(Vector3(9.42, 0.20, 9.42), Vector3(0.0, -0.40, BOARD_Z), "rim")
	rim_outer.add_to_group("board_base")

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var pos := _cell_world(Vector2i(col, row))
			var well := _make_box(Vector3(0.88, 0.09, 0.88), Vector3(pos.x, 0.10, pos.z), "well")
			well.add_to_group("well")
			wells.append(well)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var top_panel := ColorRect.new()
	top_panel.color = Color(0.01, 0.012, 0.02, 0.76)
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_bottom = 205.0
	canvas.add_child(top_panel)

	var title := Label.new()
	title.text = "ELXVRO // BLOCKS 3D"
	title.position = Vector2(42, 24)
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	top_panel.add_child(title)

	var prototype := Label.new()
	prototype.text = "v0.11.0 • REALTIME 3D PROTOTYPE"
	prototype.position = Vector2(45, 81)
	prototype.add_theme_font_size_override("font_size", 22)
	prototype.add_theme_color_override("font_color", Color(0.62, 0.68, 0.78))
	top_panel.add_child(prototype)

	score_label = Label.new()
	score_label.text = "SKOR  0"
	score_label.position = Vector2(44, 132)
	score_label.add_theme_font_size_override("font_size", 30)
	top_panel.add_child(score_label)

	combo_label = Label.new()
	combo_label.text = "COMBO x0"
	combo_label.position = Vector2(270, 132)
	combo_label.add_theme_font_size_override("font_size", 30)
	combo_label.add_theme_color_override("font_color", Color(0.78, 0.86, 1.0))
	top_panel.add_child(combo_label)

	theme_label = Label.new()
	theme_label.text = "TEMA: CAM"
	theme_label.position = Vector2(735, 132)
	theme_label.add_theme_font_size_override("font_size", 25)
	theme_label.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	top_panel.add_child(theme_label)

	var theme_picker := OptionButton.new()
	theme_picker.position = Vector2(760, 32)
	theme_picker.size = Vector2(280, 64)
	theme_picker.add_theme_font_size_override("font_size", 24)
	for n in theme_names:
		theme_picker.add_item(n)
	theme_picker.item_selected.connect(_on_theme_selected)
	top_panel.add_child(theme_picker)

	var instruction := Label.new()
	instruction.text = "BLOĞU SÜRÜKLE  •  TAHTAYA BIRAK  •  SATIR / SÜTUN TEMİZLE"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	instruction.offset_top = -105.0
	instruction.offset_bottom = -32.0
	instruction.add_theme_font_size_override("font_size", 23)
	instruction.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84))
	canvas.add_child(instruction)

	game_over_layer = Control.new()
	game_over_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_layer.visible = false
	canvas.add_child(game_over_layer)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.76)
	game_over_layer.add_child(shade)

	var over_title := Label.new()
	over_title.text = "SİNYAL KESİLDİ"
	over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_title.position = Vector2(140, 690)
	over_title.size = Vector2(800, 80)
	over_title.add_theme_font_size_override("font_size", 58)
	game_over_layer.add_child(over_title)

	var over_sub := Label.new()
	over_sub.text = "Yerleştirilebilir blok kalmadı."
	over_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_sub.position = Vector2(140, 780)
	over_sub.size = Vector2(800, 55)
	over_sub.add_theme_font_size_override("font_size", 28)
	over_sub.add_theme_color_override("font_color", Color(0.70, 0.74, 0.82))
	game_over_layer.add_child(over_sub)

	var restart := Button.new()
	restart.text = "YENİDEN BAŞLAT"
	restart.position = Vector2(310, 880)
	restart.size = Vector2(460, 92)
	restart.add_theme_font_size_override("font_size", 30)
	restart.pressed.connect(_restart)
	game_over_layer.add_child(restart)


func _spawn_piece_set() -> void:
	for p in active_pieces:
		if is_instance_valid(p):
			p.queue_free()
	active_pieces.clear()

	var homes := [
		Vector3(-3.20, 0.86, TRAY_Z),
		Vector3(-0.30, 0.86, TRAY_Z),
		Vector3(2.65, 0.86, TRAY_Z)
	]

	for i in range(3):
		var shape: Array = shapes[rng.randi_range(0, shapes.size() - 1)].duplicate()
		var p := _create_piece(shape)
		p.position = homes[i]
		p.set_meta("home", homes[i])
		p.set_meta("cells", shape)
		p.set_meta("piece_index", i)
		active_pieces.append(p)


func _create_piece(cells: Array) -> Node3D:
	var root := Node3D.new()
	root.name = "Piece"
	add_child(root)
	for cell in cells:
		var block := _create_block_visual(Vector3(float(cell.x) * CELL, 0.0, float(cell.y) * CELL), true)
		root.add_child(block)
	return root


func _create_block_visual(local_pos: Vector3, tray := false) -> Node3D:
	var root := Node3D.new()
	root.position = local_pos
	root.add_to_group("block_root")
	root.set_meta("tray", tray)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.84, 0.56 if not tray else 0.48, 0.84)
	body.mesh = body_mesh
	body.position.y = 0.0
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_to_group("theme_block_body")
	root.add_child(body)

	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(0.70, 0.055, 0.70)
	top.mesh = top_mesh
	top.position.y = 0.31 if not tray else 0.27
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top.add_to_group("theme_block_top")
	root.add_child(top)

	var core := MeshInstance3D.new()
	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.15, 0.08, 0.15)
	core.mesh = core_mesh
	core.position.y = 0.34 if not tray else 0.30
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.add_to_group("theme_block_core")
	root.add_child(core)

	_apply_material_to_block(root)
	return root


func _make_box(size: Vector3, pos: Vector3, role: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.set_meta("role", role)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh_instance)
	return mesh_instance


func _material(color: Color, roughness: float, metallic: float, emission_strength := 0.0, transparent := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if transparent or color.a < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = color.a
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(color.r, color.g, color.b)
		mat.emission_energy_multiplier = emission_strength
	return mat


func _apply_theme(index: int) -> void:
	current_theme = clamp(index, 0, theme_data.size() - 1)
	var t: Dictionary = theme_data[current_theme]

	if world_env and world_env.environment:
		world_env.environment.background_color = t["bg"]
		world_env.environment.ambient_light_color = t["top"]
		world_env.environment.ambient_light_energy = 0.58 if current_theme == 1 else 0.72

	if key_light:
		key_light.light_color = t["top"]
		key_light.light_energy = 2.4 if current_theme in [0, 4, 5] else 2.0
	if fill_light:
		fill_light.light_color = t["accent"]
		fill_light.light_energy = 5.8 if current_theme in [0, 4] else 4.4

	for n in get_tree().get_nodes_in_group("board_base"):
		if n is MeshInstance3D:
			n.material_override = _material(t["board"], 0.36, 0.15)
	for n in get_tree().get_nodes_in_group("well"):
		if n is MeshInstance3D:
			n.material_override = _material(t["well"], 0.52, 0.02)
	for n in get_tree().get_nodes_in_group("background"):
		if n is MeshInstance3D:
			n.material_override = _material(t["bg"].lightened(0.04), 0.76, 0.0)

	for n in get_tree().get_nodes_in_group("block_root"):
		if n is Node3D:
			_apply_material_to_block(n)

	theme_label.text = "TEMA: " + theme_names[current_theme]
	theme_label.add_theme_color_override("font_color", t["accent"])


func _apply_material_to_block(root: Node3D) -> void:
	var t: Dictionary = theme_data[current_theme]
	for child in root.get_children():
		if not child is MeshInstance3D:
			continue
		if child.is_in_group("theme_block_body"):
			child.material_override = _material(t["base"], t["rough"], t["metal"], t["emit"], t["alpha"])
		elif child.is_in_group("theme_block_top"):
			child.material_override = _material(t["top"], max(0.04, float(t["rough"]) * 0.60), min(1.0, float(t["metal"]) + 0.08), float(t["emit"]) * 0.7, t["alpha"])
		elif child.is_in_group("theme_block_core"):
			child.material_override = _material(t["accent"], 0.12, 0.22, max(0.18, float(t["emit"]) + 0.34), false)


func _on_theme_selected(index: int) -> void:
	_apply_theme(index)
	_pulse_camera(0.06)


func _unhandled_input(event: InputEvent) -> void:
	if game_over_layer.visible:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_down(event.position, event.index)
		else:
			_pointer_up(event.position, event.index)
	elif event is InputEventScreenDrag:
		if selected_piece and event.index == selected_pointer:
			_pointer_move(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_down(event.position, 999)
		else:
			_pointer_up(event.position, 999)
	elif event is InputEventMouseMotion and selected_piece and selected_pointer == 999 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_pointer_move(event.position)


func _pointer_down(screen_pos: Vector2, pointer_id: int) -> void:
	if selected_piece:
		return
	var world := _screen_to_plane(screen_pos, 0.85)
	if world == null:
		return

	var best: Node3D
	var best_dist := 999.0
	for p in active_pieces:
		if not is_instance_valid(p):
			continue
		var cells: Array = p.get_meta("cells")
		var center_offset := _shape_center(cells)
		var center := p.position + Vector3(center_offset.x, 0.0, center_offset.y)
		var d := Vector2(center.x - world.x, center.z - world.z).length()
		if d < best_dist:
			best_dist = d
			best = p

	if best and best_dist < 1.8:
		selected_piece = best
		selected_pointer = pointer_id
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(selected_piece, "position:y", 1.42, 0.10)
		tween.tween_property(selected_piece, "scale", Vector3(1.08, 1.08, 1.08), 0.10)
		_pointer_move(screen_pos)


func _pointer_move(screen_pos: Vector2) -> void:
	if not selected_piece:
		return
	var world := _screen_to_plane(screen_pos, 0.62)
	if world == null:
		return
	selected_piece.position.x = world.x
	selected_piece.position.z = world.z - 0.55
	selected_piece.position.y = 1.30
	var cells: Array = selected_piece.get_meta("cells")
	_update_ghost(selected_piece.position, cells)


func _pointer_up(screen_pos: Vector2, pointer_id: int) -> void:
	if not selected_piece or pointer_id != selected_pointer:
		return

	var p := selected_piece
	var cells: Array = p.get_meta("cells")
	var anchor := _world_to_cell(p.position)
	var placed := _can_place(anchor, cells)

	_clear_ghost()

	if placed:
		_commit_piece(p, anchor, cells)
	else:
		var home: Vector3 = p.get_meta("home")
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(p, "position", home, 0.24)
		tween.tween_property(p, "scale", Vector3.ONE, 0.18)
		_invalid_impulse()

	selected_piece = null
	selected_pointer = -1


func _commit_piece(piece: Node3D, anchor: Vector2i, cells: Array) -> void:
	for cell in cells:
		var board_cell := Vector2i(anchor.x + cell.x, anchor.y + cell.y)
		var world := _cell_world(board_cell)
		var placed := _create_block_visual(Vector3.ZERO, false)
		placed.position = Vector3(world.x, BLOCK_Y, world.z)
		placed.scale = Vector3(0.18, 1.42, 0.18)
		add_child(placed)
		occupied[board_cell] = placed

		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(placed, "scale", Vector3.ONE, 0.19)

	score += cells.size() * 12
	_update_score()
	_pulse_camera(0.08)

	active_pieces.erase(piece)
	piece.queue_free()

	_clear_complete_lines()

	if active_pieces.is_empty():
		_spawn_piece_set()

	if not _has_any_move():
		game_over_layer.visible = true
		_pulse_camera(0.18)


func _clear_complete_lines() -> void:
	var full_rows: Array[int] = []
	var full_cols: Array[int] = []

	for row in range(GRID_SIZE):
		var full := true
		for col in range(GRID_SIZE):
			if not occupied.has(Vector2i(col, row)):
				full = false
				break
		if full:
			full_rows.append(row)

	for col in range(GRID_SIZE):
		var full := true
		for row in range(GRID_SIZE):
			if not occupied.has(Vector2i(col, row)):
				full = false
				break
		if full:
			full_cols.append(col)

	if full_rows.is_empty() and full_cols.is_empty():
		combo = 0
		_update_score()
		return

	var clear_cells := {}
	for row in full_rows:
		for col in range(GRID_SIZE):
			clear_cells[Vector2i(col, row)] = true
	for col in full_cols:
		for row in range(GRID_SIZE):
			clear_cells[Vector2i(col, row)] = true

	combo += 1
	score += (full_rows.size() + full_cols.size()) * 130 * combo

	var delay := 0.0
	for cell in clear_cells.keys():
		if not occupied.has(cell):
			continue
		var node: Node3D = occupied[cell]
		occupied.erase(cell)
		_break_block(node, delay)
		delay += 0.012

	_update_score()
	_pulse_camera(0.12 + min(0.09, float(combo) * 0.018))


func _break_block(node: Node3D, delay: float) -> void:
	if not is_instance_valid(node):
		return
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(node, "position:y", node.position.y + 1.0, 0.30).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "rotation", Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(-1.6, 1.6), rng.randf_range(-0.6, 0.6)), 0.30).set_delay(delay)
	t.tween_property(node, "scale", Vector3(0.05, 0.05, 0.05), 0.31).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(node.queue_free)


func _invalid_impulse() -> void:
	var original := camera.position
	var t := create_tween()
	t.tween_property(camera, "position:x", original.x + 0.10, 0.035)
	t.tween_property(camera, "position:x", original.x - 0.10, 0.05)
	t.tween_property(camera, "position:x", original.x, 0.04)


func _pulse_camera(amount: float) -> void:
	if not camera:
		return
	var original := camera_home
	var t := create_tween()
	t.tween_property(camera, "position", original + Vector3(0.0, -amount * 1.6, -amount * 2.0), 0.06)
	t.tween_property(camera, "position", original, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_ghost(piece_pos: Vector3, cells: Array) -> void:
	_clear_ghost()
	var anchor := _world_to_cell(piece_pos)
	var valid := _can_place(anchor, cells)
	var color := theme_data[current_theme]["accent"] if valid else Color(1.0, 0.18, 0.18, 1.0)

	for cell in cells:
		var board_cell := Vector2i(anchor.x + cell.x, anchor.y + cell.y)
		if board_cell.x < 0 or board_cell.x >= GRID_SIZE or board_cell.y < 0 or board_cell.y >= GRID_SIZE:
			continue
		var world := _cell_world(board_cell)
		var ghost := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.78, 0.10, 0.78)
		ghost.mesh = mesh
		ghost.position = Vector3(world.x, 0.24, world.z)
		ghost.material_override = _material(Color(color.r, color.g, color.b, 0.50), 0.18, 0.0, 0.58, true)
		add_child(ghost)
		ghost_nodes.append(ghost)


func _clear_ghost() -> void:
	for g in ghost_nodes:
		if is_instance_valid(g):
			g.queue_free()
	ghost_nodes.clear()


func _can_place(anchor: Vector2i, cells: Array) -> bool:
	for cell in cells:
		var c := Vector2i(anchor.x + cell.x, anchor.y + cell.y)
		if c.x < 0 or c.x >= GRID_SIZE or c.y < 0 or c.y >= GRID_SIZE:
			return false
		if occupied.has(c):
			return false
	return true


func _has_any_move() -> bool:
	for p in active_pieces:
		if not is_instance_valid(p):
			continue
		var cells: Array = p.get_meta("cells")
		for row in range(GRID_SIZE):
			for col in range(GRID_SIZE):
				if _can_place(Vector2i(col, row), cells):
					return true
	return false


func _shape_center(cells: Array) -> Vector2:
	var max_x := 0
	var max_y := 0
	for c in cells:
		max_x = max(max_x, c.x)
		max_y = max(max_y, c.y)
	return Vector2(float(max_x) * CELL * 0.5, float(max_y) * CELL * 0.5)


func _cell_world(cell: Vector2i) -> Vector3:
	var half := float(GRID_SIZE - 1) * 0.5
	return Vector3((float(cell.x) - half) * CELL, BOARD_Y, BOARD_Z + (float(cell.y) - half) * CELL)


func _world_to_cell(pos: Vector3) -> Vector2i:
	var half := float(GRID_SIZE - 1) * 0.5
	var col := int(round(pos.x / CELL + half))
	var row := int(round((pos.z - BOARD_Z) / CELL + half))
	return Vector2i(col, row)


func _screen_to_plane(screen_pos: Vector2, plane_y: float):
	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, plane_y)
	return plane.intersects_ray(origin, direction)


func _update_score() -> void:
	score_label.text = "SKOR  " + str(score)
	combo_label.text = "COMBO x" + str(combo)
	var accent: Color = theme_data[current_theme]["accent"]
	combo_label.add_theme_color_override("font_color", accent if combo > 0 else Color(0.72, 0.76, 0.84))


func _restart() -> void:
	get_tree().reload_current_scene()
