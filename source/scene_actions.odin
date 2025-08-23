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
	player := entity_create(.PLAYER)
	game_state.player_handle = player.handle

	// floor setup
	ground_1 := entity_create(.GROUND)
	ground_text_width := f32(ground_1.animation.texture.width)
	ground_2 := entity_create(.GROUND)
	ground_2.pos.x += ground_text_width
	ground_3 := entity_create(.GROUND)
	ground_3.pos.x += ground_2.pos.x + ground_text_width
	ground_4 := entity_create(.GROUND)
	ground_4.pos.x += ground_3.pos.x + ground_text_width

	entity_create(.CRAB_SPAWNER)
}

game_transition :: proc(scene: ^Scene) {
}

game_destroy :: proc(dead_scene: Scene) {
	entity_clear_all()
}
