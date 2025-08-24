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
		e.is_on_ground = false
	} else if rl.IsKeyPressed(.SPACE) && !e.is_on_ground && e.cur_rockets > 0 {
		e.animation = init_player_rocket_animation()
		e.velocity = rl.Vector2 {50, PLAYER_JUMP_FORCE} // apply up negative because world is drawn top to bottom
		e.cur_rockets -= 1
		do_screen_shake()

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
		}
	})
}

player_on_collide_crab :: proc(player, crab: ^Entity) {
	do_screen_shake()
	change_speed(-200)
	entity_destroy(crab)
}

player_on_collide_ground :: proc(player, ground: ^Entity) {
	player.is_on_ground = true
	player.velocity.xy = 0
	player.animation = init_player_run_animation()
	entity_move_and_slide(player, ground)
}

player_draw :: proc(e: Entity) {
	entity_draw_default(e)
	
	texture := 	rl.LoadTexture("assets/rocket-icon-powerup.png")
	for i in 0..<e.cur_rockets {
		rl.DrawTextureV(
		texture,
		rl.Vector2 {f32(-150 + (15 * i32(i))), 60}, //magic numbers don't mind me
		rl.WHITE,
		)
	}
}

init_player_idle_animation :: proc() -> Animation {
	return Animation {
		texture = rl.LoadTexture("assets/round_cat.png"),
		frame_count = 1,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .IDLE,
	}
}
init_player_run_animation :: proc() -> Animation {
	return Animation {
		texture = rl.LoadTexture("assets/CorgiRun.png"),
		frame_count = 4,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .RUN,
	}
}
init_player_jump_animation :: proc() -> Animation {
	return Animation {
		texture = rl.LoadTexture("assets/CorgiJump.png"),
		frame_count = 1,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .JUMP,
	}
}
init_player_fall_animation :: proc() -> Animation {
	return Animation {
		texture = rl.LoadTexture("assets/CorgiFall.png"),
		frame_count = 1,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .FALL,
	}
}
init_player_rocket_animation :: proc() -> Animation {
	return Animation {
		texture = rl.LoadTexture("assets/CorgiRocketFire.png"),
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
	if rl.GetTime() - e.last_spawn_s >= rand.float64_range(0.5, 5) {
		crab := entity_create(.CRAB)
		crab.pos = rl.Vector2{200, 20}
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

	MOVE_SPEED_MULTIPLIER :: 1

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
		case .BACKGROUND:
		case .SUN:
		case .PLAYER_HEALTH_BAR:
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
		texture = rl.LoadTexture("assets/crab/crab_run.png"),
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
	return Animation {
		texture = rl.LoadTexture("assets/ground/background.png"),
		frame_count = 1,
		kind = .NIL,
	}
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
	return Animation {
		texture = rl.LoadTexture("assets/ground/foreground.png"),
		frame_count = 1,
		kind = .NIL,
	}
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
	return Animation {
		texture = rl.LoadTexture("assets/ground/ground.png"),
		frame_count = 1,
		kind = .NIL,
	}
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
		texture = rl.LoadTexture("assets/sun.png"),
		frame_count = 4,
		frame_length = 10,
		kind = .IDLE,
	}
}

/*
* player_health_bar
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
