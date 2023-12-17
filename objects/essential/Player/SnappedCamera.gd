extends Camera2D

func _physics_process(_delta):
	var target = get_parent();
	global_position = floor(target.global_position);
