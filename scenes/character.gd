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

enum {STATE_GROUND, STATE_AIR, STATE_WALLSLIDE, STATE_SMASHDOWN, STATE_SOMERSAULT}

# Member variables

var state = STATE_AIR
var wallslide_k = 0.2
var smashdown_speed = 250.0

var anim = ""
var siding_left = false
var jumping = false
var stopping_jump = false
var on_floor = false

var crouching = false setget setCrouching, getCrouching

var WALK_ACCEL = 1000.0
var WALK_DEACCEL = 1000.0
var WALK_MAX_VELOCITY_CROUCH = 30.0
var WALK_MAX_VELOCITY_STAY = 100.0
var WALK_MAX_VELOCITY = WALK_MAX_VELOCITY_STAY
var AIR_ACCEL = 400.0
var AIR_DEACCEL = 400.0
var JUMP_VELOCITY = 250#110.0
var STOP_JUMP_FORCE = 900.0

var MAX_FLOOR_AIRBORNE_TIME = 0.07

var airborne_time = 1e20

var floor_h_velocity = 0.0
var enemy

var c_move_left = false
var c_move_right = false
var c_up = false
var c_down = false
var c_crouch = false
var c_jump = false
var c_shoot = false

onready var weaponPoint = get_node("Sprite/WeaponPoint1").get_pos()

signal right
signal left
signal weaponPointChanged

func setCrouching(c):
	if(c != crouching):
		if(not c):
			if(get_node("AreaUp").get_overlapping_bodies().size() > 0):
				return
		get_node("CollisionCrouching").set_trigger(not c)
		get_node("Collision").set_trigger(c)
		get_node("AreaUp/CollisionUp").set_trigger(not c)
		if(c):
			WALK_MAX_VELOCITY = WALK_MAX_VELOCITY_CROUCH
			weaponPoint = get_node("Sprite/WeaponPoint2").get_pos()
			get_node("AnimationTreePlayer").oneshot_node_start("oneshot")
		else:
			WALK_MAX_VELOCITY = WALK_MAX_VELOCITY_STAY
			weaponPoint = get_node("Sprite/WeaponPoint1").get_pos()
			get_node("AnimationTreePlayer").oneshot_node_start("oneshot2")
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
	if(c_crouch && on_floor):
		self.crouching = true
	else:
		self.crouching = false
	var jump = c_jump
	if(self.crouching):
		jump = false
	var shoot = c_shoot
	
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
	
	if (found_floor):
		airborne_time = 0.0
	else:
		airborne_time += step # Time it spent in the air
	
	on_floor = airborne_time < MAX_FLOOR_AIRBORNE_TIME

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
	
	#get_node("AnimationTreePlayer").transition_node_set_current("transition_jump", 0)
	if (on_floor):
		# Process logic when character is on floor
		state = STATE_GROUND
		
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
			get_node("AnimationTreePlayer").transition_node_set_current("transition_jump", 1)
		elif (abs(lv.x) < 0.1) and anim != "crouch_stay" and anim != "stay_crouch":
			new_anim = "idle"
			get_node("AnimationTreePlayer").transition_node_set_current("transition_jump", 0)
			get_node("AnimationTreePlayer").transition_node_set_current("transition", 0)
			get_node("AnimationTreePlayer").transition_node_set_current("transition_crouch", 0)
		else:
			new_anim = "run"
			get_node("AnimationTreePlayer").transition_node_set_current("transition_jump", 0)
			get_node("AnimationTreePlayer").transition_node_set_current("transition", 1)
			get_node("AnimationTreePlayer").transition_node_set_current("transition_crouch", 1)
	else:
		# Process logic when the character is in the air
		if(state != STATE_SMASHDOWN):
			state = STATE_AIR
			if(c_down):
				state = STATE_SMASHDOWN
			else:
				if !jumping and (move_left and get_node("AreaLeft").get_overlapping_bodies().size() > 0) or (move_right and get_node("AreaRight").get_overlapping_bodies().size() > 0):
					state = STATE_WALLSLIDE
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
		
		get_node("AnimationTreePlayer").transition_node_set_current("transition_jump", 1)
	
	# Update siding
	if (new_siding_left != siding_left):
		if (new_siding_left):
			get_node("Sprite").set_scale(Vector2(-1, 1))
			emit_signal("left")
		else:
			get_node("Sprite").set_scale(Vector2(1, 1))
			emit_signal("right")
		
		siding_left = new_siding_left
	
	if(self.crouching):
		new_anim += "_crouch"
		get_node("AnimationTreePlayer").transition_node_set_current("transition2", 1)
	else:
		get_node("AnimationTreePlayer").transition_node_set_current("transition2", 0)
	
	# Change animation
	if (new_anim != anim):
		anim = new_anim
		#get_node("Animation").play(anim)
	
	# Apply floor velocity
	if (found_floor):
		floor_h_velocity = s.get_contact_collider_velocity_at_pos(floor_index).x
		lv.x += floor_h_velocity
	
	# Finally, apply gravity and set back the linear velocity
	if(state == STATE_SMASHDOWN):
		s.set_linear_velocity(Vector2(0, smashdown_speed))
	else:
		var k = 1.0
		if(state == STATE_WALLSLIDE):
			k = wallslide_k
		lv += s.get_total_gravity() * step * k
		s.set_linear_velocity(lv)


func _ready():
	#get_node("AreaUp").set_layer_mask(self.get_layer_mask())
	#get_node("AreaUp").set_collision_mask(self.get_collision_mask())
	get_node("AnimationTreePlayer").set_active(true)
	#pass
	#set_process_input(true)
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
