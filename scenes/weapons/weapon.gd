extends Node2D

var c_up = false
var c_down = false
var c_shoot = false

var cooldown = 0.1
var timer = 0.0
var canShoot = true

var deviation = 0.1
var looksRight = true

func _ready():
	get_parent().get_parent().connect("right", self, "right")
	get_parent().get_parent().connect("left", self, "left")
	get_parent().get_parent().connect("weaponPointChanged", self, "changePos")
	set_fixed_process(true)

func _fixed_process(delta):
	timer -= delta
	if (timer < 0.0):
		timer = 0

	#var tmp = 1
	#if !looksRight:
	#	tmp = -1
	if c_up and get_node("Sprite").get_rot() <= 1:
		get_node("Sprite").set_rot(get_node("Sprite").get_rot() + 3 * delta)
	elif c_down and get_node("Sprite").get_rot() >= -1:
		get_node("Sprite").set_rot(get_node("Sprite").get_rot() - 3 * delta)
	
	if(c_shoot):
		shoot()

func shoot():
	if (canShoot and timer <= 0.0):
		if(get_node("Sprite/AreaBlock").get_overlapping_bodies().size() > 0):
			return
		var bullet = load("res://scenes/weapons/bullet.tscn").instance()
		get_node("Sprite/Laser").add_exception(bullet)
		bullet.rotation = get_node("Sprite").get_rot()
		if(!looksRight):
			bullet.rotation = -bullet.rotation
			bullet.rotation += (PI)
		bullet.set_global_pos(get_node("Sprite/OutPoint").get_global_pos())
		get_node("Sprite/Sound").play("gun_shot")
		get_parent().get_parent().get_parent().add_child(bullet)
		get_node("Sprite").set_rot(get_node("Sprite").get_rot() + deviation * (randf() - 0.5))
		timer = cooldown

func right():
	#if(not looksRight):
	#	get_node("Sprite").set_rot(-get_node("Sprite").get_rot())
	#get_node("Sprite").set_scale(Vector2(1, 1))
	looksRight = true

func left():
	#if(looksRight):
	#	get_node("Sprite").set_rot(-get_node("Sprite").get_rot())
	#get_node("Sprite").set_scale(Vector2(-1, 1))
	looksRight = false

func changePos(p):
	set_pos(p[0])