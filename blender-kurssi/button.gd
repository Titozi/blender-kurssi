extends Node3D

## Emitted whenever this button's powered state changes (true = a box is near it).
signal power_changed(is_powered: bool)

## Objects in this group count as activators. Falls back to box name-matching.
@export var box_group: StringName = "Boxes"

## How close an activator's X/Z position needs to be to this button's X/Z position to count.
## A small tolerance gives a bit of visual slack for slight placement offsets.
@export var proximity_radius: float = 1.0
@export var activation_margin: float = 0.15

var has_power: bool = false

var _tracked_activators: Array[Node3D] = []

@onready var button_on: MeshInstance3D = get_node_or_null("button_on") as MeshInstance3D
@onready var button_off: MeshInstance3D = get_node_or_null("button_off") as MeshInstance3D


func _ready() -> void:
	add_to_group("Buttons")
	_disable_collisions()
	_gather_activators()
	_update_mesh_visibility()


func _process(_delta: float) -> void:
	_update_power()


## Scans the scene once for boxes and CharacterBody3D nodes that can activate this button.
func _gather_activators() -> void:
	_tracked_activators.clear()

	for node in get_tree().get_nodes_in_group(box_group):
		if node == self:
			continue
		if node is Node3D and not _tracked_activators.has(node):
			_tracked_activators.append(node)

	for node in _get_all_node3d(get_tree().current_scene):
		if node == self:
			continue
		if (node is CharacterBody3D or node.name.to_lower().begins_with("box")) and not _tracked_activators.has(node):
			_tracked_activators.append(node)


func _get_all_node3d(node: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in node.get_children():
		if child is Node3D:
			result.append(child)
		result.append_array(_get_all_node3d(child))
	return result


func _update_power() -> void:
	var is_powered := _has_activator_nearby()
	if is_powered != has_power:
		has_power = is_powered
		_update_mesh_visibility()
		power_changed.emit(has_power)


func _update_mesh_visibility() -> void:
	if button_on:
		button_on.visible = has_power
	if button_off:
		button_off.visible = not has_power


func _disable_collisions() -> void:
	for node in _get_all_node3d(self):
		if node is CollisionObject3D:
			node.collision_layer = 0
			node.collision_mask = 0


## Checks X/Z distance only (Y/height is ignored).
func _has_activator_nearby() -> bool:
	var my_pos := Vector2(global_position.x, global_position.z)
	for activator in _tracked_activators:
		if not is_instance_valid(activator):
			continue
		var activator_pos := Vector2(activator.global_position.x, activator.global_position.z)
		if my_pos.distance_to(activator_pos) <= proximity_radius + activation_margin:
			return true
	return false
