package game
import "core:fmt"
import box "vendor:box2d"
import rl "vendor:raylib"

/*
* PLAYER
*/
player_setup :: proc(e: ^Entity) {
	e.pos.x = 50
	e.texture_offset = .CENTER
	e.body_rectangle = rl.Rectangle {
		width  = 15,
		height = 15,
	}
	e.offset = .CENTER
	e.has_collision = true
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

	process_collisions(e, proc(entity_a, entity_b: ^Entity) {
		#partial switch entity_b.kind {
		case .COOKIE:
			entity_destroy(entity_b)
		case .WALL:
			player_on_collide_wall(entity_a, entity_b)
		}
	})
}
player_on_collide_wall :: proc(player: ^Entity, wall: ^Entity) {
	fmt.assertf(player != nil, "Player is missing in player_on_collide_wall")
	fmt.assertf(wall != nil, "Wall is missing in player_on_collide_wall")
	entity_move_and_slide(player, wall)
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
	e.body_rectangle = rl.Rectangle {
		width  = 10,
		height = 10,
	}
	e.offset = .CENTER
	e.has_collision = true

	init_default_physics(e, 1, 0.3, .dynamicBody)
}

cookie_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

cookie_update :: proc(e: ^Entity) {
	e.pos = box.Body_GetPosition(e.body_id)
	e.rotation = box.Rot_GetAngle(box.Body_GetRotation(e.body_id))

	collision_box_update(e)
	if rl.IsKeyPressed(.ENTER) {
		scene_push(.GAME)
	}
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
* WALL
*/
wall_setup :: proc(e: ^Entity) {
	e.pos.y = 50
	e.texture_offset = .CENTER
	e.animation = init_wall_anim()
	e.body_rectangle = rl.Rectangle {
		width  = f32(e.animation.texture.width + 1),
		height = f32(e.animation.texture.height + 1),
	}
	e.offset = .CENTER
	e.has_collision = true

	init_default_physics(e, 0, 0.3)

}

wall_update :: proc(e: ^Entity) {
	collision_box_update(e)
}

wall_draw :: proc(e: Entity) {
	entity_draw_default(e)
}

init_wall_anim :: proc() -> Animation {
	return Animation {
		texture = rl.LoadTexture("assets/grass_block.png"),
		frame_count = 1,
		kind = .NIL,
	}
}
