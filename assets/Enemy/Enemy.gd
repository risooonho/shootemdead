extends Node2D

class_name Enemy


####################################################################################
# Signals

# Triggered when the enemy leaves the scene, either because it survived or was
# killed. We don't split this into different events because this allows connecting
# to this event using a one-shot connection that is disconnected as soon as this
# event is triggered.
signal enemy_left(enemy, survived)


####################################################################################
# Scene Objects and Resources

onready var _texture_rect: TextureRect = $Visuals/TextureRect
onready var _animation_player: AnimationPlayer = $AnimationPlayer
onready var _blood_splatter: Particles2D = $BloodSplatter
onready var _visibiliy_notifier: VisibilityNotifier2D = $VisibilityNotifier2D

# Resources we'll use
var sounds_scream = [
	preload("res://assets/Sounds/scream_01.ogg"),
	preload("res://assets/Sounds/scream_02.ogg"),
	preload("res://assets/Sounds/scream_03.ogg"),
	preload("res://assets/Sounds/scream_04.ogg"),
	preload("res://assets/Sounds/scream_05.ogg"),
	preload("res://assets/Sounds/scream_06.ogg"),
	preload("res://assets/Sounds/scream_07.ogg"),
	preload("res://assets/Sounds/scream_08.ogg"),
	preload("res://assets/Sounds/scream_09.ogg"),
	preload("res://assets/Sounds/scream_10.ogg"),
	preload("res://assets/Sounds/scream_11.ogg"),
	preload("res://assets/Sounds/scream_12.ogg"),
	preload("res://assets/Sounds/scream_13.ogg"),
	preload("res://assets/Sounds/scream_14.ogg"),
	preload("res://assets/Sounds/scream_15.ogg"),
	preload("res://assets/Sounds/scream_16.ogg"),
	preload("res://assets/Sounds/scream_17.ogg"),
	preload("res://assets/Sounds/scream_18.ogg")
]
var sounds_wilhelm_scream = preload("res://assets/Sounds/scream_wilhelm.ogg")


####################################################################################
# State

# Number off different enemies we can load.
const ENEMY_COUNT := 14

# The chance we have of going into troll mode instead of being a typical enemy.
const CHANCE_OF_TROLLING := 0.05

# The enemy's ID. Used by the game for scoring multiplier purposes.
var id := 0

var _troll_mode := false

# The number of lifes the enemy has initially. This is
var _initial_lifes := 1

# How many lifes the enemy still has
var _lifes: int


####################################################################################
# Scene Lifecycle

func _ready() -> void:
	if randf() < CHANCE_OF_TROLLING:
		# We're in troll mode!
		_texture_rect.texture = load("res://assets/Enemy/troll.png")
		_troll_mode = true
		_initial_lifes = 3
	else:
		# We're a regular enemy
		var enemy_no: int = 1 + randi() % ENEMY_COUNT
		_texture_rect.texture = load("res://assets/Enemy/enemy" + str(enemy_no) + ".png")
	
	_texture_rect.rect_size = Vector2(
		_texture_rect.texture.get_width(),
		_texture_rect.texture.get_height())
	
	_lifes = _initial_lifes


func _process(delta) -> void:
	var global_pos: Vector2 = _texture_rect.rect_global_position
	if is_alive() and global_pos.x + _texture_rect.rect_size.x < 0:
		survive(true, false)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		
		if mouse_event.button_index == BUTTON_LEFT and mouse_event.pressed:
			if _hit():
				get_tree().set_input_as_handled()


# Tells listeners that this enemy has survived, optionally triggers animations and
# removes it from the scene.
func survive(signal_listeners: bool, play_animation: bool) -> void:
	if signal_listeners:
		emit_signal("enemy_left", self, true)
	
	if play_animation:
		_animation_player.play("Hide")
		yield(_animation_player, "animation_finished")
	
	self.queue_free()


# Tells listeners that this enemy has died, triggers any death animations and
# removes it from the scene.
func die(signal_listeners: bool) -> void:
	_lifes = 0
	
	if (signal_listeners):
		emit_signal("enemy_left", self, false)
	
	# Trigger effects
	_animation_player.play("Die")
	_blood_splatter.emitting = true
	
	# The animation is long enough to allow the particle emitter to finish and will
	# also trigger our _die_sound function. Handy!
	yield(_animation_player, "animation_finished")
	self.queue_free()


func _die_sound():
	var sound: AudioStream
	if _troll_mode:
		sound = sounds_wilhelm_scream
	else:
		sound = sounds_scream[randi() % sounds_scream.size()]
		
	SoundPlayer.play_sound(self, sound)


# Called if the left mouse button was pressed. Returns if the press resulted in
# this enemy being hit.
func _hit() -> bool:
	if is_alive():
		# Turn the global coordinates into local coordinates
		var local_pos: Vector2 = _texture_rect.get_local_mouse_position()
		if _texture_rect.get_rect().has_point(local_pos):
			# If we hit a transparent pixel... DON'T CARE!!!
			# (we need to lock the image to get pixel data out of it)
			var image: Image = _texture_rect.texture.get_data()
			image.lock()
			var hit_pixel: Color = image.get_pixel(
				round(local_pos.x),
				round(local_pos.y))
			image.unlock()
			
			if hit_pixel.a > 0:
				_lifes -= 1
				
				if _lifes > 0:
					# Dim the enemy
					self.modulate.a = (_lifes as float) / _initial_lifes
				
				else:
					# Place the blood splatter origin at hit point
					_blood_splatter.position.x = local_pos.x
					_blood_splatter.position.y = local_pos.y
					
					die(true)
					
				return true
	
	return false


####################################################################################
# Getters / Setters

func set_spawn_location(location: Vector2) -> void:
	set_position(Vector2(
		location.x,
		location.y - _texture_rect.rect_size.y))


# Returns the top center point of this enemy as a global position. Can be used to
# spawn score multipliers above the enemy.
func get_top_center() -> Vector2:
	var global_rect = _texture_rect.rect_global_position
	return Vector2(global_rect.x + _texture_rect.rect_size.x / 2, global_rect.y)


# Whether the enemy is still alive.
func is_alive() -> bool:
	return _lifes > 0


# Whether the enemy (or at least parts of the enemy) are currently visible.
func is_on_screen() -> bool:
	var enemy_global_rect = _texture_rect.get_global_rect()
	return enemy_global_rect.position.x < get_viewport().size.x and enemy_global_rect.end.x > 0
