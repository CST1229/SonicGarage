extends Panel

@export var level_container: LevelContainer;

@onready var back_button: Button = $BackButton;
@onready var scroll_container: ScrollContainer = $HMargin/ScrollContainer;

func entered() -> void:
	scroll_container.scroll_vertical = 0;
	back_button.grab_focus();

func _on_back_button_pressed() -> void:
	go_back.emit();

signal go_back;
