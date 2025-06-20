## Functions for drawing levels.
extends Node

var semisolid_decor_cache: Dictionary[Array, Array] = {};

## Computes what decor (e.g grass edges) to render, based off of vertices.
func compute_decor(verts: Array[Vertex], polygon: Polygon) -> Array[DecorSection]:
	# TODO: don't hardcode the decor type
	var decors: Array = Decor.GHZ_DECOR;
	var decor_sections: Dictionary[Decor, DecorSection] = {};
	
	if polygon.is_in_editor() && polygon.semisolid:
		if decors not in semisolid_decor_cache:
			var new_decors := decors.duplicate();
			new_decors.append(Decor.EDITOR_SEMISOLID);
			semisolid_decor_cache[decors] = new_decors;
		decors = semisolid_decor_cache[decors];
	
	# Indexes that decide which decor takes precedence in case of a
	# MUTUALLY_EXCLUSIVE conflict.
	var decor_precedence: Dictionary[Decor, int] = {};
	for i in range(decors.size()):
		decor_precedence[decors[i]] = i;
	
	# List of decoration sections to render
	var sections_arr: Array[DecorSection] = [];
	
	var size: int = verts.size();
	var vert: Vertex;
	var next_vert: Vertex = verts[size - 1];
	for i: int in range(-1, size):
		vert = next_vert;
		next_vert = verts[(i + 1) % size];
		
		var angle := vert.position.angle_to_point(next_vert.position);
		
		for decor: Decor in decors:
			var matches = decor.matches(vert, angle);
			if matches && decor in Decor.MUTUALLY_EXCLUSIVE:
				for exclusive in Decor.MUTUALLY_EXCLUSIVE[decor]:
					if exclusive in decor_sections:
						if decor_precedence[decor] > decor_precedence[exclusive]:
							matches = false;
							break;
			if matches && decor not in decor_sections:
				var section := DecorSection.new(decor);
				decor_sections[decor] = section;
			if decor in decor_sections:
				var section := decor_sections[decor];
				section.verts.append(vert.position);
				# append here so don't create 1-vertex sections
				if section.verts.size() == 2:
					sections_arr.append(section);
				section.angles.append(angle);
				if !matches:
					decor_sections.erase(decor);
	
	return sections_arr;

func draw_decor(to: CanvasItem, sections: Array[DecorSection], layer: Decor.Layer):
	var size: int = sections.size();
	var section: DecorSection;
	for i: int in range(size):
		section = sections[i];
		
		if (section.decor.layer & layer) == 0:
			continue;
		
		match section.decor.type:
			&"grass":
				LevelDrawing.draw_grass_section(to, section, layer == Decor.Layer.SHADOW);
			&"shade":
				LevelDrawing.draw_shade(to, section);

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
		# for some reason draw_primitive draws the wrong texture if i don't do this
		# godot bug????
		to.draw_texture(edge_tex, verts[0], Color(0,0,0,0));
		var vert: Vector2 = verts[0];
		var next_vert: Vector2 = verts[1 % verts.size()];
		if vert.x != next_vert.x:
			var prev_width := absf(next_vert.x - vert.x);
			var skew_pixels: float = (next_vert.y - vert.y) * (edge_width / prev_width);
			var _off: Vector2 = off + Vector2(overhang_width, skew_pixels);
			draw_skew_texture(to, vert + _off, vert + _off - Vector2(edge_width, skew_pixels), edge_tex, false, 0, modulate);
	
	to.draw_texture(tex, verts[0], Color(0,0,0,0));
	
	var offset: float = 0.0;
	for i in range(verts.size() - 1):
		var vert: Vector2 = verts[i];
		var next_vert: Vector2 = verts[i + 1];
		if vert.x == next_vert.x:
			continue;
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
		to.draw_texture(edge_tex, verts[0], Color(0,0,0,0));
		var vert: Vector2 = verts[-1];
		var prev_vert: Vector2  = verts[-2 % verts.size()];
		if vert.x != prev_vert.x:
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
	
	#if is_nan(p1.x):
		#push_error("draw_skew_texture: p1.x is nan");
	#elif is_nan(p1.y):
		#push_error("draw_skew_texture: p1.y is nan");
	#elif is_nan(p2.x):
		#push_error("draw_skew_texture: p2.x is nan");
	#elif is_nan(p2.y):
		#push_error("draw_skew_texture: p2.y is nan");
	
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
	
	# clipping apparently breaks some culling thing

func draw_shade(to: CanvasItem, section: DecorSection):
	# TODO: proper shade drawing
	var shade_width = 8.0 * 3;
	to.draw_polyline(section.verts, section.decor.color, shade_width);
