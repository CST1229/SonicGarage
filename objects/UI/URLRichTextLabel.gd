extends RichTextLabel

func _ready():
	meta_clicked.connect(on_meta_clicked);

func on_meta_clicked(meta):
	OS.shell_open(str(meta))
