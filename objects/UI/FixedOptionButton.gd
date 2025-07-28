## OptionButton but with nearest filtering and without the radio buttons in the menu.
extends OptionButton

@export var no_radio_buttons: bool = false;

func _ready():
	if no_radio_buttons:
		make_option_button_items_non_radio_checkable(self);
	get_popup().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST;

# https://www.reddit.com/r/godot/comments/oz45zd/comment/h7x8iav/
func make_option_button_items_non_radio_checkable(option_button: OptionButton) -> void:
	var pm: PopupMenu = option_button.get_popup()
	for i in pm.get_item_count():
		if pm.is_item_radio_checkable(i):
			pm.set_item_as_radio_checkable(i, false)
