## Functions for drawing levels.
extends Node

## Computes what decor (e.g grass edges) to render, based off of vertices.
func compute_decor(verts: Array[Vertex]) -> Array[DecorSection]:
	var grass_angle := deg_to_rad(70);
	
	var current_decor_type := Decor.NONE;
	var prev_section_type := current_decor_type;
	var current_section: PackedVector2Array = PackedVector2Array();
	var _sections: Dictionary = {};
	# List of decoration sections to render
	var sections_arr: Array[DecorSection] = [];
	
	var size: int = verts.size();
	var vert: Vertex;
	var next_vert: Vertex;
	for i: int in range(size):
		vert = verts[i];
		next_vert = verts[(i + 1) % size];
		
		prev_section_type = current_decor_type;
		
		current_decor_type = Decor.NONE;
		if vert.edge == "auto" && absf(vert.position.angle_to_point(next_vert.position)) <= grass_angle: 
			current_decor_type = Decor.GHZ_GRASS;
		
		if current_decor_type != prev_section_type:
			if prev_section_type != Decor.NONE && current_section.size() >= 1:
				current_section.append(vert.position);
				sections_arr.append(DecorSection.create(prev_section_type, current_section));
			else:
				current_section = PackedVector2Array();
				current_section.append(vert.position);
		elif current_decor_type != Decor.NONE:
			current_section.append(vert.position);
	if current_decor_type != Decor.NONE && current_section.size() >= 1:
		current_section.append(next_vert.position);
		sections_arr.append(DecorSection.create(current_decor_type, current_section));
	
	return sections_arr;

func draw_decor(to: CanvasItem, sections: Array[DecorSection], is_shadow: bool):
	var size: int = sections.size();
	var section: DecorSection;
	for i: int in range(size):
		section = sections[i];
		
		match section.decor.type:
			&"grass":
				LevelDrawing.draw_grass_section(to, section, is_shadow);

func draw_grass_section(to: CanvasItem, section: DecorSection, is_shadow: bool = false):
	var verts: PackedVector2Array = section.verts;
	var tex: Texture2D = section.decor.texture;
	var edge_tex: Texture2D = section.decor.edge;
	
	var tex_height := float(tex.get_height());
	var off := Vector2(0, tex_height * -0.5);
	
	var modulate := Color.WHITE;
	if is_shadow:
		modulate = Color(0, 0, 0);
		off.y += tex_height * 0.5;
	
	var edge_width: float;
	var overhang_width: float;
	if edge_tex:
		edge_width = float(edge_tex.get_width());
		overhang_width = edge_width / 2;
	
	if edge_tex:
		var vert: Vector2 = verts[0];
		var next_vert: Vector2 = verts[1 % verts.size()];
		var prev_width := absf(next_vert.x - vert.x);
		var skew_pixels: float = (next_vert.y - vert.y) * (edge_width / prev_width);
		var _off: Vector2 = off + Vector2(overhang_width, skew_pixels);
		draw_skew_texture(to, vert + _off, vert + _off - Vector2(edge_width, skew_pixels), edge_tex, false, 0, modulate);
	
	var offset: float = 0.0;
	for i in range(verts.size() - 1):
		var vert: Vector2 = verts[i];
		var next_vert: Vector2 = verts[i + 1];
		if i == 0 && edge_tex:
			var section_width := absf(next_vert.x - vert.x);
			vert.y += (next_vert.y - vert.y) * (edge_width / section_width);
			vert.x += overhang_width;
		if i == (verts.size() - 2) && edge_tex:
			var section_width := absf(next_vert.x - vert.x);
			next_vert.y -= (next_vert.y - vert.y) * (edge_width / section_width);
			next_vert.x -= overhang_width;
		draw_skew_texture(to, vert + off, next_vert + off, tex, true, offset, modulate);
		offset += next_vert.x - vert.x;
	
	if edge_tex:
		var vert: Vector2 = verts[-1];
		var prev_vert: Vector2  = verts[-2 % verts.size()];
		var prev_width := absf(vert.x - prev_vert.x);
		var skew_pixels: float = (vert.y - prev_vert.y) * (edge_width / prev_width);
		var _off: Vector2 = off - Vector2(overhang_width, skew_pixels);
		draw_skew_texture(to, vert + _off, vert + _off + Vector2(edge_width, skew_pixels), edge_tex, false, 0, modulate);
		

func draw_skew_texture(to: CanvasItem, p1: Vector2, p2: Vector2, texture: Texture2D, repeat: bool = true, h_offset: float = 0, modulate: Color = Color.WHITE):
	var th_v := Vector2(0, texture.get_height());
	var uv_width: float = 1.0;
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
	
