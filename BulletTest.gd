extends Area2D

export (int) var speed
export (int) var damage
export (float) var lifetime

var velocity =  Vector2()

func start(_position, _direction):
	position = _position
	rotation = _direction.angle()
	$Lifetime.wait_time = lifetime
	velocity = _direction * speed

func _process(delta: float):
	position += velocity * delta

func explode():
	queue_free()

func _on_BulletTest_body_entered(body: Node) -> void:
	explode()
	#if body.has_method("take_damage"):
	#	body.take_damage(damage)

func _on_Lifetime_timeout() -> void:
	explode()
