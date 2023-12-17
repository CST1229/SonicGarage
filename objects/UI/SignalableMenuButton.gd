extends MenuButton

# MenuButton if it was good

func _ready():
	get_popup().id_pressed.connect(_on_id_pressed);

func _on_id_pressed(id: int):
	id_pressed.emit(id);

signal id_pressed(id: int);
