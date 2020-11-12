extends EditorProperty


# The main control for editing the property.
var property_control = Button.new()
# An internal value of the property.
var current_value = []
# A guard against internal changes when the property is updated.
var updating = false

var cube_width = 1


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
	#Do the casting for one
	while !(result.empty() and !cast_forward):
		if cast_forward:
			result = space_state.intersect_ray(result['position'],result['position'] + dir*1e6)
			if result.empty():
				#No more hits in forward direction
				result = {'position':initial_pos + dir*1e6}
				cast_forward = false
				continue
			else:
				hits.append(result)
				continue
		else:
			result = space_state.intersect_ray(result['position'],initial_pos)
			if result.empty():
				#No more hits in backward direction
				break
			else:
				hits.append(result)
				continue
	return hits

func get_point_arr():
	var spatial = Spatial.new()
	get_tree().get_root().add_child(spatial)
	var space_state =  spatial.get_world().direct_space_state
	var state_arr = []
	state_arr.resize(pow(cube_width,3))
	
	for i in range(cube_width):
		for j in range(cube_width):
			for k in range(cube_width):
				var hits = raycast_get_hits(Vector3(i,j,k),Vector3.RIGHT,space_state)
				if hits.size() % 2 == 0:
					#Inside mesh
					state_arr[i*cube_width*cube_width + j*cube_width + k] = 0
				else:
					#Outside mesh
					state_arr[i*cube_width*cube_width + j*cube_width + k] = 1
	spatial.free()
	return state_arr


func _on_button_pressed():
	# Ignore the signal if the property is currently being updated.
	if (updating):
		return

	# Generate a new random integer between 0 and 99.
	current_value = get_point_arr()
	property_control.text = "Generate Array"
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
