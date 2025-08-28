extends Node

var lanes = [0, 0, 0]

var bricks_destroyed = 0
# In seconds
var time_survived = 0
var time_left = 8 
var time_gain = 1.5

# Lane Visuals
var brick = load("res://Brick-Breaker/Assets/Cave_texture_1B_grey_fill.png")
var bombed_brick = load("res://Brick-Breaker/Assets/Cave_base_texture_1b_desat_red_fill.png")
var active_bombed_brick = load("res://Brick-Breaker/Assets/brick.jpg")
var destroyed = load("res://Brick-Breaker/Assets/background.jpg")

func _ready() -> void:
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
		generate_lanes()

func update_timer():
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
