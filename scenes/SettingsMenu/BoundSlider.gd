extends Slider

@export var setting_name: StringName;
@export var hide_with_tags := PackedStringArray();

func _ready():
	for tag in hide_with_tags:
		if OS.has_feature(tag):
			visible = false;
			return;
			
	Global.setting_binding(setting_name, self, &"value", value_changed);
	drag_ended.connect(func(has_value_changed: bool):
		if has_value_changed: Settings.save_settings();
	);

func _process(delta):
	if has_focus():
		value += Input.get_axis("ui_left", "ui_right") * delta * (max_value - min_value);
