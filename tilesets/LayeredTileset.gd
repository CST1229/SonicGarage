extends TileMap

func _ready():
	layerify();

func layerify():
	tile_set = tile_set.duplicate(true);
	while tile_set.get_physics_layers_count() < 3:
		tile_set.add_physics_layer();
	tile_set.set_physics_layer_collision_layer(0, Global.LAYER_A | Global.LAYER_B);
	tile_set.set_physics_layer_collision_layer(1, Global.LAYER_A);
	tile_set.set_physics_layer_collision_layer(2, Global.LAYER_B);
	tile_set.set_physics_layer_collision_mask(0, Global.LAYER_A | Global.LAYER_B);
	tile_set.set_physics_layer_collision_mask(1, Global.LAYER_A | Global.LAYER_B);
	tile_set.set_physics_layer_collision_mask(2, Global.LAYER_A | Global.LAYER_B);
	
	var source_map = {};
	for i in range(tile_set.get_source_count()):
		var source = tile_set.get_source(i);
		if !(source is TileSetAtlasSource): continue;
		var new_a_id = tile_set.add_source(source.duplicate(true));
		var new_a = tile_set.get_source(new_a_id);
		var new_b_id = tile_set.add_source(source.duplicate(true));
		var new_b = tile_set.get_source(new_b_id);
		
		source_map[i] = [new_a_id, new_b_id];
		
		for j in range(source.get_tiles_count()):
			var tile = source.get_tile_id(j);
			for k in range(source.get_alternative_tiles_count(tile)):
				var alt_id = source.get_alternative_tile_id(tile, k);
				var data_a = new_a.get_tile_data(tile, alt_id);
				var data_b = new_b.get_tile_data(tile, alt_id);
				
				move_polygons(data_a, 0, 1);
				move_polygons(data_b, 0, 2);
	
	for layerid in range(get_layers_count()):
		var layer_name = get_layer_name(layerid);
		if layer_name != Global.LAYER_A_NAME && layer_name != Global.LAYER_B_NAME: continue;
		var source_i = 1 if (layer_name == Global.LAYER_B_NAME) else 0;
		for cell in get_used_cells(layerid):
			var tile_source = get_cell_source_id(layerid, cell);
			if tile_source in source_map:
				var coords = get_cell_atlas_coords(layerid, cell);
				var alttile = get_cell_alternative_tile(layerid, cell);
				set_cell(layerid, cell, source_map[tile_source][source_i], coords, alttile);

func move_polygons(data: TileData, from, to):
	if from == to: return;
	
	for old_poly in range(data.get_collision_polygons_count(from)):
		var points = data.get_collision_polygon_points(from, old_poly);
		var ow = data.is_collision_polygon_one_way(from, old_poly);
		var owm = data.get_collision_polygon_one_way_margin(from, old_poly);
		
		var new_poly = data.get_collision_polygons_count(to);
		data.add_collision_polygon(to);
		data.set_collision_polygon_points(to, new_poly, points);
		data.set_collision_polygon_one_way(to, new_poly, ow);
		data.set_collision_polygon_one_way_margin(to, new_poly, owm);
	
	for old_poly in range(data.get_collision_polygons_count(from)):
		data.remove_collision_polygon(from, old_poly);
