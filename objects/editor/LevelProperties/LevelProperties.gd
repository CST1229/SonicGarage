extends Node

func _on_back_button_pressed() -> void:
	go_back.emit();

signal go_back;
