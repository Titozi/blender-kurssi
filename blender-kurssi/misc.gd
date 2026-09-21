extends Node3D

@export var player: Node = null
@export var sea: Node = null

func _process(_delta: float) -> void:
	check_sea_hazard()
	
func check_sea_hazard() -> void:
	if sea and player.global_position.y < sea.global_position.y:
		get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
