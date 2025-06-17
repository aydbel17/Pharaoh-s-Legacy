extends CharacterBody2D

enum State { IDLE, RUNNING, JUMPING, FALLING, DASHING, SLIDING, CROUCHING }

@export var input_left: String = "ui_left"
@export var input_right: String = "ui_right"
@export var input_jump: String = "ui_accept"
@export var input_dash: String = "ui_select"
@export var input_crouch: String = "ui_down"

@export var speed: float = 300.0
@export var jump_velocity: float = -350.0
@export var dash_speed: float = 700.0
@export var dash_time: float = 0.4
@export var slide_speed: float = 600.0  # Speed when initiating a slide
@export var slide_time: float = 0.4     # Duration of the slide
@export var slide_friction: float = 1000.0  # Deceleration rate when sliding
@export var slide_cooldown: float = 0.5  # Cooldown between slides
@export var standstill_slide_factor: float = 0.5  # Speed multiplier for sliding from standstill

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_state: State = State.IDLE
var can_double_jump: bool = false
var has_double_jumped: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var slide_timer: float = 0.0
var slide_direction: float = 0.0  # Direction of the slide (-1 or 1)
var slide_cooldown_timer: float = 0.0  # Timer for slide cooldown
var can_slide: bool = true  # Tracks if sliding is allowed

@onready var normal_collision = $NormalCollision
@onready var crouch_collision = $CrouchCollision
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	crouch_collision.disabled = true
	print("Player initialized. NormalCollision: ", normal_collision, " CrouchCollision: ", crouch_collision, " AnimatedSprite: ", animated_sprite)

func _physics_process(delta: float):
	if not is_on_floor() and current_state != State.DASHING:
		velocity.y += gravity * delta
	
	# Update cooldown timer
	if slide_cooldown_timer > 0:
		slide_cooldown_timer -= delta
		if slide_cooldown_timer <= 0:
			can_slide = true
	
	handle_input()
	update_movement(delta)
	play_animation()
	move_and_slide()
	print("Physics tick. State: ", State.keys()[current_state], " Delta: ", delta, " Position: ", position)  # Debug

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
			elif crouching and can_slide and (moving or Input.is_action_just_pressed(input_crouch)):
				start_slide()
			elif crouching:
				start_crouch()
			elif moving:
				current_state = State.RUNNING
			else:
				current_state = State.IDLE
		
		State.JUMPING, State.FALLING:
			if Input.is_action_just_pressed(input_jump) and can_double_jump and not has_double_jumped:
				double_jump()
			elif Input.is_action_just_pressed(input_dash):
				start_dash()
			elif is_on_floor():
				current_state = State.IDLE if abs(velocity.x) < 10 else State.RUNNING
		
		State.DASHING:
			dash_timer -= 2
			if dash_timer <= 0:
				current_state = State.FALLING if not is_on_floor() else State.IDLE
				print("Dash ended. Distance traveled: ", position.x)  # Debug
		
		State.SLIDING:
			slide_timer -= 2
			if slide_timer <= 0 or not crouching or not is_on_floor():
				end_crouch()
				current_state = State.FALLING if not is_on_floor() else State.IDLE
				can_slide = false
				slide_cooldown_timer = slide_cooldown
				print("Slide ended. Distance traveled: ", position.x)  # Debug
		
		State.CROUCHING:
			if Input.is_action_just_pressed(input_jump):
				end_crouch()
				jump()
			elif not crouching or not is_on_floor():
				end_crouch()
				current_state = State.FALLING if not is_on_floor() else State.IDLE
	
	print("Input handled. State: ", State.keys()[current_state], " Moving: ", moving, " Crouching: ", crouching)  # Debug

func update_movement(delta: float):
	var direction = Input.get_axis(input_left, input_right)
	
	match current_state:
		State.IDLE:
			velocity.x = 0
		State.RUNNING:
			velocity.x = direction * speed
			animated_sprite.flip_h = direction < 0
		State.JUMPING, State.FALLING:
			velocity.x = direction * speed
			if direction != 0:
				animated_sprite.flip_h = direction < 0
		State.DASHING:
			velocity = dash_direction * dash_speed
		State.SLIDING:
			velocity.x = move_toward(velocity.x, 0, slide_friction * delta)
			animated_sprite.flip_h = slide_direction < 0
		State.CROUCHING:
			velocity.x = 0

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
	print("Jump triggered. Velocity: ", velocity)  # Debug

func double_jump():
	velocity.y = jump_velocity * 0.8
	has_double_jumped = true
	can_double_jump = false
	current_state = State.JUMPING
	print("Double jump triggered. Velocity: ", velocity)  # Debug

func start_dash():
	var direction = Input.get_axis(input_left, input_right)
	if direction == 0:
		direction = 1 if not animated_sprite.flip_h else -1
	dash_direction = Vector2(direction, 0)
	dash_timer = dash_time
	current_state = State.DASHING
	print("Dash started. Direction: ", dash_direction, " Timer: ", dash_timer, " Position: ", position.x)  # Debug

func start_slide():
	if is_on_floor():
		normal_collision.disabled = true
		crouch_collision.disabled = false
		slide_timer = slide_time
		var direction = Input.get_axis(input_left, input_right)
		slide_direction = sign(velocity.x) if abs(velocity.x) > 50 else (direction if direction != 0 else (1 if not animated_sprite.flip_h else -1))
		var target_speed = slide_direction * slide_speed * (standstill_slide_factor if abs(velocity.x) < 50 else 1.0)
		velocity.x = lerp(velocity.x, target_speed, 0.5)
		current_state = State.SLIDING
		print("Slide started. Direction: ", slide_direction, " Timer: ", slide_timer, " Position: ", position.x)  # Debug

func start_crouch():
	if is_on_floor():
		normal_collision.disabled = true
		crouch_collision.disabled = false
		current_state = State.CROUCHING
		print("Crouch started")  # Debug

func end_crouch():
	normal_collision.disabled = false
	crouch_collision.disabled = true
	print("Crouch ended")  # Debug
