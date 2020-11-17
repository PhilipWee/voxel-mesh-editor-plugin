extends Spatial

class_name VoxMeshHandler

export(float) var cube_width = 1
export(Vector3) var chunk_dimensions = Vector3(256,256,128)
export(int) var generate_children
export(int) var chunk_size = 16
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func generate_child_meshes_and_col():
	pass
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
