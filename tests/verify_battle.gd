extends SceneTree

const Battle = preload("res://battle.gd")
var failures := 0
var checks := 0

func check(condition: bool, title: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", title)

func _initialize() -> void:
	var game := Battle.new()
	game.start()
	check(game.hp == Battle.MAX_HP and game.boss_hp == Battle.MAX_BOSS_HP, "fresh battle")
	game.aim = 0.5
	game.confirm()
	check(game.last_damage == 32 and game.state == "defend", "centered attack")
	game.update(0.25, Vector2.ONE)
	check(game.player.distance_to(Battle.ARENA.get_center()) <= 60.001, "diagonal speed capped")
	for i in range(100):
		game.update(0.1, Vector2(1, 1), true)
	check(Battle.ARENA.grow(-Battle.PLAYER_RADIUS).has_point(game.player - Vector2(0.001, 0.001)), "player stays inside arena")
	game.start()
	game.toggle_pause()
	var initial_aim := game.aim
	game.update(0.25)
	game.confirm()
	check(game.elapsed == 0 and game.state == "attack" and game.aim == initial_aim, "pause freezes actions and time")
	game.toggle_pause()
	game.aim = 0
	game.confirm()
	check(game.last_damage == 12, "edge attack")
	game.invincible = 0
	game.add_bullet(game.player - Vector2(100, 0), Vector2(24000, 0), 6)
	game.update(1.0 / 120.0)
	check(game.hp == Battle.MAX_HP - 6, "swept collision prevents tunneling")
	game.add_bullet(game.player, Vector2.ZERO, 6)
	game.update(1.0 / 120.0)
	check(game.hp == Battle.MAX_HP - 6, "invincibility prevents repeated damage")
	game.hp = 1
	game.invincible = 0
	game.add_bullet(game.player, Vector2.ZERO, 6)
	game.update(1.0 / 120.0)
	check(game.state == "defeat" and game.hp == 0 and game.bullets.is_empty(), "defeat ends battle")
	game.start()
	game.boss_hp = 1
	game.confirm()
	check(game.state == "victory" and game.bullets.is_empty(), "victory ends battle")
	game.start()
	check(game.hits == 0 and game.elapsed == 0 and not game.paused, "retry resets state")
	# Exercise every difficulty and every attack pattern through full cycles.
	for level in range(3):
		game.start(level)
		for pattern in range(3):
			game.aim = 0.5
			game.confirm()
			var saw_bullets := false
			var safe_mode := true
			for frame in range(970):
				game.invincible = 100.0 if safe_mode else game.invincible
				game.update(1.0 / 120.0, Vector2.RIGHT if frame % 240 < 120 else Vector2.LEFT)
				saw_bullets = saw_bullets or not game.bullets.is_empty()
				check(game.bullets.size() < 200, "bounded projectile count")
				if game.state == "attack":
					break
			check(saw_bullets, "pattern emits projectiles")
			check(game.state == "attack" and game.wave == pattern + 1, "defense returns to attack")
	print("RESULT: ", checks, " checks; ", failures, " failures. Full cycles use forced invincibility; this is not human difficulty validation.")
	quit(1 if failures else 0)
