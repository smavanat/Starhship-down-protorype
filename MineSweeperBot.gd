extends KinematicBody2D

enum{
	IDLE,
	WANDER,
	CHASE
}

export var max_speed = 100
export var steer_force = 0.1
export var look_ahead = 100
export var num_rays = 32;

#context array
var ray_directions = []
var interest = []
var danger = []

var chosen_dir = Vector2.ZERO
var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var state = IDLE


onready var player_detection_zone = get_node("PlayerDetectionZone")
onready var wander_controller = $WanderController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interest.resize(num_rays)
	danger.resize(num_rays)
	ray_directions.resize(num_rays)
	for i in num_rays:
		var angle = i * 2 * PI / num_rays
		ray_directions[i] = Vector2.RIGHT.rotated(angle)

func _physics_process(delta: float):
	set_interest(delta)
	set_danger()
	choose_direction()
	var desired_velocity = chosen_dir.rotated(rotation) * max_speed
	velocity = velocity.linear_interpolate(desired_velocity, steer_force)
	#rotation = velocity.angle()
	move_and_slide(velocity)

func set_interest(delta):
	var player = player_detection_zone.player
	#Set interest in each slot based on world direction
	match state:
		IDLE:
			velocity  = velocity.move_toward(Vector2.ZERO, delta)
			seek_player()
			#Randomly switch between wander and idle states
			if wander_controller.get_time_left() ==0:
				state = pick_random_state(IDLE, WANDER)
				wander_controller.start_wander_timer(rand_range(1,3))
		#Move towards random position close to start point
		WANDER:
			seek_player()
			#THIS DOESN'T WORK FOR SOME REASON, TARGET POSITION COMES UP AS A NULL VALUE EVEN WHEN IT CAN BE DISPLAYED USING PRINT. FIND ALTERNATE METHOD.
			if wander_controller.get_time_left() == 0:
				#print(wander_controller.target_position)
				state = pick_random_state(IDLE, WANDER)
				wander_controller.start_wander_timer(rand_range(1,3))
			var direction = (wander_controller.target_position - global_position).normalized()#global_position.direction_to(wander_controller.target_position)
			for i in num_rays:
				var d = ray_directions[i].rotated(rotation).dot(direction)
				interest[i] = max(0, d)
			print(interest)
		#If player enters detection zone, chase them
		CHASE:
			if player != null:
				var direction = (player.global_position - global_position).normalized()
				for i in num_rays:
					var d = ray_directions[i].rotated(rotation).dot(direction)
					interest[i] = max(0, d)
			else:
				state = IDLE
	#print(state)
#func set_default_interest():
#	#default to moving forward
#	for i in num_rays:
#		var d = ray_directions[i].rotated(rotation).dot(transform.x)
#		interest[i] = max(0, d )

func set_danger():
	#Cast rays to find danger directions
	var space_state = get_world_2d().direct_space_state
	for i in num_rays:
		var result = space_state.intersect_ray(position, position+ray_directions[i].rotated(rotation)*look_ahead, [self], 0x1)
		danger[i] = 1.0 if result else 0.0
		
func choose_direction():
	#Eliminate interest in slots with danger
	for i in num_rays:
		if danger[i] > 0.0:
			interest[i] = 0.0
	#Choose direction based on remaining interest
	chosen_dir = Vector2.ZERO
	for i in num_rays:
		if state !=IDLE:
			chosen_dir += ray_directions[i] * interest[i] 
		else:
			chosen_dir = Vector2.ZERO
	chosen_dir = chosen_dir.normalized()

#Sees if the player enters the detection zone
func seek_player():
	if player_detection_zone.can_see_player():
		state = CHASE
		
func pick_random_state(state0, state1):
	var state_list = [state0, state1]
	state_list.shuffle()
	return state_list.pop_front()
