@tool
extends Control

var paths := []
var plugin = EditorPlugin.new()
func _enter_tree():
	for ch in $GridContainer.get_children():
		paths.append(NodePath(str(get_path()) + "/GridContainer/" + str(ch.name)))
	# Sets a dedicated Multiplayer API for each branch.
	print(paths)
	for path in paths:
		get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), path)
	
	
	

func _exit_tree():
	# Clear the branch-specific Multiplayer API.
	for path in paths:
		get_tree().set_multiplayer(null)

	
