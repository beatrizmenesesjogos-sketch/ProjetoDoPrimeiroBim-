extends CharacterBody2D

@export var speed: float = 80.0
@export var follow_distance: float = 250.0
@export var gravity: float = 900.0

var player: Node2D = null
var dead: bool = false
var already_triggered: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var head_hitbox: Area2D = $HeadHitbox

func _ready() -> void:
	anim.play("walk")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	head_hitbox.body_entered.connect(_on_head_hitbox_body_entered)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if player != null:
		var dx = player.global_position.x - global_position.x

		if abs(dx) <= follow_distance:
			velocity.x = sign(dx) * speed
			anim.flip_h = dx < 0
		else:
			velocity.x = 0.0
	else:
		velocity.x = 0.0

	move_and_slide()

func _on_hitbox_body_entered(body: Node) -> void:
	if dead or already_triggered:
		return

	if body == self:
		return

	print("Hitbox tocou em:", body.name)

	if body.is_in_group("player"):
		already_triggered = true
		if body.has_method("die"):
			body.die()

func _on_head_hitbox_body_entered(body: Node) -> void:
	if dead or already_triggered:
		return

	if body == self:
		return

	print("Cabeça tocou em:", body.name)

	if body.is_in_group("player"):
		if body is CharacterBody2D:
			if body.velocity.y > 0 and body.global_position.y < global_position.y - 8:
				already_triggered = true
				if body.has_method("bounce"):
					body.bounce()
				die()

func die() -> void:
	if dead:
		return

	dead = true
	hitbox.monitoring = false
	head_hitbox.monitoring = false
	$CollisionShape2D.disabled = true

	if anim.sprite_frames.has_animation("dead"):
		anim.play("dead")
		await anim.animation_finished

	queue_free()
