extends CanvasItem

@export var tags := PackedStringArray();

func _ready():
	for tag in tags:
		if OS.has_feature(tag):
			visible = false;
			return;
	
