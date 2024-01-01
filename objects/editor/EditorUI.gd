extends Control

@export var editor: LevelEditor;

@onready var terrain_tools = $TerrainTools;
@onready var poly_layer_button = $TerrainTools/PolyLayerButton;
@onready var line_edge_button = $TerrainTools/LineEdgeButton;

@onready var object_tools = $ObjectTools;
@onready var object_selector = $ObjectTools/ObjectSelector;
@onready var object_list = $ObjectTools/ObjectSelector/Selector/List;

var objects_flap_open: bool = false;
var objects_flap_transition: float = 0;

var listed_objects: Array[String] = [
	"ring",
	"layer_switcher",
	"signpost",
	"motobug",
	"monitor",
];

func _ready():
	select_mode(LevelEditor.Mode.TERRAIN, LevelEditor.Tool.VERT_SELECT);
	populate_object_list(listed_objects);
	do_gui_hover(self);

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
	object_selector.offset_left = ease(objects_flap_transition, -2) * -196;

func populate_object_list(objects: Array[String]):
	for obj_id in objects:
		assert(Global.object_list.has(obj_id), "Object not defined: " + obj_id);
		var obj: Global.ObjectDef = Global.object_list[obj_id];
		
		var button: Button = Button.new();
		button.pressed.connect(select_object.bind(obj_id));
		button.text = obj.name;
		object_list.add_child(button);

func select_object(obj_id: String):
	select_mode(LevelEditor.Mode.OBJECTS, LevelEditor.Tool.OBJECT_PLACE);
	select_tool(LevelEditor.Tool.OBJECT_PLACE);
	editor.place_object = obj_id;

# mode switching
func select_tool(t: LevelEditor.Tool):
	objects_flap_open = false;
	if t != LevelEditor.Tool.OBJECT_PLACE: objects_flap_transition = 0;
	
	editor.select_tool(t);
	
	poly_layer_button.visible = editor.tool == LevelEditor.Tool.POLY_SELECT;
	line_edge_button.visible = editor.tool == LevelEditor.Tool.VERT_SELECT;

func select_mode(m: LevelEditor.Mode, t: LevelEditor.Tool):
	objects_flap_open = false;
	if t != LevelEditor.Tool.OBJECT_PLACE: objects_flap_transition = 0;
	
	editor.select_mode(m);
	editor.select_tool(t);
	
	tools_visible(terrain_tools, LevelEditor.Mode.TERRAIN);
	tools_visible(object_tools, LevelEditor.Mode.OBJECTS);
func tools_visible(tools: Node, m: LevelEditor.Mode):
	if tools:
		tools.visible = editor.mode == m;

# buttons

func poly_select_tool_pressed():
	select_tool(LevelEditor.Tool.POLY_SELECT);
func select_tool_pressed():
	select_tool(LevelEditor.Tool.VERT_SELECT);
func line_tool_pressed():
	select_tool(LevelEditor.Tool.LINE);
func object_select_tool_pressed():
	select_tool(LevelEditor.Tool.OBJECT_SELECT);
func terrain_mode_pressed():
	select_mode(LevelEditor.Mode.TERRAIN, LevelEditor.Tool.VERT_SELECT);
func objects_mode_pressed():
	select_mode(LevelEditor.Mode.OBJECTS, LevelEditor.Tool.OBJECT_SELECT);

func objects_flap_pressed():
	objects_flap_open = !objects_flap_open;

func menu_pressed(id: int):
	match id:
		0: # Save Level
			Global.load_level = editor.container.serialize();
			DisplayServer.file_dialog_show(
				"Save Level", "",
				"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
				PackedStringArray(["*.sgl"]),
				EditorLib.save_level
			);
		1: # Load Level
			DisplayServer.file_dialog_show(
				"Load Level", "",
				"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
				PackedStringArray(["*.sgl", "*"]),
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

signal hover_over_gui
signal dehover_over_gui
