extends Control

@onready var start_button = $ButtonContainer/StartButton
@onready var quit_button = $ButtonContainer/QuitButton
@onready var transition_rect = $TransitionRect  # Optional for fade effect

func _ready():
	# Verify textures are assigned
	if start_button.texture_normal == null:
		print("Warning: StartButton texture not set")
	if quit_button.texture_normal == null:
		print("Warning: QuitButton texture not set")
	
	# Connect signals if not done in editor
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Optional: Initialize transition rect (if using fade)
	if transition_rect:
		transition_rect.color.a = 0.0

func _on_start_button_pressed():
	# Start fade-out transition (if using)
	if transition_rect:
		var tween = create_tween()
		tween.tween_property(transition_rect, "color:a", 1.0, 0.5)  # Fade to black in 0.5s
		tween.tween_callback(_load_game_level)  # Load level after fade
	else:
		_load_game_level()
	print("Start button pressed. Loading GameLevel.tscn")

func _load_game_level():
	get_tree().change_scene_to_file("res://GameLevel.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
	print("Quit button pressed. Exiting game")

# Optional: Hover effects for buttons
func _on_start_button_mouse_entered():
	start_button.modulate = Color(1.2, 1.2, 1.2)  # Brighten
	print("Start button hovered")

func _on_start_button_mouse_exited():
	start_button.modulate = Color(1, 1, 1)  # Reset
	print("Start button hover exited")

func _on_quit_button_mouse_entered():
	quit_button.modulate = Color(1.2, 1.2, 1.2)
	print("Quit button hovered")

func _on_quit_button_mouse_exited():
	quit_button.modulate = Color(1, 1, 1)
	print("Quit button hover exited")
