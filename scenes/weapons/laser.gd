extends RayCast2D

onready var collisionPoint = get_cast_to()

func _ready():
	add_exception(get_parent())
	add_exception(get_parent().get_parent())
	set_fixed_process(true)

func _draw():
	draw_line(get_pos(), collisionPoint, Color(255, 0, 0, 0.2), 1)

func _fixed_process(delta):
	if is_colliding():
		collisionPoint = Vector2(get_collision_point().distance_to(get_global_pos()), 0)
	else:
		collisionPoint = get_cast_to()
	update()
