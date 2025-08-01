class_name ControlBind
extends HFlowContainer

@export var action: StringName = &"left";
@export var player: int = 0;

var padding: Control;
var add_binds_button: Button;
var reset_button: Button;

var num_bind_buttons := 0;

var rebinding_event: InputEvent = null;

const UNBIND_ICON = preload("res://sprites/icons/ui/unbind_x.png");
const ADD_BIND_ICON = preload("res://sprites/icons/ui/add_binding.png");
const RESET_BINDS_ICON = preload("res://sprites/icons/ui/reset_binds.png");

func _ready():
	add_binds_button = add_button("", start_binding, "Add");
	add_binds_button.icon = ADD_BIND_ICON;
	reset_button = add_button("", func(_button: Button):
		if action in Settings.default_keybinds:
			Settings.deserialize_action(Settings.default_keybinds[action], action);
		else:
			InputMap.action_erase_events(action);
		update_labels();
		Settings.save_settings();
	, "Reset");
	reset_button.icon = RESET_BINDS_ICON;
	padding = Control.new();
	padding.custom_minimum_size.x = 1;
	add_child(padding);
	update_labels();

func start_binding(_button: Button = null) -> void:
	get_tree().call_group(&"currently_binding", &"cancel_bind");
	
	add_to_group(&"currently_binding");
	process_mode = Node.PROCESS_MODE_ALWAYS;
	bind_start.emit();

func _input(event: InputEvent) -> void:
	if !is_in_group(&"currently_binding"):
		return
		
	get_tree().root.set_input_as_handled();
	if event is InputEventKey || event is InputEventJoypadButton || event is InputEventJoypadMotion || event is InputEventMouseButton:
		if event is InputEventJoypadMotion:
			if absf(event.axis_value) < 0.8: return;
		if event is InputEventKey:
			if !event.is_released():
				return;
			if event.echo:
				return;
		else:
			if !event.is_pressed():
				return;
		
		var filtered_event: InputEvent = Settings.filter_input_event(event);
		var already_exists: bool = false;
		for existing_event in InputMap.action_get_events(action):
			if filtered_event.is_match(existing_event):
				already_exists = true;
				break;
		if !already_exists:
			InputMap.action_add_event(action, filtered_event);
			add_input_button(filtered_event);
			Settings.save_settings();
		
		cancel_bind();

func cancel_bind():
	remove_from_group(&"currently_binding");
	bind_end.emit();
	process_mode = Node.PROCESS_MODE_INHERIT;

func _on_delete_button_pressed() -> void:
	InputMap.action_erase_events(action);
	Settings.save_settings();
	update_labels();

func clear_labels() -> void:
	for child in get_children():
		if child.is_in_group(&"binds"):
			child.queue_free();
	num_bind_buttons = 0;
	reset_button.focus_neighbor_right = ^"";

func update_labels() -> void:
	clear_labels();
	for event: InputEvent in InputMap.action_get_events(action):
		add_input_button(event);

func add_input_button(event: InputEvent) -> void:
	var button := add_button(Settings.get_bind_name(event), remove_event.bind(event), "Click to remove");
	button.add_to_group(&"binds");
	button.icon = UNBIND_ICON;
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT;
	num_bind_buttons += 1;
	if num_bind_buttons == 1:
		reset_button.focus_neighbor_right = button.get_path();
		button.focus_neighbor_left = reset_button.get_path();

func add_button(text: String, callback: Callable = Callable(), tooltip: String = "") -> Button:
	var button := Button.new();
	button.theme_type_variation = &"SmallButton";
	button.text = text;
	button.tooltip_text = tooltip;
	button.custom_minimum_size.y = 15;
	button.pressed.connect(callback.bind(button));
	
	add_child(button);
	return button;

func remove_event(node: Node, event: InputEvent) -> void:
	InputMap.action_erase_event(action, event);
	if node:
		node.queue_free();
	Settings.save_settings();

signal bind_start;
signal bind_end;
