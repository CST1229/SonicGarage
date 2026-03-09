@tool
extends EditorScript

# Puts a non-monospaced font from Aseprite (single-row only) into an imported font image.
# How to use:
# 1. Make sure Aseprite is in your PATH (so typing `aseprite` in the terminal should launch it)
#    except on Linux and maybe macOS, where you have to add it to the hardcoded_path array
# 2. Run this script (Ctrl+Shift+X), and select the exported font JSON.

func exec(cmd: String, args: PackedStringArray) -> int:
	var out := [];
	var exitcode := OS.execute(cmd, args, out, true);
	prints(cmd, "with args", args, "exited with exitcode", exitcode);
	return exitcode;

func _run():
	var ase_path := "aseprite";
	# hacky but OS.execute doesnt seem to play well with PATH
	for hardcoded_path in [
		"/home/cst/Documents/Projects/Other/aseprite/aseprite-release/bin/aseprite"
	]:
		if FileAccess.file_exists(hardcoded_path):
			ase_path = hardcoded_path;
			break;
	
	for font_name in ["ui_font"]:
		var font_msgname := \
			ProjectSettings.globalize_path("res://sprites/fonts/" + font_name);
		var font_png := \
			ProjectSettings.globalize_path("res://sprites/fonts/" + font_name + ".png");
		var font_aseprite := \
			ProjectSettings.globalize_path("res://sprites/fonts/" + font_name + ".aseprite");
		var font_json := \
			ProjectSettings.globalize_path("res://sprites/fonts/" + font_name + ".json");
		# aseprite -b --sheet ui_font.png ui_font.aseprite
		# aseprite -b --trim --data ui_font.json --list-layers ui_font.aseprite
		exec(ase_path, ["-b", "--sheet", font_png, font_aseprite]);
		exec(ase_path, ["-b", "--trim", "--data", font_json, "--list-layers", font_aseprite]);
		
		var import_path := font_png + ".import";
		if !FileAccess.file_exists(import_path):
			OS.alert(font_msgname + ": " + import_path + " does not exist!", "Error");
			return;
		
		var json = JSON.parse_string(FileAccess.get_file_as_string(font_json));
		if json is not Dictionary:
			OS.alert(font_msgname + ": Invalid JSON file.", "Error");
			return;
		
		@warning_ignore("unsafe_cast")
		var json_dict := json as Dictionary;
		var strings := PackedStringArray();
		var frames := dict_to_arr(json_dict.frames);
		
		var layer = json_dict.meta.layers[0];
		var missing_userdatas := [];
		for cel: Dictionary in layer.cels:
			if "data" in cel and cel.data:
				var frame_no := int(cel.frame);
				var frame: Dictionary = frames[frame_no];
				
				var data := String(cel.data);
				var data_split := data.split("=");
				if data == "=":
					data_split = PackedStringArray([data]);
				var character := data_split[0];
				var width: int = \
					int(frame.spriteSourceSize.w) + int(frame.spriteSourceSize.x);
				if data_split.size() >= 2:
					width = data_split[1].to_int();
				
				while strings.size() <= frame_no:
					strings.append(
						"you missed a user data spot at frame %s!!!" % (frame_no + 1)
					);
					missing_userdatas.append(frame_no + 1);
				var x_offset: int = width - frame.sourceSize.w;
				strings[frame_no] = "{0}-{0} {1}".format(
					[character.unicode_at(0), x_offset]
				);
				missing_userdatas.erase(frame_no + 1);
		var config := ConfigFile.new();
		if config.load(import_path) != OK:
			OS.alert(font_msgname + ": Could not load file.", "Error");
			return;
		config.set_value("params", "character_ranges", strings);
		config.set_value("params", "columns", strings.size());
		config.save(import_path);
		if missing_userdatas.is_empty():
			print(font_msgname, ": Saved!");
		else:
			OS.alert(
				font_msgname + ": Saved, but cel user data is missing at frames %s" % [
					missing_userdatas
				],
				"Warning"
			);
	
	# reimport
	EditorInterface.get_resource_filesystem().scan();

func dict_to_arr(arr_or_dict) -> Array:
	if arr_or_dict is Dictionary:
		return arr_or_dict.values();
	return arr_or_dict;
