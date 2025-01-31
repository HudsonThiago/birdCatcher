extends CanvasLayer

func _ready() -> void:
	pass 


func _process(_delta: float) -> void:
	pass


func _richtextlabel_on_meta_clicked(meta):
	OS.shell_open(str(meta))
