extends Control

const R16_IDX := 48
const QF_IDX  := 56
const SF_IDX  := 60
const FIN_IDX := 62

const BOX_W := 155.0
const BOX_H := 48.0

# Column left-x positions: [R16L, QFL, SFL, FIN, SFR, QFR, R16R]
# BOX_W=155, gap=20, margin=38 → Final centered at x=640
const CX: Array = [38.0, 213.0, 388.0, 563.0, 738.0, 913.0, 1088.0]

# Y-top positions for left side (right side uses same values)
# R16 pair1: (80,200) → QF center=(104+224)/2=164 → QF y_top=140
# R16 pair2: (380,500) → QF center=(404+524)/2=464 → QF y_top=440
# SF center=(164+464)/2=314 → SF y_top=290
const Y_R16: Array  = [80.0, 200.0, 380.0, 500.0]
const Y_QF:  Array  = [140.0, 440.0]
const Y_SF:  float  = 290.0
const Y_FIN: float  = 290.0

var _matches: Array = []
var _font:    Font   = null

func setup(matches: Array) -> void:
	_matches = matches
	queue_redraw()

func _draw() -> void:
	_font = ThemeDB.fallback_font

	draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.03, 0.07, 0.91))

	draw_string(_font, Vector2(0, 52), "KNOCKOUT BRACKET",
		HORIZONTAL_ALIGNMENT_CENTER, 1280, 28, Color(1, 0.85, 0.2, 1))

	_draw_connectors()
	_draw_boxes()
	_draw_labels()

# ── Connectors ─────────────────────────────────────────────────────────────────

func _draw_connectors() -> void:
	var col := Color(0.42, 0.42, 0.54, 0.65)
	var lw  := 1.5

	# Left: R16 pair1 → QF[56]
	_bracket_join(Y_R16[0]+BOX_H*0.5, Y_R16[1]+BOX_H*0.5, Y_QF[0]+BOX_H*0.5,
				  CX[0]+BOX_W, CX[1], col, lw)
	# Left: R16 pair2 → QF[57]
	_bracket_join(Y_R16[2]+BOX_H*0.5, Y_R16[3]+BOX_H*0.5, Y_QF[1]+BOX_H*0.5,
				  CX[0]+BOX_W, CX[1], col, lw)
	# Left: QF[56]+QF[57] → SF[60]
	_bracket_join(Y_QF[0]+BOX_H*0.5, Y_QF[1]+BOX_H*0.5, Y_SF+BOX_H*0.5,
				  CX[1]+BOX_W, CX[2], col, lw)
	# Left SF[60] → Final (same Y, straight line)
	var sf_cy := Y_SF + BOX_H * 0.5
	draw_line(Vector2(CX[2]+BOX_W, sf_cy), Vector2(CX[3], sf_cy), col, lw)

	# Right: R16 pair1 → QF[58]
	_bracket_join(Y_R16[0]+BOX_H*0.5, Y_R16[1]+BOX_H*0.5, Y_QF[0]+BOX_H*0.5,
				  CX[6], CX[5]+BOX_W, col, lw)
	# Right: R16 pair2 → QF[59]
	_bracket_join(Y_R16[2]+BOX_H*0.5, Y_R16[3]+BOX_H*0.5, Y_QF[1]+BOX_H*0.5,
				  CX[6], CX[5]+BOX_W, col, lw)
	# Right: QF[58]+QF[59] → SF[61]
	_bracket_join(Y_QF[0]+BOX_H*0.5, Y_QF[1]+BOX_H*0.5, Y_SF+BOX_H*0.5,
				  CX[5], CX[4]+BOX_W, col, lw)
	# Right SF[61] → Final (same Y, straight line)
	draw_line(Vector2(CX[3]+BOX_W, sf_cy), Vector2(CX[4], sf_cy), col, lw)

# Draws the classic bracket connector: two inputs at y1/y2 merge to one output at out_y.
# from_x is the source side edge, to_x is the destination side edge.
func _bracket_join(y1: float, y2: float, out_y: float,
				   from_x: float, to_x: float, col: Color, lw: float) -> void:
	var mid_x := (from_x + to_x) * 0.5
	draw_line(Vector2(from_x, y1),    Vector2(mid_x, y1),    col, lw)
	draw_line(Vector2(from_x, y2),    Vector2(mid_x, y2),    col, lw)
	draw_line(Vector2(mid_x,  y1),    Vector2(mid_x, y2),    col, lw)
	draw_line(Vector2(mid_x,  out_y), Vector2(to_x,  out_y), col, lw)

# ── Match boxes ────────────────────────────────────────────────────────────────

func _draw_boxes() -> void:
	# Left R16: matches 48..51
	for i in range(4):
		_match_box(CX[0], Y_R16[i], _get_m(R16_IDX + i))
	# Left QF: 56, 57
	_match_box(CX[1], Y_QF[0], _get_m(QF_IDX))
	_match_box(CX[1], Y_QF[1], _get_m(QF_IDX + 1))
	# Left SF: 60
	_match_box(CX[2], Y_SF, _get_m(SF_IDX))
	# Final: 62
	_match_box(CX[3], Y_FIN, _get_m(FIN_IDX))
	# Right SF: 61
	_match_box(CX[4], Y_SF, _get_m(SF_IDX + 1))
	# Right QF: 58, 59
	_match_box(CX[5], Y_QF[0], _get_m(QF_IDX + 2))
	_match_box(CX[5], Y_QF[1], _get_m(QF_IDX + 3))
	# Right R16: matches 52..55
	for i in range(4):
		_match_box(CX[6], Y_R16[i], _get_m(R16_IDX + 4 + i))

func _get_m(idx: int) -> Dictionary:
	if idx < _matches.size():
		return _matches[idx] as Dictionary
	return {}

func _match_box(x: float, y: float, m: Dictionary) -> void:
	var ta:      Dictionary = m.get("team_a", {}) as Dictionary
	var tb:      Dictionary = m.get("team_b", {}) as Dictionary
	var winner:  Dictionary = m.get("winner", {}) as Dictionary
	var win_name: String    = winner.get("name", "") as String

	draw_rect(Rect2(x, y, BOX_W, BOX_H), Color(0.07, 0.09, 0.13, 0.96))

	var rh:     float = BOX_H * 0.5
	var a_wins: bool  = win_name != "" and win_name == (ta.get("name", "") as String)
	var b_wins: bool  = win_name != "" and win_name == (tb.get("name", "") as String)
	_team_row(x, y,    rh, ta, a_wins)
	draw_line(Vector2(x, y+rh), Vector2(x+BOX_W, y+rh), Color(0.28, 0.28, 0.38, 1.0), 1.0)
	_team_row(x, y+rh, rh, tb, b_wins)

	draw_rect(Rect2(x, y, BOX_W, BOX_H), Color(0.32, 0.32, 0.46, 0.85), false, 1.0)

func _team_row(x: float, y: float, h: float, team: Dictionary, is_winner: bool) -> void:
	if is_winner:
		draw_rect(Rect2(x, y, BOX_W, h), Color(0.22, 0.17, 0.01, 0.55))

	var tname: String
	var tcol:  Color
	if team.is_empty():
		tname = "TBD"
		tcol  = Color(0.4, 0.4, 0.4, 0.7)
	else:
		tname = team.get("name", "?") as String
		tcol  = team.get("color", Color(0.6, 0.6, 0.6)) as Color

	var col: Color = Color(1.0, 0.84, 0.18, 1.0) if is_winner else tcol

	var fs     := 11
	var ascent := _font.get_ascent(fs) if _font else 8.0
	var base_y := y + (h + ascent) * 0.5
	draw_string(_font, Vector2(x + 5.0, base_y), tname,
		HORIZONTAL_ALIGNMENT_LEFT, BOX_W - 10.0, fs, col)

# ── Column labels ──────────────────────────────────────────────────────────────

func _draw_labels() -> void:
	var fs  := 10
	var col := Color(0.62, 0.62, 0.70, 0.88)
	var cy  := 658.0
	var lbl := ["ROUND OF 16", "QUARTER FINAL", "SEMI FINAL", "FINAL",
				"SEMI FINAL", "QUARTER FINAL", "ROUND OF 16"]
	for i in range(7):
		var lx: float = CX[i] - 10.0
		draw_string(_font, Vector2(lx, cy), lbl[i],
			HORIZONTAL_ALIGNMENT_CENTER, BOX_W + 20.0, fs, col)
