extends MonitorItem

func _ready():
	play(&"ring");

func _give_reward(_player: Player):
	Global.level_manager.rings += 10;
	GlobalSounds.play_ring();
