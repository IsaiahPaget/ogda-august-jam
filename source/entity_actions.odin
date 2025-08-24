package game
import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

/*
* PLAYER
*/

PLAYER_STARTING_POSITION :: -75
player_setup :: proc(e: ^Entity) {
	e.pos.x = PLAYER_STARTING_POSITION
	e.pos.y = 45
	e.texture_offset = .CENTER
	e.collision.rectangle = rl.Rectangle {
		x      = e.pos.x,
		y      = e.pos.y,
		width  = 15.0,
		height = 15.0,
	}
	e.collision.offset = .CENTER
	e.collision.is_active = true
	e.animation = init_player_run_animation()
	e.has_physics = true
	e.max_health = 100
	e.cur_health = e.max_health
	entity_create(.PLAYER_HEALTH_BAR)
	e.scale = 0.35
	e.cur_rockets = 3
	e.z_index = 2
}


player_update :: proc(e: ^Entity) {
	fmt.assertf(e != nil, "player missing", e)
	PLAYER_JUMP_FORCE :: -250

	if e.pos.x > PLAYER_STARTING_POSITION && e.is_on_ground {
		e.velocity.x -= 1
	}

	if e.pos.x < PLAYER_STARTING_POSITION {
		game_state.target_speed = DEFAULT_MOVE_SPEED
		e.pos.x += .5 // get you back on track faster
	}

	if e.pos.x < TOO_SLOW {
		scene_pop()
	}

	if e.pos.x > TOO_FAST {
		e.pos.x = TOO_FAST
	}

	if rl.IsKeyPressed(.SPACE) && e.is_on_ground {
		e.velocity.y = PLAYER_JUMP_FORCE // negative because the world is drawn from top to.CENTER
		e.animation = init_player_jump_animation()
		rl.PlaySound(game_state.sounds.jump_sfx)
		poof := entity_create(.JUMP_POOF)
		poof.pos = e.pos
		e.is_on_ground = false
	} else if rl.IsKeyPressed(.SPACE) && !e.is_on_ground && e.cur_rockets > 0 {
		e.animation = init_player_rocket_animation()
		e.velocity = rl.Vector2{50, PLAYER_JUMP_FORCE} // apply up negative because world is drawn top to bottom
		e.cur_rockets -= 1
		rl.PlaySound(game_state.sounds.rocket_sfx)
		do_screen_shake(4, 5.1,40)

		fmt.assertf(e.cur_rockets > -1, "some how you spent zero rockets")
	} else if (e.velocity.y > 0 && e.animation.kind != .ROCKET) {
		e.animation = init_player_fall_animation()
	}

	if e.has_physics {
		if !e.is_on_ground {
			e.velocity.y += get_applied_gravity()
		}
	}

	if e.cur_health <= 0 {
		rl.PlaySound(game_state.sounds.game_over)
		scene_pop()
	}

	e.cur_health -= SUN_DAMAGE * rl.GetFrameTime()

	e.pos += e.velocity * rl.GetFrameTime()

	process_collisions(e, proc(entity_a, entity_b: ^Entity) {
		switch entity_b.kind {
		case .CRAB:
			player_on_collide_crab(entity_a, entity_b)
		case .GROUND:
			player_on_collide_ground(entity_a, entity_b)
		case .NIL:
		case .PLAY_BUTTON:
		case .PLAYER:
		case .CRAB_SPAWNER:
		case .FOREGROUND:
		case .BACKGROUND:
		case .SUN:
		case .PLAYER_HEALTH_BAR:
		case .JUMP_POOF:
		case .PARASOL_SPAWNER:
		case .PARASOL:
			player_on_collide_parasol(entity_a,entity_b)
		case .PIDGEON_SPAWNER:
		case .PIDGEON:
			player_on_collide_pidgeon(entity_a, entity_b)
		case .TOWEL_SPAWNER:
		case .TOWEL:
			player_on_collide_towel(entity_a, entity_b)
		}
	})
}

player_on_collide_parasol :: proc(player, parasol: ^Entity) {
	if player.velocity.y > 0 && player.pos.y < parasol.pos.y - 14{ // because remember it's flipped on the Y
		player.velocity.y = 0
		player.velocity.y += -370 // needs to be high to overcome gravity
		player.animation = init_player_jump_animation()
		rl.PlaySound(game_state.sounds.parasol_bounce_sfx)
	}
	parasol.animation = init_parasol_bounce_anim()
	parasol.last_bounce_s = rl.GetTime()
	parasol.is_bounce = true
}

player_on_collide_pidgeon :: proc(player, pidgeon: ^Entity) {
	do_screen_shake(1.5, 2, 60)
	change_speed(-100)
	pidgeon.velocity.y += -50
	rl.PlaySound(game_state.sounds.seagull_airborne_sfx)
}

player_on_collide_towel :: proc(player, towel: ^Entity) {
	change_speed(20)
}

player_on_collide_crab :: proc(player, crab: ^Entity) {
	do_screen_shake(1.5, 2, 60)
	change_speed(-200)
	crab.velocity.y += -300
	rl.PlaySound(game_state.sounds.dog_pain_sfx)
}

player_on_collide_ground :: proc(player, ground: ^Entity) {
	player.is_on_ground = true
	player.velocity.xy = 0
	player.animation = init_player_run_animation()
	entity_move_and_slide(player, ground)
}

player_draw :: proc(e: Entity) {
	entity_draw_default(e)

	texture := game_state.textures.rocket_icon_powerup
	for i in 0 ..< e.cur_rockets {
		rl.DrawTextureV(
			texture,
			rl.Vector2{f32(-150 + (15 * i32(i))), 60}, //magic numbers don't mind me
			rl.WHITE,
		)
	}
}

init_player_idle_animation :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.round_cat,
		frame_count = 1,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .IDLE,
	}
}
init_player_run_animation :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.corgi_run,
		frame_count = 4,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .RUN,
	}
}
init_player_jump_animation :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.corgi_jump,
		frame_count = 1,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .JUMP,
	}
}
init_player_fall_animation :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.corgi_fall,
		frame_count = 1,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .FALL,
	}
}
init_player_rocket_animation :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.corgi_rocket_fire,
		frame_count = 2,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .ROCKET,
	}
}

/*
* CRAB SPAWNER
*/

crab_spawner_setup :: proc(e: ^Entity) {

	e.spawner_interval_s = 3
}

crab_spawner_update :: proc(e: ^Entity) {
	if rl.GetTime() - e.last_spawn_s >= e.spawner_interval_s {
		e.spawner_interval_s = rand.float64_range(0.5, 2)
		crab := entity_create(.CRAB)
		crab.pos = rl.Vector2{300, 20}
		crab.collision.rectangle.x = 110
		crab.collision.rectangle.y = 10
		e.last_spawn_s = rl.GetTime()
	}
}

crab_spawner_draw :: proc(e: Entity) {
	if DEBUG {
		rl.DrawRectangleV(e.pos, {15, 15}, rl.RED)
	}
}

/*
* CRAB
*/
crab_setup :: proc(e: ^Entity) {
	e.animation = init_crab_run_anim()
	e.z_index = 3
	e.lifespan_s = 10
	e.texture_offset = .BOTTOM
	e.collision.rectangle = rl.Rectangle {
		width  = 10,
		height = 10,
	}
	e.collision.offset = .BOTTOM
	e.collision.is_active = true
	e.has_physics = true
	e.scale = 0.75
}

crab_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

crab_update :: proc(e: ^Entity) {

	MOVE_SPEED_MULTIPLIER :: 1.1

	if rl.GetTime() - e.created_on >= e.lifespan_s {
		entity_destroy(e)
	}

	if e.has_physics {
		if !e.is_on_ground {
			e.velocity.y += get_applied_gravity()
		}
	}

	e.velocity.x = game_state.current_speed * MOVE_SPEED_MULTIPLIER
	e.pos += e.velocity * rl.GetFrameTime()

	process_collisions(e, proc(entity_a, entity_b: ^Entity) {
		switch entity_b.kind {
		case .CRAB:
		case .GROUND:
			crab_on_collide_ground(entity_a, entity_b)
		case .FOREGROUND:
		case .NIL:
		case .PLAY_BUTTON:
		case .PLAYER:
		case .CRAB_SPAWNER:
		case .JUMP_POOF:
		case .BACKGROUND:
		case .SUN:
		case .PLAYER_HEALTH_BAR:
		case .TOWEL:
		case .TOWEL_SPAWNER:
		case .PIDGEON_SPAWNER:
		case .PIDGEON:
		case .PARASOL_SPAWNER:
		case .PARASOL:
		}
	})
}

crab_on_collide_ground :: proc(crab, ground: ^Entity) {
	crab.is_on_ground = true
	crab.velocity.y = 0
	entity_move_and_slide(crab, ground)
}

init_crab_run_anim :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.crab_run,
		frame_count = 3,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .RUN,
	}
}

// ground helper
ground_replace :: proc(e: ^Entity) {
	if e.pos.x <= -f32(e.animation.texture.width) - 50 {
		// Instead of resetting to .initial_position,
		// move this background tile just after the rightmost one
		rightmost_x: f32 = -999999 // somewhere way off to the left of the screen
		for handle in entity_get_all() {
			g := entity_get(handle)
			if g.kind == e.kind && g != e {
				if g.pos.x > rightmost_x {
					rightmost_x = g.pos.x
				}
			}
		}
		e.pos.x = rightmost_x + f32(e.animation.texture.width - 3)
	}
}
/*
* BACKGROUND
*/
background_setup :: proc(e: ^Entity) {
	e.pos.y = 30
	e.pos.x = -50
	e.texture_offset = .CENTER
	e.animation = init_background_anim()
}
background_update :: proc(e: ^Entity) {
	MOVE_SPEED_MULTIPLIER :: 0.8
	e.velocity = rl.Vector2{game_state.current_speed * MOVE_SPEED_MULTIPLIER, 0}
	e.pos += e.velocity * rl.GetFrameTime()

	ground_replace(e)

	collision_box_update(e)
}

background_draw :: proc(e: Entity) {
	texture := e.animation.texture
	offset := get_texture_position(e)

	rl.DrawTextureV(texture, offset, rl.WHITE)
	if DEBUG {
		rl.DrawCircleV(e.pos, 2, rl.PINK)
		rl.DrawRectangleRec(e.collision.rectangle, rl.ColorAlpha(rl.BLUE, .50))
	}
}

init_background_anim :: proc() -> Animation {
	return Animation{texture = game_state.textures.background, frame_count = 1, kind = .NIL}
}

/*
* FOREGROUND
*/
foreground_setup :: proc(e: ^Entity) {
	e.pos.y = 90
	e.pos.x = -50
	e.texture_offset = .CENTER
	e.animation = init_foreground_anim()
}

foreground_update :: proc(e: ^Entity) {
	MOVE_SPEED_MULTIPLIER :: 1.10
	e.velocity = rl.Vector2{game_state.current_speed * MOVE_SPEED_MULTIPLIER, 0}
	e.pos += e.velocity * rl.GetFrameTime()

	ground_replace(e)

	collision_box_update(e)
}

foreground_draw :: proc(e: Entity) {
	texture := e.animation.texture
	offset := get_texture_position(e)

	rl.DrawTextureV(texture, offset, rl.WHITE)
	if DEBUG {
		rl.DrawCircleV(e.pos, 2, rl.PINK)
		rl.DrawRectangleRec(e.collision.rectangle, rl.ColorAlpha(rl.BLUE, .50))
	}
}

init_foreground_anim :: proc() -> Animation {
	return Animation{texture = game_state.textures.foreground, frame_count = 1, kind = .NIL}
}

/*
* GROUND
*/
ground_setup :: proc(e: ^Entity) {
	e.pos.y = 75
	e.pos.x = -50
	e.texture_offset = .CENTER
	e.animation = init_ground_anim()
	e.collision.rectangle = rl.Rectangle {
		x      = e.pos.x,
		y      = e.pos.y,
		width  = f32(e.animation.texture.width + 1),
		height = f32(e.animation.texture.height + 1),
	}
	e.collision.offset = .CENTER
	e.collision.is_active = true
}

ground_update :: proc(e: ^Entity) {
	MOVE_SPEED_MULTIPLIER :: 1
	e.velocity = rl.Vector2{game_state.current_speed * MOVE_SPEED_MULTIPLIER, 0}
	e.pos += e.velocity * rl.GetFrameTime()

	ground_replace(e)

	collision_box_update(e)
}

ground_draw :: proc(e: Entity) {
	texture := e.animation.texture
	offset := get_texture_position(e)

	rl.DrawTextureV(texture, offset, rl.WHITE)
	if DEBUG {
		rl.DrawCircleV(e.pos, 2, rl.PINK)
		rl.DrawRectangleRec(e.collision.rectangle, rl.ColorAlpha(rl.BLUE, .50))
	}
}

init_ground_anim :: proc() -> Animation {
	return Animation{texture = game_state.textures.ground, frame_count = 1, kind = .NIL}
}


/*
* PLAY BUTTON
*/

play_button_setup :: proc(e: ^Entity) {
	e.pos.x = -100
	e.pos.y = -40
}
play_button_update :: proc(e: ^Entity) {
	if rl.IsKeyPressed(.ENTER) {
		scene_push(.GAME)
	}
}
play_button_draw :: proc(e: Entity) {
	rl.DrawRectangleV(rl.Vector2{e.pos.x, e.pos.y}, rl.Vector2{200, 80}, rl.DARKGRAY)
	rl.DrawText("Press enter to play", -40, 0, 8, rl.WHITE)
}

// init_play_button_anim :: proc() -> Animation {
// 	return Animation {
// 		texture = rl.LoadTexture("assets/grass_block.png"),
// 		frame_count = 1,
// 		kind = .NIL,
// 	}
// }

/*
* SUN
*/
sun_setup :: proc(e: ^Entity) {
	e.pos.x = 150
	e.pos.y = -50
	e.scale = 0.25
	e.animation = init_sun_anim()
}

sun_update :: proc(e: ^Entity) {

}
sun_draw :: proc(e: Entity) {
	entity_draw_default(e)
}
init_sun_anim :: proc() -> Animation {
	// TODO: make the sun stay angry after x amount of time
	return Animation {
		texture = game_state.textures.sun,
		frame_count = 4,
		frame_length = 10,
		kind = .IDLE,
	}
}

/*
* PLAYER_HEALTH_BAR
*/
player_health_bar_setup :: proc(e: ^Entity) {
	e.pos.x = -150
	e.pos.y = -60
	e.scale = 0.25
	e.health_bar_max_width = 50
}

player_health_bar_update :: proc(e: ^Entity) {
	player := get_player()

	player_health_percent := player.cur_health / player.max_health
	e.health_bar_width = e.health_bar_max_width * player_health_percent
}
player_health_bar_draw :: proc(e: Entity) {
	rl.DrawRectangleV(e.pos, rl.Vector2{e.health_bar_width, 20}, rl.RED)
}

/*
* PLAYER JUMP POOF
*/
jump_poof_setup :: proc(e: ^Entity) {
	e.animation = init_jump_poof_anim()
	e.scale = .5
	e.lifespan_s = .3
	e.texture_offset = .CENTER
	e.z_index = 10
}

jump_poof_update :: proc(e: ^Entity) {
	if rl.GetTime() - e.created_on >= e.lifespan_s {
		entity_destroy(e)
	}

	e.velocity.x = game_state.current_speed
	e.pos += e.velocity * rl.GetFrameTime()
}
jump_poof_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

init_jump_poof_anim :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.jump_poof,
		frame_count = 3,
		frame_length = .1,
		kind = .IDLE,
	}
}


/*
* TOWEL SPAWNER
*/

towel_spawner_setup :: proc(e: ^Entity) {
	e.spawner_interval_s = 3
}

towel_spawner_update :: proc(e: ^Entity) {
	if rl.GetTime() - e.last_spawn_s >= e.spawner_interval_s {
		e.spawner_interval_s = rand.float64_range(1, 3)
		towel := entity_create(.TOWEL)
		towel.pos = rl.Vector2{300, 70}
		towel.collision.rectangle.x = 110
		towel.collision.rectangle.y = 10
		e.last_spawn_s = rl.GetTime()
	}
}

towel_spawner_draw :: proc(e: Entity) {
	if DEBUG {
		rl.DrawRectangleV(e.pos, {30, 30}, rl.ORANGE)
	}
}

/*
* TOWEL
*/
towel_setup :: proc(e: ^Entity) {
	e.lifespan_s = 10
	e.animation = init_towel_idle_anim()
	e.texture_offset = .BOTTOM
	e.collision.rectangle = rl.Rectangle {
		width  = 50,
		height = 15,
	}
	e.collision.offset = .BOTTOM
	e.collision.is_active = true
	e.scale = 0.75
}

towel_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

towel_update :: proc(e: ^Entity) {

	MOVE_SPEED_MULTIPLIER :: 1

	if rl.GetTime() - e.created_on >= e.lifespan_s {
		entity_destroy(e)
	}

	e.velocity.x = game_state.current_speed * MOVE_SPEED_MULTIPLIER
	e.pos += e.velocity * rl.GetFrameTime()

	collision_box_update(e)
}

init_towel_idle_anim :: proc() -> Animation {
	texture: rl.Texture2D
	switch rl.GetRandomValue(1, 3) {
	case 1:
		texture = game_state.textures.towel_green
	case 2:
		texture = game_state.textures.towel_red
	case 3:
		texture = game_state.textures.towel_yellow
	}

	return Animation{texture = texture, frame_count = 1, kind = .IDLE}
}

/*
* PIDGEON SPAWNER
*/

pidgeon_spawner_setup :: proc(e: ^Entity) {
	e.spawner_interval_s = 3
}

pidgeon_spawner_update :: proc(e: ^Entity) {
	if rl.GetTime() - e.last_spawn_s >= e.spawner_interval_s {
		e.spawner_interval_s = rand.float64_range(0.5, 2)
		pidgeon := entity_create(.PIDGEON)
		pidgeon.pos = rl.Vector2{300, rand.float32_range(-60, 30)}
		pidgeon.collision.rectangle.x = 300
		pidgeon.collision.rectangle.y = 10
		e.last_spawn_s = rl.GetTime()
	}
}

pidgeon_spawner_draw :: proc(e: Entity) {
	if DEBUG {
		rl.DrawRectangleV(e.pos, {30, 30}, rl.BLUE)
	}
}

/*
* PIDGEON
*/
pidgeon_setup :: proc(e: ^Entity) {
	e.lifespan_s = 10
	e.animation = init_pidgeon_fly_anim()
	e.texture_offset = .CENTER
	e.collision.rectangle = rl.Rectangle {
		width  = 10,
		height = 10,
	}
	e.collision.offset = .CENTER
	e.collision.is_active = true
	e.scale = 0.75
	e.animation.flip_x = true
}

pidgeon_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

pidgeon_update :: proc(e: ^Entity) {

	MOVE_SPEED_MULTIPLIER :: 1.3

	if rl.GetTime() - e.created_on >= e.lifespan_s {
		entity_destroy(e)
	}

	e.velocity.x = game_state.current_speed * MOVE_SPEED_MULTIPLIER
	e.pos += e.velocity * rl.GetFrameTime()

	collision_box_update(e)
}

init_pidgeon_fly_anim :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.pidgeon_flying,
		frame_count = 4,
		frame_length = 0.1,
		kind = .IDLE,
	}
}

/*
* PARASOL SPAWNER
*/

parasol_spawner_setup :: proc(e: ^Entity) {
	e.spawner_interval_s = 3
}

parasol_spawner_update :: proc(e: ^Entity) {
	if rl.GetTime() - e.last_spawn_s >= e.spawner_interval_s {
		e.spawner_interval_s = rand.float64_range(0.5, 2)
		parasol := entity_create(.PARASOL)
		parasol.pos = rl.Vector2{300, 30}
		parasol.collision.rectangle.x = 300
		e.last_spawn_s = rl.GetTime()
	}
}

parasol_spawner_draw :: proc(e: Entity) {
	if DEBUG {
		rl.DrawRectangleV(e.pos, {30, 30}, rl.BLUE)
	}
}

/*
* PARASOL
*/
parasol_setup :: proc(e: ^Entity) {
	e.lifespan_s = 10
	e.animation = init_parasol_idle_anim()
	e.texture_offset = .CENTER
	e.collision.rectangle = rl.Rectangle {
		width  = 50,
		height = 10,
	}
	e.collision.offset = .CENTER
	e.collision.is_active = true
	e.scale = 0.5
}

parasol_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

parasol_update :: proc(e: ^Entity) {

	MOVE_SPEED_MULTIPLIER :: 1
	BOUNCE_DURATION_S :: .3

	if e.is_bounce && rl.GetTime() - e.last_bounce_s >= BOUNCE_DURATION_S{
		e.animation = init_parasol_idle_anim()
		e.is_bounce = false
	}

	if rl.GetTime() - e.created_on >= e.lifespan_s {
		entity_destroy(e)
	}

	e.velocity.x = game_state.current_speed * MOVE_SPEED_MULTIPLIER
	e.pos += e.velocity * rl.GetFrameTime()

	// custom update of collision box because only the to of the sprite is collidable
	e.collision.rectangle.x = e.pos.x - (e.collision.rectangle.width / 2)
	e.collision.rectangle.y = e.pos.y - (e.collision.rectangle.height / 2) - 15

}

init_parasol_idle_anim :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.parasol,
		frame_count = 1,
		frame_length = 0,
		kind = .NIL,
	}
}
init_parasol_bounce_anim :: proc() -> Animation {
	return Animation {
		texture = game_state.textures.parasol_bounce,
		frame_count = 3,
		frame_length = 0.1,
		kind = .BOUNCE,
	}
}
