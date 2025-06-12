extends CharacterBody2D

enum State { IDLE, RUNNING, JUMPING, FALLING, DASHING, SLIDING, CROUCHING }

@export var input_left: String = "ui_left"
@export var input_right: String = "ui_right"
@export var input_jump: String = "ui_accept"
@export var input_dash: String = "ui_select"
@export var input_crouch: String = "ui_down"

@export var speed: float = 300.0
@export var jump_velocity: float = -800.0
@export var dash_speed: float = 1000.0
@export var dash_time: float = 0.2
@export var slide_time: float = 0.4

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_state: State = State.IDLE
var can_double_jump: bool = false
var has_double_jumped: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var slide_timer: float = 500.0

@onready var normal_collision = $NormalCollision
@onready var crouch_collision = $CrouchCollision
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	crouch_collision.disabled = true

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	handle_input()
	update_movement()
	play_animation()
	move_and_slide()

func handle_input():
	var moving = Input.is_action_pressed(input_left) or Input.is_action_pressed(input_right)
	var crouching = Input.is_action_pressed(input_crouch)
	
	match current_state:
		State.IDLE, State.RUNNING:
			if not is_on_floor():
				current_state = State.FALLING
			elif Input.is_action_just_pressed(input_jump):
				jump()
			elif Input.is_action_just_pressed(input_dash):
				start_dash()
			elif crouching and moving:
				start_slide()
			elif crouching:
				start_crouch()
			elif moving:
				current_state = State.RUNNING
			else:
				current_state = State.IDLE
		
		State.JUMPING, State.FALLING:
			if Input.is_action_just_pressed(input_jump) and can_double_jump:
				double_jump()
			elif Input.is_action_just_pressed(input_dash):
				start_dash()
			elif is_on_floor():
				current_state = State.IDLE if abs(velocity.x) < 10 else State.RUNNING
		
		State.DASHING:
			dash_timer -= get_physics_process_delta_time()
			if dash_timer <= 0:
				current_state = State.FALLING if not is_on_floor() else State.IDLE
		
		State.SLIDING:
			slide_timer -= get_physics_process_delta_time()
			if slide_timer <= 0 or not crouching or not is_on_floor():
				end_crouch()
				current_state = State.FALLING if not is_on_floor() else State.IDLE
		
		State.CROUCHING:
			if Input.is_action_just_pressed(input_jump):
				end_crouch()
				jump()
			elif not crouching or not is_on_floor():
				end_crouch()
				current_state = State.FALLING if not is_on_floor() else State.IDLE

func update_movement():
	var direction = Input.get_axis(input_left, input_right)
	
	match current_state:
		State.IDLE:
			velocity.x = 0 # Instant stop
		State.RUNNING:
			velocity.x = direction * speed # Instant full speed
			animated_sprite.flip_h = direction < 0
		State.JUMPING, State.FALLING:
			velocity.x = direction * speed # Instant full speed or stop
			if direction != 0:
				animated_sprite.flip_h = direction < 0
		State.DASHING:
			velocity = dash_direction * dash_speed # Dash remains unchanged
		State.SLIDING:
			velocity.x = slide_direction * slide_speed
			animated_sprite.flip_h = slide_direction < 0
		State.CROUCHING:
			velocity.x = 0 # No movement while crouching

func play_animation():
	match current_state:
		State.IDLE: animated_sprite.play("Idle")
		State.RUNNING: animated_sprite.play("Run")
		State.JUMPING: animated_sprite.play("Jump")
		State.DASHING: animated_sprite.play("Dash")
		State.SLIDING: animated_sprite.play("Slide")
		State.CROUCHING: animated_sprite.play("Crouch")

func jump():
	velocity.y = jump_velocity
	can_double_jump = true
	has_double_jumped = false
	current_state = State.JUMPING

func double_jump():
	velocity.y = jump_velocity * 0.8
	has_double_jumped = true
	can_double_jump = false

func start_dash():
	var direction = Input.get_axis(input_left, input_right)
	if direction == 0:
		direction = 1 if not animated_sprite.flip_h else -1 # Use facing direction as fallback
	dash_direction = Vector2(direction, 0)
	dash_timer = dash_time
	current_state = State.DASHING

func start_slide():
	if is_on_floor():
		normal_collision.disabled = true
		crouch_collision.disabled = false
		slide_timer = slide_time
		current_state = State.SLIDING

func start_crouch():
	if is_on_floor():
		normal_collision.disabled = true
		crouch_collision.disabled = false
		current_state = State.CROUCHING

func end_crouch():
	normal_collision.disabled = false
	crouch_collision.disabled = true
