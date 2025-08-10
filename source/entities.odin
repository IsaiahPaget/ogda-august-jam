package game
import rl "vendor:raylib"
import "core:fmt"

/*
* PLAYER
*/
player_setup :: proc(e: ^Entity) {
	e.kind = .PLAYER
	e.texture = rl.LoadTexture("assets/round_cat.png")
	e.collision.has_collision = true
	e.collision.rect = rl.Rectangle{
		x = -10,
		y = -10,
		width = 25,
		height = 25,
	}
}
player_update :: proc(e: ^Entity) {
	input := input_dir_normalized()
	e.pos += input * rl.GetFrameTime() * 100
	e.collision.rect.x = e.pos.x - 10
	e.collision.rect.y = e.pos.y - 10

	if len(e.entities_colliding) > 0 {
		fmt.println(e.entities_colliding)
	}

}

player_draw :: proc(e: Entity) {
	draw_entity_default(e)
	if DEBUG {
		rl.DrawRectangleRec(e.collision.rect, rl.BLUE)
	}
}

/*
* COOKIE
*/
cookie_setup :: proc(e: ^Entity) {
	e.kind = .COOKIE
	e.texture = rl.LoadTexture("assets/round_cat.png")
	e.collision.rect = rl.Rectangle{
		x = -10,
		y = -10,
		width = 25,
		height = 25,
	}
}

cookie_draw :: proc(e: Entity) {
	rl.DrawTextureEx(e.texture, e.pos, e.rotation, e.scale, rl.RED)
	if DEBUG {
		rl.DrawRectangleRec(e.collision.rect, rl.YELLOW)
	}
}


