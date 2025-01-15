extends CharacterBody2D

#State variable for current character
var character_state
enum possible_states {
	on_ground = 0,
	mid_air = 1,
	wall_grab = 2,
	jumping = 4,
}

#State variable for currently equipped spirit
var spirit_state
enum spirits {
	plant = 0,
	air = 1,
	water = 2,
	earth = 3,
	fire = 4,
}

#Basic movement variables
@onready var _animated_sprite = $AnimatedSprite2D
var speed = 300.0
var jump_speed = -400.0
var air_friction = 0.20
var friction = 0.15
var air_acceleration = 0.01
var acceleration = 0.25
var current_momentum = 0

#Coyote Time variables
@onready var _coyote_timer = $CoyoteTimer
var coyote_frames = 12 # For how many frames you can jump after leaving the floor
var coyote = false # Whether or not coyote time is still active
var last_floor = false # Whether we were previously on the floor or not
var jumping = false # Whether we are currently jumping

#Dash variables
@onready var _dash_cooldown_timer = $DashCooldown
var dash_cooldown = 0.5 # How many seconds it takes for the dash to come back
var dashed = false # Whether or not we just dashed
var dash_speed = 2500 # How strong the initial burst of speed is on the dash

#Wall grab/bounce variables
var gravity_on = true # Gravity toggle so that we can let the player grab the wall
var was_on_wall = false # Previous state of is_on_wall so that we can make wall grabbing difficult in terms of timing


# Get the gravity from the project settings so you can sync with rigid body nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	#print("Character initialized with gravity of ", gravity)
	_coyote_timer.wait_time = coyote_frames / 60.0
	_dash_cooldown_timer.wait_time = dash_cooldown
	character_state = possible_states.on_ground
	
func _on_coyote_timer_timeout():
	print("Coyote Time over")
	coyote = false
	
func get_input():
	var dir = Input.get_axis("move_left", "move_right")
	var right = Input.is_action_pressed('move_right')
	var left = Input.is_action_pressed('move_left')
	var dash = Input.is_action_pressed("dash")
	var wall_grab = Input.is_action_pressed("wall_grab")
	
	if dir > 0:
		_animated_sprite.set_flip_h(false)
		_animated_sprite.play("run")
	if dir < 0:
		_animated_sprite.set_flip_h(true)
		_animated_sprite.play("run")

	if dir != 0:
		if character_state == possible_states.wall_grab:
			velocity.x = 0.0
		elif is_on_floor(): # If we're on the floor, accelerate based on normal acceleration and set the momentum direction accordingly
			velocity.x = lerp(velocity.x, dir * speed, acceleration)
			current_momentum = dir
		elif dashed: # If we have dashed at all, we need to deccelerate using the much faster air_friction
			velocity.x = lerp(velocity.x, dir * speed, air_friction)
		elif not dashed or current_momentum != dir: # If we have not dashed (jumped in the direction we were running) or changed directions midair, deccelerate very slowly
			velocity.x = lerp(velocity.x, dir * (speed * 0.75), air_acceleration)
	else: # If no directional buttons are being pressed, deccelerate to 0.0 normally
		velocity.x = lerp(velocity.x, 0.0, friction)
	#print("Lerp: ", lerp(velocity.x, dir * speed, acceleration), "Dir: ", dir)
	#print("Vel: ", velocity.x)
	
	#Dash controls
	if dash and not dashed:
		dashed = true
		if dir < 0:
			velocity.x -= dash_speed
		elif dir > 0:
			velocity.x += dash_speed
		_dash_cooldown_timer.start()
	#print("Dashed: ", dashed)
	
	#Wall grab controls
	if wall_grab and is_on_wall():
		if character_state != possible_states.wall_grab and character_state != possible_states.jumping:
			velocity.x = 0
			velocity.y = 0
		character_state = possible_states.wall_grab
		gravity_on = false
	
	if not wall_grab or not is_on_wall():
		character_state = possible_states.mid_air
		gravity_on = true
		
	
	if dir == 0 or not is_on_floor():
		_animated_sprite.stop()

func _physics_process(delta):
	if gravity_on:
		# Add the gravity.
		velocity.y += gravity * delta
	# Get current input from player
	get_input()
	#update
	move_and_slide()
	# move_and_slide is the function that sets the on floor variable, 
	# so we should check for jumping after move_and_slide and update state
	if is_on_floor():
		character_state = possible_states.on_ground
	if jumping and is_on_floor():
		jumping = false
	if not is_on_floor() and not is_on_wall():
		character_state = possible_states.mid_air
	if (is_on_floor() or coyote or (not was_on_wall and is_on_wall()) or character_state == possible_states.wall_grab) and Input.is_action_just_pressed('jump'):
			if not was_on_wall and is_on_wall() or character_state == possible_states.wall_grab:
				#If you jump on the first frame you hit the wall, you get a wall bounce
				print("Wall jump")
				velocity.x = -speed
			if not was_on_wall and is_on_wall(): #Reward player for wall bounce with extra jump height
				velocity.y = jump_speed * 1.5
			else:
				velocity.y = jump_speed
			jumping = true
			character_state = possible_states.jumping
	#print("On_floor: ", is_on_floor(), "Last_floor: ", last_floor, ", Jumping: ", jumping)
	if not is_on_floor() and last_floor and not jumping:
		coyote = true
		print("Entering Coyote Time")
		$CoyoteTimer.start()
	last_floor = is_on_floor()
	was_on_wall = is_on_wall()


func _on_button_pressed() -> void:
	position.x = 400
	position.y = 400


func _on_dash_cooldown_timeout() -> void:
	dashed = false
