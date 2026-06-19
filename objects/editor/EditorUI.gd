## Handles the editor's UI. Controls a [LevelEditor].
extends Control
class_name EditorUI

## The [LevelEditor] to control.
@export var editor: LevelEditor;

@onready var pause_menu: PauseMenu = $PauseMenu;

@onready var terrain_tools: Control = %TerrainTools;
@onready var polygon_actions: HBoxContainer = %PolygonActions
@onready var vertex_actions: HBoxContainer = %VertexActions

@onready var poly_layer_button: Button = %PolyLayerButton;
@onready var toggle_semisolid_button: Button = %ToggleSemisolidButton;
@onready var line_edge_button: Button = %LineEdgeButton;

@onready var object_tools: Control = %ObjectTools;
@onready var object_selector: Control = %ObjectSelector;
@onready var object_selector_panel: Panel = %ObjectSelectorPanel;
@onready var object_list: FlowContainer = %ObjectList;
@onready var selected_object_name: Label = %SelectedObjectName;

@onready var file_dialog: FileDialog = $FileDialog;
var last_pause_menu: PauseMenu;

@onready var save_sound: AudioStreamPlayer = $SaveSound;

var objects_flap_open := false;
var objects_flap_transition := 0.0;

## A list of object IDs to use in the object selector.
var listed_objects: Array[String] = Global.editor_object_list;

## A map of [enum LevelEditor.Tool] to a [Button] that selects the tool.
@onready var tool_buttons: Dictionary[LevelEditor.Tool, Button] = {
	LevelEditor.Tool.POLY_SELECT: %PolySelectTool,
	LevelEditor.Tool.VERT_SELECT: %VertSelectTool,
	LevelEditor.Tool.LINE: %LineTool,
	LevelEditor.Tool.OBJECT_SELECT: %ObjectSelectTool,
};
## A map of [enum LevelEditor.Mode] to a [Button] that selects the mode.
@onready var mode_buttons: Dictionary[LevelEditor.Mode, Button] = {
	LevelEditor.Mode.TERRAIN: %TerrainMode,
	LevelEditor.Mode.OBJECTS: %ObjectsMode,
};
## The default [enum LevelEditor.Tool]s for each [LevelEditor.Mode].
@onready var mode_default_tools = {
	LevelEditor.Mode.TERRAIN: LevelEditor.Tool.VERT_SELECT,
	LevelEditor.Mode.OBJECTS: LevelEditor.Tool.OBJECT_SELECT,
};

const POLY_LAYER_A = preload("res://sprites/icons/tools/layer_a.png");
const POLY_LAYER_B = preload("res://sprites/icons/tools/layer_b.png");
const POLY_LAYER_AB = preload("res://sprites/icons/tools/layer_ab.png");

func _ready() -> void:
	select_mode(LevelEditor.Mode.TERRAIN, LevelEditor.Tool.VERT_SELECT);
	populate_object_list(listed_objects);
	do_gui_hover(self);
	
	editor.selection_changed.connect(self.selection_changed);
	
	for tool: LevelEditor.Tool in tool_buttons.keys():
		var button: Button = tool_buttons[tool];
		button.pressed.connect(select_tool.bind(tool));
	
	for mode: LevelEditor.Mode in mode_buttons.keys():
		var button: Button = mode_buttons[mode];
		var default_tool: LevelEditor.Tool = mode_default_tools[mode];
		button.pressed.connect(select_mode.bind(mode, default_tool));
	
	selection_changed();

func do_gui_hover(node: Node) -> void:
	for child in node.get_children():
		if child is Control && child.mouse_filter == Control.MOUSE_FILTER_STOP:
			child.mouse_entered.connect(do_hover);
			child.mouse_exited.connect(do_dehover);
		do_gui_hover(child);

func do_hover() -> void:
	hover_over_gui.emit();
func do_dehover() -> void:
	dehover_over_gui.emit();

func _process(delta: float) -> void:
	objects_flap_transition = move_toward(objects_flap_transition, float(objects_flap_open), delta * 5);
	object_selector.offset_right = ease(objects_flap_transition, -2) * -(object_selector_panel.offset_right - 1);
	if Input.is_action_just_pressed("editor_shortcut_save"):
		_on_pause_menu_save_pressed(null);

var mouse_entrance_token = null;
func populate_object_list(objects: Array[String]) -> void:
	selected_object_name.modulate = Color(1, 1, 1, 0.5);
	selected_object_name.text = "Select an object...";
	for obj_id in objects:
		assert(Global.object_list.has(obj_id), "Object not defined: " + obj_id);
		var obj: Global.ObjectDef = Global.object_list[obj_id];
		
		var button: Button = Button.new();
		button.pressed.connect(select_object.bind(obj_id));
		button.mouse_exited.connect(func():
			mouse_entrance_token = {renewed = false};
			var token = mouse_entrance_token;
			await get_tree().create_timer(0.25).timeout;
			if !token.renewed:
				selected_object_name.modulate = Color(1, 1, 1, 0.5);
				selected_object_name.text = "Select an object...";
		);
		button.mouse_entered.connect(func():
			if mouse_entrance_token:
				mouse_entrance_token.renewed = true;
			selected_object_name.modulate = Color.WHITE;
			selected_object_name.text = obj.name;
		);
		button.theme_type_variation = &"PaddinglessButton"
		button.icon = load(obj.icon_path);
		button.custom_minimum_size = Vector2(34, 34);
		button.text = "";
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER;
		object_list.add_child(button);

## Selects an object ID to place.
func select_object(obj_id: String) -> void:
	select_mode(LevelEditor.Mode.OBJECTS, LevelEditor.Tool.OBJECT_PLACE);
	select_tool(LevelEditor.Tool.OBJECT_PLACE);
	editor.place_object = obj_id;

## Selects a [enum LevelEditor.Tool].
func select_tool(t: LevelEditor.Tool) -> void:
	objects_flap_open = false;
	if t != LevelEditor.Tool.OBJECT_PLACE: objects_flap_transition = 0;
	
	editor.select_tool(t);
	
	polygon_actions.visible = editor.tool == LevelEditor.Tool.POLY_SELECT;
	vertex_actions.visible = editor.tool == LevelEditor.Tool.VERT_SELECT;
	
	for tool: LevelEditor.Tool in tool_buttons.keys():
		var button: Button = tool_buttons[tool];
		button.theme_type_variation = &"SelectedButton" if editor.tool == tool else &"Button";

## Selects a [enum LevelEditor.Mode] and a default [enum LevelEditor.Tool].
func select_mode(m: LevelEditor.Mode, t: LevelEditor.Tool) -> void:
	objects_flap_open = false;
	if t != LevelEditor.Tool.OBJECT_PLACE: objects_flap_transition = 0;
	
	editor.select_mode(m);
	select_tool(t);
	
	tools_visible(terrain_tools, LevelEditor.Mode.TERRAIN);
	tools_visible(object_tools, LevelEditor.Mode.OBJECTS);
	editor.container.objects.modulate.a = 1.0 if m == LevelEditor.Mode.OBJECTS else 0.5;
	editor.container.polygons.modulate.a = 1.0 if m == LevelEditor.Mode.TERRAIN else 0.5;
	
	for mode: LevelEditor.Mode in mode_buttons.keys():
		var button: Button = mode_buttons[mode];
		button.theme_type_variation = &"SelectedButton" if editor.mode == mode else &"Button";

## Helper function for [method select_mode].
func tools_visible(tools: Node, m: LevelEditor.Mode) -> void:
	if tools:
		tools.visible = editor.mode == m;

func selection_changed() -> void:
	var selected_polygons: Array = get_tree().get_nodes_in_group(&"selected_polygons");
	var has_selection: bool = editor.selected_verts.size() > 0 || selected_polygons.size() > 0;
	poly_layer_button.disabled = !has_selection;
	toggle_semisolid_button.disabled = !has_selection;
	line_edge_button.disabled = !has_selection;
	if has_selection:
		var poly_layer: String = "";
		for polygon: Polygon in selected_polygons:
			if poly_layer == "":
				poly_layer = polygon.layer;
			elif poly_layer != polygon.layer:
				poly_layer = "";
				break;
		match poly_layer:
			"a":
				poly_layer_button.icon = POLY_LAYER_A;
			"b":
				poly_layer_button.icon = POLY_LAYER_B;
			"ab":
				poly_layer_button.icon = POLY_LAYER_AB;

func objects_flap_pressed() -> void:
	objects_flap_open = !objects_flap_open;

func poly_layer_button_pressed() -> void:
	editor.poly_layer_button();
	selection_changed();

func semisolid_button_pressed() -> void:
	editor.semisolid_button();

func line_edge_button_pressed() -> void:
	editor.line_edge_button();

## Fired when hovering over any GUI element.
signal hover_over_gui;
## Fired when dehovering from any GUI element.
signal dehover_over_gui;


func _on_pause_menu_playtest_pressed(menu: PauseMenu) -> void:
	get_parent().get_parent().playtest();
	menu.active = false;

func _on_pause_menu_load_pressed(menu: PauseMenu) -> void:
	file_dialog.hide();
	last_pause_menu = menu;
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
	file_dialog.title = "Load Level";
	file_dialog.current_dir = LevelUtil.level_path.get_base_dir() if LevelUtil.level_path \
		else ProjectSettings.globalize_path(LevelUtil.FOLDER);
	file_dialog.current_file = LevelUtil.level_path.get_file() if LevelUtil.level_path \
		else "level.sgl";
	file_dialog.popup();

func _on_pause_menu_save_as_pressed(menu: PauseMenu) -> void:
	file_dialog.hide();
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE;
	file_dialog.title = "Save Level";
	file_dialog.current_dir = LevelUtil.level_path.get_base_dir() if LevelUtil.level_path \
		else ProjectSettings.globalize_path(LevelUtil.FOLDER);
	file_dialog.current_file = LevelUtil.level_path.get_file() if LevelUtil.level_path \
		else "level.sgl";
	if menu:
		menu.go_back();
	file_dialog.popup();

func _on_file_dialog_file_selected(path: String) -> void:
	if file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		if !last_pause_menu: return;
		last_pause_menu.active = false;
		EditorLib.load_level(true, path, false);
		LevelUtil.load_params.newly_loaded_level = true;
	elif file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		# Add file extension
		if !(path.to_lower().ends_with(".sgl")) && !FileAccess.file_exists(path):
			path += ".sgl";
		LevelUtil.load_params.level = editor.container.serialize();
		EditorLib.save_level(LevelUtil.load_params.level, path);
		save_sound.play();

func _on_pause_menu_save_pressed(menu: PauseMenu) -> void:
	if LevelUtil.level_path == "":
		_on_pause_menu_save_as_pressed(menu);
	else:
		LevelUtil.load_params.level = editor.container.serialize();
		EditorLib.save_level(LevelUtil.load_params.level, LevelUtil.level_path);
		save_sound.play();
		if menu:
			menu.go_back();

func _on_pause_menu_quit_pressed(_menu: PauseMenu) -> void:
	LevelUtil.load_params.level = editor.container.serialize();

func _on_menu_button_pressed() -> void:
	pause_menu.active = true;
