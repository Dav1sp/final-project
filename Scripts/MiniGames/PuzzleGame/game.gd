extends Area2D

const GAP: int = 2
const MARGIN: int = 10
const UI_HEIGHT: int = 90 

@export var shuffle_limit: int = 40
@export var image_path: String = "res://Assets/PuzzleGame/thumb__2400_0_0_0_auto.jpg"
@export var player: CharacterBody3D
@export var npc: Node3D

@export var GRID: int = 4

var grey_tile_path = ColorRect.new()
var tiles: Array[Node2D] = []
var solved_names: Array[String] = []
var song = false
var initial_layout: Array[String] = []

var mouse_event: InputEventMouseButton = null

var tile_scene: PackedScene = preload("res://Scenes/MiniGames/PuzzleGame/tile.tscn")
@onready var image_help = $CanvasLayer/ColorRect/TextureRect
@onready var image_background =$BackgroundLayer/TextureRect
@onready var swap_sound = $swapSound
@onready var mute_button = $CanvasLayer/Mute
@onready var sound_button = $CanvasLayer/Volume
@onready var setting_pannel = $setting_background
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
	if self.GRID==4:
		if GameData.puzzle_best_score_4 != null:
			$CanvasLayer/UI/BestScore.text = DialogueManager.get_dialogue_text('menu','best_score')[0] + ' '+ str(GameData.puzzle_best_score_4)
		else:
			$CanvasLayer/UI/BestScore.text = DialogueManager.get_dialogue_text('menu','best_score')[0] + ' -'
	elif self.GRID==5:
		if GameData.puzzle_best_score_5 != null:
			$CanvasLayer/UI/BestScore.text = DialogueManager.get_dialogue_text('menu','best_score')[0] + ' '+ str(GameData.puzzle_best_score_5)
		else:
			$CanvasLayer/UI/BestScore.text = DialogueManager.get_dialogue_text('menu','best_score')[0] + ' -'
	elif self.GRID==6:
		if GameData.puzzle_best_score_6 != null:
			$CanvasLayer/UI/BestScore.text = DialogueManager.get_dialogue_text('menu','best_score')[0] + ' '+ str(GameData.puzzle_best_score_6)
		else:
			$CanvasLayer/UI/BestScore.text = DialogueManager.get_dialogue_text('menu','best_score')[0] + ' -'
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grey_tile_path.color = Color(2.015, 2.015, 2.015, 0.729) # RGBA: last value = alpha (0.0-1.0)
	grey_tile_path.size = Vector2(64, 64) 
	$setting_background/Setting_panel/Setting/Exit_game.text = DialogueManager.get_dialogue_text('menu','exit_game')[0]
	$setting_background/Setting_panel/Setting/Save_game.text = DialogueManager.get_dialogue_text('menu','save_game')[0]
	$setting_background/Setting_panel/Setting/Close.text = DialogueManager.get_dialogue_text('menu','close')[0]
	$CanvasLayer/Restart.text = DialogueManager.get_dialogue_text('menu','reset')[0]
	start_game()


func start_game() -> void:
	self.image_help.texture = load(image_path)
	self.image_background.texture = load(image_path)
	
	# Limpar tiles antigos
	for n: Node2D in tiles:
		if is_instance_valid(n):
			n.queue_free()
	tiles.clear()
	solved_names.clear()

	mouse_event = null
	movecounter = 0
	previous = ""
	t = 0

	moves_label.text = DialogueManager.get_dialogue_text('menu','moves')[0]+' 0'
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

	# --- CARREGAMENTO DA IMAGEM ---
	var loaded_texture = load(image_path)
	if loaded_texture == null:
		push_error("ERRO CRÍTICO: Não foi possível carregar a textura: " + image_path)
		return
		
	var image: Image = loaded_texture.get_image()

	# Descomprimir se necessário para editar
	if image.is_compressed():
		image.decompress()
			
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
		
	# Cortar a região quadrada
	var w: int = image.get_width()
	var h: int = image.get_height()
	var side: int = min(w, h)
	var x0: int = int((w - side) / 2)
	var y0: int = int((h - side) / 2)
	image = image.get_region(Rect2i(x0, y0, side, side))

	# Redimensionar para o tamanho exato da grelha
	image.resize(GRID * tile_h, GRID * tile_h, Image.INTERPOLATE_CUBIC)
	
	# Textura completa para o final
	var texture: ImageTexture = ImageTexture.create_from_image(image)

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
		
	# --- CRIAÇÃO DAS PEÇAS ---
	for j: int in range(GRID):
		for i: int in range(GRID):
			# Cortar o pedaço da imagem
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

			# --- AQUI ESTÁ A MUDANÇA PARA O BURACO ---
			if tile_name == "Tile16":
				# Se for a última peça, passamos null (sem textura)
				newtile.tiletexture = null 
				newtile.realtexture = new_tex # Guardamos a textura real para o fim se precisares
			else:
				# Se for uma peça normal, pomos a imagem
				newtile.tiletexture = new_tex

			add_child(newtile)
			tiles.append(newtile)

	solved_names = _current_names()

	shuffle_tiles()
	save_restart_state()
	self.sound = true
	movecounter = 0
	moves_label.text = DialogueManager.get_dialogue_text('menu','moves')[0] + ' 0'
	win_label.visible = false
	win_label.text = ""

func save_restart_state():
	initial_layout.clear()
	for n in tiles:
		initial_layout.append(n.tilename)
		
func restart_game():
	if initial_layout.is_empty():
		return
		
	movecounter = 0
	moves_label.text = "Moves: 0"
	win_label.visible = false
	win_label.text = ""
	full_image.hide()
	previous = "" # Reset na peça anterior para não bloquear movimento
	
	# 1. Reconstruir o array 'tiles' na ordem correta baseada no save
	var new_tiles_order: Array[Node2D] = []
	
	for saved_name in initial_layout:
		# Encontrar a tile real que corresponde a este nome
		for tile_obj in tiles:
			if tile_obj.tilename == saved_name:
				new_tiles_order.append(tile_obj)
				break
	
	# Atualizar o array principal
	tiles = new_tiles_order
	
	# 2. Resetar as posições visuais baseadas na nova ordem do array
	for index in range(tiles.size()):
		var col = index % GRID
		var row = index / GRID
		
		var new_pos = Vector2(
			board_origin.x + float(col * offset + tile_h / 2),
			board_origin.y + float(row * offset + tile_h / 2)
		)
		
		# Movemos a tile visualmente
		tiles[index].position = new_pos

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
			GameManager.win_label.get_child(0).text = DialogueManager.get_dialogue_text('menu','complete_game')[0]
			GameManager.win_label.show()
			GameManager.win=true
			if !song:
				GameManager.win_audio.play()
				song = true
			await space_confirmado
			if self.GRID==4:
				if GameData.puzzle_best_score_4 != null:
					if self.movecounter < GameData.puzzle_best_score_4:
						GameData.puzzle_best_score_4 = self.movecounter
				else:
					GameData.puzzle_best_score_4 = self.movecounter
			elif self.GRID==5:
				if GameData.puzzle_best_score_5 != null:
					if self.movecounter < GameData.puzzle_best_score_5:
						GameData.puzzle_best_score_5 = self.movecounter
				else:
					GameData.puzzle_best_score_5 = self.movecounter
			elif self.GRID==6:
				if GameData.puzzle_best_score_6 != null:
					if self.movecounter < GameData.puzzle_best_score_6:
						GameData.puzzle_best_score_6 = self.movecounter
				else:
					GameData.puzzle_best_score_6 = self.movecounter
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
	moves_label.text = DialogueManager.get_dialogue_text('menu','moves')[0]+" " + str(movecounter)

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
	queue_free()
	pass


func _on_restart_pressed() -> void:
	restart_game()
	pass 


func _on_quit_pressed() -> void:
	exit_game()
	pass 




func _on_settings_pressed() -> void:
	self.setting_pannel.show()
	pass # Replace with function body.

func _on_volume_pressed() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	
	var is_muted = AudioServer.is_bus_mute(master_bus)

	AudioServer.set_bus_mute(master_bus, not is_muted)
	self.mute_button.show()
	self.sound_button.hide()
	pass

func _on_mute_pressed() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	# Set mute to FALSE to hear sound again
	AudioServer.set_bus_mute(master_bus, false)
	self.mute_button.hide()
	self.sound_button.show()
	pass # Replace with function body.


func _on_close_pressed() -> void:
	self.setting_pannel.hide()
	pass # Replace with function body.


func _on_exit_game_pressed() -> void:
	exit_game()
	pass # Replace with function body.


func _on_save_game_pressed() -> void:
	pass # Replace with function body.
