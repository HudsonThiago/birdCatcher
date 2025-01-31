extends CharacterBody2D

@onready var dog_sprite = $AnimatedSprite2D


var speed: float = 30.0


func _ready():
	dog_sprite.play()
	input_pickable = false
	velocity = Vector2(1, 0) * speed


func _physics_process(delta):
	var _dog_collision = move_and_collide(velocity * delta)
	if _dog_collision:
		velocity = velocity.bounce(_dog_collision.get_normal())
	var is_left = velocity.x < 0
	dog_sprite.flip_h = is_left
