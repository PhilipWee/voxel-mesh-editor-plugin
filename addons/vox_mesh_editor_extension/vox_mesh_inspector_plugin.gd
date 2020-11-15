# MyInspectorPlugin.gd
extends EditorInspectorPlugin

var VoxMeshPropertyEditor = preload("res://addons/vox_mesh_editor_extension/vox_mesh_property_editor.gd")


func can_handle(object):
	# We support all objects in this example.
	return object is VoxelMesh


func parse_property(object, type, path, hint, hint_text, usage):
	# We handle properties of type integer.
	if type == TYPE_ARRAY:
		# Create an instance of the custom property editor and register
		# it to a specific property path.
		add_property_editor(path, VoxMeshPropertyEditor.new())
		# Inform the editor to remove the default property editor for
		# this property type.
		return true
	else:
		return false
