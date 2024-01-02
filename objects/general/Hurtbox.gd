extends ConstantMonitorArea2D

@export var grounded_only = false;

func _ready():
	body_inside.connect(self._on_body_inside);

func _on_body_inside(body: Node2D):
	if body is Player:
		var player: Player = body as Player;
		if !grounded_only || !player.falling:
			if player.hurt():
				hurted.emit();

signal hurted
