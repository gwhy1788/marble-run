extends Control

@onready var _team_a_name: Label = $TeamAName
@onready var _team_b_name: Label = $TeamBName
@onready var _score_a:     Label = $ScoreRow/ScoreA
@onready var _score_b:     Label = $ScoreRow/ScoreB
@onready var _timer_label: Label = $TimerLabel
@onready var _sd_label:    Label = $SuddenDeathLabel

var _std_panel:   Control
var _std_box:     VBoxContainer
var _round_label: Label
var _timer_ls:    LabelSettings

func _ready() -> void:
	_build_standings_panel()
	_build_round_label()
	_apply_fancy_text()

func _make_ls(size: int, col: Color, outline: int = 2) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font_size      = size
	ls.font_color     = col
	ls.outline_size   = outline
	ls.outline_color  = Color(0.0, 0.0, 0.0, 0.88)
	ls.shadow_size    = 3
	ls.shadow_color   = Color(0.0, 0.0, 0.0, 0.45)
	ls.shadow_offset  = Vector2(2.0, 2.0)
	return ls

func _apply_fancy_text() -> void:
	_score_a.label_settings = _make_ls(32, Color(1, 1, 1, 1), 3)
	_score_b.label_settings = _make_ls(32, Color(1, 1, 1, 1), 3)
	_timer_ls = _make_ls(18, Color(1, 1, 1, 1), 2)
	_timer_label.label_settings = _timer_ls
	# Move sudden death label below the timer and style it
	_sd_label.offset_top    = 93.0
	_sd_label.offset_bottom = 117.0
	_sd_label.label_settings = _make_ls(16, Color(1.0, 0.22, 0.22, 1.0), 2)

func _build_round_label() -> void:
	_round_label = Label.new()
	_round_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_round_label.offset_left   = -200.0
	_round_label.offset_right  =  200.0
	_round_label.offset_bottom =  -12.0
	_round_label.offset_top    =  -46.0
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.label_settings = _make_ls(16, Color(1.0, 0.85, 0.2, 1.0), 2)
	_round_label.visible = false
	add_child(_round_label)

func set_round_label(text: String) -> void:
	_round_label.text    = text
	_round_label.visible = text != ""

func _build_standings_panel() -> void:
	_std_panel = Control.new()
	_std_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_std_panel.offset_left   = 8.0
	_std_panel.offset_top    = 63.0
	_std_panel.offset_right  = 218.0
	_std_panel.offset_bottom = 185.0
	_std_panel.visible = false
	add_child(_std_panel)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.72)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_std_panel.add_child(bg)

	_std_box = VBoxContainer.new()
	_std_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_std_box.offset_left   = 6.0
	_std_box.offset_top    = 4.0
	_std_box.offset_right  = -6.0
	_std_box.offset_bottom = -4.0
	_std_box.add_theme_constant_override("separation", 1)
	_std_panel.add_child(_std_box)

func show_group_standings(group_name: String, standings: Array) -> void:
	for c in _std_box.get_children():
		c.queue_free()

	# Header
	var hdr := Label.new()
	hdr.text = "GROUP " + group_name
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	_std_box.add_child(hdr)

	var sep := HSeparator.new()
	_std_box.add_child(sep)

	# Column labels
	var col_hdr := HBoxContainer.new()
	_std_cell(col_hdr, "",    44, Color(0.65, 0.65, 0.65, 1), 10, HORIZONTAL_ALIGNMENT_LEFT)
	_std_cell(col_hdr, "W",   24, Color(0.65, 0.65, 0.65, 1), 10, HORIZONTAL_ALIGNMENT_CENTER)
	_std_cell(col_hdr, "D",   24, Color(0.65, 0.65, 0.65, 1), 10, HORIZONTAL_ALIGNMENT_CENTER)
	_std_cell(col_hdr, "L",   24, Color(0.65, 0.65, 0.65, 1), 10, HORIZONTAL_ALIGNMENT_CENTER)
	_std_cell(col_hdr, "GD",  26, Color(0.65, 0.65, 0.65, 1), 10, HORIZONTAL_ALIGNMENT_CENTER)
	_std_cell(col_hdr, "Pts", 30, Color(0.65, 0.65, 0.65, 1), 10, HORIZONTAL_ALIGNMENT_CENTER)
	_std_box.add_child(col_hdr)

	# Team rows
	for rank in range(standings.size()):
		var s: Dictionary    = standings[rank]
		var team: Dictionary = s.get("team", {})
		var abbr: String     = team.get("abbr", "???")
		var tcol: Color      = team.get("color", Color.GRAY)
		var qualifies: bool  = rank < 2

		var name_col: Color = tcol
		var pts_col:  Color = Color(0.25, 1, 0.45, 1) if qualifies else Color(1, 1, 1, 1)

		var row := HBoxContainer.new()
		_std_cell(row, abbr,                         44, name_col, 12, HORIZONTAL_ALIGNMENT_LEFT)
		_std_cell(row, str(int(s.get("w",   0))),    24, Color(1, 1, 1, 1), 12, HORIZONTAL_ALIGNMENT_CENTER)
		_std_cell(row, str(int(s.get("d",   0))),    24, Color(1, 1, 1, 1), 12, HORIZONTAL_ALIGNMENT_CENTER)
		_std_cell(row, str(int(s.get("l",   0))),    24, Color(1, 1, 1, 1), 12, HORIZONTAL_ALIGNMENT_CENTER)
		_std_cell(row, str(int(s.get("gd",  0))),    26, Color(1, 1, 1, 1), 12, HORIZONTAL_ALIGNMENT_CENTER)
		_std_cell(row, str(int(s.get("pts", 0))),    30, pts_col,            12, HORIZONTAL_ALIGNMENT_CENTER)
		_std_box.add_child(row)

	_std_panel.visible = true

func hide_group_standings() -> void:
	_std_panel.visible = false

func _std_cell(parent: HBoxContainer, text: String, width: int,
		col: Color, font_size: int, align: HorizontalAlignment) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(width, 0)
	lbl.horizontal_alignment = align
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", col)
	parent.add_child(lbl)

func setup(team_a: Dictionary, team_b: Dictionary) -> void:
	_team_a_name.text = team_a.get("name", "") as String
	var col_a: Color = team_a.get("color", Color.WHITE)
	_team_a_name.label_settings = _make_ls(20, col_a, 2)
	_team_b_name.text = team_b.get("name", "") as String
	var col_b: Color = team_b.get("color", Color.WHITE)
	_team_b_name.label_settings = _make_ls(20, col_b, 2)
	update_score(0, 0, 0)
	_sd_label.visible = false

func update_score(team_idx: int, score_a: int, score_b: int) -> void:
	_score_a.text = str(score_a)
	_score_b.text = str(score_b)
	var flash: Label = _score_a if team_idx == 0 else _score_b
	_flash(flash)

func update_timer(secs: float, is_sd: bool) -> void:
	var t: float = maxf(0.0, secs)
	var mins: int = int(t) / 60
	var s: int    = int(t) % 60
	_timer_label.text = "%d:%02d" % [mins, s]
	_sd_label.visible = is_sd
	_timer_ls.font_color = Color.RED if (is_sd or t < 10.0) else Color.WHITE

func _flash(label: Label) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
