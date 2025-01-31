extends CanvasLayer

@export var default_cursor: Texture2D = null
@export var crosshairs_cursor: Texture2D = null


var default_window_size: Vector2 = Vector2.ZERO
var default_cursor_size: Vector2 = Vector2.ZERO
var default_cursor_scale = 0.70


func _ready():
	if not default_cursor:
		print("ATTENTION: default_cursor not set!")
	if not crosshairs_cursor:
		print("ATTENTION: crosshairs_cursor not set!")
	var _window_width = ProjectSettings.get_setting("display/window/size/window_width_override")
	var _window_height = ProjectSettings.get_setting("display/window/size/window_height_override")
	default_window_size = Vector2(_window_width, _window_height)
	if default_cursor:
		default_cursor_size = Vector2(
				default_cursor.get_size().x * default_cursor_scale,
				default_cursor.get_size().y * default_cursor_scale,
		)
		_update_cursor()
	get_viewport().size_changed.connect(_update_cursor)


func _process(_delta):
	pass


func _update_cursor(_cursor = default_cursor):
	if (
			default_window_size.x > 0 and default_window_size.y > 0
			and default_cursor_size.x > 0 and default_cursor_size.y > 0
			and _cursor
	):
		var _current_window_size = DisplayServer.window_get_size()
		var _window_rescale_factor = min(
				(_current_window_size.x / default_window_size.x),
				(_current_window_size.y / default_window_size.y),
		)
		var _cursor_img = _cursor.get_image()
		_cursor_img.resize(
				roundi(default_cursor_size.x * _window_rescale_factor),
				roundi(default_cursor_size.y * _window_rescale_factor),
				Image.INTERPOLATE_NEAREST,
		)
		var _cursor_texture = ImageTexture.create_from_image(_cursor_img)
		var _cursor_img_center = Vector2(
				floor(_cursor_img.get_size().x * 0.5),
				floor(_cursor_img.get_size().y * 0.5),
		)
		Input.set_custom_mouse_cursor(
				_cursor_texture,
				Input.CURSOR_ARROW,
				_cursor_img_center,
		)


func set_crosshairs_cursor():
	if crosshairs_cursor:
		_update_cursor(crosshairs_cursor)


func set_default_cursor():
	_update_cursor()
