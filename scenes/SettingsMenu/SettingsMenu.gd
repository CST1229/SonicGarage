extends Panel

func _on_open_folder_button_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"));

func _on_back_button_pressed() -> void:
	go_back.emit();

signal go_back();
