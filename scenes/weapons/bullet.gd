extends RigidBody2D

var rotation = 0.0
var direction = Vector2(1, 0)
var deviation = 0
var speed = 500.0
var damage = 5.0
var removeTimer = 5.0

func _ready():
	direction = direction.rotated(rotation)
	set_linear_velocity(direction * speed + Vector2(randf() - 0.5, randf() - 0.5) * deviation)
	set_rot(rotation)
	set_fixed_process(true)

func _on_body_enter(body):
	#if body.is_in_group("enemy"):
	#	body.damage(damage)
	get_node("Sound").play("hit")
	set_max_contacts_reported(0)
	get_node("CollisionShape").set_trigger(true)
	get_node("CollisionShape2").set_trigger(true)
	get_node("CollisionShape3").set_trigger(true)
	if(randf() > 0.5):
		set_linear_velocity(-get_linear_velocity() / 20)
	else:
		get_node("Sprite").hide()
	removeTimer = 0.5

func _fixed_process(delta):
	removeTimer -= delta
	if(removeTimer <= 0):
		queue_free()
	"""var p = get_pos()
	var par = get_parent().get_size()
	if p.x < 0 || p.x > par.width || p.y < 0 || p.y > par.height:
		queue_free()"""
