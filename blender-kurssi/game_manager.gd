extends Node

## Emitted the moment every button on the map becomes powered.
signal all_buttons_powered
## Emitted the moment at least one button loses power (after previously being all-on).
signal not_all_buttons_powered


@export var finish_radius: float = 1.0

@onready var start: Node3D = get_node_or_null("../Start") as Node3D
@onready var finish: Node3D = get_node_or_null("../Finish") as Node3D
@onready var player: Node3D = get_node_or_null("../Player") as Node3D
@onready var flag_active: Node3D = finish.find_child("FlagActive", true, false) as Node3D if finish else null

var buttons: Array[Node] = []

var _all_powered_last_check: bool = false
var _player_was_on_finish: bool = false

@onready var debug_label:Label = $"../DebugLabel"

func _ready() -> void:
	# Requires every button script to call add_to_group("buttons") in its own _ready(),
	# which button.gd already does.
	buttons = get_tree().get_nodes_in_group("Buttons")
	debug_print("[ButtonManager] Tracking %d button(s)." % buttons.size())

	for button in buttons:
		if button.has_signal("power_changed"):
			button.power_changed.connect(_on_button_power_changed.bind(button))

	_reset_layout()
	_check_all_powered()


func _process(_delta: float) -> void:
	_check_finish()


func _reset_layout() -> void:
	if player and start:
		player.global_position = start.global_position
	if flag_active:
		flag_active.visible = false

func debug_print(txt:String) ->void:
	if(debug_label):
		debug_label.text = txt
	
func _on_button_power_changed(is_powered: bool, button: Node) -> void:
	debug_print("[ButtonManager] %s power changed -> %s" % [button.name, is_powered])
	_check_all_powered()


func _check_all_powered() -> void:
	var all_on := are_all_buttons_powered()

	if all_on and not _all_powered_last_check:
		debug_print("[ButtonManager] All buttons powered!")
		if flag_active:
			flag_active.visible = true
		all_buttons_powered.emit()
	elif not all_on and _all_powered_last_check:
		debug_print("[ButtonManager] Not all buttons powered.")
		if flag_active:
			flag_active.visible = false
		not_all_buttons_powered.emit()

	_all_powered_last_check = all_on


## Public helper: check current state at any time, e.g. from another script.
func are_all_buttons_powered() -> bool:
	if buttons.is_empty():
		return false
	for button in buttons:
		if not button.has_power:
			return false
	return true


func _check_finish() -> void:
	if not player or not finish:
		return

	var player_position := Vector2(player.global_position.x, player.global_position.z)
	var finish_position := Vector2(finish.global_position.x, finish.global_position.z)
	var is_on_finish := player_position.distance_to(finish_position) <= finish_radius

	if is_on_finish and not _player_was_on_finish:
		if are_all_buttons_powered():
			get_tree().reload_current_scene()
		else:
			debug_print("No power")

	_player_was_on_finish = is_on_finish
