extends Badnik

@onready var visuals = $visuals;
@onready var sprite = $visuals/sprite;
@onready var smoke_sprite = $visuals/smoke_sprite;
var container: LevelContainer;

@onready var turn_sensor_left: RayCast2D = $TurnSensorLeft;
@onready var turn_sensor_right: RayCast2D = $TurnSensorRight;

var gravity := 1000.0;
var speed := 64.0;
const ACCELERATION := 35.0 ** 2;
var flip_h := false:
	set(value):
		flip_h = value;
		if visuals:
			visuals.scale.x = -1 if flip_h else 1;

func _ready():
	if !container || !container.editor_mode:
		sprite.play("default");
		smoke_sprite.visible = true;
		smoke_sprite.play("smoke");
	flip_h = flip_h;
	velocity.x = (-1 if flip_h else 1) * speed;

func _physics_process(delta: float):
	if container && container.editor_mode:
		return;
	
	var old_vel_x := velocity.x;
	velocity.x = move_toward(velocity.x, (-1 if flip_h else 1) * speed, ACCELERATION * delta);
	velocity.y += gravity * delta;
	
	smoke_sprite.visible = true;
	sprite.speed_scale = 1.0;
	if is_on_floor():
		var turn_sensor_front := turn_sensor_right;
		var turn_sensor_back := turn_sensor_left;
		if flip_h:
			turn_sensor_front = turn_sensor_left;
			turn_sensor_back = turn_sensor_right;
		turn_sensor_front.force_raycast_update();
		turn_sensor_back.force_raycast_update();
		if !turn_sensor_front.is_colliding():
			if !turn_sensor_back.is_colliding():
				velocity.x = 0;
				smoke_sprite.visible = false;
				sprite.speed_scale = 0.0;
			else:
				flip_h = !flip_h;
				velocity.x = -velocity.x;
	
	move_and_slide();
	if is_on_wall():
		var old_flip_h := flip_h;
		flip_h = get_wall_normal().x < 0;
		velocity.x = -old_vel_x if old_flip_h != flip_h else old_vel_x;
	var collision: KinematicCollision2D = get_last_slide_collision();
	if collision && collision.get_collider() is Touchbox:
		collision.get_collider().touched.emit(self);

func serialize() -> Dictionary:
	return {
		x = position.x,
		y = position.y,
		flip_h = flip_h,
	};
func deserialize(json: Dictionary) -> void:
	position.x = json.x;
	position.y = json.y;
	flip_h = json.flip_h;
