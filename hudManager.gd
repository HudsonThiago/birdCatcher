extends Control

@onready var timer_counter: Label = $timerContainer/VBoxContainer/timerCounter as Label
@onready var bullet_counter: Label = $container/bulletContainer/bulletCounter as Label
@onready var score_counter: Label = $container/scoreContainer/scoreCounter as Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score_counter.text = str("%04d" % Global.score)
	bullet_counter.text = str(Global.bullets)+"x"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
