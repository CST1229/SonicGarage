extends CheckButton

@export var setting_name: StringName;
@export var hide_with_tags := PackedStringArray();

func _ready():
	for tag in hide_with_tags:
		if OS.has_feature(tag):
			visible = false;
			return;
	
	Global.setting_binding(setting_name, self, &"button_pressed", toggled);
	toggled.connect(func(_arg: Variant):
		Settings.save_settings();
	);
