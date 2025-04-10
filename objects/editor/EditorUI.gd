## Handles the editor's UI. Controls a [LevelEditor].
extends Control
class_name EditorUI

## The [LevelEditor] to control.
@export var editor: LevelEditor;

@onready var terrain_tools = $TerrainTools;
@onready var poly_layer_button = %PolyLayerButton;
@onready var line_edge_button = %LineEdgeButton;

@onready var object_tools = $ObjectTools;
@onready var object_selector = $ObjectTools/ObjectSelector;
@onready var object_list = $ObjectTools/ObjectSelector/Selector/List;

var objects_flap_open: bool = false;
var objects_flap_transition: float = 0;

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
@onready var tool_buttons = {
	LevelEditor.Tool.POLY_SELECT: %PolySelectTool,
	LevelEditor.Tool.VERT_SELECT: %VertSelectTool,
	LevelEditor.Tool.LINE: %LineTool,
	LevelEditor.Tool.OBJECT_SELECT: %ObjectSelectTool,
};
## A map of [enum LevelEditor.Mode] to a [Button] that selects the mode.
@onready var mode_buttons = {
	LevelEditor.Mode.TERRAIN: %TerrainMode,
	LevelEditor.Mode.OBJECTS: %ObjectsMode,
};
## The default [enum LevelEditor.Tool]s for each [LevelEditor.Mode].
@onready var mode_default_tools = {
	LevelEditor.Mode.TERRAIN: LevelEditor.Tool.VERT_SELECT,
	LevelEditor.Mode.OBJECTS: LevelEditor.Tool.OBJECT_SELECT,
};

func _ready():
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

func do_gui_hover(node: Node):
	for child in node.get_children():
		if child is Control && child.mouse_filter == Control.MOUSE_FILTER_STOP:
			child.mouse_entered.connect(do_hover);
			child.mouse_exited.connect(do_dehover);
		do_gui_hover(child);

func do_hover():
	hover_over_gui.emit();
func do_dehover():
	dehover_over_gui.emit();

func _process(delta: float):
	objects_flap_transition = move_toward(objects_flap_transition, float(objects_flap_open), delta * 5);
	object_selector.offset_right = ease(objects_flap_transition, -2) * -196;

func populate_object_list(objects: Array[String]):
	for obj_id in objects:
		assert(Global.object_list.has(obj_id), "Object not defined: " + obj_id);
		var obj: Global.ObjectDef = Global.object_list[obj_id];
		
		var button: Button = Button.new();
		button.pressed.connect(select_object.bind(obj_id));
		button.text = obj.name;
		object_list.add_child(button);

## Selects an object ID to place.
func select_object(obj_id: String):
	select_mode(LevelEditor.Mode.OBJECTS, LevelEditor.Tool.OBJECT_PLACE);
	select_tool(LevelEditor.Tool.OBJECT_PLACE);
	editor.place_object = obj_id;

## Selects a [enum LevelEditor.Tool].
func select_tool(t: LevelEditor.Tool):
	objects_flap_open = false;
	if t != LevelEditor.Tool.OBJECT_PLACE: objects_flap_transition = 0;
	
	editor.select_tool(t);
	
	poly_layer_button.visible = editor.tool == LevelEditor.Tool.POLY_SELECT;
	line_edge_button.visible = editor.tool == LevelEditor.Tool.VERT_SELECT;
	
	for tool: LevelEditor.Tool in tool_buttons.keys():
		var button: Button = tool_buttons[tool];
		button.theme_type_variation = &"SelectedButton" if editor.tool == tool else &"Button";

## Selects a [enum LevelEditor.Mode] and a default [enum LevelEditor.Tool].
func select_mode(m: LevelEditor.Mode, t: LevelEditor.Tool):
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
func tools_visible(tools: Node, m: LevelEditor.Mode):
	if tools:
		tools.visible = editor.mode == m;

func selection_changed():
	var has_selection: bool = editor.selected_verts.size() > 0 || get_tree().get_nodes_in_group(&"selected_polygons").size() > 0;
	poly_layer_button.disabled = !has_selection;
	line_edge_button.disabled = !has_selection;

func objects_flap_pressed():
	objects_flap_open = !objects_flap_open;

func menu_pressed(id: int):
	match id:
		0: # Save Level
			Global.load_level = editor.container.serialize();
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
			Global.load_level = null;
			get_tree().reload_current_scene();
		3: # Exit
			Global.load_level = editor.container.serialize();
			get_tree().change_scene_to_file("res://scenes/TitleScreen/TitleScreen.tscn");

func poly_layer_button_pressed():
	editor.poly_layer_button();

func line_edge_button_pressed():
	editor.line_edge_button();

## Fired when hovering over any GUI element.
signal hover_over_gui
## Fired when dehovering from any GUI element.
signal dehover_over_gui
