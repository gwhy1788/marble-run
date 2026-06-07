extends Control

signal continue_pressed

@onready var _winner_label: Label  = $Panel/VBox/WinnerLabel
@onready var _score_label:  Label  = $Panel/VBox/ScoreLabel
@onready var _cont_btn:     Button = $Panel/VBox/ContinueBtn

var _advance_box: VBoxContainer

func _ready() -> void:
	_cont_btn.pressed.connect(func(): continue_pressed.emit())
	_advance_box = VBoxContainer.new()
	_advance_box.visible = false
	_advance_box.add_theme_constant_override("separation", 4)
	$Panel/VBox.add_child(_advance_box)
	$Panel/VBox.move_child(_advance_box, _cont_btn.get_index())

func _make_ls(size: int, col: Color) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font_size     = size
	ls.font_color    = col
	ls.outline_size  = 3
	ls.outline_color = Color(0.0, 0.0, 0.0, 0.9)
	ls.shadow_size   = 4
	ls.shadow_color  = Color(0.0, 0.0, 0.0, 0.45)
	ls.shadow_offset = Vector2(2.0, 2.0)
	return ls

func show_result(winner: Dictionary, score_a: int, score_b: int, is_final: bool, show_button: bool = true) -> void:
	if winner.is_empty():
		_winner_label.text = "DRAW"
		_winner_label.label_settings = _make_ls(30, Color(0.8, 0.8, 0.8, 1))
	else:
		var name: String = winner.get("name", "")
		var col:  Color  = winner.get("color", Color.WHITE)
		_winner_label.text = ("WORLD CHAMPION!\n" if is_final else "WINNER!\n") + name.to_upper()
		_winner_label.label_settings = _make_ls(30, col)
	_score_label.label_settings = _make_ls(40, Color(1, 1, 1, 1))
	_score_label.text    = "%d  -  %d" % [score_a, score_b]
	_cont_btn.text       = "Play Again" if is_final else "Continue"
	_cont_btn.visible    = show_button
	_advance_box.visible = false
	show()

func show_advancing(group_name: String, standings: Array) -> void:
	for c in _advance_box.get_children():
		c.queue_free()

	var sep := HSeparator.new()
	_advance_box.add_child(sep)

	var hdr := Label.new()
	hdr.text = "GROUP " + group_name + " ADVANCES"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	_advance_box.add_child(hdr)

	for rank in range(mini(2, standings.size())):
		var s: Dictionary    = standings[rank]
		var team: Dictionary = s.get("team", {})
		var tname: String    = team.get("name", "")
		var col: Color       = team.get("color", Color.WHITE)
		var pts: int         = int(s.get("pts", 0))
		var lbl := Label.new()
		lbl.text = "%d. %s  (%d pts)" % [rank + 1, tname, pts]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", col)
		_advance_box.add_child(lbl)

	_advance_box.visible = true
