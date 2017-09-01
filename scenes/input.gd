extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_fixed_process(true)
	#pass

func _fixed_process(delta):
	get_parent().c_move_left = Input.is_action_pressed("ui_left")
	get_parent().c_move_right = Input.is_action_pressed("ui_right")
	get_parent().c_up = Input.is_action_pressed("ui_up")
	get_parent().c_down = Input.is_action_pressed("ui_down")
	get_parent().c_crouch = Input.is_action_pressed("ui_crouch")
	get_parent().c_jump = Input.is_action_pressed("ui_jump")
	if(get_parent().get_node("Weapon") != null):
		get_parent().get_node("Weapon").c_up = Input.is_action_pressed("ui_up")
		get_parent().get_node("Weapon").c_down = Input.is_action_pressed("ui_down")
		get_parent().get_node("Weapon").c_shoot = Input.is_action_pressed("ui_shoot")
