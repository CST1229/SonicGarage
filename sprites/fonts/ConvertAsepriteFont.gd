@tool
extends EditorScript

# Puts a non-monospaced font from Aseprite (single-row only) into an imported font image.
# How to use:
# 1. Create the font image, export it as a spritesheet and set the proper import format
# 2. In the font Aseprite file, set the user data of each cel in the first layer to the character it represents. You can modify and use the do_font.lua file in this directory for this too.
# 3. Export it as a sprite sheet. Make sure to *uncheck* Output File, *check* JSON Data and enable Trim Cels.
# 4. Run this script (Ctrl+Shift+X), and select the font file and the exported JSON.

func _run():
	EditorInterface.popup_quick_open(func(path: String):
		if path == "": return;
		var import_path := path + ".import";
		if !FileAccess.file_exists(import_path):
			OS.alert("File's import settings do not exist!");
		else:
			DisplayServer.file_dialog_show("Select the font's Aseprite JSON file", ProjectSettings.globalize_path(import_path.get_base_dir()), path.get_file().get_basename() + ".json", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.json;Aseprite JSON;application/json"]), func(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
				if !status: return;
				var json_path := selected_paths[0];
				if json_path == "": return;
				var json = JSON.parse_string(FileAccess.get_file_as_string(json_path));
				if json is not Dictionary:
					OS.alert("Invalid JSON file.");
					return;
				
				@warning_ignore("unsafe_cast")
				var json_dict := json as Dictionary;
				var strings := PackedStringArray();
				var frames := dict_to_arr(json_dict.frames);
				
				var layer = json_dict.meta.layers[0];
				for cel: Dictionary in layer.cels:
					if "data" in cel and cel.data:
						var frame_no := int(cel.frame);
						var frame: Dictionary = frames[frame_no];
						
						var data := String(cel.data);
						var data_split := data.split("=");
						if data == "=":
							data_split = PackedStringArray([data]);
						var char := data_split[0];
						var width: int = int(frame.spriteSourceSize.w) + int(frame.spriteSourceSize.x);
						if data_split.size() >= 2:
							width = data_split[1].to_int();
						
						while strings.size() <= frame_no:
							strings.append("you missed a user data spot at frame {0}!!!".format(frame_no + 1));
						var x_offset: int = width - frame.sourceSize.w;
						strings[frame_no] = "{0}-{0} {1}".format([char.unicode_at(0), x_offset]);
				var config := ConfigFile.new();
				if config.load(import_path) != OK:
					OS.alert("Could not load file.");
					return;
				config.set_value("params", "character_ranges", strings);
				config.set_value("params", "columns", strings.size());
				config.save(import_path);
				OS.alert("Saved!");
			);
	, [&"FontFile"]);

func dict_to_arr(arr_or_dict) -> Array:
	if arr_or_dict is Dictionary:
		return arr_or_dict.values();
	return arr_or_dict;
