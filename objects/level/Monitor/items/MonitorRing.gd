extends MonitorItem

func _ready():
	play(&"ring");

func _give_reward(_player: Player):
	LevelUtil.level_manager.rings += 10;
	GlobalSounds.play_ring();
