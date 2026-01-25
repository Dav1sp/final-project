extends Node3D


func ativar_grupo(ativo: bool):
	if ativo:
		# Liga tudo: Visual e Processamento (Física/Scripts)
		visible = true
		process_mode = Node.PROCESS_MODE_INHERIT # Volta ao normal
	else:
		# Desliga tudo
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
