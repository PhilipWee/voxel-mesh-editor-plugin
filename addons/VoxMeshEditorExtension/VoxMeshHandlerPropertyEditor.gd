extends EditorProperty
tool

# The main control for editing the property.
var property_control = Button.new()
# An internal value of the property.
var current_value = 0
# A guard against internal changes when the property is updated.
var updating = false

var VoxMeshPropertyEditor = load("res://addons/VoxMeshEditorExtension/VoxMeshPropertyEditor.gd").new()

var min_dist_between_ray_hits

var MAP_COLLIDER_LAYER = pow(2,20-1)


func _init():
	# Add the control as a direct child of EditorProperty node.
	add_child(property_control)
	# Make sure the control is able to retain the focus.
	add_focusable(property_control)
	# Setup the initial state and connect to the signal to track changes.
	property_control.text = "Run"
	property_control.connect("pressed", self, "_on_button_pressed")

#The additional function is because concave meshes can be hit on the inside too!
func raycast_get_hits_concave(initial_pos,dir,space_state):
	var result = {'position':initial_pos}
	var hits = []
	dir = dir.normalized() 
	var loopCounter = 0
	#Do the casting for one
	while !(result.empty()):
		loopCounter += 1
		#Failsafe
		if loopCounter > 20:
			print("Above 20 hits cast forward")
			print("Final destination:","infinity")
			for i in range(10):
				print(hits[i].position)
			hits = [1,2]
			break
		result = space_state.intersect_ray(result['position'],result['position'] + dir*1e5,[],MAP_COLLIDER_LAYER)
		
		if result.empty():
			#No more hits in forward direction
			break
		else:
			#Do not continue hits if it is within origin distance
#				if result['position'].distance_to(initial_pos) <= min_dist_between_ray_hits:
#					#Too close to corner, assume as outside mesh
#					return [1]
			hits.append(result)
			result['position'] += dir*min_dist_between_ray_hits
			continue
	return hits
	
func raycast_get_hits(initial_pos,dir,space_state):
	var result = {'position':initial_pos}
	var cast_forward = true
	var hits = []
	dir = dir.normalized() 
	var loopCounter = 0
	#Do the casting for one
	while !(result.empty() and !cast_forward):
		loopCounter += 1
		
		if cast_forward:
			#Failsafe
			if loopCounter > 20:
				print("Above 20 hits cast forward")
				print("Final destination:","infinity")
				for i in range(10):
					print(hits[i].position)
				hits = [1,2]
				break
			result = space_state.intersect_ray(result['position'],result['position'] + dir*1e5,[],MAP_COLLIDER_LAYER)
			
			if result.empty():
				#No more hits in forward direction
				result = {'position':initial_pos + dir*1e5}
				cast_forward = false
				continue
			else:
				#Do not continue hits if it is within origin distance
#				if result['position'].distance_to(initial_pos) <= min_dist_between_ray_hits:
#					#Too close to corner, assume as outside mesh
#					return [1]
				hits.append(result)
				result['position'] += dir*min_dist_between_ray_hits
				continue
		else:
			if loopCounter > 20:
				print("Above 20 hits cast backwards")
				print("Final destination:",initial_pos)
				for i in range(10):
					print(hits[i].position)
				hits = [1,2]
				break
			result = space_state.intersect_ray(result['position'],initial_pos,[],MAP_COLLIDER_LAYER)
			if result.empty():
				#No more hits in backward direction
				break
			else:
				#Do not continue hits if it is within origin distance
#				if result['position'].distance_to(initial_pos) <= min_dist_between_ray_hits:
#					#Too close to corner, assume as outside mesh
#					return [1]
				hits.append(result)
				
				result['position'] -= dir*min_dist_between_ray_hits
				
				continue
	return hits

func get_point_arr(origin = Vector3(0,0,0), chunk_size = 16):
	var state_arr = []
	var cube_width = get_edited_object().cube_width
	var spatial = Spatial.new()
	get_tree().get_root().add_child(spatial)
	var space_state =  spatial.get_world().direct_space_state
	
	#Change value from number of points to chunksize
	chunk_size += 1
	
	#Already hit dictionary
	var alr_hit_dict = {}

	state_arr.resize(pow(chunk_size,3))
	var i
	var j
	var k
	for i_iterator in range(chunk_size):
		i = origin.x + i_iterator*cube_width
		for j_iterator in range(chunk_size):
			j = origin.y + j_iterator*cube_width
			for k_iterator in range(chunk_size):
				k = origin.z + k_iterator*cube_width
				var cur_arr_index = i_iterator*chunk_size*chunk_size + j_iterator*chunk_size + k_iterator
				if state_arr[cur_arr_index] != null:
					#We have already filled the point with an intermediate value
					continue

				#Actual code
				var hits
				var selected_option = get_edited_object().func_option
				
				#Two different raycast methods because concave polygon can get hit from inside
				if selected_option == get_edited_object().FUNC_OPTIONS.GENERATE_CHILDREN:
					hits = raycast_get_hits(Vector3(i,j,k),Vector3.RIGHT,space_state)
				elif selected_option == get_edited_object().FUNC_OPTIONS.GENERATE_CHILDREN_CONCAVE:
					hits = raycast_get_hits_concave(Vector3(i,j,k),Vector3.RIGHT,space_state)

				if hits.size() % 2 == 0:
					#Outside mesh
					state_arr[cur_arr_index] = 0
				else:
					#Inside mesh

					#Check if one unit away from any side

					var possible_augments = [
						Vector3(0,0,1),
						Vector3(0,0,-1),
						Vector3(0,1,0),
						Vector3(0,-1,0),
						Vector3(1,0,0),
						Vector3(-1,0,0),
					]

					state_arr[cur_arr_index] = 1

					for augment in possible_augments:
						var from_location = Vector3(i+augment.x*cube_width*1.01,j+augment.y*cube_width*1.01,k+augment.z*cube_width*1.01)
#						print(from_location)
#						print(cube_width)
						var one_unit_hit = space_state.intersect_ray(from_location,Vector3(i,j,k),[],MAP_COLLIDER_LAYER)

#						print(one_unit_hit)

						if !one_unit_hit.empty():
#							print('hit detected')
							#Get the average distance away of the hit
							var avg_dist_away = 0
							var num_hits = 0
							var other_pt_location = Vector3(i+augment.x*cube_width,j+augment.y*cube_width,k+augment.z*cube_width)
							for other_pt_augment in possible_augments:
								var other_from_location = Vector3(other_pt_location.x+other_pt_augment.x*cube_width*1.01,
																	other_pt_location.y+other_pt_augment.y*cube_width*1.01,
																	other_pt_location.z+other_pt_augment.z*cube_width*1.01)
								var other_one_unit_hit = space_state.intersect_ray(other_pt_location,other_from_location,[],MAP_COLLIDER_LAYER)
								if !other_one_unit_hit.empty():
									num_hits += 1
									avg_dist_away += other_one_unit_hit.position.distance_to(other_pt_location)
#								print("Other from:",other_from_location)
#								print("Other pt:",other_pt_location)
							if num_hits == 0:
								#The collision is at the point itself
								avg_dist_away = 0.99
								print('hi')
							else:
								avg_dist_away = 1-avg_dist_away/num_hits
								
								
							var distance_proportion = clamp(avg_dist_away/cube_width,0,0.999) #To ensure next point is not outside mesh

							
							
#							if distance_proportion == 0:
#								otherval = 0
#							else:
#								otherval = clamp((-0.5+distance_proportion)/distance_proportion,0,0.5)
							#Set the other value
							if i_iterator+augment.x > chunk_size-1 or i_iterator+augment.x < 0:
								continue
							if j_iterator+augment.y > chunk_size-1 or j_iterator+augment.y < 0:
								continue
							if k_iterator+augment.z > chunk_size-1 or k_iterator+augment.z < 0:
								continue
							var other_arr_index = (i_iterator+augment.x)*chunk_size*chunk_size + (j_iterator+augment.y)*chunk_size + (k_iterator+augment.z)
								
							state_arr[other_arr_index] = distance_proportion

	spatial.free()
	print("Point Array Generated: " + str(state_arr).substr(0,1000))
	return state_arr

func generate_children():
	var chunk_dimensions = get_edited_object().chunk_dimensions
	var chunk_size = get_edited_object().chunk_size
	var chunks_per_axis = chunk_dimensions/chunk_size
	chunks_per_axis = Vector3(ceil(chunks_per_axis.x),ceil(chunks_per_axis.y),ceil(chunks_per_axis.z))
	var cube_width = get_edited_object().cube_width
	var origin = get_edited_object().global_transform.origin
	min_dist_between_ray_hits = 0.05
	var i
	var j
	var k
	#Remove all children from the Mesh Handler
	var vox_mesh_handler = get_tree().get_edited_scene_root().get_node("VoxMeshHandler")
	for child in vox_mesh_handler.get_children():
		child.name = 'to_be_queued_free'
		child.queue_free()
	
	#For progress indication
	var total_iterations = chunks_per_axis.x*chunks_per_axis.y*chunks_per_axis.z
	var cur_iteration = 0
	
	for i_iterator in range(chunks_per_axis.x):
		i = origin.x + i_iterator*chunk_size*cube_width
		for j_iterator in range(chunks_per_axis.y):
			j = origin.y + j_iterator*chunk_size*cube_width
			for k_iterator in range(chunks_per_axis.z):
				k = origin.z + k_iterator*chunk_size*cube_width
				var new_origin = Vector3(i,j,k)
				print("New origin: ", new_origin)
				#For each point, create a chunk
				var new_static_body = StaticBody.new()
				var new_vox_mesh_instance = VoxMeshInstance.new()
				new_vox_mesh_instance.mesh = VoxelMesh.new()
				var new_col_shape = CollisionShape.new()
				#Add the children to the voxel mesh
				new_static_body.add_child(new_vox_mesh_instance)
				new_static_body.add_child(new_col_shape)
				#Create the scalar field
				var new_scalar_field = get_point_arr(new_origin,chunk_size)
				new_vox_mesh_instance.mesh.scalar_field = new_scalar_field
				vox_mesh_handler.add_child(new_static_body)
				#Set the owner to ensure it gets saved with the scene
				new_vox_mesh_instance.set_owner(get_tree().get_edited_scene_root())
				new_static_body.set_owner(get_tree().get_edited_scene_root())
				new_col_shape.set_owner(get_tree().get_edited_scene_root())
				#Set the material of the mesh instance
				if get_edited_object().voxel_mesh_material:
					new_vox_mesh_instance.set_surface_material(0,get_edited_object().voxel_mesh_material)
				
				#Set the location and name appropriately
				new_static_body.global_transform.origin = new_origin
				new_static_body.name = str(i_iterator,'-',j_iterator,'-',k_iterator)
				#Update the collision shape
				new_vox_mesh_instance.update_collision_shape()
				
				cur_iteration += 1
				print(cur_iteration, "/", total_iterations, " completed")
	return 0
	
func test_raycast():
	var spatial = Spatial.new()
	get_tree().get_root().add_child(spatial)
	var space_state =  spatial.get_world().direct_space_state
	var from = get_edited_object()['test_ray_from']
	var to = get_edited_object()['test_ray_to']
	print(from,to)
	print(space_state.intersect_ray(from,to,[],MAP_COLLIDER_LAYER))
	spatial.free()


func check_magnitude():
	print("Warning: Function incomplete, may not work as expected")
	#get the node in question
	var child_static_body = get_edited_object().get_node(get_edited_object().mag_check_child_node_name)
	#Change value from number of points to chunksize
	var chunk_size = get_edited_object().chunk_size
	chunk_size += 1
	#Get the array index required
	var point_coords = get_edited_object().mag_check_location
	var arr_index_required = point_coords.x*chunk_size*chunk_size + point_coords.y*chunk_size + point_coords.z
	print("Magnitude for static body ",get_edited_object().mag_check_child_node_name," at coords ",point_coords)
	print(child_static_body.get_node('MeshInstance').mesh.scalar_field[arr_index_required])
	
	var spatial = Spatial.new()
	get_tree().get_edited_scene_root().add_child(spatial)
	spatial.set_owner(get_tree().get_edited_scene_root())
	
	
	
	var total_iterations = pow(chunk_size,3)
	var cur_iter = 0
	#Add sphere for magnitude at each point
	for i in range(chunk_size):
		for j in range(chunk_size):
			for k in range(chunk_size):
				cur_iter += 1
				var index_to_plot = i*chunk_size*chunk_size + j*chunk_size + k
				var scalar_field_val = child_static_body.get_node('MeshInstance').mesh.scalar_field[index_to_plot]
				if scalar_field_val == 0:
					continue
				
				var mag_sphere = MeshInstance.new()
				spatial.add_child(mag_sphere)
				mag_sphere.set_owner(get_tree().get_edited_scene_root())
				mag_sphere.mesh = SphereMesh.new()
				mag_sphere.mesh.radius = child_static_body.get_node('MeshInstance').mesh.scalar_field[index_to_plot]/10
				mag_sphere.mesh.height = child_static_body.get_node('MeshInstance').mesh.scalar_field[index_to_plot]/10 * 2
				mag_sphere.global_transform.origin = Vector3(i,j,k)
				
				print('currently at iteration ',cur_iter,',',total_iterations)
	print(child_static_body.get_node('MeshInstance').mesh.scalar_field)
#	print("Function not implemented yet")
	


func _on_button_pressed():
	# Ignore the signal if the property is currently being updated.
	if (updating):
		return
	
	var selected_option = get_edited_object().func_option
	
	if selected_option == get_edited_object().FUNC_OPTIONS.GENERATE_CHILDREN:
		print("Note that mesh is generated from collisions on layer 20")
		print("Note that crash may occur if you use more than one collision shape")
		generate_children()
		print("Children Generated!")
	elif selected_option == get_edited_object().FUNC_OPTIONS.TEST_RAYCAST:
		test_raycast()
	elif selected_option == get_edited_object().FUNC_OPTIONS.GENERATE_CHILDREN_CONCAVE:
		print("Note that mesh is generated from collisions on layer 20")
		print("Note that crash may occur if you use more than one collision shape")
		generate_children()
		print("Children Generated!")
	elif selected_option == get_edited_object().FUNC_OPTIONS.CHECK_MAGNITUDE:
		check_magnitude()
	elif selected_option == get_edited_object().FUNC_OPTIONS.CHANGE_VAL_AT_POINT:
		var coord = get_edited_object().point_to_change_val
		var new_val = get_edited_object().new_point_val
		get_edited_object().change_val_at_point(coord,new_val)
		print('done')
	elif selected_option == get_edited_object().FUNC_OPTIONS.GET_VAL_AT_POINT:
		var coord = get_edited_object().point_to_change_val
		print("val is:",get_edited_object().get_val_at_point(coord))
	property_control.text = "Run"

	 #TODO make dependent on mesh starting location
	
	emit_changed(get_edited_property(), current_value)


func update_property():
	# Read the current value from the property.
	var new_value = get_edited_object()[get_edited_property()]
	if (new_value == current_value):
		return

	# Update the control with the new value.
	updating = true
	current_value = new_value
	property_control.text = "Run"
	updating = false
