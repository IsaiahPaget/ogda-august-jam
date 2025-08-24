package game

/*
* MAIN MENU
*/
main_menu_setup :: proc(scene: ^Scene) {
	entity_clear_all()
	entity_create(.PLAY_BUTTON)
}

main_menu_transition :: proc(scene: ^Scene) {
}

main_menu_destroy :: proc(dead_scene: Scene) {
	entity_clear_all()
}

/*
* GAME
*/
game_setup :: proc(scene: ^Scene) {
	entity_clear_all()

	// floor init
	background_1 := entity_create(.BACKGROUND)
	background_text_width := f32(background_1.animation.texture.width)
	background_2 := entity_create(.BACKGROUND)
	background_2.pos.x += background_text_width
	background_3 := entity_create(.BACKGROUND)
	background_3.pos.x += background_2.pos.x + background_text_width

	ground_1 := entity_create(.GROUND)
	ground_text_width := f32(ground_1.animation.texture.width)
	ground_2 := entity_create(.GROUND)
	ground_2.pos.x += ground_text_width
	ground_3 := entity_create(.GROUND)
	ground_3.pos.x += ground_2.pos.x + ground_text_width

	foreground_1 := entity_create(.FOREGROUND)
	foreground_text_width := f32(foreground_1.animation.texture.width)
	foreground_2 := entity_create(.FOREGROUND)
	foreground_2.pos.x += foreground_text_width
	foreground_3 := entity_create(.FOREGROUND)
	foreground_3.pos.x += foreground_2.pos.x + foreground_text_width

	// player init
	player := entity_create(.PLAYER)
	game_state.player_handle = player.handle

	entity_create(.SUN)
	entity_create(.CRAB_SPAWNER)
}

game_transition :: proc(scene: ^Scene) {
}

game_destroy :: proc(dead_scene: Scene) {
	entity_clear_all()
}
