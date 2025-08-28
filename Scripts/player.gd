extends CharacterBody2D

@export var lane_positions: Array[Marker2D]

var lane_index = 1
signal breaking(lane_index: int)

func _physics_process(_delta: float) -> void:
	if (Input.is_action_just_pressed("Left")):
		if (lane_index != 0):
			lane_index -= 1
			move_player()
	elif (Input.is_action_just_pressed("Right")):
		if (lane_index != 2):
			lane_index += 1
			move_player()
	elif (Input.is_action_just_pressed("Break")):
		break_brick()

func move_player():
	$AudioStreamPlayer2D.play()
	match(lane_index):
		0:
			global_position = lane_positions[0].global_position
		1:
			global_position = lane_positions[1].global_position
		2:
			global_position = lane_positions[2].global_position

func break_brick():
	breaking.emit(lane_index)
