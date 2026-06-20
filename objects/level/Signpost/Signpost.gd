extends Area2D

@onready var sprite = $sprite;
@onready var sound = $sound;

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
			passed_player.queue_level_complete = true;
			
			var scene = Fades.current_scene;
			if "playtest_room" in scene && scene.playtest_room:
				exit_timer = 2;
			else:
				exit_timer = 8;
				Music.play(load("res://music/levelcomplete.ogg"))
	
	if exit_timer > 0:
		exit_timer = move_toward(exit_timer, 0, delta);
		if exit_timer <= 0:
			var scene = Fades.current_scene;
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
			if LevelUtil.level_manager:
				LevelUtil.level_manager.tick_time = false;
			
			sprite.play("spin");
			sound.play();
			end_timer = 2;

func serialize() -> Dictionary:
	return {
		x = position.x,
		y = position.y
	};
func deserialize(json: Dictionary) -> void:
	position.x = json.x;
	position.y = json.y;
