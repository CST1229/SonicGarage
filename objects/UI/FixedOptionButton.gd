## OptionButton but without the radio buttons in the menu.
extends OptionButton

func _ready():
	make_option_button_items_non_radio_checkable(self);

# https://www.reddit.com/r/godot/comments/oz45zd/comment/h7x8iav/
func make_option_button_items_non_radio_checkable(option_button: OptionButton) -> void:
	var pm: PopupMenu = option_button.get_popup()
	for i in pm.get_item_count():
		if pm.is_item_radio_checkable(i):
			pm.set_item_as_radio_checkable(i, false)
