extends Node2D

signal goal_scored(team_idx: int, score_a: int, score_b: int)
signal match_finished(winner_team_id: int, score_a: int, score_b: int)
signal match_drawn(score_a: int, score_b: int)

const MARBLE_SCENE  := preload("res://scenes/Marble.tscn")
const FIELD_W       := 1280.0
const FIELD_H       := 720.0
const GOAL_TOP      := 260.0
const GOAL_BOT      := 460.0
const MATCH_TIME    := 30.0
const SD_TIME       := 20.0
const CELEBRATE_DUR := 1.8
const RESPAWN_DELAY := 0.6

# Goalie constants
const GOALIE_W     := 18.0
const GOALIE_H     := 38.0
const GOALIE_AMP   := 68.0   # oscillation half-range in pixels
const GOALIE_SPEED := 1.3    # radians per second
const GOALIE_Y     := FIELD_H * 0.5
const GOALIE_X_L   := 80.0
const GOALIE_X_R   := FIELD_W - 80.0

enum Phase { WARMUP, PLAYING, CELEBRATING, RESPAWNING, OVER }

var allow_draw: bool      = false
var team_a: Dictionary    = {}
var team_b: Dictionary    = {}
var score: Array          = [0, 0]
var time_left: float      = MATCH_TIME
var is_sudden_death: bool = false
var phase: Phase          = Phase.WARMUP
var _phase_timer: float   = 0.0
var _left_goal: Area2D
var _right_goal: Area2D
var _marbles: Node2D
var _left_goalie: AnimatableBody2D
var _right_goalie: AnimatableBody2D
var _goalie_t: float = 0.0

func setup(p_team_a: Dictionary, p_team_b: Dictionary) -> void:
	team_a = p_team_a
	team_b = p_team_b

func start_match() -> void:
	score           = [0, 0]
	time_left       = MATCH_TIME
	is_sudden_death = false
	phase           = Phase.WARMUP
	_phase_timer    = RESPAWN_DELAY
	_goalie_t       = 0.0
	_spawn_marbles()

# ── Physics loop ───────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if phase != Phase.OVER:
		_update_goalies(delta)
		queue_redraw()
		time_left -= delta
		if time_left <= 0.0:
			_handle_time_up()
			return

	match phase:
		Phase.WARMUP:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				phase = Phase.PLAYING
		Phase.PLAYING:
			_check_oob()
		Phase.CELEBRATING:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_set_all_marbles_active(false)
				_clear_marbles()
				phase        = Phase.RESPAWNING
				_phase_timer = RESPAWN_DELAY
		Phase.RESPAWNING:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_spawn_marbles()
				phase        = Phase.WARMUP
				_phase_timer = RESPAWN_DELAY
		Phase.OVER:
			pass

func _update_goalies(delta: float) -> void:
	_goalie_t += delta
	var y_l: float = GOALIE_Y + GOALIE_AMP * sin(_goalie_t * GOALIE_SPEED)
	var y_r: float = GOALIE_Y + GOALIE_AMP * sin(_goalie_t * GOALIE_SPEED + PI)
	_left_goalie.move_and_collide(Vector2(GOALIE_X_L, y_l) - _left_goalie.position)
	_right_goalie.move_and_collide(Vector2(GOALIE_X_R, y_r) - _right_goalie.position)

func _check_oob() -> void:
	for m in _marbles.get_children():
		if m.position.x < -120 or m.position.x > FIELD_W + 120 \
				or m.position.y < -80 or m.position.y > FIELD_H + 80:
			m.position        = _spawn_pos(m.team_id, 0)
			m.linear_velocity = Vector2.ZERO

# ── Scoring ────────────────────────────────────────────────────────────────────

func _on_left_goal_entered(body: Node2D) -> void:
	if phase != Phase.PLAYING:
		return
	if body.is_in_group("marble"):
		_register_goal(1, body)

func _on_right_goal_entered(body: Node2D) -> void:
	if phase != Phase.PLAYING:
		return
	if body.is_in_group("marble"):
		_register_goal(0, body)

func _register_goal(team_idx: int, marble: Node2D) -> void:
	score[team_idx] += 1
	marble.set_active(false)
	marble.queue_free()
	goal_scored.emit(team_idx, score[0], score[1])

	var winner_found: bool = is_sudden_death
	if winner_found:
		phase = Phase.OVER
		_set_all_marbles_active(false)
		match_finished.emit(team_idx, score[0], score[1])
	else:
		phase        = Phase.CELEBRATING
		_phase_timer = CELEBRATE_DUR
		_set_all_marbles_active(false)

func _handle_time_up() -> void:
	time_left = 0.0
	if score[0] != score[1]:
		var winner: int = 0 if (score[0] as int) > (score[1] as int) else 1
		phase = Phase.OVER
		_set_all_marbles_active(false)
		match_finished.emit(winner, score[0], score[1])
	elif allow_draw:
		phase = Phase.OVER
		_set_all_marbles_active(false)
		match_drawn.emit(score[0], score[1])
	else:
		is_sudden_death = true
		time_left       = SD_TIME

# ── Marble management ──────────────────────────────────────────────────────────

func _spawn_marbles() -> void:
	var spawns_a := [Vector2(170, 300), Vector2(170, 420)]
	var spawns_b := [Vector2(FIELD_W - 170, 300), Vector2(FIELD_W - 170, 420)]
	var tgt_a    := Vector2(FIELD_W + 30.0, FIELD_H * 0.5)
	var tgt_b    := Vector2(-30.0,          FIELD_H * 0.5)

	for i in 2:
		var ma: RigidBody2D = MARBLE_SCENE.instantiate()
		_marbles.add_child(ma)
		ma.setup(team_a, 0, tgt_a)
		ma.position = spawns_a[i] + Vector2(randf_range(-10, 10), randf_range(-10, 10))

		var mb: RigidBody2D = MARBLE_SCENE.instantiate()
		_marbles.add_child(mb)
		mb.setup(team_b, 1, tgt_b)
		mb.position = spawns_b[i] + Vector2(randf_range(-10, 10), randf_range(-10, 10))

func _clear_marbles() -> void:
	for c in _marbles.get_children():
		c.queue_free()

func _set_all_marbles_active(active: bool) -> void:
	for m in _marbles.get_children():
		if m.has_method("set_active"):
			m.set_active(active)

func _spawn_pos(tid: int, _idx: int) -> Vector2:
	return Vector2(170, FIELD_H * 0.5) if tid == 0 else Vector2(FIELD_W - 170, FIELD_H * 0.5)

# ── World building ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_marbles = $Marbles
	_build_boundaries()
	_build_goals()
	_build_goalies()
	_build_obstacles()
	queue_redraw()

func _build_boundaries() -> void:
	var mat := _wall_mat(0.45, 0.3)
	_wall(Vector2(FIELD_W * 0.5, 5),                                       Vector2(FIELD_W, 10),            mat)
	_wall(Vector2(FIELD_W * 0.5, FIELD_H - 5),                             Vector2(FIELD_W, 10),            mat)
	_wall(Vector2(5, GOAL_TOP * 0.5),                                       Vector2(10, GOAL_TOP),           mat)
	_wall(Vector2(5, GOAL_BOT + (FIELD_H - GOAL_BOT) * 0.5),               Vector2(10, FIELD_H - GOAL_BOT), mat)
	_wall(Vector2(FIELD_W - 5, GOAL_TOP * 0.5),                             Vector2(10, GOAL_TOP),           mat)
	_wall(Vector2(FIELD_W - 5, GOAL_BOT + (FIELD_H - GOAL_BOT) * 0.5),    Vector2(10, FIELD_H - GOAL_BOT), mat)

func _build_goals() -> void:
	_left_goal  = _make_goal(Vector2(-30.0, FIELD_H * 0.5))
	_right_goal = _make_goal(Vector2(FIELD_W + 30.0, FIELD_H * 0.5))
	_left_goal.body_entered.connect(_on_left_goal_entered)
	_right_goal.body_entered.connect(_on_right_goal_entered)

func _build_goalies() -> void:
	_left_goalie  = _make_goalie(Vector2(GOALIE_X_L, GOALIE_Y))
	_right_goalie = _make_goalie(Vector2(GOALIE_X_R, GOALIE_Y))

func _make_goalie(pos: Vector2) -> AnimatableBody2D:
	var body := AnimatableBody2D.new()
	body.sync_to_physics = false
	body.position = pos
	var mat := _wall_mat(0.65, 0.1)
	body.physics_material_override = mat
	var cs := CollisionShape2D.new()
	var r  := RectangleShape2D.new()
	r.size = Vector2(GOALIE_W, GOALIE_H)
	cs.shape = r
	body.add_child(cs)
	add_child(body)
	return body

func _build_obstacles() -> void:
	var bmat := _wall_mat(0.88, 0.08)
	_bumper(Vector2(FIELD_W * 0.5, FIELD_H * 0.5), 36.0, bmat)
	for pos: Vector2 in [Vector2(252, 182), Vector2(1028, 182), Vector2(252, 538), Vector2(1028, 538)]:
		_bumper(pos, 22.0, bmat)
	var wmat := _wall_mat(0.55, 0.2)
	_wall(Vector2(FIELD_W * 0.5, 242), Vector2(184, 16), wmat)
	_wall(Vector2(FIELD_W * 0.5, 478), Vector2(184, 16), wmat)

# ── Factory helpers ────────────────────────────────────────────────────────────

func _wall_mat(bounce: float, friction: float) -> PhysicsMaterial:
	var m      := PhysicsMaterial.new()
	m.bounce   = bounce
	m.friction = friction
	return m

func _wall(pos: Vector2, size: Vector2, mat: PhysicsMaterial) -> void:
	var body := StaticBody2D.new()
	body.physics_material_override = mat
	body.position = pos
	var cs := CollisionShape2D.new()
	var r  := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	body.add_child(cs)
	add_child(body)

func _bumper(pos: Vector2, radius: float, mat: PhysicsMaterial) -> void:
	var body := StaticBody2D.new()
	body.physics_material_override = mat
	body.position = pos
	var cs := CollisionShape2D.new()
	var c  := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	body.add_child(cs)
	add_child(body)

func _make_goal(pos: Vector2) -> Area2D:
	var area := Area2D.new()
	area.position        = pos
	area.collision_layer = 0
	area.collision_mask  = 1
	var cs := CollisionShape2D.new()
	var r  := RectangleShape2D.new()
	r.size = Vector2(60, GOAL_BOT - GOAL_TOP)
	cs.shape = r
	area.add_child(cs)
	add_child(area)
	return area

# ── Drawing ────────────────────────────────────────────────────────────────────

func _draw() -> void:
	var W  := FIELD_W
	var H  := FIELD_H
	var GT := GOAL_TOP
	var GB := GOAL_BOT
	var GH := GB - GT

	# Pitch stripes
	for i in 10:
		var col := Color(0.118, 0.565, 0.176) if i % 2 == 0 else Color(0.094, 0.502, 0.149)
		draw_rect(Rect2(i * W / 10, 0, W / 10, H), col)

	# Goal mouths
	draw_rect(Rect2(0, GT, 32, GH), Color(0.85, 0.9, 0.85, 0.45))
	draw_rect(Rect2(W - 32, GT, 32, GH), Color(0.85, 0.9, 0.85, 0.45))

	# Field markings
	draw_rect(Rect2(32, 12, W - 64, H - 24), Color.WHITE, false, 3.0)
	draw_line(Vector2(W * 0.5, 12), Vector2(W * 0.5, H - 12), Color.WHITE, 3.0)
	draw_arc(Vector2(W * 0.5, H * 0.5), 80, 0, TAU, 48, Color.WHITE, 3.0)
	draw_circle(Vector2(W * 0.5, H * 0.5), 5, Color.WHITE)
	draw_rect(Rect2(32, H * 0.5 - 88, 100, 176), Color.WHITE, false, 2.0)
	draw_rect(Rect2(W - 132, H * 0.5 - 88, 100, 176), Color.WHITE, false, 2.0)
	draw_line(Vector2(0, GT), Vector2(32, GT), Color.WHITE, 3.0)
	draw_line(Vector2(0, GB), Vector2(32, GB), Color.WHITE, 3.0)
	draw_line(Vector2(W, GT), Vector2(W - 32, GT), Color.WHITE, 3.0)
	draw_line(Vector2(W, GB), Vector2(W - 32, GB), Color.WHITE, 3.0)

	# Obstacles
	draw_circle(Vector2(W * 0.5, H * 0.5), 36, Color(0.55, 0.32, 0.06))
	draw_arc(Vector2(W * 0.5, H * 0.5), 36, 0, TAU, 32, Color(0.9, 0.55, 0.1), 4.0)
	for pos: Vector2 in [Vector2(252, 182), Vector2(1028, 182), Vector2(252, 538), Vector2(1028, 538)]:
		draw_circle(pos, 22, Color(0.55, 0.32, 0.06))
		draw_arc(pos, 22, 0, TAU, 24, Color(0.9, 0.55, 0.1), 3.0)
	draw_rect(Rect2(W * 0.5 - 92, 234, 184, 16), Color(0.45, 0.28, 0.08))
	draw_rect(Rect2(W * 0.5 - 92, 470, 184, 16), Color(0.45, 0.28, 0.08))

	# Goalies
	if _left_goalie and _right_goalie:
		var gw2: float = GOALIE_W * 0.5
		var gh2: float = GOALIE_H * 0.5
		var lp: Vector2 = _left_goalie.position
		var rp: Vector2 = _right_goalie.position
		draw_rect(Rect2(lp.x - gw2, lp.y - gh2, GOALIE_W, GOALIE_H), Color(0.15, 0.55, 0.9, 1))
		draw_rect(Rect2(lp.x - gw2, lp.y - gh2, GOALIE_W, GOALIE_H), Color(1, 1, 1, 0.5), false, 2.0)
		draw_rect(Rect2(rp.x - gw2, rp.y - gh2, GOALIE_W, GOALIE_H), Color(0.15, 0.55, 0.9, 1))
		draw_rect(Rect2(rp.x - gw2, rp.y - gh2, GOALIE_W, GOALIE_H), Color(1, 1, 1, 0.5), false, 2.0)
