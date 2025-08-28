extends Node

var lanes = [0, 0, 0]

var bricks_destroyed = 0
# In seconds
var time_survived = 0
var time_left = 8 
var time_gain = 1.5

var orig_scale
var orig_position
# Lane Visuals
var brick = load("res://Brick-Breaker/Assets/cave_base_texture_1c_black_fill_1.png")
var bombed_brick = load("res://Brick-Breaker/Assets/Cave_base_texture_1c_desat_red_fill.png")
var active_bombed_brick = load("res://Brick-Breaker/Assets/brick.jpg")
var destroyed = load("res://Brick-Breaker/Assets/New Piskel-2.png (1).png")

func _ready() -> void:
	orig_scale = $Lanes2.scale
	orig_position = $Lanes2.position
	GameManager.final_score = 0
	generate_lanes()
	$Player.connect("breaking", Callable(self, "break_brick"))

func _physics_process(delta: float) -> void:
	time_left -= delta
	time_survived += delta
	update_timer()
	
	if (time_left < 0): player_lost()
	
	var all_destroyed = true
	for lane in lanes:
		if (lane != -1):
			all_destroyed = false
			break
	
	if (all_destroyed): 
		move_animation()

func update_timer():
	if (time_left >= 60): time_left = 59.99
	var seconds = fmod(time_left, 60)
	$Player/Timer.text = "%05.2f" % [seconds]

func add_time():
	time_left += time_gain

func update_score():
	GameManager.final_score += (int(time_survived) + bricks_destroyed)

func player_lost():
	update_score()
	get_tree().change_scene_to_file("res://Brick-Breaker/Scenes/final_screen.tscn")

func generate_lanes():
	lanes[0] = randi_range(0, 1)
	lanes[1] = randi_range(0, 1)
	lanes[2] = randi_range(0, 1)
	
	var not_all_bombs = false
	for lane in lanes:
		if (lane == 0): 
			not_all_bombs = true
			break
	
	if (!not_all_bombs): lanes[lanes.pick_random()] = 0
	
	for i in range(lanes.size()):
		match (lanes[i]):
			0:
				$Lanes.get_child(i).texture = brick
			1:
				$Lanes.get_child(i).texture = bombed_brick

func move_animation():
	var tween = get_tree().create_tween()
	tween.tween_property($Lanes2, "scale", $Lanes.scale, 2)
	tween.parallel().tween_property($Lanes2, "position", $Lanes.position, 2)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	get_tree().paused = true
	await tween.finished
	get_tree().paused = false
	$Lanes2.scale = orig_scale
	$Lanes2.position = orig_position
	generate_lanes()

func break_brick(lane_index: int):
	match (lanes[lane_index]):
		0: # Destroyable Brick
			break_success(lane_index)
		1: # Bomb Brick
			bomb_brick_triggered(lane_index)

func break_success(lane_index: int):
	$Lanes.get_child(lane_index).texture = destroyed
	lanes[lane_index] = -1
	time_left += time_gain

#func bomb_break(lane_index: int):
	

func bomb_brick_triggered(lane_index: int):
	$Lanes.get_child(lane_index).texture = active_bombed_brick
	lanes[lane_index] = 0
	if (is_inside_tree()):
		await get_tree().create_timer(.5).timeout
	
	if ($Player.lane_index == lane_index):
		player_lost()
		
	match (lane_index):
		0: # Left Lane: Destroys Left & Middle
			break_brick(0)
			break_brick(1)
		1: # Middle Lane: Destroys All
			break_brick(0)
			break_brick(1)
			break_brick(2)
		2: # Right Lane: Destroys Middle & Right
			break_brick(1)
			break_brick(2)
