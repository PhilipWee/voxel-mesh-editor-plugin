extends EditorProperty


# The main control for editing the property.
var property_control = Button.new()
# An internal value of the property.
var current_value = []
# A guard against internal changes when the property is updated.
var updating = false

var chunk_size = 16 #Change this if necessary
var cube_width = 1
var origin = Vector3(0,0,0)
var min_dist_between_ray_hits


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
			result = space_state.intersect_ray(result['position'],result['position'] + dir*1e5,[],pow(2,20-1))
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
			result = space_state.intersect_ray(result['position'],initial_pos,[],pow(2,20-1))
			if result.empty():
				#No more hits in backward direction
				break
			else:
				hits.append(result)
				result['position'] -= dir*min_dist_between_ray_hits
				continue
	return hits

func get_point_arr():
	var spatial = Spatial.new()
	get_tree().get_root().add_child(spatial)
	var space_state =  spatial.get_world().direct_space_state
	var state_arr = []
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
				#Actual code
				var hits = raycast_get_hits(Vector3(i,j,k),Vector3.RIGHT,space_state)
				var cur_arr_index = i_iterator*chunk_size*chunk_size + j_iterator*chunk_size + k_iterator
				if hits.size() % 2 == 0:
					#Outside mesh
					state_arr[cur_arr_index] = 0
				else:
					#Inside mesh
					state_arr[cur_arr_index] = 90
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
	print("Point Array Retrieved:" + str(current_value).substr(0,200))
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
