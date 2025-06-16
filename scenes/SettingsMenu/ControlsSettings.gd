extends GridContainer

const BIND_SCENE = preload("res://scenes/SettingsMenu/ControlBind.tscn");

func _ready() -> void:
	add_controls_heading("Gameplay");
	add_control("Move Left", &"player_left");
	add_control("Move Right", &"player_right");
	add_control("Jump", &"player_jump");
	add_control("Crouch/Roll", &"player_down");
	add_controls_heading("Editor");

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
	add_child(bind);

func add_padding() -> void:
	add_child(Control.new());
