## Handles the editor's UI. Controls a [LevelEditor].
extends Control
class_name EditorUI

## The [LevelEditor] to control.
@export var editor: LevelEditor;

@onready var terrain_tools: Control = $TerrainTools;
@onready var poly_layer_button: Button = %PolyLayerButton;
@onready var line_edge_button: Button = %LineEdgeButton;

@onready var object_tools: Control = $ObjectTools;
@onready var object_selector: Control = $ObjectTools/ObjectSelector;
@onready var object_list: FlowContainer = $ObjectTools/ObjectSelector/Selector/List;

var objects_flap_open := false;
var objects_flap_transition := 0.0;

## A list of object IDs to use in the object selector.
var listed_objects: Array[String] = [
	"ring",
	"layer_switcher",
	"signpost",
	"motobug",
	"monitor",
	"spike",
	"spring",
];

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
	object_selector.offset_right = ease(objects_flap_transition, -2) * -196;

func populate_object_list(objects: Array[String]) -> void:
	for obj_id in objects:
		assert(Global.object_list.has(obj_id), "Object not defined: " + obj_id);
		var obj: Global.ObjectDef = Global.object_list[obj_id];
		
		var button: Button = Button.new();
		button.pressed.connect(select_object.bind(obj_id));
		button.text = obj.name;
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
	
	poly_layer_button.visible = editor.tool == LevelEditor.Tool.POLY_SELECT;
	line_edge_button.visible = editor.tool == LevelEditor.Tool.VERT_SELECT;
	
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

func menu_pressed(id: int) -> void:
	match id:
		0: # Save Level
			LevelUtil.load_level = editor.container.serialize();
			DisplayServer.file_dialog_show(
				"Save Level", "",
				"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
				PackedStringArray(["*.sgl;Sonic Garage Levels (*.sgl)", "*;All Files (*.*)"]),
				EditorLib.save_level
			);
		1: # Load Level
			DisplayServer.file_dialog_show(
				"Load Level", "",
				"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
				PackedStringArray(["*.sgl;Sonic Garage Levels (*.sgl)", "*;All Files (*.*)"]),
				EditorLib.load_level_editor
			);
		2: # Clear Level
			LevelUtil.load_level = null;
			Fades.reload_current_scene();
		3: # Exit
			LevelUtil.load_level = editor.container.serialize();
			Fades.fade_to_scene("res://scenes/TitleScreen/TitleScreen.tscn");

func poly_layer_button_pressed() -> void:
	editor.poly_layer_button();
	selection_changed();

func line_edge_button_pressed() -> void:
	editor.line_edge_button();

## Fired when hovering over any GUI element.
signal hover_over_gui;
## Fired when dehovering from any GUI element.
signal dehover_over_gui;
