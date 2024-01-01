extends Area2D

@export var check_areas := true;
@export var check_bodies := true;

func _physics_process(_delta: float):
	if !monitoring:
		return;
	if check_areas:
		for area in get_overlapping_areas():
			area_inside.emit(area);
	if check_bodies:
		for body in get_overlapping_bodies():
			body_inside.emit(body);
		

signal area_inside(area: Area2D);
signal body_inside(body: Node2D);
