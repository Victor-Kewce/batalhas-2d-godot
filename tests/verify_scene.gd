extends SceneTree

var failures := 0

func check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", text)

func key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	check(scene.game.state == "menu", "initial menu")
	scene._input(key(KEY_3))
	check(scene.selected == 2, "difficulty keyboard selection")
	scene._input(key(KEY_ENTER))
	check(scene.game.state == "attack" and scene.game.difficulty == 2, "keyboard starts chosen difficulty")
	scene.game.aim = 0.5
	scene._input(key(KEY_SPACE))
	check(scene.game.state == "defend" and scene.game.last_damage == 32, "keyboard attack")
	scene._input(key(KEY_ESCAPE))
	check(scene.game.paused, "keyboard pause")
	scene._input(key(KEY_ENTER))
	check(not scene.game.paused, "keyboard resume")
	scene._input(key(KEY_R))
	check(scene.game.state == "attack" and scene.game.hp == 80, "keyboard retry")
	scene._input(key(KEY_B))
	check(scene.game.state == "menu", "keyboard return")
	scene.do_action("0")
	scene.do_action("start")
	check(scene.game.difficulty == 0 and scene.game.state == "attack", "button selection starts chosen level")
	scene.queue_free()
	print("SCENE RESULT: ", failures, " failures")
	quit(1 if failures else 0)
