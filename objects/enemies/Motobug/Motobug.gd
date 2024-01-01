extends Badnik

@onready var visuals = $visuals;
@onready var sprite = $visuals/sprite;
@onready var smoke_sprite = $visuals/smoke_sprite;
var container: LevelContainer;

var gravity := 1000.0;
var speed := 64.0;
var flip_h = false:
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

func _physics_process(delta: float):
	if container && container.editor_mode:
		return;
	
	velocity.x = (-1 if flip_h else 1) * speed;
	velocity.y += gravity * delta;
	move_and_slide();
	if is_on_wall():
		flip_h = get_wall_normal().x < 0;

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
