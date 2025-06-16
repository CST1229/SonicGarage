extends HFlowContainer
class_name MultiKeybind

@export var action: StringName = &"left";
@export var player: int = 0;

var ignore_input: float = 0;

func _ready():
	update_labels();

func _process(delta: float):
	ignore_input = move_toward(ignore_input, 0, delta);

func _on_add_button_pressed() -> void:
	if !get_tree().get_nodes_in_group(&"currently_binding").is_empty():
		return
	
	add_to_group(&"currently_binding");
	process_mode = Node.PROCESS_MODE_ALWAYS;
	bind_start.emit();

func _input(event: InputEvent) -> void:
	if !is_in_group(&"currently_binding"):
		return
		
	if ignore_input <= 0 && (event is InputEventKey || event is InputEventJoypadButton || event is InputEventJoypadMotion):
		if event is InputEventJoypadMotion:
			if absf(event.axis_value) < 0.8: return;
			
		InputMap.action_add_event(action, event);
		add_button(event);
		
		Settings.save_settings();
		
		cancel_bind();
		get_tree().root.set_input_as_handled();

func cancel_bind():
	remove_from_group(&"currently_binding");
	bind_end.emit();
	process_mode = Node.PROCESS_MODE_INHERIT;

func _on_delete_button_pressed() -> void:
	InputMap.action_erase_events(action);
	Settings.save_settings();
	update_labels();

func update_labels() -> void:
	for child in get_children():
		if child.is_in_group(&"binds"):
			child.queue_free();
	for event: InputEvent in InputMap.action_get_events(action):
		add_button(event);

func add_button(event: InputEvent):
	var button := Button.new();
	button.theme_type_variation = &"SmallButton";
	button.text = Settings.get_bind_name(event);
	button.pressed.connect(remove_event.bind(event, button));
	
	add_child(button);

func remove_event(event: InputEvent, node: Node = null) -> void:
	InputMap.action_erase_event(action, event);
	if node:
		node.queue_free();

signal bind_start;
signal bind_end;
