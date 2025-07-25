extends Area2D
@export var next_level_path: String = ""
func _ready():
	print("Door ready, next_level_path:", next_level_path)
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node):
	print("Collision detected with:", body.name, "Groups:", body.get_groups())
	if body.is_in_group("Player"):
		print("Player detected, attempting to load:", next_level_path)
		get_tree().change_scene_to_file("res://first_level_complete.tscn")
