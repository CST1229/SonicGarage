class_name SettingsMenu
extends VBoxContainer

@onready var options: GridContainer = $Options

@onready var terrain_detail: OptionButton = $Options/TerrainDetail;

func _ready() -> void:
	Global.setting_binding(&"terrain_detail", terrain_detail, &"selected", terrain_detail.item_selected,
		func(value: int) -> int: return 2 - value;
	, func(value: int) -> int: return 2 - value;
	);
	handle_save(terrain_detail.item_selected);
	
	for option in options.get_children():
		if option is BaseButton:
			option.focus_neighbor_left = ^".";
			option.focus_neighbor_right = ^".";

func handle_save(listen: Signal):
	listen.connect(func(_arg: Variant):
		Settings.save_settings();
	);
