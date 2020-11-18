extends Spatial

class_name VoxMeshHandler

export(float) var cube_width = 1
export(Vector3) var chunk_dimensions = Vector3(256,256,128)
export(int) var execute_func
export(int) var chunk_size = 16

export(ShaderMaterial) var voxel_mesh_material

enum FUNC_OPTIONS {GENERATE_CHILDREN,TEST_RAYCAST,GENERATE_CHILDREN_CONCAVE}
export (FUNC_OPTIONS) var func_option

export(Vector3) var test_ray_from
export(Vector3) var test_ray_to
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
