tool
extends EditorPlugin

var plugin
const ray_length = 1000

#Hardcode the sphere layers
var sphere_layer_point_deltas = [
	[Vector2(0,0),
	Vector2(-1,0),
	Vector2(-1,-1),
	Vector2(0,-1),
	Vector2(1,-1),
	Vector2(1,0),
	Vector2(1,1),
	Vector2(0,1),
	Vector2(-1,1),
	#New layer start
	Vector2(-1,2),
	Vector2(0,2),
	Vector2(1,2),
	Vector2(-1,-2),
	Vector2(0,-2),
	Vector2(1,-2),
	Vector2(2,-1),
	Vector2(2,0),
	Vector2(2,1),
	Vector2(-2,-1),
	Vector2(-2,0),
	Vector2(-2,1)
	],
	[Vector2(0,0),
	Vector2(-1,0),
	Vector2(-1,-1),
	Vector2(0,-1),
	Vector2(1,-1),
	Vector2(1,0),
	Vector2(1,1),
	Vector2(0,1),
	Vector2(-1,1)
	],
	[Vector2(0,0)],
]


func _enter_tree():
	set_input_event_forwarding_always_enabled ()
	plugin = preload("res://addons/VoxMeshEditorExtension/VoxMeshInspectorPlugin.gd").new()
	add_inspector_plugin(plugin)


func _exit_tree():
	remove_inspector_plugin(plugin)

# Consumes InputEventMouseMotion and forwards other InputEvent types
func forward_spatial_gui_input(camera, ev):
	if ev is InputEventMouseButton:
		if ev.pressed and (ev.button_index==1 or ev.button_index==2):
			var pos = ev.position
			var from = camera.global_transform.origin
			var to = from + camera.project_ray_normal(pos) * ray_length
			var space_state =  camera.get_world().direct_space_state
			
			var hit = space_state.intersect_ray(from,to)
	
			var pos3d = get_tree().get_edited_scene_root().get_node_or_null("Position3D")
			if pos3d != null and !hit.empty():
				pos3d.global_transform.origin = hit.position
				if ev.button_index == 1:
					create_sphere_at_point(hit.position,0.1)
				elif ev.button_index == 2:
					create_sphere_at_point(hit.position,-0.1)
	return false

func set_sphere_mag_at_point(point:Vector3,mag_delta:float):
	var vox_mesh_handler = get_tree().get_edited_scene_root().get_node_or_null('VoxMeshHandler')
	var previous_val = vox_mesh_handler.get_val_at_point(point)
	vox_mesh_handler.change_val_at_point(point,previous_val + mag_delta)
	pass

func create_sphere_at_point(point:Vector3,mag_delta:float):
	#Get closest integer point
	point = Vector3(round(point.x),round(point.y),round(point.z))
	#Get all of the points to edit
	var points_to_edit = []
	var num_levels = sphere_layer_point_deltas.size()
	for layer_num in num_levels:
		var necessary_heights
		if layer_num == 0:
			necessary_heights = [layer_num]
		else:
			necessary_heights = [layer_num,-layer_num]
		for necessary_height in necessary_heights:
			for delta in sphere_layer_point_deltas[layer_num]:
				var point_to_edit_loc = point + Vector3(0,necessary_height,0) + Vector3(delta.x,0,delta.y)
				set_sphere_mag_at_point(point_to_edit_loc,mag_delta)
