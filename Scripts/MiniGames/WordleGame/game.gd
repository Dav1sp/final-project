extends Node2D

@onready var grid: GridContainer = $GridContainer
@onready var menu: CanvasLayer = $Menu

@onready var label: Label = $Menu/ResultLabel
@onready var word_label: Label = $Menu/WordLabel
@onready var cursor: ColorRect = $Cursor
@onready var cursor_timer: Timer = $CursorTimer


@onready var play_button: Button = $Menu/PlayButton


const MAX_LEN := 10
const ATTEMPTS := 5
const MIN_LEN := 1
const CURSOR_HEIGHT := 70


const COLOR_GREEN := Color("#6aaa64")
const COLOR_YELLOW := Color("#c9b458")
const COLOR_GRAY := Color("#3a3a3c")

var cursor_slot_valid := false

var buttons: Array[Button] = []

var wordle: String = ""
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

func _find_dialogue_instance() -> Node:
	var tb := get_tree().root.find_child(TEXT_BOX_NODE_NAME, true, false)
	if tb != null:
		return tb

	var stack: Array = [get_tree().root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur == null:
			continue
		if ("current_file" in cur) or ("current_language" in cur):
			return cur
		for c in cur.get_children():
			stack.append(c)
	return null

func _get_dialogue_language_code(dialogue_node: Node) -> String:
	if dialogue_node == null:
		return ""
	if "current_file" in dialogue_node:
		return str(dialogue_node.get("current_file"))
	if "current_language" in dialogue_node:
		return str(dialogue_node.get("current_language"))
	return ""

func _apply_language_from_dialogue() -> void:
	var dialogue_node := _find_dialogue_instance()
	var code := _get_dialogue_language_code(dialogue_node)
	if code == "":
		return
	current_lang = _lang_from_code(code)

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
	cursor.visible = true

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
		rect.position.y + (rect.size.y - CURSOR_HEIGHT) / 2
	)
	cursor.size.y = CURSOR_HEIGHT
	cursor.visible = true

func clear_cursor():
	cursor.visible = false
	cursor_timer.stop()

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
		label.text = t("YOU_WON")
		word_label.text = t("CORRECT_WORD") + " " + wordle
		show_menu_delayed(0.35)
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

	index = current_row * MAX_LEN
	update_cursor()


func _reveal_row_flip(row_start: int, length: int, colors: Array[Color], done_cb: Callable) -> void:
	var last_tween: Tween = null

	for i in range(length):
		var btn := buttons[row_start + i]
		var delay := i * 0.08
		last_tween = flip_tile(btn, colors[i], delay)

	
	if last_tween != null:
		last_tween.finished.connect(func():
			done_cb.call()
		)
	else:
		done_cb.call()

func flip_tile(button: Button, color: Color, delay: float = 0.0) -> Tween:
	var tween := create_tween()

	
	if delay > 0.0:
		tween.tween_interval(delay)

	
	tween.tween_property(button, "scale:y", 0.0, 0.12)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	
	tween.tween_callback(func():
		update_button_style(button, color)
	)

	
	tween.tween_property(button, "scale:y", 1.0, 0.12)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	return tween


func _compute_colors(guess: String, target: String) -> Array[Color]:
	var out: Array[Color] = []
	for i in range(guess.length()):
		var g := guess[i]
		if i < target.length() and g == target[i]:
			out.append(COLOR_GREEN)
		elif g in target:
			out.append(COLOR_YELLOW)
		else:
			out.append(COLOR_GRAY)
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


func reset_game():
	is_animating = false
	index = 0
	current_row = 0

	label.text = ""
	word_label.text = ""
	menu.hide()

	wordle = get_random_wordle()
	print("Wordle:", wordle)

	for b in buttons:
		init_button_styles(b)
		b.modulate = Color(1, 1, 1, 1)

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
