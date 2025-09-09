extends Badnik

@onready var visuals = $visuals;
@onready var sprite = $visuals/sprite;
@onready var smoke_sprite = $visuals/smoke_sprite;
var container: LevelContainer;

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
	move_and_slide();
	if is_on_wall():
		var old_flip_h := flip_h;
		flip_h = get_wall_normal().x < 0;
		velocity.x = -old_vel_x if old_flip_h != flip_h else old_vel_x;
	$asdfasdf.a()
	var collision: KinematicCollision2D = get_last_slide_collision();
	if collision && collision.get_collider() is Touchbox:
		collision.get_collider().touched.emit(self);

func serialize():
	return {
		id = "motobug",
		x = position.x,
		y = position.y,
		flip_h = flip_h,
	};
func deserialize(json: Dictionary):
	position.x = json.x;
	position.y = json.y;
	flip_h = json.flip_h;
