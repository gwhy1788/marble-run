extends Control

signal start_match_requested

@onready var _container:  VBoxContainer = $ScrollContainer/Container
@onready var _start_btn:  Button        = $StartBtn
@onready var _title:      Label         = $Title

const TOTAL_GROUP_MATCHES := 48
const R16_IDX  := 48
const QF_IDX   := 56
const SF_IDX   := 60
const FIN_IDX  := 62

func _ready() -> void:
	_start_btn.pressed.connect(func(): start_match_requested.emit())

func refresh(matches: Array, current_idx: int, groups: Array) -> void:
	for c in _container.get_children():
		c.queue_free()

	if current_idx < TOTAL_GROUP_MATCHES:
		_show_group_stage(matches, current_idx, groups)
		_start_btn.visible = current_idx < matches.size()
		if current_idx < matches.size():
			var m: Dictionary    = matches[current_idx]
			var rnd: String      = m.get("round", "")
			_start_btn.text      = "Start %s Match" % rnd
			_title.text          = "Group Stage — %s" % rnd
	else:
		_show_knockout(matches, current_idx)
		var is_done: bool = current_idx >= matches.size()
		_start_btn.visible = not is_done
		if not is_done:
			var m: Dictionary = matches[current_idx]
			var rnd: String   = m.get("round", "")
			_start_btn.text   = "Start %s Match" % rnd
			_title.text       = "World Cup — %s" % rnd
		else:
			_title.text = "Tournament Complete!"

# ── Group Stage ────────────────────────────────────────────────────────────────

func _show_group_stage(matches: Array, current_idx: int, groups: Array) -> void:
	var current_group: int = -1
	if current_idx < matches.size():
		current_group = int(matches[current_idx].get("group", -1))

	for g_idx in range(groups.size()):
		var gd: Dictionary  = groups[g_idx]
		var g_name: String  = gd.get("name", "?")
		var g_teams: Array  = gd.get("teams", [])
		var is_active: bool = g_idx == current_group

		_add_header("GROUP " + g_name + (" ▶" if is_active else ""))
		_add_group_header_row()

		var standings: Array = _compute_standings(matches, g_teams, g_idx)
		for rank in range(standings.size()):
			_add_standings_row(standings[rank], rank < 2, is_active)

func _compute_standings(matches: Array, group_teams: Array, group_idx: int) -> Array:
	var standings: Array = []
	for t in group_teams:
		standings.append({"team": t, "p": 0, "w": 0, "d": 0, "l": 0,
				"gf": 0, "ga": 0, "gd": 0, "pts": 0})

	for m in matches:
		var md: Dictionary = m
		if int(md.get("group", -1)) != group_idx:
			continue
		var is_draw: bool      = md.get("is_draw", false)
		var winner: Dictionary = md.get("winner", {})
		if winner.is_empty() and not is_draw:
			continue

		var sa: int          = int(md.get("score_a", 0))
		var sb: int          = int(md.get("score_b", 0))
		var ta_name: String  = (md.get("team_a", {}) as Dictionary).get("name", "")
		var tb_name: String  = (md.get("team_b", {}) as Dictionary).get("name", "")
		var win_name: String = winner.get("name", "")

		for s in standings:
			var sd: Dictionary = s
			var sname: String  = (sd.get("team", {}) as Dictionary).get("name", "")
			var is_a: bool     = sname == ta_name
			var is_b: bool     = sname == tb_name
			if not (is_a or is_b):
				continue
			var fg: int = sa if is_a else sb
			var ag: int = sb if is_a else sa
			sd["p"]  = int(sd.get("p",  0)) + 1
			sd["gf"] = int(sd.get("gf", 0)) + fg
			sd["ga"] = int(sd.get("ga", 0)) + ag
			if is_draw:
				sd["pts"] = int(sd.get("pts", 0)) + 1
				sd["d"]   = int(sd.get("d",   0)) + 1
			elif win_name == sname:
				sd["pts"] = int(sd.get("pts", 0)) + 3
				sd["w"]   = int(sd.get("w",   0)) + 1
			else:
				sd["l"] = int(sd.get("l", 0)) + 1

	for s in standings:
		var sd: Dictionary = s
		sd["gd"] = int(sd.get("gf", 0)) - int(sd.get("ga", 0))

	standings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: int = int(a.get("pts", 0)); var pb: int = int(b.get("pts", 0))
		if pa != pb: return pa > pb
		var da: int = int(a.get("gd", 0)); var db: int = int(b.get("gd", 0))
		if da != db: return da > db
		return int(a.get("gf", 0)) > int(b.get("gf", 0))
	)
	return standings

func _add_group_header_row() -> void:
	var row := HBoxContainer.new()
	_cell(row, "Team",  136, true, Color(0.75, 0.75, 0.75, 1))
	_cell(row, "P",  28, true, Color(0.75, 0.75, 0.75, 1))
	_cell(row, "W",  28, true, Color(0.75, 0.75, 0.75, 1))
	_cell(row, "D",  28, true, Color(0.75, 0.75, 0.75, 1))
	_cell(row, "L",  28, true, Color(0.75, 0.75, 0.75, 1))
	_cell(row, "GD", 32, true, Color(0.75, 0.75, 0.75, 1))
	_cell(row, "Pts",32, true, Color(0.75, 0.75, 0.75, 1))
	_container.add_child(row)

func _add_standings_row(s: Dictionary, qualifies: bool, group_active: bool) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 20)

	var team: Dictionary = s.get("team", {})
	var tname: String    = team.get("name", "?")
	var tcol: Color      = team.get("color", Color.GRAY)
	if tname.length() > 12:
		tname = tname.substr(0, 12)

	var name_col: Color = Color.YELLOW if qualifies else (tcol if group_active else Color(tcol.r, tcol.g, tcol.b, 0.65))
	_cell(row, tname, 136, false, name_col)

	var stats: Array = ["p", "w", "d", "l", "gd", "pts"]
	var widths: Array = [28, 28, 28, 28, 32, 32]
	for i in range(stats.size()):
		var val: int = int(s.get(stats[i], 0))
		var val_col: Color = Color(1, 1, 1, 1) if qualifies else Color(0.8, 0.8, 0.8, 1)
		_cell(row, str(val), widths[i], false, val_col)

	_container.add_child(row)

func _cell(parent: HBoxContainer, text: String, width: int, bold: bool, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(width, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11 if bold else 12)
	lbl.add_theme_color_override("font_color", col)
	parent.add_child(lbl)

# ── Knockout ───────────────────────────────────────────────────────────────────

func _show_knockout(matches: Array, current_idx: int) -> void:
	var rounds: Array = [
		{"label": "ROUND OF 16",   "start": R16_IDX, "count": 8},
		{"label": "QUARTER FINALS","start": QF_IDX,  "count": 4},
		{"label": "SEMI FINALS",   "start": SF_IDX,  "count": 2},
		{"label": "FINAL",         "start": FIN_IDX, "count": 1},
	]
	for rnd in rounds:
		var label: String = rnd.get("label", "")
		var start: int    = int(rnd.get("start", 0))
		var count: int    = int(rnd.get("count", 0))
		_add_header(label)
		for i in range(count):
			var idx: int = start + i
			if idx < matches.size():
				_add_match_row(matches[idx], idx, current_idx)

func _add_match_row(m: Dictionary, idx: int, current_idx: int) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(0, 50)

	var team_a: Dictionary = m.get("team_a", {})
	var team_b: Dictionary = m.get("team_b", {})
	var winner: Dictionary = m.get("winner", {})
	var score_a: int       = m.get("score_a", 0)
	var score_b: int       = m.get("score_b", 0)
	var played: bool       = not winner.is_empty()
	var is_current: bool   = idx == current_idx

	var a_lbl := _team_label(team_a, played and winner == team_a)
	a_lbl.custom_minimum_size = Vector2(180, 0)
	a_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var vs_lbl := Label.new()
	vs_lbl.text = "  %d – %d  " % [score_a, score_b] if played else "  vs  "
	vs_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vs_lbl.add_theme_font_size_override("font_size", 16)

	var b_lbl := _team_label(team_b, played and winner == team_b)
	b_lbl.custom_minimum_size = Vector2(180, 0)
	b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	row.add_child(a_lbl)
	row.add_child(vs_lbl)
	row.add_child(b_lbl)

	if is_current:
		var bg := ColorRect.new()
		bg.color = Color(1, 1, 0, 0.08)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_child(bg)
		row.move_child(bg, 0)

	_container.add_child(row)

# ── Shared helpers ─────────────────────────────────────────────────────────────

func _add_header(text: String) -> void:
	var sep := HSeparator.new()
	_container.add_child(sep)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_container.add_child(lbl)

func _team_label(team: Dictionary, is_winner: bool) -> Label:
	var lbl := Label.new()
	lbl.text = team.get("name", "TBD")
	var col: Color = team.get("color", Color.GRAY)
	lbl.add_theme_color_override("font_color", Color.YELLOW if is_winner else col)
	lbl.add_theme_font_size_override("font_size", 16)
	return lbl
