extends Node

func _ready() -> void:
	$Label.text += str(GameManager.final_score)
	get_tree().paused = false

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://Brick-Breaker/Scenes/game.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
