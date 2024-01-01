extends Camera2D

@onready var target: Player = get_parent();

var end_sign: Node2D = null;

var v_focus := -16.0;

func _ready():
	global_position = target.global_position;

func _physics_process(delta: float):
	if target.state == Player.State.DEAD:
		return;
	
	if end_sign:
		var speed := 1.0 * 60;
		var epos: Vector2 = end_sign.global_position;
		global_position.x = move_toward(global_position.x, epos.x, speed * delta);
		global_position.y = move_toward(global_position.y, epos.y - 16, speed * delta);
		return;
	
	var off := (target.global_position + Vector2(0, v_focus)) - global_position;
	
	var h_border: float = 8.0;
	if off.x < -h_border:
		global_position.x += off.x + h_border;
	if off.x > h_border:
		global_position.x += off.x - h_border;
	
	var top_border: float = v_focus - 32.0;
	var bottom_border: float = v_focus + 32.0;
	
	if target.falling >= 0.05:
		if off.y < top_border:
			global_position.y += off.y - top_border;
		if off.y > bottom_border:
			global_position.y += off.y - bottom_border;
	else:
		var move_speed: float;
		var gsp := absf(target.velocity.length());
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
	
	global_position = global_position.floor();
