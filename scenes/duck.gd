extends CharacterBody2D
signal next_duck


@onready var animation_player = $AnimationPlayer
@onready var cursor_manager = $CursorManager
@onready var duck_drop_fall_player = $DuckDropFallPlayer
@onready var duck_drop_hit_player = $DuckDropHitPlayer
@onready var duck_quack_player = $DuckQuackPlayer
@onready var duck_scream_player = $DuckScreamPlayer
@onready var duck_sprite = $AnimatedSprite2D
@onready var quack_timer: Timer = $QuackTimer
@onready var wings_flap_player = $WingsFlapPlayer


var current_duck_type: String
var duck_death_animation_suffix = "_death"
var duck_fall_animation_suffix = "_fall"
var duck_fall_multiplier = 150
var duck_fly_animation_suffix = "_fly"
var duck_hit = false
var duck_hit_position = Vector2(0, 0)
var duck_initial_quack = true
var duck_random_quack = true
var duck_random_quack_min_sec = 2
var duck_random_quack_max_sec = 5
var duck_types = [
	"brown",
	"blue",
	"red",
]
var duck_points = {
	"brown": 100,
	"blue": 250,
	"red": 300,
}
var current_duck_points: int = 500
var speed: float = 100



func _ready():
	await _choose_random_duck_type(current_duck_type)
	_update_current_duck_type()
	current_duck_points = duck_points[current_duck_type]
	wings_flap_player.play()
	if duck_random_quack:
		_random_duck_quack()




func _physics_process(delta):

	var _collision = move_and_collide(velocity * delta)
	if _collision:
		velocity = velocity.bounce(_collision.get_normal())

	duck_sprite.flip_h = velocity.x < 0
	if duck_random_quack:
		_random_duck_quack()



func _on_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("left_click") and input_pickable:
		duck_hit = true
		input_pickable = false
		wings_flap_player.stop()
		quack_timer.stop()
		duck_quack_player.stop()
		duck_hit_position = Vector2(roundi(self.position.x), roundi(self.position.y))
		print("duck_hit_position: " + str(duck_hit_position))
		duck_scream_player.play()
		velocity = Vector2.ZERO
		animation_player.play(current_duck_type + duck_death_animation_suffix)
		await get_tree().create_timer(0.6).timeout
		duck_drop_fall_player.play()
		velocity = Vector2.DOWN * duck_fall_multiplier
		duck_sprite.play(current_duck_type + duck_fall_animation_suffix)
		await get_tree().create_timer(0.5).timeout



func _on_screen_exited():
	print(current_duck_type + " duck exited screen")
	next_duck.emit()

	queue_free()

func random_up_direction() -> Vector2:
	var _randf_deg = randf_range(0, 180)
	var _random_direction = Vector2(
			cos(deg_to_rad(_randf_deg)),
			sin(-1 * deg_to_rad(_randf_deg)),
	)
	return _random_direction.normalized()



func _choose_random_duck_type(_random_duck=""):
	if _random_duck.is_empty():
		_random_duck = duck_types[randi_range(0, duck_types.size()-1)]
	print("random duck: " + _random_duck)
	if duck_initial_quack:
		duck_quack_player.play()
	duck_sprite.play(_random_duck + duck_fly_animation_suffix)


func _update_current_duck_type():
	current_duck_type = duck_sprite.get_animation().split("_")[0]
	if current_duck_type not in duck_types:
		current_duck_type = duck_types[0]
	


func _random_duck_quack():
	if quack_timer.is_stopped():
		var _current_wait = quack_timer.wait_time
		while quack_timer.wait_time == _current_wait:
			quack_timer.wait_time = randi_range(
					duck_random_quack_min_sec,
					duck_random_quack_max_sec,
			)
		quack_timer.one_shot = true
		quack_timer.start()




func _on_mouse_entered() -> void:

	if input_pickable:
		cursor_manager.set_crosshairs_cursor()



func _on_mouse_exited() -> void:

	cursor_manager.set_default_cursor()


func _on_quack_timer_timeout() -> void:
	duck_quack_player.play()
