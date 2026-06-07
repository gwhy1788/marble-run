extends RigidBody2D

const MARBLE_RADIUS := 20.0
const MAX_FORCE     := 520.0
const MAX_SPEED     := 290.0
const WOBBLE_RATE   := 0.75
const STUCK_LIMIT   := 18.0
const STUCK_TIME    := 2.8

var country: Dictionary = {}
var team_id: int = 0
var target_pos: Vector2 = Vector2.ZERO
var is_active: bool = false

var _wobble: float = 0.0
var _wobble_t: float = 0.0
var _stuck_t: float = 0.0

func _ready() -> void:
	add_to_group("marble")

func setup(p_country: Dictionary, p_team_id: int, p_target: Vector2) -> void:
	country    = p_country
	team_id    = p_team_id
	target_pos = p_target
	is_active  = true
	_wobble    = randf_range(-1.0, 1.0)
	_wobble_t  = WOBBLE_RATE
	queue_redraw()

func set_active(active: bool) -> void:
	is_active = active

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	_tick_wobble(delta)
	_steer()
	_unstuck(delta)

func _tick_wobble(delta: float) -> void:
	_wobble_t -= delta
	if _wobble_t <= 0.0:
		_wobble   = randf_range(-1.0, 1.0)
		_wobble_t = WOBBLE_RATE + randf_range(-0.2, 0.2)

func _steer() -> void:
	var dir := (target_pos - global_position).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var steer := (dir + perp * _wobble * 0.35).normalized()
	apply_central_force(steer * MAX_FORCE)
	if linear_velocity.length_squared() > MAX_SPEED * MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED

func _unstuck(delta: float) -> void:
	if linear_velocity.length() < STUCK_LIMIT:
		_stuck_t += delta
		if _stuck_t >= STUCK_TIME:
			_stuck_t = 0.0
			var kick := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			apply_central_impulse(kick * MAX_FORCE * 2.2)
	else:
		_stuck_t = 0.0

# ── Drawing ────────────────────────────────────────────────────────────────────

func _draw() -> void:
	if country.is_empty():
		return
	var R  := MARBLE_RADIUS
	var flag: Dictionary = country.get("flag", {})

	draw_circle(Vector2(3.0, 3.0), R, Color(0.0, 0.0, 0.0, 0.25))
	_draw_flag(flag, R)
	draw_arc(Vector2.ZERO, R, 0.0, TAU, 32, Color(0.0, 0.0, 0.0, 0.35), 1.5)
	draw_circle(Vector2(-6.0, -6.0), 7.0, Color(1.0, 1.0, 1.0, 0.28))

	var abbr: String = country.get("abbr", "")
	if abbr.length() > 0:
		var font      := ThemeDB.fallback_font
		var font_size := 9
		var text_col  := _text_color(flag)
		var sz        := font.get_string_size(abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var pos       := Vector2(-sz.x * 0.5, sz.y * 0.5 - 2.0)
		draw_string_outline(font, pos, abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2,
				Color(0.0, 0.0, 0.0, 0.85))
		draw_string(font, pos, abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_col)

func _text_color(flag: Dictionary) -> Color:
	var ftype: String = flag.get("type", "solid")
	var ref: Color
	match ftype:
		"h_stripes", "v_stripes":
			var cols: Array = flag.get("colors", [Color.GRAY]) as Array
			ref = cols[cols.size() / 2] as Color
		"cross", "swiss_cross", "england", "nordic_cross":
			ref = flag.get("c2", Color.RED) as Color
		"wales":
			ref = flag.get("c3", Color(0.76, 0.08, 0.08)) as Color
		"korea":
			ref = flag.get("c3", Color(0, 0.25, 0.62)) as Color
		"circle":
			ref = flag.get("c2", Color.RED) as Color
		"diamond":
			ref = flag.get("c3", Color.BLUE) as Color
		_:
			ref = flag.get("c1", Color.GRAY) as Color
	return Color.BLACK if ref.get_luminance() > 0.45 else Color.WHITE

func _draw_flag(flag: Dictionary, R: float) -> void:
	match flag.get("type", "solid"):
		"h_stripes":
			_draw_h_stripes(flag.get("colors", [Color.GRAY]) as Array, R)
		"v_stripes":
			_draw_v_stripes(flag.get("colors", [Color.GRAY]) as Array, R)
		"cross":
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color.WHITE) as Color)
			_draw_circle_strip_h(-R * 0.22, R * 0.22, flag.get("c2", Color.RED) as Color, R)
			_draw_circle_strip_v(-R * 0.22, R * 0.22, flag.get("c2", Color.RED) as Color, R)
		"england":
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color.WHITE) as Color)
			_draw_circle_strip_h(-R * 0.25, R * 0.25, flag.get("c2", Color.RED) as Color, R)
			_draw_circle_strip_v(-R * 0.25, R * 0.25, flag.get("c2", Color.RED) as Color, R)
		"swiss_cross":
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color.RED) as Color)
			var al: float = R * 0.5
			var ah: float = R * 0.165
			draw_rect(Rect2(-al, -ah, al * 2.0, ah * 2.0), flag.get("c2", Color.WHITE) as Color)
			draw_rect(Rect2(-ah, -al, ah * 2.0, al * 2.0), flag.get("c2", Color.WHITE) as Color)
		"circle":
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color.WHITE) as Color)
			draw_circle(Vector2.ZERO, R * 0.42, flag.get("c2", Color.RED) as Color)
		"diamond":
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color.GREEN) as Color)
			var d: float = R * 0.73
			draw_polygon(PackedVector2Array([
				Vector2(0.0, -d * 0.65), Vector2(d, 0.0),
				Vector2(0.0,  d * 0.65), Vector2(-d, 0.0),
			]), PackedColorArray([flag.get("c2", Color.YELLOW) as Color]))
			draw_circle(Vector2.ZERO, R * 0.32, flag.get("c3", Color.BLUE) as Color)
		"wales":
			_draw_circle_strip_h(-R, 0.0, Color.WHITE, R)
			_draw_circle_strip_h(0.0, R, flag.get("c2", Color(0, 0.4, 0.15)) as Color, R)
			var dr: Color = flag.get("c3", Color(0.76, 0.08, 0.08)) as Color
			var bp := PackedVector2Array()
			for j in 10:
				var a: float = TAU * float(j) / 10.0
				bp.append(Vector2(cos(a) * R * 0.25 + 1.5, sin(a) * R * 0.19 + 2.0))
			draw_polygon(bp, PackedColorArray([dr]))
			draw_circle(Vector2(R * 0.36, -R * 0.24), R * 0.14, dr)
			draw_polygon(PackedVector2Array([
				Vector2(R * 0.12, -R * 0.02), Vector2(R * 0.26, -R * 0.28),
				Vector2(R * 0.38, -R * 0.12), Vector2(R * 0.2, R * 0.04),
			]), PackedColorArray([dr]))
			draw_polygon(PackedVector2Array([
				Vector2(-R * 0.08, -R * 0.06), Vector2(-R * 0.46, -R * 0.44),
				Vector2(-R * 0.1, -R * 0.28),
			]), PackedColorArray([dr]))
			draw_polygon(PackedVector2Array([
				Vector2(-R * 0.2, R * 0.1), Vector2(-R * 0.5, R * 0.42),
				Vector2(-R * 0.08, R * 0.25),
			]), PackedColorArray([dr]))
		"canton_stripes":
			var n_s: int = 13
			var s_h: float = R * 2.0 / float(n_s)
			for i in n_s:
				var sc: Color = flag.get("c1", Color.RED) as Color
				if i % 2 == 1:
					sc = flag.get("c2", Color.WHITE) as Color
				_draw_circle_strip_h(-R + float(i) * s_h, -R + float(i + 1) * s_h, sc, R)
			_draw_circle_rect(-R, -R, -R + R * 0.8, -R + 7.0 * s_h,
					flag.get("c3", Color.BLUE) as Color, R)
		"australia":
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color(0, 0.2, 0.6)) as Color)
			var cr: float = -R * 0.08
			var cb: float = -R * 0.02
			var ccx: float = (-R + cr) * 0.5
			var ccy: float = (-R + cb) * 0.5
			var hs: float = R * 0.18
			_draw_circle_rect(-R, -R, cr, cb, Color.WHITE, R)
			_draw_circle_rect(-R, ccy - hs, cr, ccy + hs,
					flag.get("c2", Color(0.76, 0.08, 0.08)) as Color, R)
			_draw_circle_rect(ccx - hs, -R, ccx + hs, cb,
					flag.get("c2", Color(0.76, 0.08, 0.08)) as Color, R)
			var sw: Color = Color.WHITE
			_draw_star(Vector2(R * 0.4,   -R * 0.4), 2.8, 1.1, 4, sw)
			_draw_star(Vector2(R * 0.7,    R * 0.0), 2.8, 1.1, 4, sw)
			_draw_star(Vector2(R * 0.24,   R * 0.4), 2.8, 1.1, 4, sw)
			_draw_star(Vector2(R * 0.1,    R * 0.0), 2.8, 1.1, 4, sw)
			_draw_star(Vector2(R * 0.5,   -R * 0.1), 1.8, 0.7,  4, sw)
			_draw_star(Vector2(-R * 0.52,  R * 0.3), 3.2, 1.1,  7, sw)
		"argentina":
			_draw_h_stripes(flag.get("colors", [Color.GRAY]) as Array, R)
			var sun_col: Color = flag.get("c2", Color(0.88, 0.72, 0.0)) as Color
			for k in 16:
				var ang: float = TAU * float(k) / 16.0
				draw_polygon(PackedVector2Array([
					Vector2(cos(ang - 0.14) * R * 0.22, sin(ang - 0.14) * R * 0.22),
					Vector2(cos(ang + 0.14) * R * 0.22, sin(ang + 0.14) * R * 0.22),
					Vector2(cos(ang) * R * 0.42, sin(ang) * R * 0.42),
				]), PackedColorArray([sun_col]))
			draw_circle(Vector2.ZERO, R * 0.2, sun_col)
			draw_circle(Vector2.ZERO, R * 0.13, flag.get("c3", Color(0.78, 0.52, 0.02)) as Color)
		"nordic_cross":
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color.RED) as Color)
			_draw_circle_strip_h(-R * 0.22, R * 0.22, flag.get("c2", Color.WHITE) as Color, R)
			_draw_circle_strip_v(-R * 0.47, -R * 0.03, flag.get("c2", Color.WHITE) as Color, R)
		"morocco":
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color(0.76, 0.09, 0.09)) as Color)
			_draw_star(Vector2.ZERO, R * 0.42, R * 0.17, 5, flag.get("c2", Color(0, 0.39, 0.2)) as Color)
		"korea":
			draw_circle(Vector2.ZERO, R, Color.WHITE)
			var tk_r: float = R * 0.4
			var tk_red: Color  = flag.get("c2", Color(0.82, 0.1, 0.1)) as Color
			var tk_blue: Color = flag.get("c3", Color(0, 0.25, 0.62)) as Color
			_draw_circle_strip_h(-tk_r, 0.0, tk_blue, tk_r)
			_draw_circle_strip_h(0.0, tk_r, tk_red, tk_r)
			draw_circle(Vector2(0, -tk_r * 0.5), tk_r * 0.25, tk_red)
			draw_circle(Vector2(0,  tk_r * 0.5), tk_r * 0.25, tk_blue)
		"canada":
			_draw_v_stripes(flag.get("colors", [Color.GRAY]) as Array, R)
			var ml: Color = flag.get("c2", Color(0.86, 0.06, 0.06)) as Color
			draw_polygon(PackedVector2Array([
				Vector2(0,           -R * 0.38),
				Vector2(-R * 0.08,  -R * 0.26),
				Vector2(-R * 0.27,  -R * 0.3),
				Vector2(-R * 0.18,  -R * 0.1),
				Vector2(-R * 0.38,   R * 0.0),
				Vector2(-R * 0.22,   R * 0.08),
				Vector2(-R * 0.1,    R * 0.28),
				Vector2(0,           R * 0.2),
				Vector2(R * 0.1,     R * 0.28),
				Vector2(R * 0.22,    R * 0.08),
				Vector2(R * 0.38,    R * 0.0),
				Vector2(R * 0.18,   -R * 0.1),
				Vector2(R * 0.27,   -R * 0.3),
				Vector2(R * 0.08,   -R * 0.26),
			]), PackedColorArray([ml]))
			draw_polygon(PackedVector2Array([
				Vector2(-R * 0.04,  R * 0.2),
				Vector2(R * 0.04,   R * 0.2),
				Vector2(R * 0.04,   R * 0.36),
				Vector2(-R * 0.04,  R * 0.36),
			]), PackedColorArray([ml]))
		_:
			draw_circle(Vector2.ZERO, R, flag.get("c1", Color.GRAY) as Color)

# ── Flag geometry helpers ──────────────────────────────────────────────────────

func _draw_h_stripes(colors: Array, R: float) -> void:
	var n: int = colors.size()
	if n == 0:
		return
	var h: float = R * 2.0 / float(n)
	for i in n:
		_draw_circle_strip_h(-R + float(i) * h, -R + float(i + 1) * h,
				colors[i] as Color, R)

func _draw_v_stripes(colors: Array, R: float) -> void:
	var n: int = colors.size()
	if n == 0:
		return
	var w: float = R * 2.0 / float(n)
	for i in n:
		_draw_circle_strip_v(-R + float(i) * w, -R + float(i + 1) * w,
				colors[i] as Color, R)

func _draw_circle_strip_h(y_top: float, y_bot: float, col: Color, R: float) -> void:
	var pts := PackedVector2Array()
	var steps: int = 20
	# Left arc: from bottom to top
	for i in steps + 1:
		var yc: float = clampf(y_bot + (y_top - y_bot) * float(i) / float(steps), -R, R)
		pts.append(Vector2(-sqrt(maxf(0.0, R * R - yc * yc)), yc))
	# Right arc: from top to bottom
	for i in steps + 1:
		var yc: float = clampf(y_top + (y_bot - y_top) * float(i) / float(steps), -R, R)
		pts.append(Vector2(sqrt(maxf(0.0, R * R - yc * yc)), yc))
	if pts.size() >= 3:
		draw_polygon(pts, PackedColorArray([col]))

func _draw_circle_strip_v(x_left: float, x_right: float, col: Color, R: float) -> void:
	var pts := PackedVector2Array()
	var steps: int = 20
	# Bottom arc: left to right
	for i in steps + 1:
		var xc: float = clampf(x_left + (x_right - x_left) * float(i) / float(steps), -R, R)
		pts.append(Vector2(xc, sqrt(maxf(0.0, R * R - xc * xc))))
	# Top arc: right to left
	for i in steps + 1:
		var xc: float = clampf(x_right + (x_left - x_right) * float(i) / float(steps), -R, R)
		pts.append(Vector2(xc, -sqrt(maxf(0.0, R * R - xc * xc))))
	if pts.size() >= 3:
		draw_polygon(pts, PackedColorArray([col]))

func _draw_circle_rect(rx1: float, ry1: float, rx2: float, ry2: float, col: Color, R: float) -> void:
	var steps: int = 14
	for i in steps:
		var ya: float = ry1 + (ry2 - ry1) * float(i) / float(steps)
		var yb: float = ry1 + (ry2 - ry1) * float(i + 1) / float(steps)
		var ym: float = (ya + yb) * 0.5
		if ym <= -R or ym >= R:
			continue
		var x_circ: float = sqrt(maxf(0.0, R * R - ym * ym))
		var xa: float = maxf(rx1, -x_circ)
		var xb: float = minf(rx2, x_circ)
		if xb <= xa:
			continue
		draw_polygon(PackedVector2Array([
			Vector2(xa, ya), Vector2(xb, ya),
			Vector2(xb, yb), Vector2(xa, yb)
		]), PackedColorArray([col]))

func _draw_star(center: Vector2, r_out: float, r_in: float, n_pts: int, col: Color) -> void:
	var verts := PackedVector2Array()
	for k in n_pts * 2:
		var ang: float = -PI * 0.5 + TAU * float(k) / float(n_pts * 2)
		var rad: float = r_out if k % 2 == 0 else r_in
		verts.append(center + Vector2(cos(ang) * rad, sin(ang) * rad))
	draw_polygon(verts, PackedColorArray([col]))
