extends Node

func draw_ghz_grass(to: CanvasItem, verts: Array[Vertex], is_shadow: bool):
	var edge_tex = preload("res://sprites/level_themes/GreenHill/grass_edge.png");
	var grass_tex = preload("res://sprites/level_themes/GreenHill/grass.png");
	
	var grass_angle = deg_to_rad(70);
	
	var grass_section = PackedVector2Array();
	var is_grass = false;
	
	var size: int = verts.size();
	var vert: Vertex;
	var next_vert: Vertex;
	for i: int in range(size):
		vert = verts[i];
		next_vert = verts[(i + 1) % size];
		
		var prev_grass = is_grass;
		is_grass = false;
		
		if vert.edge == "auto" && abs(vert.position.angle_to_point(next_vert.position)) <= grass_angle: 
			is_grass = true;
		if is_grass:
			grass_section.append(vert.position);
		
		if !is_grass && prev_grass:
			grass_section.append(vert.position);
			LevelDrawing.draw_grass_section(to, grass_section, grass_tex, is_shadow, edge_tex);
			grass_section.clear();
	if is_grass:
		grass_section.append(next_vert.position);
		LevelDrawing.draw_grass_section(to, grass_section, grass_tex, is_shadow, edge_tex);
		grass_section.clear();

func draw_grass_section(to: CanvasItem, section: PackedVector2Array, tex: Texture2D, is_shadow: bool = false, edge_tex: Texture2D = null):
	if section.size() <= 0: return;
	var tex_height = float(tex.get_height());
	var off = Vector2(0, tex_height * -0.5);
	
	var modulate = Color.WHITE;
	if is_shadow:
		modulate = Color(0, 0, 0, 0.6);
		off.y += tex_height * 0.5;
	
	var edge_width: float;
	var overhang_width: float;
	if edge_tex:
		edge_width = float(edge_tex.get_width());
		overhang_width = edge_width / 2;
	
	if edge_tex:
		var vert = section[0];
		var next_vert = section[1 % section.size()];
		var prev_width = abs(next_vert.x - vert.x);
		var skew_pixels = (next_vert.y - vert.y) * (edge_width / prev_width);
		var _off = off + Vector2(overhang_width, skew_pixels);
		draw_skew_texture(to, vert + _off, vert + _off - Vector2(edge_width, skew_pixels), edge_tex, false, 0, modulate);
	
	var offset = 0;
	for i in range(section.size() - 1):
		var vert = section[i];
		var next_vert = section[i + 1];
		if i == 0 && edge_tex:
			var section_width = abs(next_vert.x - vert.x);
			vert.y += (next_vert.y - vert.y) * (edge_width / section_width);
			vert.x += overhang_width;
		if i == (section.size() - 2) && edge_tex:
			var section_width = abs(next_vert.x - vert.x);
			next_vert.y -= (next_vert.y - vert.y) * (edge_width / section_width);
			next_vert.x -= overhang_width;
		draw_skew_texture(to, vert + off, next_vert + off, tex, true, offset, modulate);
		offset += next_vert.x - vert.x;
	
	if edge_tex:
		var vert = section[-1];
		var prev_vert = section[-2 % section.size()];
		var prev_width = abs(vert.x - prev_vert.x);
		var skew_pixels = (vert.y - prev_vert.y) * (edge_width / prev_width);
		var _off = off - Vector2(overhang_width, skew_pixels);
		draw_skew_texture(to, vert + _off, vert + _off + Vector2(edge_width, skew_pixels), edge_tex, false, 0, modulate);
		

func draw_skew_texture(to: CanvasItem, p1: Vector2, p2: Vector2, texture: Texture2D, repeat: bool = true, h_offset: float = 0, modulate: Color = Color.WHITE):
	var th_v = Vector2(0, texture.get_height());
	var uv_width: float = 1;
	if repeat:
		uv_width = (p2.x - p1.x) / texture.get_width();
	
	h_offset = h_offset / texture.get_width();
	
	# for some reason draw_primitive draws the wrong texture if i don't do this
	# godot bug????
	to.draw_texture(texture, Vector2.ZERO, Color(0,0,0,0));
	to.draw_primitive(
		PackedVector2Array([p1, p2, (p2 + th_v), (p1 + th_v)]),
		PackedColorArray([modulate, modulate, modulate, modulate]),
		PackedVector2Array([
			Vector2(h_offset, 0),
			Vector2(uv_width + h_offset, 0),
			Vector2(uv_width + h_offset, 1),
			Vector2(h_offset, 1)
		]),
		texture
	);
	
