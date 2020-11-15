tool
extends MeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	mesh.connect("changed",self,"update_collision_shape")
	pass # Replace with function body.

func update_collision_shape():
	var shape = mesh.create_trimesh_shape()
	var col_shape_node = get_parent().get_node_or_null("CollisionShape")
	if col_shape_node:
		col_shape_node.set_shape(shape)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
