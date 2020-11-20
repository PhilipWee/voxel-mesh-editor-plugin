tool
extends Spatial

class_name VoxMeshHandler

export(float) var cube_width = 1
export(Vector3) var chunk_dimensions = Vector3(256,256,128)
export(int) var execute_func
export(int) var chunk_size = 16

export(ShaderMaterial) var voxel_mesh_material

enum FUNC_OPTIONS {
	GENERATE_CHILDREN,
	TEST_RAYCAST,
	GENERATE_CHILDREN_CONCAVE,
	CHECK_MAGNITUDE,
	CHANGE_VAL_AT_POINT,
	GET_VAL_AT_POINT}
export (FUNC_OPTIONS) var func_option

export(Vector3) var test_ray_from
export(Vector3) var test_ray_to
export(String) var mag_check_child_node_name
export(Vector3) var mag_check_location
export(Vector3) var point_to_change_val
export(float,0,1) var new_point_val

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func change_val_at_point(coord: Vector3, new_val: float):
	#Determine who has the coord
	#3 cases - inside the cube, on edge of cube, corner of cube
	var necessary_chunks = {}
	var necessary_chunks_buffer = []
	var leftovers_buffer = []
	
	var leftovers = Vector3.ZERO
	for dir in ['x','y','z']:
		leftovers[dir] = int(coord[dir]) % chunk_size
		#The box it is in is always necessary
		var necessary_for_dir = [(coord[dir]-leftovers[dir])/chunk_size]
		if leftovers[dir] == 0:
			necessary_for_dir.append(necessary_for_dir[0]-1)
		necessary_chunks_buffer.append(necessary_for_dir)
		
	
	for i_iter in range(necessary_chunks_buffer[0].size()):
		for j_iter in range(necessary_chunks_buffer[1].size()):
			for k_iter in range(necessary_chunks_buffer[2].size()):
				var chunk_coord = Vector3(
					necessary_chunks_buffer[0][i_iter],
					necessary_chunks_buffer[1][j_iter],
					necessary_chunks_buffer[2][k_iter])
				var coord_in_chunk = Vector3.ZERO
				#Remove negatives
				if chunk_coord.x>=0 and chunk_coord.y>=0 and chunk_coord.z>=0:
					for dir in ['x','y','z']:
						coord_in_chunk[dir] = int(coord[dir]) % chunk_size
						var old_dir_coord = chunk_coord
						if i_iter == 1:
							coord_in_chunk.x = chunk_size
#							old_dir_coord.x = necessary_chunks_buffer[0][0]
#							necessary_chunks[_ccts(old_dir_coord)].x = chunk_size
						if j_iter == 1:
							coord_in_chunk.y = chunk_size
#							old_dir_coord.y = necessary_chunks_buffer[1][0]
#							necessary_chunks[_ccts(old_dir_coord)].y = chunk_size
						if k_iter == 1:
							coord_in_chunk.z = chunk_size
#							old_dir_coord.z = necessary_chunks_buffer[2][0]
#							necessary_chunks[_ccts(old_dir_coord)].z = chunk_size
							
						
					necessary_chunks[_ccts(chunk_coord)] = coord_in_chunk
	
	#NOTE: CURRENTLY CHANGING AT WRONG POINT
	for chunk in necessary_chunks.keys():
		var chunk_node = get_node_or_null(chunk)
		if chunk_node:
			var voxel_mesh = chunk_node.get_node('MeshInstance').mesh
			var chunk_size_points = chunk_size +1 
			var cur_arr_index = necessary_chunks[chunk].x*chunk_size_points*chunk_size_points + necessary_chunks[chunk].y*chunk_size_points + necessary_chunks[chunk].z
			voxel_mesh.scalar_field[cur_arr_index] = clamp(new_val,0,1)

func get_val_at_point(coord: Vector3):
	var leftovers = Vector3.ZERO
	var chunk_coord = Vector3.ZERO
	for dir in ['x','y','z']:
		leftovers[dir] = int(coord[dir]) % chunk_size
		#The box it is in is always necessary
		chunk_coord[dir] = (coord[dir]-leftovers[dir])/chunk_size
	var chunk_node = get_node_or_null(_ccts(chunk_coord))
	if chunk_node:
		var voxel_mesh = chunk_node.get_node('MeshInstance').mesh
		var chunk_size_points = chunk_size +1 
		var cur_arr_index = leftovers.x*chunk_size_points*chunk_size_points + leftovers.y*chunk_size_points + leftovers.z
		return voxel_mesh.scalar_field[cur_arr_index]
	else:
		return -1

#Chunk coord to string
func _ccts(chunk_coord):
	return str(chunk_coord.x,'-',chunk_coord.y,'-',chunk_coord.z)

func generate_child_meshes_and_col():
	pass
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
