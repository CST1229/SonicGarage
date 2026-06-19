class_name ControlBind
extends HFlowContainer

@export var action: StringName = &"left";
@export var player: int = 0;

const MAX_EVENTS = 32;

var padding: Control;
var add_binds_button: Button;
var reset_button: Button;

var num_bind_buttons := 0;
var last_button_added: Button;

var rebinding_event: InputEvent = null;

const UNBIND_ICON = preload("res://sprites/icons/ui/unbind_x.png");
const ADD_BIND_ICON = preload("res://sprites/icons/ui/add_binding.png");
const RESET_BINDS_ICON = preload("res://sprites/icons/ui/reset_binds.png");

func _ready():
	add_binds_button = add_button("", start_binding, "");
	add_binds_button.focus_neighbor_left = ^".";
	add_binds_button.icon = ADD_BIND_ICON;
	reset_button = add_button("", func(_btn):
		reset_binds();
		Settings.save_settings();
	, "Reset");
	reset_button.icon = RESET_BINDS_ICON;
	padding = Control.new();
	padding.custom_minimum_size.x = 1;
	add_child(padding);
	
	changed.connect(func():
		if InputMap.action_get_events(action).size() >= MAX_EVENTS:
			add_binds_button.disabled = true;
			add_binds_button.tooltip_text = "Max of %s keys reached." % [MAX_EVENTS];
		else:
			add_binds_button.disabled = false;
			add_binds_button.tooltip_text = "Add";
	);
	update_labels();

func reset_binds() -> void:
	if action in Settings.default_keybinds:
		Settings.deserialize_action(Settings.default_keybinds[action], action);
	else:
		push_error("Action does not exist in default keybinds: " + str(action));
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
	if event is InputEventKey || event is InputEventJoypadButton || \
		event is InputEventJoypadMotion || event is InputEventMouseButton:
		if event is InputEventJoypadMotion:
			if absf(event.axis_value) < 0.8: return;
		if event is InputEventKey:
			if event.physical_keycode in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META]:
				if !event.is_released():
					return;
			else:
				if !event.is_pressed():
					return;
			if event.echo:
				return;
		else:
			if !event.is_pressed():
				return;
		
		var filtered_event: InputEvent = Settings.filter_input_event(event, action);
		var already_exists: bool = false;
		for existing_event in InputMap.action_get_events(action):
			if filtered_event.is_match(existing_event):
				already_exists = true;
				break;
		if !already_exists:
			InputMap.action_add_event(action, filtered_event);
			add_input_button(filtered_event);
			changed.emit();
			Settings.save_settings();
		
		cancel_bind();

func cancel_bind():
	remove_from_group(&"currently_binding");
	bind_end.emit();
	process_mode = Node.PROCESS_MODE_INHERIT;

func _on_delete_button_pressed() -> void:
	InputMap.action_erase_events(action);
	update_labels();
	Settings.save_settings();

func clear_labels() -> void:
	for child in get_children():
		if child.is_in_group(&"binds"):
			child.queue_free();
	last_button_added = reset_button;
	num_bind_buttons = 0;
	reset_button.focus_neighbor_right = ^".";

func update_labels() -> void:
	clear_labels();
	for event: InputEvent in InputMap.action_get_events(action):
		add_input_button(event);
	changed.emit();

func add_input_button(event: InputEvent) -> void:
	var button := add_button(
		Settings.get_bind_name(event, action), remove_event.bind(event), "Click to remove"
	);
	button.add_to_group(&"binds");
	button.icon = UNBIND_ICON;
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT;
	button.focus_neighbor_right = ^".";
	num_bind_buttons += 1;
	if last_button_added:
		last_button_added.focus_neighbor_right = button.get_path();
		button.focus_neighbor_left = last_button_added.get_path();
	last_button_added = button;

func add_button(text: String, callback: Callable = Callable(), tooltip: String = "") -> Button:
	var button := Button.new();
	button.theme_type_variation = &"SmallButton";
	button.text = text;
	button.tooltip_text = tooltip;
	button.custom_minimum_size.y = 15;
	button.pressed.connect(callback.bind(button));
	
	add_child(button);
	return button;

func remove_event(node: Control, event: InputEvent) -> void:
	InputMap.action_erase_event(action, event);
	if node:
		if node.focus_neighbor_right:
			node.get_node(node.focus_neighbor_right).focus_neighbor_left = node.focus_neighbor_left;
		if node.focus_neighbor_left:
			node.get_node(node.focus_neighbor_left).focus_neighbor_right = node.focus_neighbor_right;
		if node.has_focus():
			# focus the button to the left if there's one within
			# the same control, otherwise the one to the left
			if node.get_index() == (node.get_parent().get_child_count() - 1):
				node.get_node(node.focus_neighbor_left).grab_focus(!node.has_focus(true));
			else:
				node.get_node(node.focus_neighbor_right).grab_focus(!node.has_focus(true));
		node.queue_free();
	for child in get_children():
		if child is Button && !child.is_queued_for_deletion():
			last_button_added = child;
	changed.emit();
	Settings.save_settings();

signal bind_start;
signal bind_end;
signal changed;
