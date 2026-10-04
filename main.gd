extends Node2D

const Battle = preload("res://battle.gd")
const BG := Color("0b0f1b")
const PANEL := Color("131b2b")
const MUTED := Color("8c9bb4")
const WHITE := Color("eef3ff")
const CYAN := Color("62e8d1")
const GOLD := Color("ffcf70")
const RED := Color("ff6787")
const FONT := preload("res://ui_font.tres")

var game := Battle.new()
var time := 0.0
var selected := 0
var buttons: Array[Dictionary] = []
var pointer := Vector2.ZERO
var capture_path := ""
var capture_done := false
var capture_mode := ""

func _ready() -> void:
	DisplayServer.window_set_title("Protótipo de Batalhas | versão local 0.1")
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--capture" and i + 1 < args.size():
			capture_path = args[i + 1]
		if args[i] == "--battle":
			capture_mode = "battle"
	if capture_mode == "battle":
		game.start(0)
		game.aim = 0.5
		game.confirm()
		for i in range(300):
			game.update(1.0 / 120.0, Vector2(0.25, 0))
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	if capture_path.is_empty():
		var move := Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		)
		game.update(delta, move, Input.is_physical_key_pressed(KEY_SHIFT))
	queue_redraw()
	if not capture_path.is_empty() and time > 0.65 and not capture_done:
		capture_done = true
		await RenderingServer.frame_post_draw
		var screenshot := get_viewport().get_texture().get_image()
		var error := screenshot.save_png(capture_path)
		print("CAPTURE ", error, " ", capture_path)
		get_tree().quit(error)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer = get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click := get_global_mouse_position()
		for button in buttons:
			if Rect2(button["rect"]).has_point(click):
				do_action(button["action"])
				return
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3:
			if game.state == "menu":
				selected = event.physical_keycode - KEY_1
		KEY_ENTER, KEY_SPACE:
			if game.state == "menu":
				game.start(selected)
			elif game.state in ["victory", "defeat"]:
				game.start(selected)
			elif game.paused:
				game.toggle_pause()
			else:
				game.confirm()
		KEY_ESCAPE:
			game.toggle_pause()
		KEY_R:
			if game.state != "menu":
				game.start(selected)
		KEY_B:
			game.state = "menu"
			game.paused = false
		KEY_LEFT:
			if game.state == "menu":
				selected = maxi(0, selected - 1)
		KEY_RIGHT:
			if game.state == "menu":
				selected = mini(2, selected + 1)

func do_action(action: String) -> void:
	match action:
		"start", "retry": game.start(selected)
		"menu":
			game.state = "menu"
			game.paused = false
		"resume": game.toggle_pause()
		"0", "1", "2": selected = int(action)

func label_at(text: String, position: Vector2, size := 20, color := WHITE) -> void:
	draw_string(FONT, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(text: String, x: float, y: float, size := 20, color := WHITE) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	label_at(text, Vector2(x - width / 2, y), size, color)

func card(rect: Rect2, fill := PANEL, border := Color("28344b")) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	draw_style_box(style, rect)

func button(rect: Rect2, text: String, action: String, accent := false) -> void:
	var hovered := rect.has_point(pointer)
	card(rect, Color("203c41") if accent else (Color("26354c") if hovered else PANEL), CYAN if accent else Color("34465f"))
	centered(text, rect.get_center().x, rect.get_center().y + 7, 20, CYAN if accent else WHITE)
	buttons.append({"rect": rect, "action": action})

func _draw() -> void:
	buttons.clear()
	draw_rect(Rect2(0, 0, 1280, 720), BG)
	for x in range(0, 1280, 40):
		draw_line(Vector2(x, 0), Vector2(x, 720), Color(0.08, 0.12, 0.19, 0.32))
	for y in range(0, 720, 40):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.08, 0.12, 0.19, 0.32))
	label_at("LABORATÓRIO DE COMBATE", Vector2(48, 45), 18, CYAN)
	label_at("VERSÃO LOCAL 0.1", Vector2(1052, 45), 16, MUTED)
	if game.state == "menu":
		draw_menu()
	else:
		draw_battle()
		if game.state in ["victory", "defeat"]:
			draw_result()
		elif game.paused:
			draw_pause()
	label_at("WASD / SETAS  mover     SHIFT  precisão     ESPAÇO / ENTER  confirmar", Vector2(48, 687), 16, MUTED)
	label_at("ESC  pausa     R  reiniciar     B  menu", Vector2(900, 687), 16, MUTED)

func draw_menu() -> void:
	label_at("PROTÓTIPO", Vector2(80, 145), 58)
	label_at("DE BATALHAS", Vector2(80, 208), 58)
	label_at("Uma primeira base para testar esquiva e ritmo.", Vector2(84, 257), 22, MUTED)
	label_at("Escolha a dificuldade", Vector2(84, 320), 20)
	for i in range(3):
		button(Rect2(84 + i * 186, 341, 172, 54), Battle.SETTINGS[i]["label"], str(i), selected == i)
	var descriptions := ["Projéteis mais lentos e dano reduzido.", "Velocidade e dano intermediários.", "Projéteis mais rápidos e dano maior."]
	label_at(descriptions[selected], Vector2(84, 427), 18, MUTED)
	button(Rect2(84, 462, 356, 66), "INICIAR BATALHA  →", "start", true)
	label_at("ENTER para começar  ·  1 / 2 / 3 para selecionar", Vector2(84, 558), 17, MUTED)
	card(Rect2(744, 107, 448, 481))
	centered("ALVO PROVISÓRIO", 968, 150, 17, MUTED)
	draw_enemy(Vector2(968, 290), 1.35)
	label_at("03", Vector2(782, 432), 38, CYAN)
	label_at("padrões de ataque", Vector2(868, 426), 21)
	label_at("Chuva · Corredores · Mira", Vector2(868, 454), 17, MUTED)
	draw_line(Vector2(780, 478), Vector2(1158, 478), Color("28344b"))
	label_at("MODO MISTO", Vector2(782, 516), 18, GOLD)
	label_at("Exploração, história e puzzles (planejado).", Vector2(782, 545), 16, MUTED)

func draw_enemy(center: Vector2, scale_value: float = 1.0) -> void:
	var offset := sin(time * 2.4) * 5.0
	var c := center + Vector2(0, offset)
	draw_circle(c, 76 * scale_value, Color(0.38, 0.85, 0.78, 0.04))
	var points := PackedVector2Array([c + Vector2(0, -64) * scale_value, c + Vector2(61, 0) * scale_value, c + Vector2(0, 64) * scale_value, c + Vector2(-61, 0) * scale_value])
	draw_colored_polygon(points, Color("162b39"))
	points.append(points[0])
	draw_polyline(points, CYAN, 2.0, true)
	draw_line(c + Vector2(-61, 0) * scale_value, c + Vector2(61, 0) * scale_value, Color("306378"), 1.5)
	draw_line(c + Vector2(0, -64) * scale_value, c + Vector2(0, 64) * scale_value, Color("306378"), 1.5)
	draw_circle(c, 12 * scale_value, CYAN)
	draw_circle(c, 5 * scale_value, BG)
	for side in [-1, 1]:
		var satellite := c + Vector2(side * 112, 0) * scale_value
		draw_arc(satellite, 16 * scale_value, 0, TAU, 20, CYAN, 2.0, true)
		draw_line(c + Vector2(side * 70, 0) * scale_value, satellite - Vector2(side * 20, 0) * scale_value, Color("306378"), 2.0)

func draw_battle() -> void:
	label_at("ALVO PROVISÓRIO", Vector2(48, 97), 22)
	label_at(Battle.SETTINGS[game.difficulty]["label"], Vector2(48, 128), 17, CYAN)
	draw_enemy(Vector2(640, 200), 0.95)
	card(Rect2(430, 282, 420, 12), Color("273044"))
	if game.boss_hp > 0:
		draw_rect(Rect2(432, 284, 416.0 * game.boss_hp / Battle.MAX_BOSS_HP, 8), RED)
	centered("ENERGIA DO ALVO  %d / %d" % [game.boss_hp, Battle.MAX_BOSS_HP], 640, 318, 16, MUTED)
	card(Rect2(48, 164, 229, 252))
	label_at("SUA ENERGIA", Vector2(68, 200), 17, MUTED)
	label_at("%02d / %d" % [game.hp, Battle.MAX_HP], Vector2(68, 243), 32, WHITE)
	draw_rect(Rect2(69, 266, 186, 8), Color("273044"))
	draw_rect(Rect2(69, 266, 186.0 * game.hp / Battle.MAX_HP, 8), CYAN if game.hp > 25 else RED)
	label_at("ACERTOS RECEBIDOS  %d" % game.hits, Vector2(68, 310), 16, MUTED)
	label_at("ATAQUES FEITOS  %d" % game.attacks, Vector2(68, 345), 16, MUTED)
	label_at("TEMPO  %.1fs" % game.elapsed, Vector2(68, 382), 18, WHITE)
	card(Rect2(998, 164, 234, 252))
	label_at("PRÓXIMA ESQUIVA", Vector2(1018, 200), 17, MUTED)
	label_at(game.pattern_name(), Vector2(1018, 244), 23, GOLD)
	var hints := ["Procure a abertura", "entre as colunas."]
	if game.wave % 3 == 1:
		hints = ["Use as faixas livres.", "O lado de origem muda."]
	elif game.wave % 3 == 2:
		hints = ["A mira trava ao disparar.", "Continue se movendo."]
	label_at(hints[0], Vector2(1018, 290), 16, MUTED)
	label_at(hints[1], Vector2(1018, 317), 16, MUTED)
	label_at("DANO CAUSADO  %d" % game.last_damage, Vector2(1018, 373), 16, CYAN)
	card(Battle.ARENA, Color("101725"), CYAN if game.state == "defend" else Color("40516b"))
	if game.state == "attack":
		centered("SUA VEZ", 640, 406, 24, GOLD)
		centered("Confirme quando a linha estiver no centro.", 640, 440, 19, MUTED)
		var bar := Rect2(385, 465, 510, 54)
		card(bar, Color("233044"))
		draw_rect(Rect2(625, 467, 30, 50), Color("326659"))
		draw_line(Vector2(640, 467), Vector2(640, 517), CYAN, 2.0)
		var aim_x := bar.position.x + bar.size.x * game.aim
		draw_line(Vector2(aim_x, 459), Vector2(aim_x, 525), WHITE, 4.0)
		centered("ESPAÇO / ENTER  •  atacar", 640, 563, 18, WHITE)
	elif game.state == "defend":
		for bullet in game.bullets:
			var p: Vector2 = bullet["position"]
			if Battle.ARENA.grow(-8).has_point(p):
				draw_circle(p, float(bullet["radius"]) + 3, Color(1, 0.42, 0.53, 0.12))
				draw_circle(p, float(bullet["radius"]), RED)
				var velocity: Vector2 = bullet["velocity"]
				draw_line(p - velocity.normalized() * 13, p - velocity.normalized() * 7, RED, 2.0)
		if game.invincible <= 0.0 or int(time * 12) % 2 == 0:
			var p: Vector2 = game.player
			draw_circle(p, 19, Color(0.38, 0.91, 0.82, 0.1))
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -9), p + Vector2(9, 0), p + Vector2(0, 9), p + Vector2(-9, 0)]), CYAN)
		centered("DESVIE  •  %.1fs" % maxf(0, Battle.DEFENSE_TIME - game.clock), 640, 345, 19, GOLD)
		var left := 1.0 - game.clock / Battle.DEFENSE_TIME
		draw_rect(Rect2(332, 601, 616 * left, 4), GOLD)
	centered("R para recomeçar imediatamente", 640, 644, 17, MUTED)

func draw_result() -> void:
	draw_rect(Rect2(0, 65, 1280, 592), Color(0.025, 0.035, 0.06, 0.94))
	card(Rect2(360, 170, 560, 390))
	var won := game.state == "victory"
	centered("DESAFIO CONCLUÍDO" if won else "TENTE NOVAMENTE", 640, 231, 30, CYAN if won else RED)
	centered("%s  ·  %.1fs  ·  %d acertos recebidos" % [Battle.SETTINGS[game.difficulty]["label"], game.elapsed, game.hits], 640, 280, 18, MUTED)
	centered("Ajuste sua posição e aprenda o próximo padrão.", 640, 332, 18)
	button(Rect2(404, 374, 472, 62), "JOGAR NOVAMENTE  /  R", "retry", true)
	button(Rect2(404, 456, 472, 54), "VOLTAR AO MENU  /  B", "menu")

func draw_pause() -> void:
	draw_rect(Rect2(0, 65, 1280, 592), Color(0.025, 0.035, 0.06, 0.88))
	card(Rect2(420, 220, 440, 264))
	centered("PAUSADO", 640, 279, 34)
	button(Rect2(458, 312, 364, 58), "CONTINUAR  /  ESC", "resume", true)
	button(Rect2(458, 394, 364, 52), "VOLTAR AO MENU  /  B", "menu")
