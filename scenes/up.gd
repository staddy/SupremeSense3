extends Area2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	for b in get_overlapping_bodies():
		b.set_linear_velocity(b.get_linear_velocity() - Vector2(sin(get_rot()), cos(get_rot())) * 5000 * delta)
