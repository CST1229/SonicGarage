extends GridContainer

const BIND_SCENE = preload("res://scenes/SettingsMenu/ControlBind.tscn");

@onready var bind_window: CanvasLayer = $BindWindow;
@onready var bind_cancel_timer: Timer = $BindWindow/CancelTimer;
@onready var bind_label: Label = $BindWindow/Label;
@onready var bind_label_text: String = bind_label.text;

var bind_label_name := "";
var cancel_countdown := 5;

func _ready() -> void:
	add_controls_heading("Gameplay");
	add_control("Move Left", &"player_left");
	add_control("Move Right", &"player_right");
	add_control("Jump", &"player_jump");
	add_control("Crouch/Roll", &"player_down");
	
	add_controls_heading("Editor");
	add_control("Scroll Up", &"editor_scroll_up");
	add_control("Scroll Down", &"editor_scroll_down");
	add_control("Scroll Left", &"editor_scroll_left");
	add_control("Scroll Right", &"editor_scroll_right");
	add_control("Mouse Up", &"editor_mouse_up");
	add_control("Mouse Down", &"editor_mouse_down");
	add_control("Mouse Left", &"editor_mouse_left");
	add_control("Mouse Right", &"editor_mouse_right");
	add_control("Move Faster", &"editor_scroll_fast");
	add_control("Click", &"editor_click");
	add_control("Cancel Drawing", &"editor_cancel");
	add_control("Delete", &"editor_delete");
	add_control("Multiselect", &"editor_multiselect");
	
	add_controls_heading("Misc");
	add_control("Toggle Playtest", &"editor_playtest");
	add_control("Exit Editor/Level", &"editor_quit");

func add_controls_heading(text: String) -> void:
	var heading := Label.new();
	heading.text = text;
	add_child(heading);
	add_padding();

func add_control(text: String, action: StringName) -> void:
	var title := Label.new();
	title.text = text;
	title.theme_type_variation = &"SmallLabel";
	title.size_flags_vertical = Control.SIZE_SHRINK_BEGIN;
	add_child(title);
	var bind := BIND_SCENE.instantiate();
	bind.action = action;
	bind.bind_start.connect(func():
		bind_label_name = text;
		cancel_countdown = 5;
		bind_label.text = bind_label_text.format([bind_label_name, cancel_countdown]);
		bind_cancel_timer.start();
		
		bind_window.visible = true;
		bind_label.grab_click_focus.call_deferred();
		Fades.current_scene.process_mode = PROCESS_MODE_DISABLED;
	);
	bind.bind_end.connect(func():
		bind_window.visible = false;
		bind_cancel_timer.stop();
		Fades.current_scene.process_mode = PROCESS_MODE_INHERIT;
	);
	add_child(bind);

func add_padding() -> void:
	add_child(Control.new());

func _on_cancel_timer_timeout() -> void:
	cancel_countdown -= 1;
	if cancel_countdown == 0:
		for binder: MultiKeybind in get_tree().get_nodes_in_group(&"currently_binding"):
			binder.cancel_bind();
		bind_window.visible = false;
		Fades.current_scene.process_mode = PROCESS_MODE_INHERIT;
	else:
		bind_label.text = bind_label_text.format([bind_label_name, cancel_countdown]);
