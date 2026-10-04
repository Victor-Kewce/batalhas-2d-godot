extends RefCounted

const ARENA := Rect2(330, 365, 620, 230)
const PLAYER_RADIUS := 7.0
const MAX_HP := 80
const MAX_BOSS_HP := 160
const DEFENSE_TIME := 8.0
const SETTINGS := [
	{"label": "TREINO", "speed": 130.0, "interval": 0.7, "damage": 6},
	{"label": "NORMAL", "speed": 185.0, "interval": 0.5, "damage": 10},
	{"label": "DESAFIO", "speed": 235.0, "interval": 0.38, "damage": 13},
]

var state := "menu"
var paused := false
var difficulty := 0
var hp := MAX_HP
var boss_hp := MAX_BOSS_HP
var player := ARENA.get_center()
var bullets: Array[Dictionary] = []
var wave := 0
var clock := 0.0
var elapsed := 0.0
var spawn_clock := 0.0
var invincible := 0.0
var hits := 0
var attacks := 0
var last_damage := 0
var last_accuracy := 0.0
var aim := 0.0
var aim_direction := 1.0
var random := RandomNumberGenerator.new()

func start(level: int = 0, seed_value: int = 1938) -> void:
	difficulty = clampi(level, 0, 2)
	hp = MAX_HP
	boss_hp = MAX_BOSS_HP
	player = ARENA.get_center()
	bullets.clear()
	wave = 0
	clock = 0.0
	elapsed = 0.0
	spawn_clock = 0.0
	invincible = 0.0
	hits = 0
	attacks = 0
	last_damage = 0
	last_accuracy = 0.0
	paused = false
	aim = 0.0
	aim_direction = 1.0
	random.seed = seed_value
	state = "attack"

func confirm() -> void:
	if paused or state != "attack":
		return
	last_accuracy = clampf(1.0 - absf(aim - 0.5) * 2.0, 0.0, 1.0)
	last_damage = int(round(12.0 + 20.0 * pow(last_accuracy, 2.0)))
	boss_hp = maxi(0, boss_hp - last_damage)
	attacks += 1
	clock = 0.0
	if boss_hp == 0:
		state = "victory"
		bullets.clear()
		return
	state = "defend"
	player = ARENA.get_center()
	spawn_clock = 0.0
	invincible = 0.55

func toggle_pause() -> void:
	if state in ["attack", "defend"]:
		paused = not paused

func update(delta: float, movement: Vector2 = Vector2.ZERO, precision := false) -> void:
	if paused or state not in ["attack", "defend"]:
		return
	# Substeps keep movement and swept collisions consistent during slow frames.
	var remaining := minf(delta, 0.25)
	while remaining > 0.00001 and state in ["attack", "defend"]:
		var step := minf(remaining, 1.0 / 120.0)
		_step(step, movement.limit_length(1.0), precision)
		remaining -= step

func _step(delta: float, movement: Vector2, precision: bool) -> void:
	elapsed += delta
	clock += delta
	if state == "attack":
		aim += aim_direction * delta * 0.72
		if aim > 1.0:
			aim = 2.0 - aim
			aim_direction = -1.0
		elif aim < 0.0:
			aim = -aim
			aim_direction = 1.0
		return
	var previous_player := player
	player += movement * (105.0 if precision else 240.0) * delta
	player.x = clampf(player.x, ARENA.position.x + PLAYER_RADIUS, ARENA.end.x - PLAYER_RADIUS)
	player.y = clampf(player.y, ARENA.position.y + PLAYER_RADIUS, ARENA.end.y - PLAYER_RADIUS)
	invincible = maxf(0.0, invincible - delta)
	spawn_clock -= delta
	if clock > 0.8 and spawn_clock <= 0.0:
		spawn_wave()
		spawn_clock += float(SETTINGS[difficulty]["interval"])
	for i in range(bullets.size() - 1, -1, -1):
		var bullet := bullets[i]
		var old: Vector2 = bullet["position"]
		var current: Vector2 = old + Vector2(bullet["velocity"]) * delta
		bullet["position"] = current
		var closest := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, old - previous_player, current - player)
		if invincible <= 0.0 and closest.length() <= PLAYER_RADIUS + float(bullet["radius"]):
			hp = maxi(0, hp - int(SETTINGS[difficulty]["damage"]))
			hits += 1
			invincible = 0.9
			bullets.remove_at(i)
			if hp == 0:
				state = "defeat"
				bullets.clear()
				return
		elif not ARENA.grow(80.0).has_point(current):
			bullets.remove_at(i)
	if clock >= DEFENSE_TIME:
		wave += 1
		state = "attack"
		clock = 0.0
		aim = 0.0
		aim_direction = 1.0
		bullets.clear()

func spawn_wave() -> void:
	var speed := float(SETTINGS[difficulty]["speed"])
	match wave % 3:
		0:
			# Vertical rain with a continuous visible gap.
			var gap := 1 + int(floor(clock * 0.6)) % 6
			for column in range(9):
				if column in [gap, gap + 1]:
					continue
				add_bullet(Vector2(ARENA.position.x + 36 + column * 68, ARENA.position.y - 15), Vector2(0, speed), 6.0)
		1:
			# Horizontal volleys leave two adjacent lanes open.
			var gap := int(floor(clock * 0.75)) % 4
			var from_left := int(floor(clock)) % 2 == 0
			for row in range(6):
				if row in [gap, gap + 1]:
					continue
				add_bullet(Vector2(ARENA.position.x - 15 if from_left else ARENA.end.x + 15, ARENA.position.y + 20 + row * 38), Vector2(speed if from_left else -speed, 0), 6.0)
		2:
			# Aimed fan: arrows show direction; the aim locks when spawned.
			var origin := Vector2(random.randf_range(ARENA.position.x + 25, ARENA.end.x - 25), ARENA.position.y - 20)
			var direction := (player - origin).normalized()
			for offset in [-0.3, 0.0, 0.3]:
				add_bullet(origin, direction.rotated(offset) * speed * 0.9, 6.0)

func add_bullet(position: Vector2, velocity: Vector2, radius: float) -> void:
	bullets.append({"position": position, "velocity": velocity, "radius": radius})

func pattern_name() -> String:
	return ["CHUVA", "CORREDORES", "MIRA"][wave % 3]

func pattern_hint() -> String:
	return ["Procure a abertura entre as colunas.", "Encontre as faixas livres e acompanhe a troca de lado.", "A mira trava no disparo. Continue se movendo."][wave % 3]
