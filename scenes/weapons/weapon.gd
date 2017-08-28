extends Sprite

var c_up = false
var c_down = false
var c_shoot = false

var cooldown = 0.1
var timer = 0.0
var canShoot = true

var deviation = 0.1
var looksRight = true

func _ready():
	get_parent().connect("right", self, "right")
	get_parent().connect("left", self, "left")
	get_parent().connect("weaponPointChanged", self, "changePos")
	set_fixed_process(true)

func _fixed_process(delta):
	timer -= delta
	if (timer < 0.0):
		timer = 0

	if c_up and get_rot() * get_scale().x <= 1:
		set_rot(get_rot() + 3 * delta * get_scale().x)
	elif c_down and get_rot() * get_scale().x >= -1:
		set_rot(get_rot() - 3 * delta * get_scale().x)
	
	if(c_shoot):
		shoot()

func shoot():
	if (canShoot and timer <= 0.0):
		if(get_node("AreaBlock").get_overlapping_bodies().size() > 1):
			return
		var bullet = load("res://scenes/weapons/bullet.tscn").instance()
		get_node("Laser").add_exception(bullet)
		bullet.rotation = get_rot()
		if(get_scale().x < 0):
			bullet.rotation += (PI)
		bullet.set_pos(get_node("OutPoint").get_global_pos())
		get_node("Sound").play("gun_shot")
		get_parent().get_parent().add_child(bullet)
		set_rot(get_rot() + deviation * (randf() - 0.5))
		timer = cooldown

func right():
	if(not looksRight):
		set_rot(-get_rot())
	set_scale(Vector2(1, 1))
	looksRight = true

func left():
	if(looksRight):
		set_rot(-get_rot())
	set_scale(Vector2(-1, 1))
	looksRight = false

func changePos(p):
	set_pos(p[0])