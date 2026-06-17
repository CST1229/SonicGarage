extends EditorRoomBase

func _ready() -> void:
	super();
	LevelUtil.playtest_trails.clear();
	
	if level_container && level_container.player:
		record_player_pos(level_container.player);
		level_container.player.sudden_momentum_change.connect(func() -> void:
			record_player_pos(level_container.player);
		);

func playtest() -> void:
	if level_container && level_container.player:
		record_player_pos(level_container.player);
	super();

func _on_trail_timer_timeout() -> void:
	if !level_container:
		return;
	var player := level_container.player;
	if player:
		record_player_pos(player);

func record_player_pos(player: Player) -> void:
	if player.state != Player.State.DEAD:
		var pos := player.position;
		if !LevelUtil.playtest_trails.is_empty() && \
			LevelUtil.playtest_trails[-1].is_equal_approx(pos):
			return;
		LevelUtil.playtest_trails.append(pos);
