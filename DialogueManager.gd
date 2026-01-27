extends Node

# 1. Carrega a cena e os dados UMA vez
const TEXT_BOX_SCENE = preload("res://Scenes/UI/text_box.tscn")
const DIALOGUE_FILE = preload("res://Data/dialogue.json")

# 2. Guarda os dados do jogador
var player_data: Dictionary = {} 
var is_dialogue_active = false

signal dialogue_finished

# ALTERAÇÃO PRINCIPAL: Adicionei 'title_key' (pode ser vazio "")
func show_dialogue(scene_key: String, character_key: String, type=null, name_receive = null,title_key: String = "",area=null):
	
	# 1. Segurança: Verifica se a cena e o personagem existem
	if not DIALOGUE_FILE.data.has(scene_key) or not DIALOGUE_FILE.data[scene_key].has(character_key):
		push_error("Diálogo não encontrado no JSON: " + scene_key + " -> " + character_key)
		return

	# 2. Identifica o tipo de dados (Array ou Dicionário)
	var data_node = DIALOGUE_FILE.data[scene_key][character_key]
	print(title_key)
	var dialogue_array = []
	if data_node is Array and data_node.size() > 0 and data_node[0] is Dictionary and data_node[0].has(title_key):
		data_node = data_node[0] # Remove the [ ] wrapper

	# Now proceed with normal logic
	if data_node is Array:
		# Case A: Simple Item (Lata)
		dialogue_array = data_node
		
	elif data_node is Dictionary:
		# Case B: NPC (Mariel/Nacar)
		if title_key != "" and data_node.has(title_key):
			dialogue_array = data_node[title_key]

	# 3. Cria a caixa de texto
	var text_box = TEXT_BOX_SCENE.instantiate()
	get_tree().root.add_child(text_box)
	
	text_box.tree_exited.connect(func(): dialogue_finished.emit())
	
	is_dialogue_active = true
	
	# Debug para garantir que o owner_node está a chegar bem
	
	# 4. Inicia o diálogo com o array correto
	text_box.start_dialogue(dialogue_array, type, name_receive,area,character_key)
	if(type!=0):
		if(title_key=="first_dialogue"):
			GameData.talked[area.get_meta("name_var")] = true
			area.set_meta("first_talk", true)


# Atualizei também esta função para usar a mesma lógica
func get_dialogue_text(scene_key: String, character_key: String, title_key: String = "") -> Array:
	if not DIALOGUE_FILE.data.has(scene_key) or not DIALOGUE_FILE.data[scene_key].has(character_key):
		return []

	var data_node = DIALOGUE_FILE.data[scene_key][character_key]
	var raw_dialogue_array = []

	# Lógica de seleção (igual à de cima)
	if data_node is Array:
		raw_dialogue_array = data_node
	elif data_node is Dictionary:
		if title_key != "" and data_node.has(title_key):
			raw_dialogue_array = data_node[title_key]
		else:
			return [] 

	var final_text_list: Array = []
	var lang = GameData.lang 

	for line_data in raw_dialogue_array:
		var text = line_data.get(lang, "...")
		
		# Substituição de variáveis (%s)
		if line_data.has("receive_input") and line_data["receive_input"]:
			if line_data.has("receive_input_order") and line_data["receive_input_order"].size() > 0:
				var var_name = line_data["receive_input_order"][0]
				var value = GameData.get(var_name)
				if value == null: value = ""
				text = text % value
		
		final_text_list.append(text)
		
	return final_text_list
