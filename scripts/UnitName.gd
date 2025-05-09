extends CenterContainer

var unit_id : int
var models = []

func _init() -> void:
	GlobalRules.on_state_changed.connect(self.on_state_changed)

func on_state_changed():
	if GlobalRules.library.size(GlobalRules.get_state().get_board().get_units()) > unit_id:
		set_text(RLCLib.convert_string(GlobalRules.get_unit(unit_id).get_name().get_value()))

func remove():
	get_parent().remove_unit(self)
	queue_free()
	
func remove_model(model):
	models.erase(model)

func get_models_bounding_box():
	var bounding_box = Rect2()
	bounding_box.position = models[0].position 
	bounding_box.end = models[0].position
	for model in models:
		bounding_box = bounding_box.expand(model.position)
	return bounding_box

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if len(models) == 0:
		remove()
		return
	reset_size()
	var new_position = get_models_bounding_box().get_center()  - (size / 2)
	if (new_position - position).length() > 100:
		position = new_position
	else:
		position = lerp(position, new_position, delta)
	
	# when we are driven by a remote connection, always show the name
	if Server.has_connection():
		modulate.a = 1
	else:
		modulate.a = lerp(modulate.a, float(0.8 > get_viewport().get_camera_2d().zoom.length()), delta * 10)

func set_text(text):
	$Label.text = text
