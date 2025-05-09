extends Node

var server := TCPServer.new()
var clients := []
var send_images = false
signal on_connection
signal on_message

func _ready():
	server.listen(8527)
	print("Listening on port 4242")

func has_connection():
	return self.clients.size() != 0

func _process(_delta):
	if server.is_connection_available():
		var client = server.take_connection()
		clients.append(client)
		print("New client connected")
		on_connection.emit()
		
	if send_images:
		for client in clients:
			send_frame(client)
			send_images = false
	
	for client in clients:
		if client.get_available_bytes() > 0:
			var data = client.get_utf8_string(client.get_available_bytes()) as String
			
			var buffered_messages = []
			for message in data.split("\n"):
				if message.begins_with("_"):
					parse_input(buffered_messages)
					buffered_messages.clear()
					if message == "_engine_get_image":
						send_images = true
					elif message == "_engine_reset":
						GlobalRules.reset()
						on_message.emit("")
					elif message == "_engine_stop_rendering":
						RenderingServer.render_loop_enabled = false
						Engine.time_scale = 1000
					elif message.begins_with("_engine_message"):
						on_message.emit(message.substr(15).replace("\\n", "\n"))
				else:
					buffered_messages.append(message)
			parse_input(buffered_messages)

func parse_input(data: Array):
	var decoded = []
	for message in data:
		var action = GlobalRules.action_from_string(message)
		if action != null:
			decoded.append(action)
		else:
			print("received invalid string: " + message)
	GlobalRules.apply_buffered(decoded)
	RenderingServer.render_loop_enabled = true


func send_frame(client: StreamPeerTCP):
	var img = get_viewport().get_texture().get_image()
	var byte_data = img.save_png_to_buffer()
	client.put_data(byte_data)
