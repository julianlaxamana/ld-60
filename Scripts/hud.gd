extends CanvasLayer

# Autoloaded as "Hud". Shows the player's hearts in the top-left corner
# whenever the current scene has a player in it, and an "E" prompt over the
# player's head when there's something to interact with.

const FULL := preload("res://Sprites/heart full.png")
const EMPTY := preload("res://Sprites/heart empty.png")
const HEART_SCALE = 4
const MARGIN = 24.0
const PROMPT_TEXT = "[E] Interact"
# How far above the player's origin the prompt sits, in world pixels.
const PROMPT_HEIGHT = 90.0

var _hearts: Array[TextureRect] = []
var _box: HBoxContainer
var _prompt: Label


func _ready() -> void:
	# Layer 0 with max z_index, same as the dialogue box, so the room's
	# pixel/CRT effects get applied to the hearts too.
	layer = 0
	_box = HBoxContainer.new()
	_box.position = Vector2(MARGIN, MARGIN)
	_box.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	for i in Player.MAX_HEALTH:
		var heart := TextureRect.new()
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.custom_minimum_size = Vector2(FULL.get_size()) * HEART_SCALE
		_box.add_child(heart)
		_hearts.append(heart)

	_prompt = Label.new()
	_prompt.text = PROMPT_TEXT
	_prompt.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.hide()
	add_child(_prompt)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var player: Player = scene.get_node_or_null("CharacterBody2D") as Player if scene else null
	_box.visible = player != null
	_prompt.visible = player != null and _can_interact(player)
	if not _box.visible:
		return
	for i in _hearts.size():
		_hearts[i].texture = FULL if i < Player.health else EMPTY
	if _prompt.visible:
		var head := get_viewport().get_canvas_transform() * (player.global_position + Vector2(0, -PROMPT_HEIGHT))
		_prompt.position = head - _prompt.size / 2.0


# True if pressing Interact right now would do something.
func _can_interact(player: Player) -> bool:
	if not player.can_move or Dialogue.is_busy() or Day.is_busy():
		return false
	for area in get_tree().get_nodes_in_group(Interactable.GROUP):
		if area.is_queued_for_deletion() or not area.is_processing():
			continue
		if area.get("_player_inside") and not area.get("_done"):
			return true
	return false
