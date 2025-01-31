extends CharacterBody2D
@export var speed: float = 10.0
@export var right_to_left: bool = true
@export var cloud_variant: cloud_variants


enum cloud_variants {
	Original,
	AlternativeCloud_1,
	AlternativeCloud_2,
	AlternativeCloud_3,
}
var start_position: Vector2


func _ready():
	_disable_cloud_variants()
	var _node_name = cloud_variants.keys()[cloud_variant]
	if self.get_node(_node_name):
		self.get_node(_node_name).show()
	start_position = self.position
	input_pickable = false
	if right_to_left:
		velocity = Vector2.LEFT * speed
	else:
		velocity = Vector2.RIGHT * speed


func _physics_process(_delta):
	move_and_slide()


func _on_screen_exited() -> void:
	self.position = start_position


func _disable_cloud_variants():
	for _cloud_var in cloud_variants.keys():
		if self.get_node(_cloud_var):
			self.get_node(_cloud_var).hide()
