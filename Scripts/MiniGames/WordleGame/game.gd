extends Node2D

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var menu: CanvasLayer = $Menu

@onready var label: Label = $Menu/ResultLabel
@onready var word_label: Label = $Panel2/Word
@onready var cursor: ColorRect = $Cursor
@onready var cursor_timer: Timer = $CursorTimer
@onready var mute: Button = $Panel2/Mute
@onready var volume: Button = $Panel2/Volume
@onready var setting_background: ColorRect = $setting_background

@onready var play_button: Button = $Menu/PlayButton
const LETTER_BUTTON_SCENE := preload("res://Scenes/MiniGames/WordleGame/button.tscn")

signal space_confirmado

const MAX_LEN := 10
const ATTEMPTS := 100
const MIN_LEN := 1
const CURSOR_HEIGHT := 70

const COLOR_GREEN := Color("#6aaa64")
const COLOR_YELLOW := Color("#c9b458")
const COLOR_GRAY := Color("#3a3a3c")

var cursor_slot_valid := false

var buttons: Array[Button] = []

var wordle: String = "MATO"
var index := 0
var current_row := 0


var is_animating := false

enum Lang { EN, IT, PT, ME, JP }
var current_lang: Lang = Lang.EN


const TEXT_BOX_SCENE_PATH := "res://Scenes/UI/text_box.tscn"
const DIALOGUE_SCRIPT_PATH := "res://Scripts/dialogue.gd"
const TEXT_BOX_NODE_NAME := "TextBox"

func _lang_from_code(code: String) -> Lang:
	var c := code.strip_edges().to_upper()
	match c:
		"ME": return Lang.ME
		"PT": return Lang.PT
		"IT": return Lang.IT
		"JP": return Lang.JP
		"EN": return Lang.EN
		_: return current_lang

func _get_dialogue_language_code(dialogue_node: Node) -> String:
	if dialogue_node == null:
		return ""
	if "current_file" in dialogue_node:
		return str(dialogue_node.get("current_file"))
	if "current_language" in dialogue_node:
		return str(dialogue_node.get("current_language"))
	return ""

func _apply_language_from_dialogue() -> void:
	current_lang = _lang_from_code(GameData.lang)

const UI_TEXT := {
	Lang.EN: {
		"YOU_WON": "You won!",
		"YOU_LOST": "You lost!",
		"CORRECT_WORD": "Correct word:",
		"NOT_IN_DICT": "Not in word list",
		"PLAY": "Play"
	},
	Lang.PT: {
		"YOU_WON": "Voce ganhou!",
		"YOU_LOST": "Voce perdeu!",
		"CORRECT_WORD": "Palavra correta:",
		"NOT_IN_DICT": "Nao esta no dicionario",
		"PLAY": "Jogar"
	},
	Lang.IT: {
		"YOU_WON": "Hai vinto!",
		"YOU_LOST": "Hai perso!",
		"CORRECT_WORD": "Parola corretta:",
		"NOT_IN_DICT": "Non è nel dizionario",
		"PLAY": "Gioca"
	},
	Lang.ME: {
		"YOU_WON": "Pobijedio si!",
		"YOU_LOST": "Izgubio si!",
		"CORRECT_WORD": "Tacna rijec:",
		"NOT_IN_DICT": "Nema u rjecniku",
		"PLAY": "Igraj"
	},
	Lang.JP: {
		"YOU_WON": "かち！",
		"YOU_LOST": "まけ！",
		"CORRECT_WORD": "こたえ：",
		"NOT_IN_DICT": "じしょにありません",
		"PLAY": "あそぶ"
	}
}

func t(key: String) -> String:
	var lang_map = UI_TEXT.get(current_lang, UI_TEXT[Lang.EN])
	return lang_map.get(key, key)

const ALPHABET := {
	Lang.EN: "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	Lang.IT: "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	Lang.PT: "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	Lang.ME: "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	Lang.JP: "ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞ"
		+ "ただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽ"
		+ "まみむめもゃやゅゆょよらりるれろゎわをんー"
}

const WORDLIST_PATH := {
	Lang.EN: "res://Scripts/MiniGames/WordleGame/wordle-en.txt",
	Lang.IT: "res://Scripts/MiniGames/WordleGame/wordle-it.txt",
	Lang.PT: "res://Scripts/MiniGames/WordleGame/wordle-pt.txt",
	Lang.ME: "res://Scripts/MiniGames/WordleGame/wordle-me.txt",
	Lang.JP: "res://Scripts/MiniGames/WordleGame/wordle-jp.txt"
}

var allowed_chars: Dictionary = {}
var words_set: Dictionary = {}
var words_list: Array[String] = []

func _ready():
	buttons.clear()
	cursor_timer.timeout.connect(_on_cursor_timer)

	for n in grid.get_children():
		var b := n as Button
		if b != null:
			buttons.append(b)

	for b in buttons:
		b.focus_mode = Control.FOCUS_NONE

	_apply_language_from_dialogue()
	set_language(current_lang)
	reset_game()

func _on_cursor_timer():
	if not cursor_slot_valid:
		cursor.visible = false
		return
	cursor.visible = !cursor.visible

func update_cursor():
	var row_start := current_row * MAX_LEN
	var row_end := row_start + MAX_LEN

	cursor_slot_valid = (index >= row_start and index < row_end and index < buttons.size())
	
	if not cursor_slot_valid:
		cursor.visible = false
		return

	var btn := buttons[index]
	var rect := btn.get_global_rect()
	
	cursor.global_position = Vector2(
		rect.position.x + rect.size.x / 2 - cursor.size.x / 2,
		rect.position.y + (rect.size.y - CURSOR_HEIGHT + 8) / 2
	)

func clear_cursor():
	cursor.visible = false
	cursor_timer.stop()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			# Isto avisa o "await" lá em cima que pode continuar
			space_confirmado.emit()
			
func _unhandled_key_input(event):
	if menu.visible:
		return
	if is_animating:
		return

	if event is InputEventKey and event.is_pressed() and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			submit_current_row()
			return

		# BACKSPACE
		if event.keycode == KEY_BACKSPACE:
			var row_start := current_row * MAX_LEN
			if index > row_start:
				index -= 1
				buttons[index].text = ""
				update_cursor()
			return

		if event.unicode > 0:
			var ch := String.chr(event.unicode)

			if ch == " " or ch == "\n" or ch == "\t":
				return

			if not allowed_chars.has(ch):
				return

			if current_lang != Lang.JP:
				ch = ch.to_upper()

			var row_end := (current_row + 1) * MAX_LEN
			if index < row_end and index < buttons.size():
				buttons[index].text = ch
				index += 1
				update_cursor()

func submit_current_row():
	var row_start := current_row * MAX_LEN
	var guess_len := index - row_start
	if guess_len < MIN_LEN:
		return

	var guess := ""
	for i in range(row_start, index):
		guess += buttons[i].text

	if current_lang != Lang.JP:
		guess = guess.to_upper()

	var is_valid := words_set.has(guess)

	var colors: Array[Color] = _compute_colors(guess, wordle)

	if not is_valid:
		label.text = t("NOT_IN_DICT")
	else:
		label.text = ""

	is_animating = true
	_reveal_row_flip(row_start, guess_len, colors, func():
		_after_reveal(guess)
	)

func show_menu_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	is_animating = false
	menu.show()


func _after_reveal(guess: String) -> void:

	if guess == wordle:
		clear_cursor()
		word_label.text = wordle
		word_label.show()
		GameManager.win_label.get_child(0).text = 'Congratulation, you completed the game!\n Press space to continue'
		GameManager.win_label.show()
		GameManager.win_audio.play()
		await space_confirmado
		queue_free()
		#show_menu_delayed(0.35)
		return

	is_animating = false
	advance_row()

func advance_row() -> void:
	current_row += 1
	if current_row >= ATTEMPTS:
		clear_cursor()
		label.text = t("YOU_LOST")
		word_label.text = t("CORRECT_WORD") + " " + wordle
		show_menu_delayed(0.35)
		return

	add_new_row()
	index = current_row * MAX_LEN
	
	# Aguarda o Godot calcular a nova altura da Grid
	await get_tree().process_frame
	
	# Faz o scroll automático para o final
	if scroll_container:
		var scroll_bar = scroll_container.get_v_scroll_bar()
		scroll_container.scroll_vertical = scroll_bar.max_value
	
	# Aguarda mais um frame para as posições globais estabilizarem
	await get_tree().process_frame
	update_cursor()


func _reveal_row_flip(row_start: int, length: int, colors: Array[Color], done_cb: Callable) -> void:
	var last_tween: Tween = null

	for i in range(length):
		var btn := buttons[row_start + i]
		var delay := i * 0.08
		
		# Verifica se é a primeira ou a última letra da linha
		var is_first = (i == 0)
		var is_last = (i == length - 1)
		
		last_tween = flip_tile(btn, colors[i], delay, is_first, is_last)

	if last_tween != null:
		last_tween.finished.connect(func(): done_cb.call())
	else:
		done_cb.call()

func flip_tile(button: Button, color: Color, delay: float, is_first: bool, is_last: bool) -> Tween:
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)

	tween.tween_property(button, "scale:y", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.tween_callback(func():
		# Chama a nova função com a lógica de arredondamento
		apply_rounded_style(button, color, is_first, is_last)
	)

	tween.tween_property(button, "scale:y", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween


func _compute_colors(guess: String, target: String) -> Array[Color]:
	var length := guess.length()
	var out: Array[Color] = []
	out.resize(length)
	
	# Usamos um dicionário para contar quantas vezes cada letra aparece na palavra secreta
	var target_counts = {}
	for char in target:
		target_counts[char] = target_counts.get(char, 0) + 1

	# PASSAGEM 1: Encontrar os Verdes (Match exato)
	for i in range(length):
		if i < target.length() and guess[i] == target[i]:
			out[i] = COLOR_GREEN
			target_counts[guess[i]] -= 1 # Removemos esta letra da contagem disponível
		else:
			out[i] = Color(0,0,0,0) # Marcador temporário para letras não processadas

	# PASSAGEM 2: Encontrar os Amarelos ou Cinzas
	for i in range(length):
		# Se já for verde, pulamos
		if out[i] == COLOR_GREEN:
			continue
			
		var char = guess[i]
		# Se a letra existe na palavra secreta E ainda temos saldo na contagem
		if char in target_counts and target_counts[char] > 0:
			out[i] = COLOR_YELLOW
			target_counts[char] -= 1 # Consome uma instância da letra
		else:
			# Se a letra não existe ou o saldo acabou (ex: o segundo 'A' de AGUA)
			out[i] = COLOR_GRAY

	return out


func set_language(lang: Lang) -> void:
	current_lang = lang

	
	if play_button:
		play_button.text = t("PLAY")

	
	allowed_chars.clear()
	var a: String = ALPHABET[current_lang]
	for ch in a:
		allowed_chars[ch] = true
		allowed_chars[ch.to_lower()] = true

	_load_words()

func _load_words() -> void:
	words_set.clear()
	words_list.clear()

	var path: String = WORDLIST_PATH[current_lang]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open word list: " + path)
		return

	var lines := file.get_as_text(true).split("\n")
	for line in lines:
		var w := line.strip_edges()
		if w == "":
			continue

		if current_lang != Lang.JP:
			w = w.to_upper()

		if w.length() >= MIN_LEN and w.length() <= MAX_LEN:
			words_set[w] = true
			words_list.append(w)

func _process(delta: float) -> void:
	if scroll_container:
		var scroll_bar = scroll_container.get_v_scroll_bar()
		if scroll_bar.visible:
			# Este sinal detecta QUALQUER movimento (roda do mouse, arrastar, etc.)
			scroll_bar.value_changed.connect(func(_v): 
				var current_pos = scroll_bar.value + scroll_bar.page
				var threshold = scroll_bar.max_value - 10.0 # 10 pixels de margem
				var is_at_bottom = current_pos >= threshold
				# Força a visibilidade baseada no resultado
				if is_at_bottom:
					# Só mostra se não estivermos a animar e o slot for válido
					cursor.z_index = 10
				else:
					# Se subiu 1 pixel que seja, desaparece imediatamente
					cursor.z_index = -10
			)
		
		# Detecta se a barra apareceu/sumiu (importante para o cursor não sumir do nada)
	pass

func reset_game():
	is_animating = false
	index = 0
	current_row = 0

	label.text = ""
	word_label.text = ""
	menu.hide()

	# 1. LIMPEZA SEGURA: Só remove o que for botão
	for n in grid.get_children():
		if n is Button:
			n.queue_free()
	
	# 2. LIMPA O ARRAY: Caso contrário, o jogo tentará acessar botões deletados
	buttons.clear()

	print("Wordle:", wordle)

	# 3. CRIA A PRIMEIRA LINHA
	add_new_row()

	# 4. AGUARDA O FRAME: Essencial para que os botões existam antes do cursor se mover
	await get_tree().process_frame
	
	if is_instance_valid(cursor):
		cursor.visible = true
		cursor_timer.start()
		update_cursor()

func init_button_styles(b: Button):
	b.scale = Vector2.ONE
	b.text = ""

		
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6

	b.add_theme_stylebox_override("normal", style)

func update_button_style(button: Button, bg_color: Color):
	var base := button.get_theme_stylebox("normal")
	var style := base.duplicate() as StyleBoxFlat
	style.bg_color = bg_color
	button.add_theme_stylebox_override("normal", style)

func get_random_wordle() -> String:
	if words_list.is_empty():
		return ""
	randomize()
	return words_list.pick_random()

func _on_button_pressed():
	reset_game()
	cursor.visible = true
	cursor_timer.start()
	update_cursor()

func add_new_row():
	for i in range(MAX_LEN): # MAX_LEN já é 10 no seu código
		var new_btn = LETTER_BUTTON_SCENE.instantiate() as Button
		new_btn.text = "X"
		new_btn.focus_mode = Control.FOCUS_NONE
		# Adiciona ao GridContainer
		grid.add_child(new_btn)
		# Adiciona ao seu array de controle para lógica de cor/texto
		buttons.append(new_btn)
		# Inicializa o estilo (escala e cores base)
		init_button_styles(new_btn)
		


func _on_volume_pressed() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	
	var is_muted = AudioServer.is_bus_mute(master_bus)

	AudioServer.set_bus_mute(master_bus, not is_muted)
	self.mute.show()
	self.volume.hide()
	pass

func _on_mute_pressed() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	# Set mute to FALSE to hear sound again
	AudioServer.set_bus_mute(master_bus, false)
	self.mute.hide()
	self.volume.show()
	pass # Replace with function body.
	
func _on_settings_pressed() -> void:
	self.setting_background.show()
	get_tree().paused = true
	pass # Replace with function body.
	
func _on_close_pressed() -> void:
	self.setting_background.hide()
	get_tree().paused = false
	pass # Replace with function body.

func exit_game():
	get_tree().paused = false
	self.player.minigame = false
	GameManager.score_label.visible = false
	GameManager.win_label.visible = false
	self.npc.iteract.show()
	queue_free()
	pass
	
func _on_exit_game_pressed() -> void:
	exit_game()



func _on_save_game_pressed() -> void:
	pass # Replace with function body.


func apply_rounded_style(button: Button, color: Color, is_first: bool, is_last: bool):
	var style := StyleBoxFlat.new()
	style.bg_color = color
	if color == COLOR_GREEN:
		# Define o arredondamento (ex: 15 pixels)
		var radius := 50
		
		if is_first:
			style.corner_radius_top_left = radius
			style.corner_radius_bottom_left = radius
			
		elif is_last:
			
			style.corner_radius_top_right = radius
			style.corner_radius_bottom_right = radius
	
	# Aplica o estilo ao botão
	button.add_theme_stylebox_override("normal", style)
