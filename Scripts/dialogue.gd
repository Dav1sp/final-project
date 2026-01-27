extends CanvasLayer

signal player_pressed_space
const CHAR_READ_RATE = 0.01

@onready var textbox_container = $TextboxContainer
@onready var name_symbol = $TextboxContainer/MarginContainer/Panel2/Panel/HBoxContainer/Name
@onready var text_layer = $TextboxContainer/MarginContainer/Panel2/Panel/HBoxContainer/text
@onready var press_spacebar = $"TextboxContainer/MarginContainer/Panel2/Panel/HBoxContainer/Press Spacebar"
@onready var input = $disable_input
@onready var input_val = $disable_input/insertInput
@onready var label: Label = $disable_input/insertInput/Label
@onready var quiz_ui_ref = $CanvasLayer
@onready var quest = $CanvasLayer/quiz_box/MarginContainer/VBoxContainer/Label
@onready var answer_1 =$CanvasLayer/quiz_box/MarginContainer/VBoxContainer/VBoxContainer/Button
@onready var answer_2 =$CanvasLayer/quiz_box/MarginContainer/VBoxContainer/VBoxContainer/Button2
@onready var answer_3 =$CanvasLayer/quiz_box/MarginContainer/VBoxContainer/VBoxContainer/Button3

const SCROLL_SPEED = 25
var is_waiting_for_space = false
var is_waiting_for_input = false
var is_waiting_for_quiz = false
signal answer_chosen(index)

func _ready():
	
	hide_textbox()
	label.text = DialogueManager.get_dialogue_text('menu','enter_press')[0]
	self.answer_1.pressed.connect(func(): answer_chosen.emit(0))
	self.answer_2.pressed.connect(func(): answer_chosen.emit(1))
	self.answer_3.pressed.connect(func(): answer_chosen.emit(2))

func hide_textbox():
	press_spacebar.text = ''
	text_layer.text = ''
	name_symbol.text = ''
	textbox_container.hide()
	input.hide()
	var v_bar = text_layer.get_v_scroll_bar()

	# 1. Configuração de Estilo (Grabber)
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.6, 0.6, 0.6, 1.0)
	grabber_style.set_corner_radius_all(4)
	# Margens internas ajudam a centralizar o grabber no trilho se a barra for larga
	grabber_style.content_margin_left = 2 
	grabber_style.content_margin_right = 2

	# 2. Configuração de Estilo (Fundo/Trilho)
	var scroll_bg = StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0.1, 0.1, 0.1, 0.3)

	scroll_bg.set_corner_radius_all(4) 

	# Aplicar estilos
	v_bar.add_theme_stylebox_override("scroll", scroll_bg)
	v_bar.add_theme_stylebox_override("grabber", grabber_style)
	v_bar.add_theme_stylebox_override("grabber_highlight", grabber_style)
	v_bar.add_theme_stylebox_override("grabber_pressed", grabber_style)


	v_bar.custom_minimum_size.x = 6 
	return

func show_textbox():
	print(DialogueManager.get_dialogue_text('menu','space_press'))
	press_spacebar.text = DialogueManager.get_dialogue_text('menu','space_press')[0]
	textbox_container.show()

func _unhandled_input(event):
	# Se estivermos à espera de input de texto, ignoramos o sinal do espaço
	if is_waiting_for_input:
		return
	if is_waiting_for_quiz:
		return	
	if textbox_container.visible:
		if event is InputEventMouseButton and event.pressed:
			var v_bar = text_layer.get_v_scroll_bar()
			
			# Scroll para Cima
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				v_bar.value -= SCROLL_SPEED
				get_viewport().set_input_as_handled() # Impede que o scroll afete o resto do jogo (ex: zoom da câmara)
				
			# Scroll para Baixo
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				v_bar.value += SCROLL_SPEED
				get_viewport().set_input_as_handled()	
				
	if event.is_action_pressed("ui_accept"):
		player_pressed_space.emit()
		
func add_text(next_text,person):
	name_symbol.text = person+':'
	text_layer.text = next_text
	text_layer.visible_characters = 0 	
	show_textbox()


func start_dialogue(dialogue_array: Array, type=null, name_receive = null,area=null,name=null):
	show_textbox()
	for line_data in dialogue_array:
		var lang = GameData.lang
		var text_to_show = line_data.get(lang, "...")
		
		# Substituição de variáveis (ex: "Olá %s!")
		if line_data.has("receive_input") and line_data["receive_input"]:
			var var_name = line_data["receive_input_order"][0]
			var value = GameData.get(var_name)
			text_to_show = text_to_show % value
		
		if type == 0:
			name_symbol.hide()

		# 1. Primeiro anima o texto da pergunta
		await animate_text(text_to_show, name) 
		
		# 2. Verifica se esta linha pede um input do utilizador
		if line_data.has("input") and line_data["input"]:
			await player_pressed_space	
			# Ativamos o bloqueio ANTES de mostrar a caixa
			is_waiting_for_input = true 
			
			input.show()
			input_val.grab_focus()
			
			# O código fica parado aqui até carregares ENTER no LineEdit
			var result = await input_val.text_submitted
			
			GameData.set(line_data["input_name"],result)
			
			input.hide()
			input_val.clear()
			
			# Desativamos o bloqueio agora que o input terminou
			is_waiting_for_input = false
		elif line_data.has("quiz") and line_data["quiz"]:
			await player_pressed_space	
			GameManager.quiz = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_waiting_for_quiz = true 
			quiz_ui_ref.show()
			for quest in line_data['quests']:
				self.quest.text = quest['question'][GameData.lang]
				self.answer_1.text = quest['options'][0][GameData.lang]
				self.answer_2.text = quest['options'][1][GameData.lang]
				self.answer_3.text = quest['options'][2][GameData.lang]
				var selected_index = await answer_chosen
				if int(selected_index) == int(quest["correct_option_index"]):
					if line_data["begin"]:
						GameData.first_quiz[int(quest['id'])] = true
					else:
						GameData.second_quiz[int(quest['id'])] = true
			is_waiting_for_quiz = false
			quiz_ui_ref.hide()
			GameManager.quiz = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	
			print(GameData.first_quiz)
		else:
			# Se não for input, apenas espera o Espaço normal para continuar
			await player_pressed_space	
	
	hide_textbox()
	DialogueManager.is_dialogue_active = false
	queue_free()
	
func animate_text(text, character):
	name_symbol.text = character + ':'
	text_layer.text = text
	text_layer.visible_characters = 0
	
	var duration = text.length() * CHAR_READ_RATE
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# MUDANÇA: Em vez de tween_property, usamos tween_method para chamar a nossa função
	# Isso garante que a barra de scroll desce enquanto o texto escreve
	tween.tween_method(_update_scroll_text, 0, text.length(), duration)
	
	await tween.finished
	
func _update_scroll_text(current_char_count: int):
	text_layer.visible_characters = current_char_count
	
	if current_char_count == 0:
		return

	# 1. Descobre em que linha está o caractere que acabou de aparecer
	var current_line_index = text_layer.get_character_line(current_char_count - 1)
	
	# 2. Calcula a posição Y (em pixels) do fundo dessa linha
	# Tentamos pegar o offset da PRÓXIMA linha para saber onde a atual termina
	var line_bottom_y = 0.0
	var total_lines = text_layer.get_line_count()
	
	if current_line_index + 1 < total_lines:
		line_bottom_y = text_layer.get_line_offset(current_line_index + 1)
	else:
		# Se for a última linha, usamos a altura total do conteúdo
		line_bottom_y = text_layer.get_content_height()
	
	# 3. Calcula o scroll necessário
	# Queremos que o fundo da linha atual fique alinhado com o fundo da caixa visível
	var box_height = text_layer.size.y
	var v_bar = text_layer.get_v_scroll_bar()
	
	# Só alteramos o scroll se o texto já tiver ultrapassado a altura da caixa
	if line_bottom_y > box_height:
		v_bar.value = line_bottom_y - box_height
	else:
		v_bar.value = 0 # Garante que fica no topo se o texto for pequeno
