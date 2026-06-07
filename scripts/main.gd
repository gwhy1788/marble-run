extends Node

const Countries      := preload("res://scripts/countries.gd")
const GameFieldScene := preload("res://scenes/GameField.tscn")

@onready var _game_container: Node2D  = $GameContainer
@onready var _menu_panel:     Control  = $UI/MenuPanel
@onready var _bracket_panel             = $UI/BracketPanel
@onready var _hud                       = $UI/HUD
@onready var _result_panel              = $UI/MatchResult
@onready var _champion_panel: Control  = $UI/ChampionPanel
@onready var _champ_label:    Label    = $UI/ChampionPanel/ChampLabel
@onready var _play_again_btn: Button   = $UI/ChampionPanel/PlayAgainBtn
@onready var _start_btn:      Button   = $UI/MenuPanel/StartBtn

# Match index boundaries
const TOTAL_GROUP_MATCHES := 48   # 8 groups × 6 matches
const MATCHES_PER_GROUP   := 6
const R16_IDX  := 48
const QF_IDX   := 56
const SF_IDX   := 60
const FIN_IDX  := 62
const AUTO_ADVANCE_DELAY  := 3.0  # seconds before next match auto-starts
const GROUP_ADVANCE_DELAY := 5.0  # longer pause to read advancing-teams panel

var _teams: Array   = []
var _groups: Array  = []   # Array[{name, teams:[4 dicts]}]
var _matches: Array = []   # All matches (48 group + up to 15 knockout)
var _current_idx: int = 0
var _game_field = null
var _group_result_panel: Control
var _group_result_box:   VBoxContainer

func _ready() -> void:
	_start_btn.pressed.connect(_on_start_pressed)
	_play_again_btn.pressed.connect(_reset)
	_bracket_panel.start_match_requested.connect(_on_bracket_start)
	_result_panel.continue_pressed.connect(_on_result_continue)
	_build_group_result_panel()
	_style_static_labels()
	_show_menu()

func _style_static_labels() -> void:
	_apply_ls($UI/MenuPanel/Title,          52, Color(1.0, 0.85, 0.1, 1.0), 5)
	_apply_ls($UI/ChampionPanel/Trophy,     72, Color(1.0, 0.85, 0.1, 1.0), 6)

func _apply_ls(node: Label, size: int, col: Color, outline: int) -> void:
	var ls := LabelSettings.new()
	ls.font_size     = size
	ls.font_color    = col
	ls.outline_size  = outline
	ls.outline_color = Color(0.0, 0.0, 0.0, 0.9)
	ls.shadow_size   = int(outline * 1.5)
	ls.shadow_color  = Color(0.0, 0.0, 0.0, 0.45)
	ls.shadow_offset = Vector2(3.0, 3.0)
	node.label_settings = ls

func _process(_delta: float) -> void:
	if _game_field != null and _hud.visible:
		_hud.update_timer(_game_field.time_left, _game_field.is_sudden_death)

# ── State transitions ──────────────────────────────────────────────────────────

func _show_menu() -> void:
	_hide_all()
	_menu_panel.show()

func _show_bracket() -> void:
	_hide_all()
	_bracket_panel.show()
	_bracket_panel.refresh(_matches, _current_idx, _groups)

func _show_match() -> void:
	var m: Dictionary      = _matches[_current_idx]
	var team_a: Dictionary = m.get("team_a", {})
	var team_b: Dictionary = m.get("team_b", {})
	var is_group: bool     = m.get("stage", "group") == "group"

	_hide_all()
	_hud.show()
	_hud.setup(team_a, team_b)

	if _game_field:
		_game_field.queue_free()
		_game_field = null

	_game_field = GameFieldScene.instantiate()
	_game_container.add_child(_game_field)
	_game_field.setup(team_a, team_b)
	_game_field.allow_draw = is_group
	if is_group:
		var g_idx: int       = int(m.get("group", 0))
		var g_name: String   = (_groups[g_idx] as Dictionary).get("name", "")
		var standings: Array = _get_group_standings(g_idx)
		_hud.show_group_standings(g_name, standings)
		_hud.set_round_label("")
	else:
		_hud.hide_group_standings()
		var round_label: String = ""
		if _current_idx < QF_IDX:
			round_label = "ROUND OF 16"
		elif _current_idx < SF_IDX:
			round_label = "QUARTER FINAL"
		elif _current_idx < FIN_IDX:
			round_label = "SEMI FINAL"
		else:
			round_label = "FINAL"
		_hud.set_round_label(round_label)
	_game_field.goal_scored.connect(_on_goal_scored)
	_game_field.match_finished.connect(_on_match_finished)
	_game_field.match_drawn.connect(_on_match_drawn)
	_game_field.start_match()

func _show_result(winner: Dictionary, sa: int, sb: int, show_button: bool = true) -> void:
	_hud.show()
	_result_panel.show_result(winner, sa, sb, _current_idx == FIN_IDX, show_button)

func _show_champion(team: Dictionary) -> void:
	_hide_all()
	if _game_field:
		_game_field.queue_free()
		_game_field = null
	_champion_panel.show()
	var team_name: String  = team.get("name", "")
	var team_color: Color  = team.get("color", Color.YELLOW)
	_champ_label.text = team_name.to_upper() + "\nARE THE\nWORLD CHAMPIONS!"
	_apply_ls(_champ_label, 38, team_color, 4)

# ── Signal handlers ────────────────────────────────────────────────────────────

func _on_start_pressed() -> void:
	_init_tournament()
	_show_match()

func _on_bracket_start() -> void:
	_show_match()

func _on_goal_scored(team_idx: int, sa: int, sb: int) -> void:
	_hud.update_score(team_idx, sa, sb)

func _on_match_finished(winner_id: int, sa: int, sb: int) -> void:
	var m: Dictionary      = _matches[_current_idx]
	var winner: Dictionary = m.get("team_a", {}) if winner_id == 0 else m.get("team_b", {})
	m["winner"]  = winner
	m["score_a"] = sa
	m["score_b"] = sb
	m["is_draw"] = false
	_advance_round_if_complete()
	var group_end: bool = _is_group_end()
	_show_result(winner, sa, sb, false)
	if group_end:
		var g_idx: int       = int(m.get("group", 0))
		var g_name: String   = (_groups[g_idx] as Dictionary).get("name", "")
		var standings: Array = _get_group_standings(g_idx)
		get_tree().create_timer(AUTO_ADVANCE_DELAY).timeout.connect(func() -> void:
			_result_panel.hide()
			_show_group_result(g_name, standings)
			get_tree().create_timer(GROUP_ADVANCE_DELAY).timeout.connect(_auto_advance_match)
		)
	else:
		get_tree().create_timer(AUTO_ADVANCE_DELAY).timeout.connect(_auto_advance_match)

func _on_match_drawn(sa: int, sb: int) -> void:
	var m: Dictionary = _matches[_current_idx]
	m["winner"]  = {}
	m["score_a"] = sa
	m["score_b"] = sb
	m["is_draw"] = true
	_advance_round_if_complete()
	var group_end: bool = _is_group_end()
	_show_result({}, sa, sb, false)
	if group_end:
		var g_idx: int       = int(m.get("group", 0))
		var g_name: String   = (_groups[g_idx] as Dictionary).get("name", "")
		var standings: Array = _get_group_standings(g_idx)
		get_tree().create_timer(AUTO_ADVANCE_DELAY).timeout.connect(func() -> void:
			_result_panel.hide()
			_show_group_result(g_name, standings)
			get_tree().create_timer(GROUP_ADVANCE_DELAY).timeout.connect(_auto_advance_match)
		)
	else:
		get_tree().create_timer(AUTO_ADVANCE_DELAY).timeout.connect(_auto_advance_match)

func _on_result_continue() -> void:
	_result_panel.hide()
	_current_idx += 1
	if _current_idx >= _matches.size():
		var last: Dictionary  = _matches.back()
		var champ: Dictionary = last.get("winner", {})
		_show_champion(champ)
	else:
		_show_match()

func _auto_advance_match() -> void:
	_result_panel.hide()
	_group_result_panel.hide()
	_current_idx += 1
	if _current_idx >= _matches.size():
		var last: Dictionary  = _matches.back()
		var champ: Dictionary = last.get("winner", {})
		_show_champion(champ)
	else:
		_show_match()

func _is_group_end() -> bool:
	return _current_idx < TOTAL_GROUP_MATCHES and \
		   (_current_idx % MATCHES_PER_GROUP) == (MATCHES_PER_GROUP - 1)


# ── Tournament logic ───────────────────────────────────────────────────────────

func _init_tournament() -> void:
	_teams   = Countries.TEAMS.duplicate(true)
	_groups  = []
	_matches = []
	_current_idx = 0

	var g_idx: int = 0
	for g_data in Countries.GROUPS:
		var g_name: String   = g_data.get("name", "")
		var g_indices: Array = g_data.get("teams", [])
		var g_teams: Array   = []
		for raw_i in g_indices:
			g_teams.append(_teams[int(raw_i)])
		_groups.append({"name": g_name, "teams": g_teams})

		for sched in Countries.GROUP_SCHEDULE:
			var ia: int = int(sched[0])
			var ib: int = int(sched[1])
			_matches.append({
				"team_a":  g_teams[ia],
				"team_b":  g_teams[ib],
				"winner":  {},
				"score_a": 0,
				"score_b": 0,
				"is_draw": false,
				"round":   "Group " + g_name,
				"group":   g_idx,
				"stage":   "group",
			})
		g_idx += 1

func _advance_round_if_complete() -> void:
	if _current_idx == TOTAL_GROUP_MATCHES - 1:
		_build_round_of_16()
	elif _current_idx == QF_IDX - 1:
		_build_quarter_finals()
	elif _current_idx == SF_IDX - 1:
		_build_semi_finals()
	elif _current_idx == FIN_IDX - 1:
		_build_final()

func _build_round_of_16() -> void:
	# qualifiers[0]=A1, [1]=A2, [2]=B1, [3]=B2 ... [14]=H1, [15]=H2
	var qualifiers: Array = []
	for g in range(8):
		var st: Array = _get_group_standings(g)
		qualifiers.append((st[0] as Dictionary).get("team", {}))
		qualifiers.append((st[1] as Dictionary).get("team", {}))

	# Standard WC bracket pairing
	var pairs: Array = [
		[0, 3], [4, 7], [2, 1], [6, 5],
		[8, 11], [12, 15], [10, 9], [14, 13],
	]
	for pair in pairs:
		_matches.append({
			"team_a": qualifiers[int(pair[0])],
			"team_b": qualifiers[int(pair[1])],
			"winner": {}, "score_a": 0, "score_b": 0,
			"is_draw": false, "round": "Round of 16", "stage": "knockout",
		})

func _build_quarter_finals() -> void:
	for i in range(0, 8, 2):
		var wa: Dictionary = (_matches[R16_IDX + i]     as Dictionary).get("winner", {})
		var wb: Dictionary = (_matches[R16_IDX + i + 1] as Dictionary).get("winner", {})
		_matches.append({
			"team_a": wa, "team_b": wb,
			"winner": {}, "score_a": 0, "score_b": 0,
			"is_draw": false, "round": "Quarter Final", "stage": "knockout",
		})

func _build_semi_finals() -> void:
	for i in range(0, 4, 2):
		var wa: Dictionary = (_matches[QF_IDX + i]     as Dictionary).get("winner", {})
		var wb: Dictionary = (_matches[QF_IDX + i + 1] as Dictionary).get("winner", {})
		_matches.append({
			"team_a": wa, "team_b": wb,
			"winner": {}, "score_a": 0, "score_b": 0,
			"is_draw": false, "round": "Semi Final", "stage": "knockout",
		})

func _build_final() -> void:
	var w0: Dictionary = (_matches[SF_IDX]     as Dictionary).get("winner", {})
	var w1: Dictionary = (_matches[SF_IDX + 1] as Dictionary).get("winner", {})
	_matches.append({
		"team_a": w0, "team_b": w1,
		"winner": {}, "score_a": 0, "score_b": 0,
		"is_draw": false, "round": "Final", "stage": "knockout",
	})

func _get_group_standings(group_idx: int) -> Array:
	var gd: Dictionary  = _groups[group_idx]
	var g_teams: Array  = gd.get("teams", [])
	var standings: Array = []
	for t in g_teams:
		standings.append({"team": t, "p": 0, "w": 0, "d": 0, "l": 0,
				"gf": 0, "ga": 0, "gd": 0, "pts": 0})

	for m in _matches:
		var md: Dictionary = m
		if int(md.get("group", -1)) != group_idx:
			continue
		var is_draw: bool      = md.get("is_draw", false)
		var winner: Dictionary = md.get("winner", {})
		if winner.is_empty() and not is_draw:
			continue

		var sa: int         = int(md.get("score_a", 0))
		var sb: int         = int(md.get("score_b", 0))
		var ta_name: String = (md.get("team_a", {}) as Dictionary).get("name", "")
		var tb_name: String = (md.get("team_b", {}) as Dictionary).get("name", "")
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
		var pa: int = int(a.get("pts", 0))
		var pb: int = int(b.get("pts", 0))
		if pa != pb: return pa > pb
		var da: int = int(a.get("gd", 0))
		var db: int = int(b.get("gd", 0))
		if da != db: return da > db
		return int(a.get("gf", 0)) > int(b.get("gf", 0))
	)
	return standings

func _reset() -> void:
	if _game_field:
		_game_field.queue_free()
		_game_field = null
	_show_menu()

# ── Group standings panel ──────────────────────────────────────────────────────

func _build_group_result_panel() -> void:
	_group_result_panel = Control.new()
	_group_result_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_group_result_panel.visible = false
	$UI.add_child(_group_result_panel)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_group_result_panel.add_child(overlay)

	var card := ColorRect.new()
	card.color = Color(0.06, 0.10, 0.06, 0.97)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left   = -230.0
	card.offset_right  =  230.0
	card.offset_top    = -175.0
	card.offset_bottom =  175.0
	_group_result_panel.add_child(card)

	_group_result_box = VBoxContainer.new()
	_group_result_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_group_result_box.offset_left   =  14.0
	_group_result_box.offset_top    =  10.0
	_group_result_box.offset_right  = -14.0
	_group_result_box.offset_bottom = -10.0
	_group_result_box.add_theme_constant_override("separation", 4)
	card.add_child(_group_result_box)

func _show_group_result(g_name: String, standings: Array) -> void:
	for c in _group_result_box.get_children():
		c.queue_free()

	var title := Label.new()
	title.text = "GROUP " + g_name + "  —  FINAL STANDINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	_group_result_box.add_child(title)

	_group_result_box.add_child(HSeparator.new())

	var hdr := HBoxContainer.new()
	_gr_cell(hdr, "Team", 170, Color(0.7, 0.7, 0.7, 1.0), true)
	for col_name in ["W", "D", "L", "GD", "Pts"]:
		_gr_cell(hdr, col_name, 44, Color(0.7, 0.7, 0.7, 1.0), true)
	_group_result_box.add_child(hdr)

	for rank in range(standings.size()):
		var s: Dictionary    = standings[rank]
		var team: Dictionary = s.get("team", {})
		var tname: String    = team.get("name", "")
		var tcol: Color      = team.get("color", Color.GRAY)
		var qualifies: bool  = rank < 2

		var name_col: Color = tcol if qualifies else Color(tcol.r, tcol.g, tcol.b, 0.6)
		var pts_col:  Color = Color(0.25, 1.0, 0.45, 1.0) if qualifies else Color(1.0, 1.0, 1.0, 1.0)
		var val_col:  Color = Color(1.0, 1.0, 1.0, 1.0) if qualifies else Color(0.72, 0.72, 0.72, 1.0)

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 30)
		_gr_cell(row, tname,                     170, name_col, false)
		_gr_cell(row, str(int(s.get("w",  0))),   44, val_col,  false)
		_gr_cell(row, str(int(s.get("d",  0))),   44, val_col,  false)
		_gr_cell(row, str(int(s.get("l",  0))),   44, val_col,  false)
		_gr_cell(row, str(int(s.get("gd", 0))),   44, val_col,  false)
		_gr_cell(row, str(int(s.get("pts",0))),   44, pts_col,  false)
		_group_result_box.add_child(row)

		if rank == 1:
			_group_result_box.add_child(HSeparator.new())

	_group_result_panel.show()

func _gr_cell(parent: HBoxContainer, text: String, width: int,
		col: Color, bold: bool) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(width, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12 if bold else 15)
	lbl.add_theme_color_override("font_color", col)
	parent.add_child(lbl)

func _hide_all() -> void:
	_menu_panel.hide()
	_bracket_panel.hide()
	_hud.hide()
	_result_panel.hide()
	_champion_panel.hide()
	if _group_result_panel:
		_group_result_panel.hide()
