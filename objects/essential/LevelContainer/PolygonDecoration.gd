extends Node2D

var vectors: PackedVector2Array;

@export var is_shadow: bool = false;

func _draw():
	if !vectors:
		return;
	LevelDrawing.draw_ghz_grass(self, vectors, is_shadow);
