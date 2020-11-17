extends EditorProperty


# The main control for editing the property.
var property_control = Button.new()
# An internal value of the property.
var current_value = []
# A guard against internal changes when the property is updated.
var updating = false

var chunk_size = VoxMeshHandler.new().chunk_size #Change this if necessary
var cube_width = 1
var origin = Vector3(0,0,0)

var min_dist_between_ray_hits

var MAP_COLLIDER_LAYER = pow(2,20-1)


func _init():
	# Add the control as a direct child of EditorProperty node.
	add_child(property_control)
	# Make sure the control is able to retain the focus.
	add_focusable(property_control)
	# Setup the initial state and connect to the signal to track changes.
	property_control.text = "Generate Array"
	property_control.connect("pressed", self, "_on_button_pressed")
	
func raycast_get_hits(initial_pos,dir,space_state):
	var result = {'position':initial_pos}
	var cast_forward = true
	var hits = []
	dir = dir.normalized()
	#Do the casting for one
	while !(result.empty() and !cast_forward):
		if cast_forward:
			result = space_state.intersect_ray(result['position'],result['position'] + dir*1e5,[],MAP_COLLIDER_LAYER)
			if result.empty():
				#No more hits in forward direction
				result = {'position':initial_pos + dir*1e5}
				cast_forward = false
				continue
			else:
				hits.append(result)
				result['position'] += dir*min_dist_between_ray_hits
				continue
		else:
			result = space_state.intersect_ray(result['position'],initial_pos,[],MAP_COLLIDER_LAYER)
			if result.empty():
				#No more hits in backward direction
				break
			else:
				hits.append(result)
				result['position'] -= dir*min_dist_between_ray_hits
				continue
	return hits

func get_point_arr(origin = Vector3(0,0,0), chunk_size = 16):
	var state_arr = []
	var spatial = Spatial.new()
	get_tree().get_root().add_child(spatial)
	var space_state =  spatial.get_world().direct_space_state
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
				var hits = raycast_get_hits(Vector3(i,j,k),Vector3.RIGHT,space_state)

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
							#Get the distance away of the hit
							var distance_away = one_unit_hit.position.distance_to(Vector3(i,j,k))
							var distance_proportion = clamp(distance_away/cube_width,0,1)
							var otherval
							if distance_proportion == 0:
								otherval = -99
							else:
								otherval = clamp((-0.5+distance_proportion)/distance_proportion,-99,0.5)
							#Set the other value
							var other_arr_index = (i_iterator+augment.x)*chunk_size*chunk_size + (j_iterator+augment.y)*chunk_size + (k_iterator+augment.z)
							#Make sure the other side is not outside of the chunk
							if other_arr_index >= 0:
								state_arr[other_arr_index] = otherval
							print("distanceProportion:",distance_proportion)
							print("Otherval:",otherval)

	spatial.free()
	return state_arr


func _on_button_pressed():
	# Ignore the signal if the property is currently being updated.
	if (updating):
		return

	# Generate a new random integer between 0 and 99.
	current_value = get_point_arr()
	property_control.text = "Generate Array"
	#The plus one is so that the chunk size is by number of cubes, not number of points
#	chunk_size = get_edited_object().get_chunk_size() + 1 
	cube_width = get_edited_object().cube_width
	min_dist_between_ray_hits = cube_width/4
	origin = Vector3(0,0,0) #TODO make dependent on mesh starting location
	print("Note that mesh is generated from collisions on layer 20")
	print("Point Array Retrieved:" + str(current_value).substr(0,300))
	emit_changed(get_edited_property(), current_value)


func update_property():
	# Read the current value from the property.
	var new_value = get_edited_object()[get_edited_property()]
	if (new_value == current_value):
		return

	# Update the control with the new value.
	updating = true
	current_value = new_value
	property_control.text = "Generate Array"
	updating = false
