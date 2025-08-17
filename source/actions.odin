package game
import rl "vendor:raylib"
import "core:fmt"

/*
* PLAYER
*/
player_setup :: proc(e: ^Entity) {
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
    player_rect := player.collision.rectangle
    wall_rect := wall.collision.rectangle

    overlap := get_rect_overlap(player_rect, wall_rect)

    if overlap.x < overlap.y {
        // Push along X axis
        if player_rect.x < wall_rect.x {
            player.pos.x -= overlap.x
        } else {
            player.pos.x += overlap.x
        }
    } else {
        // Push along Y axis
        if player_rect.y < wall_rect.y {
            player.pos.y -= overlap.y
        } else {
            player.pos.y += overlap.y
        }
    }

	collision_box_update(player)
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

/*
* WALL
*/
wall_setup :: proc(e: ^Entity) {
	e.pos.x = 100
	e.texture_offset = .BOTTOM
	e.animation = init_wall_anim()
	e.collision.rectangle = rl.Rectangle {
		width  = f32(e.animation.texture.width + 1),
		height = f32(e.animation.texture.height + 1),
	}
	e.collision.offset = .BOTTOM
	e.collision.is_active = true
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
