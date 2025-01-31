extends Node2D

signal highscore_screen_continued
signal intro_screen_continued

@onready var bell_player = $AudioPlayers/BellPlayer
@onready var bg_atmosphere_player = $AudioPlayers/BgAtmospherePlayer
@onready var bg_music_player = $AudioPlayers/BgMusicPLayer
@onready var bullets_debug_label = $InfoElements/BulletsDebugLabel
@onready var bullets_info = $InfoElements/BulletsInfo
@onready var bullets_sprite = $InfoElements/BulletsInfo/Bullets
@onready var foreground = $Foreground
@onready var dog_node = $Dog
@onready var duck_points_label = $InfoElements/DuckPointsLabel
@onready var duck_quack_player = $AudioPlayers/DuckQuackPlayer
@onready var ducks_shot_sprite = $InfoElements/HitsInfo/DucksShot
@onready var ducks_unshot_sprite = $InfoElements/HitsInfo/DucksUnshot
@onready var game_over_player = $AudioPlayers/GameOverPlayer
@onready var game_over_sign = $InfoElements/GameOverSign
@onready var game_over_timer = $GameOverTimer
@onready var ground_dog_walk = $GroundDogWalk
@onready var hits_info = $InfoElements/HitsInfo
@onready var info_elements = $InfoElements
@onready var intro_screen = $IntroScreen
@onready var intro_screen_timer = $IntroScreenTimer
@onready var round_complete_sign = $InfoElements/RoundCompleteSign
@onready var round_info = $InfoElements/RoundInfo
@onready var round_start_sign = $InfoElements/RoundStartSign
@onready var round_label = $InfoElements/RoundInfo/RoundLabel
@onready var score_info = $InfoElements/ScoreInfo
@onready var score_label = $InfoElements/ScoreInfo/ScoreLabel
@onready var shotgun_empty_player = $AudioPlayers/ShotgunEmptyPlayer
@onready var shotgun_reload_player = $AudioPlayers/ShotgunReloadPlayer
@onready var shotgun_shot_player = $AudioPlayers/ShotgunShotPlayer
@onready var success_player = $AudioPlayers/SuccessPlayer
@onready var time_elapsed_label = $InfoElements/TimeElapsedLabel
@onready var top_edge_grass = $TopEdgeGrass
@onready var version_label = $VersionLabel


@export var duck_node: PackedScene
@export var highscore_node: PackedScene
var duck
var highscore_screen


var bonus_pts_per_round_multiplier = 1000
var bullets_debug_label_show = false
var bullets_width = 8
var debug_round_mode = false
var dog_start_position = Vector2(29, 164)
var duck_pts_round_multiplier = 0.75
var duck_speed_round_multiplier = 5
var ducks_shot_width = 16
var ducks_shot_sprite_default_width = 1
var ducks_to_shoot_per_round = 10
var game_over_timeout_sec_min = 4
var intro_min_delay_sec = 7
var max_bullets = 3
var max_score = 9999999
var play_dog_intro = true
var play_round_complete_animation = true
var present_hit_duck = true
var round_compl_anim_blink_cnt = 4
var round_compl_anim_blink_delay = 0.25
var round_complete_msg_delay_after = 0.5
var round_complete_msg_prefix = "GREAT!\n"
var round_label_prefix = "R "
var round_start_msg_delay = 1.0
var round_start_msg_prefix = "Round\n"
var score_seperator = ","
var show_duck_points = true
var show_duck_points_delay = 0.35
var show_intro_screen = true
var max_bonus_multiplier = 10


var duck_types_shuffle_bag = []


var browser_game = OS.has_feature("web")
var ignore_shots = false
var ducks_shot = 0

var bullets_current = max_bullets:
	set(value):
		if value >= 0:
			bullets_current = value
			bullets_debug_label.text = str(value)

var round_current = 1:
	set(value):
		round_current = value
		round_label.text = round_label_prefix + str(value)

var score_current = 0:
	set(value):
		if value > max_score:
			value = max_score
		score_current = value
		score_label.text = format_score(str(value))

var _bonus_multiplier_counter = 0
var bonus_multiplier_counter = 0:
	set(value):
		_bonus_multiplier_counter = clamp(value, 0, max_bonus_multiplier)
		_update_bonus_display()
	get:
		return _bonus_multiplier_counter

var time_elapsed = 0
var time_elapsed_min = 0
var time_elapsed_sec = 0
var time_elapsed_string = str("00:00")
var time_now = 0
var time_start = 0

var difficulty_multiplier = 1.0
var difficulty_increase_interval = 10  # Aumenta dificuldade a cada 10 segundos
var last_difficulty_increase = 0
var combo_counter = 0
var combo_timer = 0
var combo_time_window = 1.5  # Janela de tempo para combos em segundos

var bonus_multiplier = 0

var ducks_per_bonus = 5
var bonus_segment_width = 40 

var quick_debug_mode = false


func _ready():
	ignore_shots = true
	randomize()
	_init_labels()
	bg_music_player.play()
	
	if quick_debug_mode:
		print("\nATTENTION: Quick debug mode enabled!\n")
		bullets_debug_label_show = true
		debug_round_mode = true
		play_dog_intro = false
		present_hit_duck = false
		show_intro_screen = false
	
	if show_intro_screen:
		await _show_intro_screen()
	
	print("\nStarting new game...")
	time_start = Time.get_unix_time_from_system()
	print("Started game at " + str(Time.get_datetime_string_from_unix_time(time_start)))
	
	_reset_ducks_shot()
	_reload_shotgun()
	bg_atmosphere_player.play()
	
	if play_dog_intro:
		await _dog_jump_into_grass()
	
	await get_tree().create_timer(1).timeout
	await _spawn_duck()
	ignore_shots = false


func _update_bonus_display():
	var _ducks_shot_region = ducks_shot_sprite.get_region_rect()
	_ducks_shot_region = Rect2(
		_ducks_shot_region.position,
		Vector2(
			ducks_shot_sprite_default_width + (bonus_multiplier_counter * ducks_shot_width),
			_ducks_shot_region.size.y,
		)
	)
	ducks_shot_sprite.set_region_rect(_ducks_shot_region)
	ducks_shot_sprite.show()

func _process(_delta):
	if time_start > 0:
		time_now = Time.get_unix_time_from_system()
		time_elapsed = time_now - time_start
		time_elapsed_min = int(time_elapsed / 60)
		time_elapsed_sec = int(time_elapsed) % 60
		time_elapsed_string = str("%02d:%02d") % [time_elapsed_min, time_elapsed_sec]
		time_elapsed_label.text = time_elapsed_string
		
		# Aumentar dificuldade com o tempo
		if int(time_elapsed) > last_difficulty_increase + difficulty_increase_interval:
			increase_difficulty(0.2)
			last_difficulty_increase = int(time_elapsed)
		
		# Atualizar combo
		if combo_timer > 0:
			combo_timer -= _delta
		else:
			combo_counter = 0

func increase_difficulty(amount):
	difficulty_multiplier += amount
	print("Dificuldade aumentada: ", difficulty_multiplier)

func _spawn_duck():
	top_edge_grass.get_node("CollisionShape2D").set_disabled(true)
	duck = duck_node.instantiate()
	duck.input_pickable = false
	duck.velocity = Vector2.ZERO
	
	# Aplicar dificuldade
	duck.speed *= difficulty_multiplier
	duck.current_duck_points = int(duck.current_duck_points * difficulty_multiplier)
	
	duck.next_duck.connect(_on_next_duck)
	duck.hide()

	if duck_types_shuffle_bag.is_empty():
		duck_types_shuffle_bag = duck.duck_types.duplicate()
		duck_types_shuffle_bag.shuffle()
	
	var _random_duck = duck_types_shuffle_bag.pop_back()
	duck.current_duck_type = _random_duck
	duck.get_node("AnimatedSprite2D").play(_random_duck + duck.duck_fly_animation_suffix)
	
	var _viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var _duck_width = ceil(duck.get_node("CollisionShape2D").get_shape().get_rect().size.x)
	var _duck_height = ceil(duck.get_node("CollisionShape2D").get_shape().get_rect().size.y)
	var _duck_hidden_in_grass_y = floor(
			top_edge_grass.get_node("CollisionShape2D").position.y
			+ ceil(
					top_edge_grass.get_node("CollisionShape2D").get_shape().
					get_rect().size.y * 0.5
			)
	)
	
	var _new_x = randi_range(
			0 + (_duck_width * 0.5),
			_viewport_width - (_duck_width * 0.5),
	)
	var _new_y = _duck_hidden_in_grass_y
	var _new_position = Vector2(_new_x, _new_y)
	duck.position = _new_position
	
	get_tree().current_scene.add_child(duck)
	duck.show()
	duck.velocity = duck.random_up_direction() * duck.speed
	duck.input_pickable = true
	top_edge_grass.get_node("CollisionShape2D").set_disabled(false)

func _on_next_duck():
	var _duck_hit_position = duck.duck_hit_position
	var _duck_type = duck.current_duck_type
	
	if game_over_timer.is_stopped() and not intro_screen.visible:
		ignore_shots = true
		_increase_ducks_shot()
		
		# Cálculo de pontos com multiplicador atual
		var earned_points = duck.current_duck_points * bonus_multiplier_counter
		score_current += earned_points
		
		if show_duck_points:
			await _show_duck_points(_duck_hit_position, earned_points)
		
		if present_hit_duck:
			await _dog_present_duck(_duck_hit_position, _duck_type)
		await _reload_shotgun()
		
		await get_tree().create_timer(0.8).timeout
		await _spawn_duck()
		ignore_shots = false
	elif intro_screen.visible:
		if _duck_hit_position != Vector2.ZERO and intro_screen.get_node("ContinueLabel"):
			intro_screen.get_node("AnimationPlayer").stop()
			intro_screen.get_node("ContinueLabel").hide()
			if duck.get_node("CursorManager"):
				duck.get_node("CursorManager").set_default_cursor()
		await get_tree().create_timer(0.5).timeout
		intro_screen_continued.emit()

func _show_highscore_screen():
	var _online_str = " local " if browser_game else " online "
	print("Showing" + _online_str + "highscore screen")
	ignore_shots = true
	if duck:
		duck.queue_free()
	
	highscore_screen = highscore_node.instantiate()
	get_tree().current_scene.add_child(highscore_screen)
	highscore_screen.highscore_continued.connect(_on_highscore_continued)
	info_elements.hide()
	bg_music_player.stop()

	if quick_debug_mode:
		score_current += 1234567

	await highscore_screen.init_highscore()
	await highscore_screen.check_if_new_highscore(score_current)
	if highscore_screen.continue_button:
		highscore_screen.continue_button.show()
		await highscore_screen_continued

func _init_labels():
	game_over_sign.hide()
	round_complete_sign.hide()
	round_start_sign.hide()
	duck_points_label.hide()
	version_label.hide()
	bullets_debug_label.visible = bullets_debug_label_show
	bullets_debug_label.text = str(bullets_current)
	score_label.text = str(score_current)
	time_elapsed_label.text = time_elapsed_string
	version_label.z_index=999
	version_label.text = str(
			"v" + ProjectSettings.get_setting("application/config/version")
	)
	print("Version info: " + version_label.text)


func _update_bonus():
	var new_multiplier = floor(ducks_shot / ducks_per_bonus)
	bonus_multiplier = min(new_multiplier, max_bonus_multiplier)
	
	var _ducks_shot_region = ducks_shot_sprite.get_region_rect()
	_ducks_shot_region = Rect2(
		_ducks_shot_region.position,
		Vector2(
			ducks_shot_sprite_default_width + (bonus_multiplier * bonus_segment_width),
			_ducks_shot_region.size.y,
		)
	)
	ducks_shot_sprite.set_region_rect(_ducks_shot_region)
	
func _increase_ducks_shot():
	bonus_multiplier_counter += 1
	print("Multiplicador de Bônus: ", bonus_multiplier_counter)
	_update_bonus_display()
	await get_tree().create_timer(0.5).timeout


func _show_intro_screen():
	print("Showing intro screen")
	ignore_shots = true
	info_elements.hide()
	version_label.show()
	intro_screen.show()
	
	var _continue_label = intro_screen.get_node("ContinueLabel")
	_continue_label.hide()
	bg_atmosphere_player.stop()
	intro_screen_timer.start()
	await intro_screen_timer.timeout
	await _spawn_intro_screen_duck()
	_continue_label.show()
	_continue_label.position = Vector2(
			duck.position.x - _continue_label.size.x - 25,
			duck.position.y - (_continue_label.size.y * 0.5),
	)
	var _anim_player = intro_screen.get_node("AnimationPlayer")
	_anim_player.get_animation("blink_continue_text").set_loop_mode(true)
	_anim_player.play("blink_continue_text")
	await intro_screen_continued
	_anim_player.stop()
	_continue_label.hide()
	await _exit_intro_screen()



func _spawn_intro_screen_duck():
	duck = duck_node.instantiate()
	duck.show()
	duck.velocity = Vector2.ZERO
	var _viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var _viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var _duck_width = ceil(duck.get_node("CollisionShape2D").get_shape().get_rect().size.x)
	var _duck_height = ceil(duck.get_node("CollisionShape2D").get_shape().get_rect().size.y)
	var _btn_x = _viewport_width - (_duck_width * 0.5) - 10
	var _btn_y = _viewport_height - (_duck_height * 0.5) - 10
	duck.position = Vector2(_btn_x, _btn_y)
	intro_screen.add_child(duck)
	duck.wings_flap_player.stop()
	duck.duck_random_quack = false
	duck.input_pickable = true
	duck.next_duck.connect(_on_next_duck)


func _exit_intro_screen():
	intro_screen.hide()
	info_elements.show()
	version_label.hide()
	print("Leaving intro screen...")


func _on_highscore_continued():
	highscore_screen.hide()
	highscore_screen.queue_free()
	highscore_screen_continued.emit()
	print("Leaving highscore screen")


func _on_intro_screen_timeout() -> void:
	print(
			"Intro screen timer ran for " +
			str(intro_screen_timer.get_wait_time())
			+ " seconds"
	)



func _dog_jump_into_grass():
	if dog_node.z_index < foreground.z_index:
		dog_node.z_index = foreground.z_index + 1
	dog_node.show()
	dog_node.get_node("AnimatedSprite2D").play("sniff")
	await get_tree().create_timer(2).timeout
	duck_quack_player.play()
	await get_tree().create_timer(0.3).timeout
	dog_node.get_node("AnimatedSprite2D").play("attention")
	dog_node.velocity = Vector2.ZERO
	await get_tree().create_timer(1).timeout
	dog_node.get_node("AnimationPlayer").play("jump_in_grass")
	dog_node.get_node("CollisionShape2D").set_disabled(true)
	await get_tree().create_timer(0.1).timeout
	dog_node.get_node("DogBarkPlayer").play()
	await get_tree().create_timer(0.9).timeout
	dog_node.z_index = foreground.z_index - 1
	await get_tree().create_timer(0.55).timeout
	dog_node.hide()
	dog_node.get_node("AnimationPlayer").play("RESET")
	await get_tree().create_timer(1.5).timeout
	dog_node.get_node("CollisionShape2D").set_disabled(false)


func _dog_laugh():
	dog_node.hide()
	dog_node.velocity = Vector2.ZERO
	dog_node.get_node("AnimatedSprite2D").play("laugh")
	dog_node.get_node("CollisionShape2D").set_disabled(true)
	if dog_node.z_index >= foreground.z_index - 1:
		dog_node.z_index = foreground.z_index - 1
	var _viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var _frame_count = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().get_frame_count("laugh")
	)
	var _last_frame = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().get_frame_texture("laugh", _frame_count-1)
	)
	var _dog_width = _last_frame.get_width()
	var _dog_height = _last_frame.get_height()
	var _dog_hidden_in_grass_y = foreground.region_rect.size.y + (_dog_height * 1.6)
	var _dog_hide_y_offset = _dog_height * 1.33
	var _new_x = roundi(_viewport_width * 0.5)
	var _new_y = roundi(_dog_hidden_in_grass_y)
	var _new_position = Vector2(_new_x, _new_y)
	dog_node.position = _new_position
	dog_node.get_node("DogLaughPlayer").play()
	dog_node.show()
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2(0, -1 * _dog_hide_y_offset)
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2.ZERO
	await get_tree().create_timer(2).timeout
	dog_node.velocity = Vector2(0, _dog_hide_y_offset)
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2.ZERO
	dog_node.hide()
	dog_node.get_node("CollisionShape2D").set_disabled(false)
	await get_tree().create_timer(0.5).timeout


func _dog_present_duck(_duck_hit_position, _duck_type):
	dog_node.hide()
	dog_node.velocity = Vector2.ZERO
	var _has_anim = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().
			has_animation("present_duck_" + _duck_type)
	)
	var _anim_name = "present_duck"
	if _has_anim:
		_anim_name = "present_duck_" + _duck_type
	if not _duck_type.is_empty() and _has_anim:
		dog_node.get_node("AnimatedSprite2D").play(_anim_name)
	dog_node.get_node("CollisionShape2D").set_disabled(true)
	if dog_node.z_index >= foreground.z_index - 1:
		dog_node.z_index = foreground.z_index - 1
	var _frame_count = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().get_frame_count("present_duck")
	)
	var _last_frame = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().get_frame_texture("present_duck", _frame_count-1)
	)
	var _dog_width = _last_frame.get_width()
	var _dog_height = _last_frame.get_height()
	var _dog_hidden_in_grass_y = foreground.region_rect.size.y + (_dog_height * 1.6)
	var _dog_hide_y_offset = _dog_height * 1.33
	var _new_x = roundi(_duck_hit_position.x)
	var _new_y = roundi(_dog_hidden_in_grass_y)
	var _new_position = Vector2(_new_x, _new_y)
	dog_node.position = _new_position
	dog_node.show()
	dog_node.velocity = Vector2(0, -1 * _dog_hide_y_offset)
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2.ZERO
	dog_node.get_node("DogBarkPlayer").play()
	await get_tree().create_timer(0.2).timeout
	dog_node.velocity = Vector2(0, _dog_hide_y_offset)
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2.ZERO
	dog_node.hide()
	dog_node.get_node("CollisionShape2D").set_disabled(false)
	await get_tree().create_timer(0.5).timeout





func _show_duck_points(_duck_hit_position, points):
	bell_player.play()
	duck_points_label.text = str(points) 
	duck_points_label.position = Vector2(
			roundi(_duck_hit_position.x - (duck_points_label.size.x/2)),
			roundi(_duck_hit_position.y - (duck_points_label.size.y * 0.75)),
	)
	duck_points_label.z_index = 999
	duck_points_label.show()
	await get_tree().create_timer(show_duck_points_delay).timeout
	duck_points_label.hide()



func _input(event):
	if event.is_action_pressed("left_click"):
		if bullets_current >= 1 and not ignore_shots:
			shotgun_shot_player.play()
			_set_bullets(bullets_current - 1)

			await get_tree().create_timer(0.01).timeout
			var _duck_hit = false
			if get_node_or_null(NodePath("Duck")):
				_duck_hit = duck.duck_hit
			else:
				_duck_hit = true

			if not _duck_hit:  # Resetar multiplicador ao errar
				bonus_multiplier_counter = 0
				_update_bonus_display()
				print("Tiro errado - Multiplicador resetado!")

			if (
					bullets_current == 0
					and game_over_timer.is_stopped()
					and not _duck_hit
			):
				duck.input_pickable = false
				ignore_shots = true
				print("Last bullet shot without hit!")
				_game_over()

		elif (
				intro_screen.visible
				and not info_elements.visible
				and intro_screen_timer.is_stopped()
		):
			shotgun_shot_player.play()

		else:
			shotgun_empty_player.play()
			await get_tree().create_timer(0.01).timeout


func _game_over():
	print("\nGAME OVER!")
	_dog_laugh()
	game_over_sign.show()
	game_over_player.play()
	if game_over_timer.is_stopped():
		print("wait_time from main scene: " + str (game_over_timer.wait_time))
		if game_over_timer.wait_time < game_over_timeout_sec_min:
			game_over_timer.wait_time = game_over_timeout_sec_min
			print("wait_time set to minimum: " + str (game_over_timer.wait_time))
		game_over_timer.start()


func _on_game_over_timeout():
	dog_node.get_node("DogLaughPlayer").stop()
	game_over_sign.hide()
	await _show_highscore_screen()
	print("Restarting game...\n")
	get_tree().reload_current_scene()


func _reset_ducks_shot():
	bonus_multiplier_counter = 0
	var _ducks_shot_region = ducks_shot_sprite.get_region_rect()
	_ducks_shot_region = Rect2(
		_ducks_shot_region.position,
		Vector2(
			1,
			_ducks_shot_region.size.y,
		)
	)
	ducks_shot_sprite.set_region_rect(_ducks_shot_region)



func _set_bullets(bullets_new):
	bullets_current = bullets_new
	print("bullets_current: " + str(bullets_current))
	var _bullets_region = bullets_sprite.get_region_rect()
	_bullets_region = Rect2(
		_bullets_region.position,
		Vector2(
			bullets_current * bullets_width,
			_bullets_region.size.y,
		)
	)
	bullets_sprite.set_region_rect(_bullets_region)


func _reload_shotgun():
	print("shotgun reload")
	_set_bullets(max_bullets)
	shotgun_reload_player.play()


func format_score(_score: String) -> String:
	var _i = _score.length() - 3
	while _i > 0:
		_score = _score.insert(_i, score_seperator)
		_i = _i - 3
	return _score
