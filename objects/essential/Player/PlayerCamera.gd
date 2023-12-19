extends Camera2D

@onready var target: Player = get_parent();

var end_sign: Node2D = null;;

var v_focus := -16;

func _ready():
	global_position = target.global_position;

func _physics_process(delta):
	if end_sign:
		var speed = 1 * 60;
		var epos = end_sign.global_position;
		global_position.x = move_toward(global_position.x, epos.x, speed * delta);
		global_position.y = move_toward(global_position.y, epos.y - 16, speed * delta);
		return;
	
	var off = (target.global_position + Vector2(0, v_focus)) - global_position;
	
	var h_border: int = 8;
	if off.x < -h_border:
		global_position.x += off.x + h_border;
	if off.x > h_border:
		global_position.x += off.x - h_border;
	
	var top_border: int = v_focus - 32;
	var bottom_border: int = v_focus + 32;
	
	if target.falling >= 0.05:
		if off.y < top_border:
			global_position.y += off.y - top_border;
		if off.y > bottom_border:
			global_position.y += off.y - bottom_border;
	else:
		var move_speed: int;
		var gsp = abs(target.velocity.length());
		if gsp < (5 * 60):
			move_speed = 4 * 60;
		if gsp <= (7 * 60):
			move_speed = 8 * 60;
		elif gsp <= (14 * 60):
			move_speed = 16 * 60;
		elif gsp <= (20 * 60):
			move_speed = 24 * 60;
		else:
			move_speed = 28 * 60;
		
		global_position.y = move_toward(global_position.y, target.global_position.y + v_focus, move_speed * delta);
	
	global_position = floor(global_position);
