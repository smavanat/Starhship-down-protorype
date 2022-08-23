extends KinematicBody2D

enum {
	MOVE,
	ROLL,
	ATTACK
}

const MaxSpeed = 100;
const RollSpeed = 150;
const  maxSpeed = 100;
const rollSpeed = 150;
const acceleration = 500;
const friction = 500;

var WeaponClass = preload("res://Test.tscn")

var velocity = Vector2.ZERO
var inputVector =  Vector2.ZERO;
var rollVector = Vector2.DOWN;

var state = MOVE
var instance_speed = 1000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	$Weapon.look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("attack"):
		var instance = WeaponClass.instance()
		instance.position = $Weapon/Muzzle.global_position
		instance.rotation_degrees = $Weapon/Muzzle.rotation_degrees
		instance.apply_impulse(Vector2(), Vector2(instance_speed,0).rotated($Weapon/Muzzle.global_rotation))
		get_tree().get_root().add_child(instance)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			pass
		ATTACK:
			pass
			
func move_state(delta):
	inputVector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	inputVector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up");
	inputVector = inputVector.normalized();
	
	if(inputVector != Vector2.ZERO):
		velocity = inputVector * maxSpeed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move()
	
func move():
	velocity = move_and_slide(velocity);
