@tool
extends Control

const DEF_PORT = 8080
const TRANS_PORT = 9080
const PROTO_NAME = "ludus"

@onready var _host_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Host
@onready var _connect_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Connect
@onready var _disconnect_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Disconnect
@onready var _name_edit = $Panel/VBoxContainer/HBoxContainer/NameEdit
@onready var _host_edit = $Panel/VBoxContainer/HBoxContainer2/Hostname
@onready var _game = $Panel/VBoxContainer/Game

var peer = WebSocketMultiplayerPeer.new()
var peer_send = WebSocketMultiplayerPeer.new()
var web_peer = WebSocketPeer.new()

var plugin = EditorPlugin.new()
var editor_undo_redo = plugin.get_undo_redo()

var dic:Dictionary={}

var thread:Thread
#func _init():
	#peer.supported_protocols = ["ludus"]


func _ready():
	print(multiplayer)
	multiplayer.peer_connected.connect(self._peer_connected)
	multiplayer.peer_disconnected.connect(self._peer_disconnected)
	multiplayer.server_disconnected.connect(self._close_network)
	multiplayer.connection_failed.connect(self._close_network)
	multiplayer.connected_to_server.connect(self._connected)
	
	editor_undo_redo.history_changed.connect(self._send_callable)
	
	$AcceptDialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$AcceptDialog.get_label().vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		_name_edit.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		_name_edit.text = desktop_path[desktop_path.size() - 2]
	
		
	#print(editor_undo_redo.get_history_undo_redo(6).get_current_action_name())

func start_game():
	_host_btn.disabled = true
	_name_edit.editable = false
	_host_edit.editable = false
	_connect_btn.hide()
	_disconnect_btn.show()
	_game.start()


func stop_game():
	_host_btn.disabled = false
	_name_edit.editable = true
	_host_edit.editable = true
	_disconnect_btn.hide()
	_connect_btn.show()
	_game.stop()


func _close_network():
	stop_game()
	$AcceptDialog.popup_centered()
	$AcceptDialog.get_ok_button().grab_focus()
	multiplayer.multiplayer_peer = null
	peer.close()
	peer_send.close()


func _connected():
	_game.set_player_name.rpc(_name_edit.text)


func _peer_connected(id):
	_game.on_peer_add(id)


func _peer_disconnected(id):
	print("Disconnected %d" % id)
	_game.on_peer_del(id)


func _on_Host_pressed():
	multiplayer.multiplayer_peer = null
	peer.create_server(DEF_PORT)
	peer_send.create_server(TRANS_PORT)
	multiplayer.multiplayer_peer = peer
	_game.add_player(1, _name_edit.text)
	start_game()


func _on_Disconnect_pressed():
	_close_network()


func _on_Connect_pressed():
	
	multiplayer.multiplayer_peer = null
	print(_host_edit.text)
	peer.create_client("ws://" + _host_edit.text + ":" + str(DEF_PORT))
	peer_send.create_client("ws://" + _host_edit.text + ":" + str(TRANS_PORT))
	multiplayer.multiplayer_peer = peer
	start_game()
	print(peer_send.get_connection_status())
	
	
func _process(delta):
	#var work_peer = peer.get_peer(multiplayer.get_unique_id())
	peer_send.poll()
	var state = peer_send.get_connection_status ( )
	#print(state)
	#print(peer.get_available_packet_count())
	#if peer_send.get_available_packet_count()!=0:
	#	print(state," ",peer_send.get_available_packet_count())
	if state == 2 and peer_send.get_available_packet_count()!=0:
		var result = peer_send.get_var(true)
		
		for key in result[0].keys():
			dic[result[0][key]] = key
		
		for i in range(1,len(result)):
		#	print(result[i])
			print(dic)
			if result[i]["type"]==0:
				print(result[i]["method"])
				print(str_to_var(result[i]["arguments"][0]))
				print(result[i]["arguments"][1])
				var call_func
				if result[i]["path"]==null:
					call_func=Callable(str_to_var(result[i]["object"]),result[i]["method"]).bindv(str_to_var(result[i]["arguments"][0]))
				elif plugin.get_editor_interface().get_edited_scene_root().get_node(result[i]["path"])!=null:
			#		print(result[i]["objectid"])
			#		print(plugin.get_editor_interface().get_edited_scene_root().get_node(result[i]["path"]).get_instance_id())
					dic[result[i]["objectid"]]=plugin.get_editor_interface().get_edited_scene_root().get_node(result[i]["path"]).get_instance_id()
					var arg:Array=[]
					for j in range(len(result[i]["arguments"][1])):
						
						if str_to_var(result[i]["arguments"][0])[j]!=null and typeof(str_to_var(result[i]["arguments"][0])[j])==24 and result[i]["arguments"][1][j].object_id in dic.keys():
					#		print(result[i]["arguments"][1][j])
							arg.append(instance_from_id(dic[result[i]["arguments"][1][j].object_id]))
						elif typeof(str_to_var(result[i]["arguments"][0])[j])==2&&str_to_var(result[i]["arguments"][0])[j] in dic.keys():
							arg.append(dic[str_to_var(result[i]["arguments"][0])[j]])
						elif typeof(str_to_var(result[i]["arguments"][0])[j])==28:  ##节点关系改变，输入参数是Array
							var array_objects:Array = []
							for k in range(len(result[i]["arguments"][1][j])):
								if result[i]["arguments"][1][j][k].object_id in dic.keys():
									array_objects.append(instance_from_id( dic[result[i]["arguments"][1][j][k].object_id]))
								else:
									array_objects.append(str_to_var(result[i]["arguments"][0])[j])
							arg.append(array_objects)
									
						else:
							arg.append(str_to_var(result[i]["arguments"][0])[j])
						
					
			
									
		#			print(arg)
					call_func = Callable(instance_from_id(dic[result[i]["objectid"]]),result[i]["method"]).bindv(arg)
			#	print(result[i]["method"])
				call_func.call()
			if result[i]["type"]==1:
				if plugin.get_editor_interface().get_edited_scene_root().get_node(result[i]["path"])!=null:
					dic[result[i]["objectid"]]=plugin.get_editor_interface().get_edited_scene_root().get_node(result[i]["path"]).get_instance_id()
				
				instance_from_id(dic[result[i]["objectid"]]).set(result[i]["name"],str_to_var(result[i]["value"]))	
				
				
		
		pass
		
func _send_callable():

	var edi =plugin.get_editor_interface()
	
	

#	edi.get_selection().get_selected_nodes()[0].print_tree()
	
	var id = editor_undo_redo.get_object_history_id(plugin.get_editor_interface().get_edited_scene_root())
	
 


	var operation_callable = editor_undo_redo.get_history_undo_redo(id).get_operation_callable_redo()
	var operation_type = editor_undo_redo.get_history_undo_redo(id).get_operation_type_redo()
	var operation_ref = editor_undo_redo.get_history_undo_redo(id).get_operation_ref_redo()
	var operation_objectid = editor_undo_redo.get_history_undo_redo(id).get_operation_objectid_redo()
	var operation_value = editor_undo_redo.get_history_undo_redo(id).get_operation_value_redo()
	var operation_name = editor_undo_redo.get_history_undo_redo(id).get_operation_name_redo()
	
	var data_stream = []
	data_stream.append(dic)
	for i in range(len(operation_callable)):
		var datasend:Dictionary = {}
		
		
		datasend["type"] = operation_type[i]
		datasend["ref"] = var_to_str(operation_ref[i])
		datasend["objectid"] = operation_objectid[i]
		datasend["value"] = var_to_str(operation_value[i])
		datasend["name"] = operation_name[i]
		
		if instance_from_id(operation_objectid[i]).is_class("Node"):
			datasend["path"] = instance_from_id(operation_objectid[i]).get_path()
			
		else:
			datasend["object"] = var_to_str(instance_from_id(operation_objectid[i]))
			datasend["path"]=null
			
		
		datasend["method"] = operation_callable[i].get_method()
		datasend["arguments"] = [var_to_str(operation_callable[i].get_bound_arguments()),operation_callable[i].get_bound_arguments()]
		data_stream.append(datasend)
		print(instance_from_id(datasend["objectid"]))
		print(datasend["method"])
		print(datasend["arguments"][1])

	
	
	
	
	
	
	

	#var encode_data = PackedByteArray().encode_var(20,data_send)
	if multiplayer.is_server():
		print("server")
		print(peer_send.put_var(data_stream,false))
		
		for i in range(len(data_stream)):
			if data_stream[i]["arguments"][1][0].is_class("MeshInstance3D"):
				print(data_stream[i]["arguments"][1][0].get_instance_id())
		
	else:
		peer_send.put_var(data_stream)


