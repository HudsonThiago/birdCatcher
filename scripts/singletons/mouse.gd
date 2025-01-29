extends Node

var cursor = load("res://sprites/cursor.png")

func _ready() -> void:
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(16,16))
