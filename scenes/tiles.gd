tool
extends Node

export(bool) var reset = false setget onReset

#config
var tileSize = 10
var spritesheet = preload("res://images/sprites.png")

func _ready():
    pass

func onReset(isTriggered):
	if (isTriggered):
		reset = false
		var w = spritesheet.get_width() / tileSize
		var h = spritesheet.get_height() / tileSize
		
		for y in range(h):
			for x in range(w):
				var tile = Sprite.new()
				add_child(tile)
				tile.set_owner(self)
				tile.set_name(str(x+y*w))
				tile.set_texture(spritesheet)
				tile.set_region(true)
				tile.set_region_rect(Rect2(x*tileSize, y*tileSize, tileSize, tileSize))
				tile.set_pos(Vector2(x*tileSize+tileSize/2, y*tileSize+tileSize/2))
		reset = true
	else:
		for i in range(0, get_child_count()):
    		get_child(i).queue_free()
		reset = false