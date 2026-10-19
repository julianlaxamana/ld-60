extends CanvasLayer

# Autoloaded as "Day". Tracks which day of the loop it is, what the player has
# done so far today, and all the writing that changes from day to day.
#
#   Dialogue.start(Day.lines("note"))
#   Day.end_day()      # fade out, wake up in bed the next morning
#
# Debug builds: F9 skips to the next day.

signal faded_in

const BEDROOM := "res://Scenes/map.tscn"
const TITLE := "res://Scenes/title_screen.tscn"
const LAST_DAY := 4
const FADE_TIME = 0.8
const CARD_TIME = 1.6
const ENDING_LINE_TIME = 3.0
const GLITCH_FLICKERS = 8

const DoorScript := preload("res://Scripts/door.gd")
const WakeUpScript := preload("res://Scripts/wake_up.gd")
const SpiderGateScript := preload("res://Scripts/spider_gate.gd")

# The house gets darker and dirtier each day. Applied to every room with a
# player in it.
const TINTS: Array[Color] = [
	Color(1, 1, 1),
	Color(0.86, 0.8, 0.72),
	Color(0.68, 0.6, 0.54),
	Color(0.52, 0.44, 0.44),
]

const FOOD_TEXTURES: Array = [
	preload("res://Sprites/inventory items/inventory item food.png"),
	preload("res://Sprites/inventory items/inventory item food day 2.png"),
	preload("res://Sprites/inventory items/inventory item food day 3.png"),
	null,
]

const TAPE_TEXTURES: Array = [
	preload("res://Sprites/inventory items/day 1 tape.png"),
	preload("res://Sprites/inventory items/day 2 tape.png"),
	preload("res://Sprites/inventory items/day 3 tape.png"),
	preload("res://Sprites/inventory items/final tape.png"),
]

# All the per-day writing, one dictionary per day. A key a day leaves out
# falls back to the latest earlier day that has it, so later days only need
# what changes.
const TEXT: Array[Dictionary] = [
	# Day 1: everything looks normal.
	{
		"wake": [],
		"note": [
			"A note from Mom.",
			"\"Out for the day. Food's on the table. Be good. Home by dark. Love you.\"",
		],
		"food_take": ["Breakfast. Still warm.", "You took the plate."],
		"table_empty": ["Just the table."],
		"tv_off": ["The TV is off.", "Where's my tape?"],
		"tape": ["My favorite tape.", "You put it in. The screen fills with static."],
		"static": [
			"Static.",
			"It's not broken. This is the best part.",
		],
		"couch": ["My spot."],
		"food_refuse": ["I'm not eating without my tape on."],
		"eat": ["You start eating."],
		"eye": [
			"...",
			"Hello.",
			"There are monsters in the forest.",
			"They took all of it. The river. The well. The farm, too.",
			"Your mother comes home at night.",
			"Kill them before she does.",
			"Take the knife.",
		],
		"tv_after": ["The screen is black.", "It's still watching."],
		"couch_after": ["The plate is empty."],
		"knife_locked": ["Mom doesn't let me touch the knives."],
		"knife_take": ["You took the knife."],
		"outside_locked": ["I'm not going out there with nothing."],
		"boss": [
			"Something is waiting at the farm gate.",
			"It's bigger than the others.",
		],
		"kitchen_locked": [],
	},
	# Day 2: food is stale, house is worse.
	{
		"wake": ["...", "Didn't I already do today?"],
		"note": [
			"A note from Mom.",
			"\"Out for the day. Food's on the table. Be good. Home by dark.\"",
			"The paper's gone soft.",
		],
		"food_take": ["Breakfast. It's cold.", "You took the plate anyway."],
		"tape": ["My favorite tape. The label's peeling.", "You put it in. Static."],
		"static": ["Static.", "It sounds different today. Louder."],
		"eat": ["It's stale.", "You eat it anyway."],
		"eye": [
			"You didn't finish.",
			"They're still out there. More of them now.",
			"She's coming home tonight.",
			"Go.",
		],
		"tv_after": ["Black.", "You can hear breathing behind the glass."],
		"knife_take": ["You took the knife.", "There's something dried on the handle."],
		"boss": ["It's here again.", "It was here yesterday too."],
	},
	# Day 3: food is rotten, the water is black.
	{
		"wake": ["Again."],
		"note": [
			"A note.",
			"\"Out for the day. Food's on the table.\"",
			"The rest is too stained to read.",
		],
		"food_take": ["It smells.", "You took the plate."],
		"tape": ["My tape.", "You push it in. It takes a few tries."],
		"static": ["Static.", "If you look long enough, there's a face in it."],
		"eat": ["It's rotten.", "You eat it.", "Mom made it. You have to."],
		"eye": [
			"Faster.",
			"The farm is where they come from.",
			"Don't look at them too long.",
			"They'll try to look like people.",
		],
		"tv_after": ["The screen is black.", "There's a crack you don't remember."],
		"knife_take": ["You took the knife.", "It's heavier than yesterday."],
		"outside_locked": ["Not without the knife."],
		"boss": ["It's always here.", "It always wins."],
	},
	# Day 4: the last day. No food, no going out. Just the tape.
	{
		"wake": ["...", "So hungry."],
		"tv_off": ["The TV is off.", "There's one tape left."],
		"tape": ["A tape you've never seen.", "You put it in."],
		"couch": ["Dust everywhere.", "How long has it been like this?"],
		"final_tape": [
			"...",
			"The farm next door sold us food every week.",
			"Grandma got sick first.",
			"Then Mom.",
			"Mom isn't coming home tonight.",
			"She hasn't come home in a long time.",
		],
		"ending": [
			"There were never any monsters.",
			"Only her.",
		],
		"outside_locked": ["The door won't open."],
		"kitchen_locked": ["You can't go in there.", "You don't want to."],
	},
]

var day := 1

# Today's progress. Cleared every morning.
var read_note := false
var has_food := false
var tape_in := false
var ate := false
var eye_spoke := false

var _busy := false
var _tinted_scene: Node

var _black: ColorRect
var _label: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.modulate.a = 0.0
	add_child(_black)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 40)
	_black.add_child(_label)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _tinted_scene:
		_tinted_scene = scene
		_tint(scene)


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_F9:
		end_day()


# Today's lines for `key`, or the latest earlier day's if today has none.
func lines(key: String) -> Array:
	for i in range(mini(day, TEXT.size()) - 1, -1, -1):
		if TEXT[i].has(key):
			return TEXT[i][key]
	return []


func is_last_day() -> bool:
	return day >= LAST_DAY


func food_texture() -> Texture2D:
	return FOOD_TEXTURES[mini(day, FOOD_TEXTURES.size()) - 1]


func tape_texture() -> Texture2D:
	return TAPE_TEXTURES[mini(day, TAPE_TEXTURES.size()) - 1]


# Whether a door with this lock (see door.gd) opens right now.
func can_pass(lock: String) -> bool:
	match lock:
		"outside":
			return Player.has_knife and not is_last_day()
		"kitchen":
			return not is_last_day()
	return true


# The day is over (the player died). Fade out and wake up the next morning.
func end_day() -> void:
	if _busy or is_last_day():
		return
	_busy = true
	get_tree().paused = true
	Sound.mute_music(true)
	await _glitch()
	await _fade(1.0)
	day += 1
	_reset_today()
	get_tree().paused = false
	get_tree().change_scene_to_file(BEDROOM)
	_label.text = "DAY %d" % day
	Sound.play("new_day")
	await get_tree().create_timer(CARD_TIME).timeout
	_label.text = ""
	Sound.mute_music(false)
	await _fade(0.0)
	_busy = false
	faded_in.emit()


# The last tape has played. Fade out on the ending and go back to the title.
func finish() -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = true
	await _fade(1.0)
	for line in lines("ending"):
		_label.text = line
		await get_tree().create_timer(ENDING_LINE_TIME).timeout
	_label.text = ""
	day = 1
	_reset_today()
	Sound.ending_seen = true
	Sound.mute_music(false)
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE)
	await _fade(0.0)
	_busy = false


# True while the screen is fading or covered between days.
func is_busy() -> bool:
	return _busy


func _reset_today() -> void:
	read_note = false
	has_food = false
	tape_in = false
	ate = false
	eye_spoke = false
	Player.has_knife = false
	Player.health = Player.MAX_HEALTH
	DoorScript.next_spawn = ""
	WakeUpScript.played = false
	SpiderGateScript._cleared.clear()


# The tape skipping: the screen flickers to black a few times.
func _glitch() -> void:
	Sound.play("glitch")
	for i in GLITCH_FLICKERS:
		_black.modulate.a = 0.9 if i % 2 == 0 else 0.0
		await get_tree().create_timer(randf_range(0.04, 0.12)).timeout


func _fade(to: float) -> void:
	var tween := create_tween()
	tween.tween_property(_black, "modulate:a", to, FADE_TIME)
	await tween.finished


func _tint(scene: Node) -> void:
	if scene == null or not scene.get_node_or_null("CharacterBody2D") is Player:
		return
	var tint := CanvasModulate.new()
	tint.color = TINTS[mini(day, TINTS.size()) - 1]
	scene.add_child(tint)
