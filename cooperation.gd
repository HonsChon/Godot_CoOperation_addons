@tool
extends EditorPlugin

var undo_redo = get_undo_redo()
#var calla = undo_redo.get_history_undo_redo(4).get_operation_callable_redo()
var dock

func _enter_tree():
	#print(calla)
	# Initialization of the plugin goes here.
	#var m = undo_redo.get_history_undo_redo(2).get_operation_name_redo()
	
	#print(undo_redo.get_history_undo_redo(6).get_current_action_name())
#	print(m)
#	print(undo_redo.get_history_undo_redo(2).get_operation_value_redo())
#	print(undo_redo.get_history_undo_redo(2).get_operation_callable_redo())
#	print(undo_redo.get_history_undo_redo(2).get_operation_objectid_redo())
	dock = preload("res://addons/cooperation/scene/combo.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)
	
	



func _exit_tree():
	# Clean-up of the plugin goes here.
	
	remove_control_from_docks(dock)
	#calla[0].call()
	# Erase the control from the memory.
	dock.free()
	pass
