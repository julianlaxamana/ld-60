extends CanvasLayer

# Autoloaded as "Dialogue". Shows the textbox at the bottom of the screen and
# types lines out one character at a time.
#
#   Dialogue.start(["Hello.", "It's late."])
#   await Dialogue.finished
#
# Interact (E) or ui_accept (Space/Enter) skips the typing, then advances.

signal finished

const TEXTBOX_SCENE := preload("res://Scenes/textbox.tscn")
const CHARS_PER_SECOND = 40.0
const BOTTOM_MARGIN = 24.0

var active := false

var _box: Control
var _label: Label
var _lines: Array = []
var _index := 0
var _shown := 0.0
# Frame the dialogue opened/closed on, so the key press that caused it
# doesn't also advance it or re-trigger whatever started it.
var _started_frame := -1
var _closed_frame := -1


func _ready() -> void:
	# The scenes' pixel/CRT effects sit on layer 1 and read the screen as it
	# was before that layer, so the box goes on layer 0 (with the world) to get
	# the effects applied. Max z_index keeps it above the world.
	layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = TEXTBOX_SCENE.instantiate()
	_label = _box.get_node("Label")
	_box.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	add_child(_box)
	_box.hide()


func start(lines: Array) -> void:
	if active or lines.is_empty():
		return
	active = true
	_lines = lines
	_index = 0
	_started_frame = Engine.get_process_frames()
	_place_box()
	_box.show()
	_show_line()


# True while dialogue is open, and on the frame it closed.
func is_busy() -> bool:
	return active or Engine.get_process_frames() == _closed_frame


func _process(delta: float) -> void:
	if not active:
		return

	var total := _label.get_total_character_count()
	if _label.visible_characters < total:
		_shown += CHARS_PER_SECOND * delta
		_label.visible_characters = mini(int(_shown), total)
	Sound.set_loop("speak", _label.visible_characters < total)

	if Engine.get_process_frames() == _started_frame:
		return
	if Input.is_action_just_pressed("Interact") or Input.is_action_just_pressed("ui_accept"):
		if _label.visible_characters < total:
			_label.visible_characters = total
		else:
			_advance()


func _advance() -> void:
	_index += 1
	if _index < _lines.size():
		_show_line()
		return
	active = false
	Sound.set_loop("speak", false)
	_closed_frame = Engine.get_process_frames()
	_box.hide()
	finished.emit()


func _show_line() -> void:
	_label.text = _lines[_index]
	_label.visible_characters = 0
	_shown = 0.0


func _place_box() -> void:
	var screen := get_viewport().get_visible_rect().size
	_box.position = Vector2((screen.x - _box.size.x) / 2.0, screen.y - _box.size.y - BOTTOM_MARGIN)
