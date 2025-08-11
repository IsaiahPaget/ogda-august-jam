package game
import rl "vendor:raylib"

/*
* PLAYER
*/
player_setup :: proc(e: ^Entity) {
	e.kind = .PLAYER
	e.texture = rl.LoadTexture("assets/round_cat.png")
	collision_shape_create(.HIT, e.handle, {
		x = 10,
		y = 10,
		width = 30,
		height = 30,
	})
}
player_update :: proc(e: ^Entity) {
	input := input_dir_normalized()
	e.pos += input * rl.GetFrameTime() * 100
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
}

cookie_draw :: proc(e: Entity) {
	rl.DrawTextureEx(e.texture, e.pos, e.rotation, e.scale, rl.RED)
}


