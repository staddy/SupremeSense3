extends RigidBody2D

# Character Demo, written by Juan Linietsky.
#
# Implementation of a 2D Character controller.
# This implementation uses the physics engine for
# controlling a character, in a very similar way
# than a 3D character controller would be implemented.
#
# Using the physics engine for this has the main
# advantages:
# -Easy to write.
# -Interaction with other physics-based objects is free
# -Only have to deal with the object linear velocity, not position
# -All collision/area framework available
# 
# But also has the following disadvantages:
#  
# -Objects may bounce a little bit sometimes
# -Going up ramps sends the chracter flying up, small hack is needed.
# -A ray collider is needed to avoid sliding down on ramps and  
#   undesiderd bumps, small steps and rare numerical precision errors.
#   (another alternative may be to turn on friction when the character is not moving).
# -Friction cant be used, so floor velocity must be considered
#  for moving platforms.

# Member variables
var anim = ""
var siding_left = false
var jumping = false
var stopping_jump = false
var shooting = false

var crouching = false setget setCrouching, getCrouching

var WALK_ACCEL = 800.0
var WALK_DEACCEL = 800.0
var WALK_MAX_VELOCITY = 100.0
var AIR_ACCEL = 200.0
var AIR_DEACCEL = 200.0
var JUMP_VELOCITY = 50.0
var STOP_JUMP_FORCE = 900.0

var MAX_FLOOR_AIRBORNE_TIME = 0.07

var airborne_time = 1e20
var shoot_time = 1e20

var MAX_SHOOT_POSE_TIME = 0.3

#var bullet = preload("res://bullet.tscn")

var floor_h_velocity = 0.0
var enemy

var c_move_left = false
var c_move_right = false
var c_up = false
var c_down = false
var c_crouch = false
var c_jump = false
var c_shoot = false

onready var weaponPoint = get_node("WeaponPoint1").get_pos()

signal right
signal left
signal weaponPointChanged

func setCrouching(c):
	if(c != crouching):
		if(not c):
			if(get_node("AreaUp").get_overlapping_bodies().size() > 1):
				return
		get_node("CollisionCrouching").set_trigger(not c)
		get_node("Collision").set_trigger(c)
		get_node("AreaUp/CollisionUp").set_trigger(not c)
		if(c):
			weaponPoint = get_node("WeaponPoint2").get_pos()
		else:
			weaponPoint = get_node("WeaponPoint1").get_pos()
		emit_signal("weaponPointChanged", [weaponPoint])
		crouching = c

func getCrouching():
	return crouching


func _integrate_forces(s):
	var lv = s.get_linear_velocity()
	var step = s.get_step()
	
	var new_anim = anim
	var new_siding_left = siding_left
	
	# Get the controls
	var move_left = c_move_left
	var move_right = c_move_right
	if(c_crouch):
		self.crouching = true
	else:
		self.crouching = false
	var jump = c_jump
	var shoot = c_shoot
	#var spawn = Input.is_action_pressed("spawn")
	
	"""if spawn:
		var e = enemy.instance()
		var p = get_pos()
		p.y = p.y - 100
		e.set_pos(p)
		get_parent().add_child(e)"""
	
	# Deapply prev floor velocity
	lv.x -= floor_h_velocity
	floor_h_velocity = 0.0
	
	# Find the floor (a contact with upwards facing collision normal)
	var found_floor = false
	var floor_index = -1
	
	for x in range(s.get_contact_count()):
		var ci = s.get_contact_local_normal(x)
		if (ci.dot(Vector2(0, -1)) > 0.6):
			found_floor = true
			floor_index = x
	
	# A good idea when impementing characters of all kinds,
	# compensates for physics imprecission, as well as human reaction delay.
	if (shoot and not shooting):
		shoot_time = 0
		#var bi = bullet.instance()
		var ss
		if (siding_left):
			ss = -1.0
		else:
			ss = 1.0
		#var pos = get_pos() + get_node("bullet_shoot").get_pos()*Vector2(ss, 1.0)
		
		#bi.set_pos(pos)
		#get_parent().add_child(bi)
		
		#bi.set_linear_velocity(Vector2(800.0*ss, -80))
		#get_node("sprite/smoke").set_emitting(true)
		#get_node("sound").play("shoot")
		#PS2D.body_add_collision_exception(bi.get_rid(), get_rid()) # Make bullet and this not collide
	else:
		shoot_time += step
	
	if (found_floor):
		airborne_time = 0.0
	else:
		airborne_time += step # Time it spent in the air
	
	var on_floor = airborne_time < MAX_FLOOR_AIRBORNE_TIME

	# Process jump
	if (jumping):
		# We want the character to immediately change facing side when the player
		# tries to change direction, during air control.
		# This allows for example the player to shoot quickly left then right.
		if (move_left and not move_right):
			get_node("Sprite").set_scale(Vector2(-1, 1))
			emit_signal("left")
		if (move_right and not move_left):
			get_node("Sprite").set_scale(Vector2(1, 1))
			emit_signal("right")

		if (lv.y > 0):
			# Set off the jumping flag if going down
			jumping = false
		elif (not jump):
			stopping_jump = true
		
		if (stopping_jump):
			lv.y += STOP_JUMP_FORCE*step
	
	if (on_floor):
		# Process logic when character is on floor
		if (move_left and not move_right):
			if (lv.x > -WALK_MAX_VELOCITY):
				lv.x -= WALK_ACCEL*step
		elif (move_right and not move_left):
			if (lv.x < WALK_MAX_VELOCITY):
				lv.x += WALK_ACCEL*step
		else:
			var xv = abs(lv.x)
			xv -= WALK_DEACCEL*step
			if (xv < 0):
				xv = 0
			lv.x = sign(lv.x)*xv
		
		# Check jump
		if (not jumping and jump):
			lv.y = -JUMP_VELOCITY
			jumping = true
			stopping_jump = false
			#get_node("sound").play("jump")

		# Check siding
		if (lv.x < 0 and move_left):
			new_siding_left = true
		elif (lv.x > 0 and move_right):
			new_siding_left = false
		if (jumping):
			new_anim = "jumping"
		elif (abs(lv.x) < 0.1):
			if (shoot_time < MAX_SHOOT_POSE_TIME):
				new_anim = "idle_weapon"
			else:
				new_anim = "idle"
		else:
			if (shoot_time < MAX_SHOOT_POSE_TIME):
				new_anim = "run_weapon"
			else:
				new_anim = "run"
	else:
		# Process logic when the character is in the air
		if (move_left and not move_right):
			if (lv.x > -WALK_MAX_VELOCITY):
				lv.x -= AIR_ACCEL*step
		elif (move_right and not move_left):
			if (lv.x < WALK_MAX_VELOCITY):
				lv.x += AIR_ACCEL*step
		else:
			var xv = abs(lv.x)
			xv -= AIR_DEACCEL*step
			if (xv < 0):
				xv = 0
			lv.x = sign(lv.x)*xv
		
		if (lv.y < 0):
			if (shoot_time < MAX_SHOOT_POSE_TIME):
				new_anim = "jumping_weapon"
			else:
				new_anim = "jumping"
		else:
			if (shoot_time < MAX_SHOOT_POSE_TIME):
				new_anim = "falling_weapon"
			else:
				new_anim = "falling"
	
	# Update siding
	if (new_siding_left != siding_left):
		if (new_siding_left):
			get_node("Sprite").set_scale(Vector2(-1, 1))
			emit_signal("left")
		else:
			get_node("Sprite").set_scale(Vector2(1, 1))
			emit_signal("right")
		
		siding_left = new_siding_left
	
	# Change animation
	if (new_anim != anim):
		anim = new_anim
		#get_node("anim").play(anim)
	
	shooting = shoot
	
	# Apply floor velocity
	if (found_floor):
		floor_h_velocity = s.get_contact_collider_velocity_at_pos(floor_index).x
		lv.x += floor_h_velocity
	
	# Finally, apply gravity and set back the linear velocity
	lv += s.get_total_gravity()*step
	s.set_linear_velocity(lv)


func _ready():
	#set_process_input(true)
	pass
	#set_fixed_process(true)
	#enemy = ResourceLoader.load("res://enemy.tscn")
	
#	if !Globals.has_singleton("Facebook"):
#		return
#	var Facebook = Globals.get_singleton("Facebook")
#	var link = Globals.get("facebook/link")
#	var icon = Globals.get("facebook/icon")
#	var msg = "I just sneezed on your wall! Beat my score and Stop the Running nose!"
#	var title = "I just sneezed on your wall!"
#	Facebook.post("feed", msg, title, link, icon)
