extends Control

@onready var timer_counter: Label = $timerContainer/VBoxContainer/timerCounter as Label
@onready var bullet_counter: Label = $container/bulletContainer/bulletCounter as Label
@onready var score_counter: Label = $container/scoreContainer/scoreCounter as Label

var minutes:int = 0
var seconds:int = 0
@export_range(0,10) var dMinutes := 2
@export_range(0,10) var dSeconds := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score_counter.text = str("%04d" % Global.score)
	bullet_counter.text = str(Global.bullets)+"x"
	timer_counter.text = str("%02d" % dMinutes) + ":" + str("%02d" % dSeconds)
	reset_clock_timer()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	if seconds == 0:
		if minutes > 0:
			minutes -= 1
			seconds = 60
	seconds -= 1
	timer_counter.text = str("%02d" % minutes) + ":" + str("%02d" % seconds)
	
func reset_clock_timer():	
	minutes = dMinutes
	seconds = dSeconds
