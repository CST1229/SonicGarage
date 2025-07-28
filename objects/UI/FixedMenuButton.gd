## MenuButton if it was good
extends MenuButton

func _ready():
	get_popup().id_pressed.connect(_on_id_pressed);
	get_popup().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST;

func _on_id_pressed(id: int):
	id_pressed.emit(id);

signal id_pressed(id: int);
