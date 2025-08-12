package game
import rl "vendor:raylib"

/*
* PLAYER
*/
player_setup :: proc(e: ^Entity) {
	e.kind = .PLAYER
	e.pos.x = 50
	e.texture = rl.LoadTexture("assets/round_cat.png")
	e.texture_offset = .BOTTOM
	e.collision.rectangle = rl.Rectangle {
		width  = f32(e.texture.width),
		height = f32(e.texture.height),
	}
	e.collision.offset = .BOTTOM
	e.collision.is_active = true
}
player_update :: proc(e: ^Entity) {
	input := input_dir_normalized()
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
	draw_entity_default(e)
}

/*
* COOKIE
*/
cookie_setup :: proc(e: ^Entity) {
	e.kind = .COOKIE
	e.texture = rl.LoadTexture("assets/round_cat.png")
	e.texture_offset = .BOTTOM
	e.collision.rectangle = rl.Rectangle {
		width  = 10,
		height = 10,
	}
	e.collision.offset = .BOTTOM
	e.collision.is_active = true
}

cookie_draw :: proc(e: Entity) {
	rl.DrawTextureEx(e.texture, get_texture_position(e), e.rotation, e.scale, rl.RED)
}
