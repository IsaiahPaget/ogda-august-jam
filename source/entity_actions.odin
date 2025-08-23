package game
import "core:fmt"
import rl "vendor:raylib"

/*
* PLAYER
*/
player_setup :: proc(e: ^Entity) {
	e.pos.x = 5
	e.pos.y = 5
	e.texture_offset = .CENTER
	e.collision.rectangle = rl.Rectangle {
		x = e.pos.x,
		y = e.pos.y,
		width  = 15,
		height = 15,
	}
	e.collision.offset = .CENTER
	e.collision.is_active = true
	e.animation = init_player_run_animation()
	e.has_physics = true
}


player_update :: proc(e: ^Entity) {
	fmt.assertf(e != nil, "player missing", e)

	if rl.IsKeyPressed(.SPACE) {
		e.velocity.y = -100 // negative because the world is drawn from top to.CENTER
		e.is_on_ground = false
	}

	if e.has_physics {
		if !e.is_on_ground {
			e.velocity.y += get_applied_gravity()
		}
	}

	e.pos.x += e.velocity.x * rl.GetFrameTime()
	e.pos.y += e.velocity.y * rl.GetFrameTime()

	process_collisions(e, proc(entity_a, entity_b: ^Entity) {
		switch entity_b.kind {
		case .NIL:
		case .PLAY_BUTTON:
		case .PLAYER:
		case .COOKIE:
			entity_destroy(entity_b)
		case .GROUND:
			player_on_collide_ground(entity_a, entity_b)
		}
	})
}
player_on_collide_ground :: proc(player: ^Entity, ground: ^Entity) {
	player.is_on_ground = true
	player.velocity.y = 0
	entity_move_and_slide(player, ground)
}

player_draw :: proc(e: Entity) {
	entity_draw_default(e)
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
		texture = rl.LoadTexture("assets/cat_run.png"),
		frame_count = 4,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .RUN,
	}
}

/*
* COOKIE
*/
cookie_setup :: proc(e: ^Entity) {
	e.animation = init_cookie_idle_anim()
	e.texture_offset = .CENTER
	e.collision.rectangle = rl.Rectangle {
		width  = 10,
		height = 10,
	}
	e.collision.offset = .CENTER
	e.collision.is_active = true
}

cookie_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

cookie_update :: proc(e: ^Entity) {
	collision_box_update(e)
}

init_cookie_idle_anim :: proc() -> Animation {
	return Animation {
		texture = rl.LoadTexture("assets/round_cat.png"),
		frame_count = 1,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .IDLE,
	}
}

/*
* Ground
*/
ground_setup :: proc(e: ^Entity) {
	e.pos.y = 100
	e.texture_offset = .CENTER
	e.animation = init_ground_anim()
	e.collision.rectangle = rl.Rectangle {
		x = e.pos.x,
		y = e.pos.y,
		width  = f32(e.animation.texture.width + 1),
		height = f32(e.animation.texture.height + 1),
	}
	e.collision.offset = .CENTER
	e.collision.is_active = true
}

ground_update :: proc(e: ^Entity) {
	collision_box_update(e)
}

ground_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

init_ground_anim :: proc() -> Animation {
	return Animation {
		texture = rl.LoadTexture("assets/grass_block.png"),
		frame_count = 1,
		kind = .NIL,
	}
}


/*
* Play button
*/

play_button_setup :: proc(e: ^Entity) {
}
play_button_update :: proc(e: ^Entity) {
	if rl.IsKeyPressed(.ENTER) {
		scene_push(.GAME)
	}
}
play_button_draw :: proc(e: Entity) {
	rl.DrawRectangleV(rl.Vector2{e.pos.x, e.pos.y}, rl.Vector2{200, 80}, rl.DARKGRAY)
}

// init_play_button_anim :: proc() -> Animation {
// 	return Animation {
// 		texture = rl.LoadTexture("assets/grass_block.png"),
// 		frame_count = 1,
// 		kind = .NIL,
// 	}
// }
