extends Node2D

var c_up = false
var c_down = false
var c_shoot = false

var cooldown = 0.1
var timer = 0.0
var canShoot = true

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	timer -= delta
	if (timer < 0.0):
		timer = 0

	if c_up and get_rot() <= 1:
		set_rot(get_rot() + 3 * delta)
	elif c_down and get_rot() >= -1:
		set_rot(get_rot() - 3 * delta)
	
	if(c_shoot):
		shoot()

func shoot():
	if (canShoot and timer <= 0.0):
		var bullet = load("res://scenes/weapons/bullet.tscn").instance()
		bullet.rotation = get_rot()
		bullet.set_pos(get_node("OutPoint").get_global_pos())
		get_node("Sound").play("gun_shot")
		get_parent().get_parent().add_child(bullet)
		timer = cooldown