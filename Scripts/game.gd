extends Node

var lanes = [0, 0, 0]
var lanes2 = [0, 0, 0]

var bricks_destroyed = 0
# In seconds
var time_survived = 0
var time_left = 8 
var time_gain = .5

var orig_scale
var orig_position

var lost = false;

# Lane Visuals
var brick = load("res://Brick-Breaker/Assets/base_brick.png")
var bombed_brick = load("res://Brick-Breaker/Assets/bomb_brick.png")
var active_bombed_brick = load("res://Brick-Breaker/Assets/bomb_brick_active-2.png (1).png")
var broken_brick = load("res://Brick-Breaker/Assets/broken_brick.png")
func _ready() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Rest"), false)
	orig_scale = $Lanes2.scale
	orig_position = $Lanes2.position
	GameManager.final_score = 0
	generate_lanes()
	$Player.connect("breaking", Callable(self, "break_brick"))
	$"Background Music".play(7)

func _physics_process(delta: float) -> void:
	time_left -= delta
	time_survived += delta
	if (time_left <= 0): time_left = 0
	update_timer()
	if !get_tree().paused:
		if (time_survived > 20):
			time_gain = .25
	
		if (time_left <= 0 && !lost):
			player_lost()
			lost = true
	
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
	GameManager.final_score += (int(time_survived) * bricks_destroyed)

func player_lost():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Rest"), true)
	update_score()
	$ColorRect/AnimationPlayer.play("Fade_In")
	await get_tree().create_timer(1).timeout
	$"Player/Collar Countdown".play(25)
	await get_tree().create_timer(1).timeout
	$"Player/Collar Countdown".stop()
	$Player/Dead.play()
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://Brick-Breaker/Scenes/final_screen.tscn")

func player_exploded():
	update_score()
	get_tree().change_scene_to_file("res://Brick-Breaker/Scenes/final_screen.tscn")

func generate_lanes():
	lanes[0] = lanes2[0]
	lanes[1] = lanes2[1]
	lanes[2] = lanes2[2]
	
	lanes2[0] = randi_range(0, 1)
	lanes2[1] = randi_range(0, 1)
	lanes2[2] = randi_range(0, 1)
	
	var not_all_bombs = false
	for lane in lanes2:
		if (lane == 0): 
			not_all_bombs = true
			break
	
	if (!not_all_bombs): lanes2[lanes2.pick_random()] = 0
	
	for i in range(lanes.size()):
		match (lanes[i]):
			0:
				$Lanes.get_child(i).texture = brick
			1:
				$Lanes.get_child(i).texture = bombed_brick
	
	for i in range(lanes2.size()):
		match (lanes2[i]):
			0:
				$Lanes2.get_child(i).texture = brick
			1:
				$Lanes2.get_child(i).texture = bombed_brick

func move_animation():
	get_tree().paused = true
	
	await get_tree().create_timer(0.5).timeout
	$Lanes2.position = Vector2(500, 0)
	$Lanes2.scale = Vector2(.7, .5)
		
	await get_tree().create_timer(0.5).timeout
	$Lanes2.position = $Lanes.position
	$Lanes2.scale = $Lanes.scale
		
	$Lanes2.scale = orig_scale
	$Lanes2.position = orig_position
		
	get_tree().paused = false
	time_left += 1.25
	generate_lanes()

func break_brick(lane_index: int, player_caused: bool):
	if (player_caused && lanes[lane_index] != -1):
		$Player/Punch.play(.17)
	match (lanes[lane_index]):
		0:  # Destroyable Brick
			break_success(lane_index)
		1:  # Bomb Brick
			bomb_brick_triggered(lane_index)

func break_success(lane_index: int):
	if (is_inside_tree()):
		$Lanes.get_child(lane_index).texture = broken_brick
		await get_tree().create_timer(.2).timeout
		$"Brick Crumbles".play()
	$Lanes.get_child(lane_index).texture = null
	lanes[lane_index] = -1
	time_left += time_gain
	bricks_destroyed += 10

func bomb_brick_triggered(lane_index: int):
	$Lanes.get_child(lane_index).texture = active_bombed_brick
	lanes[lane_index] = 0
	if (is_inside_tree()):
		await get_tree().create_timer(.5).timeout
	
	if ($Player.lane_index == lane_index):
		player_exploded()
	
	if (is_inside_tree()):
		$"Bomb Exploded".play()
	match (lane_index):
		0:  # Left Lane: Destroys Left & Middle
			break_brick(0, false)
			break_brick(1, false)
		1:  # Middle Lane: Destroys All
			break_brick(0, false)
			break_brick(1, false)
			break_brick(2, false)
		2:  # Right Lane: Destroys Middle & Right
			break_brick(1, false)
			break_brick(2, false)
