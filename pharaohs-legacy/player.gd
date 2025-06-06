extends CharacterBody2D
# Movement parameters
@export var move_speed: float = 200.0
@export var dash_speed: float = 600.0
@export var jump_velocity: float = -400.0
@export var roll_speed: float = 300.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var roll_duration: float = 0.4
@export var roll_cooldown: float = 1.0

# Gravity
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# State variables
enum State { IDLE, RUNNING, JUMPING, DASHING, ROLLING }
var current_state: State = State.IDLE
var is_facing_right: bool = true
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var roll_timer: float = 0.0
var roll_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# Node references (assuming an AnimatedSprite2D for animations)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Handle state transitions and movement
	match current_state:
		State.IDLE:
			_handle_idle_state(delta)
		State.RUNNING:
			_handle_running_state(delta)
		State.JUMPING:
			_handle_jumping_state(delta)
		State.DASHING:
			_handle_dashing_state(delta)
		State.ROLLING:
			_handle_rolling_state(delta)
	
	# Apply gravity when not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Update timers
	_update_timers(delta)
	
	# Move the character
	move_and_slide()
	
	# Update sprite facing direction
	_update_sprite_direction()

func _handle_idle_state(delta: float) -> void:
	# Play idle animation
	sprite.play("Idle")
	
	# Decelerate horizontal movement
	velocity.x = move_toward(velocity.x, 0, move_speed)
	
	# Check for movement input
	var direction: float = _get_input_direction()
	if direction != 0:
		current_state = State.RUNNING
		return
	
	# Check for jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		current_state = State.JUMPING
		velocity.y = jump_velocity
		sprite.play("Jump")
		return
	
	# Check for dash
	if Input.is_action_just_pressed("Dash") and dash_cooldown_timer <= 0:
		current_state = State.DASHING
		dash_timer = dash_duration
		dash_direction = Vector2(direction if direction != 0 else (1 if is_facing_right else -1), 0)
		sprite.play("Dash")
		return
	
	# Check for roll
	if Input.is_action_just_pressed("Roll") and roll_cooldown_timer <= 0 and is_on_floor():
		current_state = State.ROLLING
		roll_timer = roll_duration
		sprite.play("Roll")
		return

func _handle_running_state(delta: float) -> void:
	# Play running animation
	sprite.play("Run")
	
	# Get input direction
	var direction: float = _get_input_direction()
	
	# Move horizontally
	velocity.x = direction * move_speed
	
	# Transition to idle if no input
	if direction == 0:
		current_state = State.IDLE
		return
	
	# Check for jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		current_state = State.JUMPING
		velocity.y = jump_velocity
		sprite.play("Jump")
		return
	
	# Check for dash
	if Input.is_action_just_pressed("Dash") and dash_cooldown_timer <= 0:
		current_state = State.DASHING
		dash_timer = dash_duration
		dash_direction = Vector2(direction if direction != 0 else (1 if is_facing_right else -1), 0)
		sprite.play("Dash")
		return
	
	# Check for roll
	if Input.is_action_just_pressed("Roll") and roll_cooldown_timer <= 0 and is_on_floor():
		current_state = State.ROLLING
		roll_timer = roll_duration
		sprite.play("Roll")
		return

func _handle_jumping_state(delta: float) -> void:
	# Play jump animation (already set on jump start)
	
	# Get input direction for air control
	var direction: float = _get_input_direction()
	velocity.x = direction * move_speed
	
	# Transition to idle or running when landing
	if is_on_floor():
		current_state = State.IDLE if direction == 0 else State.RUNNING
		sprite.play("Idle" if direction == 0 else "Run")
		return
	
	# Check for dash
	if Input.is_action_just_pressed("Dash") and dash_cooldown_timer <= 0:
		current_state = State.DASHING
		dash_timer = dash_duration
		dash_direction = Vector2(direction if direction != 0 else (1 if is_facing_right else -1), 0)
		sprite.play("Dash")
		return

func _handle_dashing_state(delta: float) -> void:
	# Apply dash velocity
	velocity = dash_direction * dash_speed
	
	# End dash when timer expires
	if dash_timer <= 0:
		current_state = State.JUMPING if not is_on_floor() else State.IDLE
		dash_cooldown_timer = dash_cooldown
		sprite.play("Jump" if not is_on_floor() else "Idle")
		velocity.x = 0

func _handle_rolling_state(delta: float) -> void:
	# Apply roll velocity
	var direction: float = 1 if is_facing_right else -1
	velocity.x = direction * roll_speed
	
	# End roll when timer expires
	if roll_timer <= 0:
		current_state = State.IDLE
		roll_cooldown_timer = roll_cooldown
		sprite.play("Idle")
		velocity.x = 0

func _get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")

func _update_timers(delta: float) -> void:
	# Update dash timer
	if dash_timer > 0:
		dash_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Update roll timer
	if roll_timer > 0:
		roll_timer -= delta
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta

func _update_sprite_direction() -> void:
	var direction: float = _get_input_direction()
	if direction != 0:
		is_facing_right = direction > 0
	sprite.flip_h = not is_facing_right
