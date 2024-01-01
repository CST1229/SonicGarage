extends Area2D

@onready var sprite = $sprite;
@onready var sound = $sound;
@onready var complete_music = $complete_music;

var passed_player: Player;

var end_timer = 0;
var exit_timer = 0;

func _ready():
	sprite.play("eggman");
	 
func _process(delta: float):
	if end_timer > 0:
		end_timer = move_toward(end_timer, 0, delta);
		if end_timer <= 0:
			sprite.play("sonic");
			passed_player.velocity.x = 0;
			if passed_player.velocity.y < 0: passed_player.velocity.y = 0;
			passed_player.state = Player.State.LEVEL_COMPLETE;
			
			var scene = get_tree().current_scene;
			if "playtest_room" in scene && scene.playtest_room:
				exit_timer = 2;
			else:
				exit_timer = 8;
				complete_music.play();
	
	if exit_timer > 0:
		exit_timer = move_toward(exit_timer, 0, delta);
		if exit_timer <= 0:
			var scene = get_tree().current_scene;
			if scene.has_method("playtest") && scene.has_method("exit"):
				if "playtest_room" in scene && scene.playtest_room:
					scene.playtest();
				else:
					scene.exit();
				

func _on_body_entered(body):
	if sprite.animation == "eggman":
		if body is Player:
			passed_player = body;
			if passed_player.camera:
				passed_player.camera.end_sign = self;
			
			sprite.play("spin");
			sound.play();
			end_timer = 2;

func serialize():
	return {
		id = "signpost",
		x = position.x,
		y = position.y
	};
func deserialize(json: Dictionary):
	position.x = json.x;
	position.y = json.y;
