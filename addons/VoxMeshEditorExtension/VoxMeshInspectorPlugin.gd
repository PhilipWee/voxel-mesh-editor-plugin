# MyInspectorPlugin.gd
extends EditorInspectorPlugin

var VoxMeshPropertyEditor = preload("res://addons/VoxMeshEditorExtension/VoxMeshPropertyEditor.gd")
var VoxMeshHandlerPropertyEditor = preload("res://addons/VoxMeshEditorExtension/VoxMeshHandlerPropertyEditor.gd")

func can_handle(object):
	# We support all objects in this example.
	if object is VoxelMesh:
		return true
	if object is VoxMeshHandler:
		return true
		
	return false


func parse_property(object, type, path, hint, hint_text, usage):
	# We handle properties of type integer.
	if type == TYPE_ARRAY:
		# Create an instance of the custom property editor and register
		# it to a specific property path.
		add_property_editor(path, VoxMeshPropertyEditor.new())
		# Inform the editor to remove the default property editor for
		# this property type.
		return true
	elif type == TYPE_INT and path == 'generate_children':
		add_property_editor(path, VoxMeshHandlerPropertyEditor.new())
		return true
	else:
		return false
