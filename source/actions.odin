package game
import rl "vendor:raylib"

/*
* PLAYER
*/
player_setup :: proc(e: ^Entity) {
	e.kind = .PLAYER
	e.pos.x = 50
	e.texture_offset = .BOTTOM
	e.collision.rectangle = rl.Rectangle {
		width  = 15,
		height = 15,
	}
	e.collision.offset = .BOTTOM
	e.collision.is_active = true
	e.animation = init_player_run_animation()
}


player_update :: proc(e: ^Entity) {
	input := input_dir_normalized()

	if input.x < 0 {
		e.animation.flip_x = true
	} else {
		e.animation.flip_x = false
	}
	e.pos += input * rl.GetFrameTime() * 100

	process_collisions(e, proc(entity_b: ^Entity) {
		#partial switch entity_b.kind {
		case .COOKIE:
			entity_destroy(entity_b)
		}
	})
	collision_box_update(e)
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
	e.kind = .COOKIE

	e.animation = init_cookie_idle_anim()
	e.texture_offset = .BOTTOM
	e.collision.rectangle = rl.Rectangle {
		width  = 10,
		height = 10,
	}
	e.collision.offset = .BOTTOM
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
