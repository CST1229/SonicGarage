extends Panel

@export var save_custom_logo_movements_button: Button;

@onready var back_button: Button = $BackButton;

func entered() -> void:
	back_button.grab_focus();

func show_custom_logo_movements_button() -> void:
	save_custom_logo_movements_button.visible = true;

func _on_open_folder_button_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"));

func _on_back_button_pressed() -> void:
	go_back.emit();
	

func _on_save_custom_logo_movements_pressed() -> void:
	var path := DancingLogo.CUSTOM_MOVEMENTS_PATH;
	if !FileAccess.file_exists(path):
		path = DancingLogo.OLD_MOVEMENTS_PATH;
		if !FileAccess.file_exists(path):
			OS.alert("You don't have movements saved. Click the logo on the main menu to record one.");
			return;
		else:
			OS.alert("You don't have movements saved. The old vanilla movements will be saved.")
	var positions := PackedVector2Array();
	if DancingLogo.read_logo_movements(path, positions):
		var movements := LogoMovementsDef.new();
		movements.positions = positions;
		ResourceSaver.save(movements, DancingLogo.VANILLA_MOVEMENTS_PATH);
		OS.alert("Saved!");
	else:
		OS.alert("Could not read movements.");

signal go_back;
