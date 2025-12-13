extends TileMapLayer

@export_flags_2d_physics var layer: int;
@export_flags_2d_physics var mask: int;

func _ready():
	layerify();

func layerify():
	tile_set = tile_set.duplicate(true);
	tile_set.set_physics_layer_collision_layer(0, layer);
	tile_set.set_physics_layer_collision_mask(0, mask);
