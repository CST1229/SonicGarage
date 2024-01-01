extends MonitorItem

func _ready():
	play(&"eggman");

func _give_reward(player: Player):
	player.hurt();
