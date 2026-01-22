extends Area2D

const GAP: int = 2
const MARGIN: int = 10
const UI_HEIGHT: int = 90 

@export var shuffle_limit: int = 20
@export var image_path: String = "res://Assets/PuzzleGame/thumb__2400_0_0_0_auto.jpg"
@export var player: CharacterBody3D
@export var npc: Node3D
@export var GRID: int = 4

var grey_tile_path = ColorRect.new()
var tiles: Array[Node2D] = []
var solved_names: Array[String] = []

var mouse_event: InputEventMouseButton = null

var tile_scene: PackedScene = preload("res://Scenes/MiniGames/PuzzleGame/tile.tscn")
@onready var image_help = $CanvasLayer/ColorRect/TextureRect
@onready var image_background =$BackgroundLayer/TextureRect
@onready var swap_sound = $swapSound

var tile_h: int = 0
var offset: int = 0
var t: int = 0
var movecounter: int = 0
var previous: String = ""
var sound:bool = false
var board_size: int = 0
var board_origin: Vector2 = Vector2.ZERO
var board_w: int = 0
var board_h: int = 0
@onready var game_panel: Panel = $Panel
@onready var full_image: Sprite2D = $Panel/FullImage
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var ui_root: Control = $CanvasLayer/UI
@onready var moves_label: Label = $CanvasLayer/UI/MovementsLabel
@onready var win_label: Label = $CanvasLayer/UI/WinLabel
@onready var best_label: Label = $CanvasLayer/UI/BestScore
var sound_timer: SceneTreeTimer
var sound_ranges = [
		[0.0, 0.41], 
		[0.85, 1.15],
		[1.82, 2.15],
		[2.72, 3.05],
		[3.47, 3.90],
		[4.20, 4.71],
	]
	
signal space_confirmado

func _ready() -> void:
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grey_tile_path.color = Color(2.015, 2.015, 2.015, 0.729) # RGBA: last value = alpha (0.0-1.0)
	grey_tile_path.size = Vector2(64, 64) 
	start_game()


func start_game() -> void:
	self.image_help.texture = load(image_path)
	self.image_background.texture = load(image_path)
	for n: Node2D in tiles:
		if is_instance_valid(n):
			n.queue_free()
	tiles.clear()
	solved_names.clear()

	mouse_event = null
	movecounter = 0
	previous = ""
	t = 0

	moves_label.text = "Moves: 0"
	win_label.visible = false
	win_label.text = ""
	
	var panel_size: Vector2 = game_panel.size
	
	var vp: Vector2 = get_viewport_rect().size  

	var usable_h: float = vp.y - float(UI_HEIGHT)
	board_size = int(min(vp.x, usable_h) - 2.0 * float(MARGIN))

	tile_h = int((board_size - GAP * (GRID - 1)) / GRID)
	offset = tile_h + GAP

	board_w = GRID * offset - GAP
	board_h = GRID * offset - GAP

	var center_offset = (panel_size - Vector2(float(board_w), float(board_h))) / 2.0
	board_origin = game_panel.position + center_offset

	if collision_shape.shape is RectangleShape2D:
		var rs: RectangleShape2D = collision_shape.shape as RectangleShape2D
		rs.size = panel_size
	collision_shape.position = game_panel.position + (panel_size / 2.0)

	var image: Image = Image.load_from_file(image_path)
	if image == null:
		push_error("Ne mogu da učitam sliku: " + image_path)
		return

	var w: int = image.get_width()
	var h: int = image.get_height()
	var side: int = min(w, h)
	var x0: int = int((w - side) / 2)
	var y0: int = int((h - side) / 2)
	image = image.get_region(Rect2i(x0, y0, side, side))

	image.resize(GRID * tile_h, GRID * tile_h, Image.INTERPOLATE_CUBIC)
	var texture: ImageTexture = ImageTexture.create_from_image(image)

	var grey_image = grey_tile_path

	var gw: int = grey_image.size.x
	var gh: int = grey_image.size.y
	var gside: int = min(gw, gh)
	var gx0: int = int((gw - gside) / 2)
	var gy0: int = int((gh - gside) / 2)

	var grey_texture: ImageTexture = ImageTexture.create_from_image(grey_image)

	full_image.texture = texture
	full_image.centered = true
	full_image.hide()

	full_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	full_image.position = panel_size / 2.0

	var tex_size: Vector2 = full_image.texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		full_image.scale = Vector2(float(board_w) / tex_size.x, float(board_h) / tex_size.y)
	else:
		full_image.scale = Vector2.ONE
	for j: int in range(GRID):
		for i: int in range(GRID):
			var region: Rect2i = Rect2i(i * tile_h, j * tile_h, tile_h, tile_h)
			var new_img: Image = image.get_region(region)
			var new_tex: ImageTexture = ImageTexture.create_from_image(new_img)

			var newtile: Node2D = tile_scene.instantiate() as Node2D

			newtile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

			newtile.position = Vector2(
				board_origin.x + float(i * offset + tile_h / 2),
				board_origin.y + float(j * offset + tile_h / 2)
			)

			var tile_name: String = "Tile" + str(j * GRID + i + 1)
			newtile.tilename = tile_name

			if tile_name == "Tile16":
				newtile.tiletexture = grey_texture
				newtile.realtexture = new_tex
			else:
				newtile.tiletexture = new_tex

			add_child(newtile)
			tiles.append(newtile)

	solved_names = _current_names()

	shuffle_tiles()
	self.sound = true
	movecounter = 0
	moves_label.text = "Moves: 0"
	win_label.visible = false
	win_label.text = ""


func shuffle_tiles() -> void:
	t = 0
	while t < shuffle_limit:
		var atile: int = randi() % (GRID * GRID)

		if tiles[atile].tilename != "Tile16" and tiles[atile].tilename != previous:
			var local_y: float = tiles[atile].position.y - board_origin.y
			var local_x: float = tiles[atile].position.x - board_origin.x

			var rows: int = int(local_y / float(offset))
			var cols: int = int(local_x / float(offset))

			check_neighbours(rows, cols)


func _process(_delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and mouse_event != null:
		var mouse_copy: InputEventMouseButton = mouse_event
		mouse_event = null

		var local: Vector2 = mouse_copy.position - board_origin

		if local.x < 0.0 or local.y < 0.0:
			return

		var rows: int = int(local.y / float(offset))
		var cols: int = int(local.x / float(offset))

		if rows < 0 or rows >= GRID or cols < 0 or cols >= GRID:
			return

		check_neighbours(rows, cols)

		if _current_names() == solved_names and movecounter > 1:
			full_image.show()
			win_label.text = "Well done! You solved the puzzle in " + str(movecounter) + " moves.\nPress SpaceBar to continue"
			win_label.visible = true
			await space_confirmado
			queue_free()


func check_neighbours(rows: int, cols: int) -> void:
	var empty: bool = false
	var done: bool = false
	var pos: int = rows * GRID + cols

	while not empty and not done:
		var new_pos: Vector2 = tiles[pos].position

		if rows < GRID - 1:
			new_pos.y += float(offset)
			empty = find_empty(new_pos, pos)
			new_pos.y -= float(offset)

		if rows > 0:
			new_pos.y -= float(offset)
			empty = find_empty(new_pos, pos)
			new_pos.y += float(offset)

		if cols < GRID - 1:
			new_pos.x += float(offset)
			empty = find_empty(new_pos, pos)
			new_pos.x -= float(offset)

		if cols > 0:
			new_pos.x -= float(offset)
			empty = find_empty(new_pos, pos)
			new_pos.x += float(offset)

		done = true


func find_empty(position: Vector2, pos: int) -> bool:
	var local_y: float = position.y - board_origin.y
	var local_x: float = position.x - board_origin.x

	var new_rows: int = int(local_y / float(offset))
	var new_cols: int = int(local_x / float(offset))

	var new_pos: int = new_rows * GRID + new_cols

	if tiles[new_pos].tilename == "Tile16" and tiles[new_pos].tilename != previous:
		swap_tiles(pos, new_pos)
		if sound:
			var selected = sound_ranges.pick_random()
			play_sound_segment(selected[0], selected[1])
		t += 1
		return true

	return false


func swap_tiles(tile_src: int, tile_dst: int) -> void:
	var temp_pos: Vector2 = tiles[tile_src].position
	tiles[tile_src].position = tiles[tile_dst].position
	tiles[tile_dst].position = temp_pos

	var temp_tile: Node2D = tiles[tile_src]
	tiles[tile_src] = tiles[tile_dst]
	tiles[tile_dst] = temp_tile

	movecounter += 1
	moves_label.text = "Moves: " + str(movecounter)

	previous = tiles[tile_dst].tilename

func play_sound_segment(start_time: float, end_time: float) -> void:
	# 1. Começa a tocar a partir do segundo X
	self.swap_sound.play(start_time)
	
	# 2. Calcula quanto tempo o som deve durar
	var duration = end_time - start_time
	
	# 3. Cria um timer que espera essa duração
	# Usamos uma variável para o timer para evitar erros se o som for interrompido
	sound_timer = get_tree().create_timer(duration)
	
	# 4. Espera o tempo acabar
	await sound_timer.timeout
	
	# 5. Pára o som
	swap_sound.stop()
	
func _current_names() -> Array[String]:
	var arr: Array[String] = []
	for n: Node2D in tiles:
		arr.append(n.tilename)
	return arr


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		mouse_event = event as InputEventMouseButton
		
func _input(event):
	if event.is_action_pressed('ui_cancel'):
		exit_game()
	# Esta função serve APENAS para disparar o sinal
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# Isto avisa o "await" lá em cima que pode continuar
		space_confirmado.emit()

func exit_game():
	self.player.minigame = false
	self.npc.iteract.show()
	queue_free()
	pass
