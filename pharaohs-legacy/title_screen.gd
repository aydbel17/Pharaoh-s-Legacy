extends Control

func _ready():
	$Button.pressed.connect(load_game)
	
func load_game():
	get_tree().change_scene_to_file("res://Level 1.tscn")
