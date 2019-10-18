extends State


####################################################################################
# Scene Objects

onready var animator: AnimationPlayer = $AnimationPlayer
onready var version_label: Label = $MiscContainer/Label


####################################################################################
# Scene Lifecycle

func _ready():
	# We need to fill in the version number
	version_label.text = tr("VERSION_LABEL") % \
		ProjectSettings.get("application/config/version")


####################################################################################
# State Lifecycle

func state_started(prev_state: State) -> void:
	.state_started(prev_state)
	animator.play("fade")


func state_paused(next_state: State) -> void:
	.state_paused(next_state)
	animator.play_backwards("fade")


####################################################################################
# Event Handling

func _on_ButtonPlay_pressed():
	# TODO Replace this by a signal
	transition_push($"/root/Main/StateMachine/GameIntro")
	

func _on_ButtonExit_pressed():
	# Fade out the menu before quitting
	animator.play_backwards("fade")
	yield(animator, "animation_finished")
	
	# Removing all states tells our main controller to quit the game
	transition_replace_all(null)
