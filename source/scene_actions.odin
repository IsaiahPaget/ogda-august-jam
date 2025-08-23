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
	entity_create(.GROUND)
	entity_create(.CRAB_SPAWNER)
}

game_transition :: proc(scene: ^Scene) {
}

game_destroy :: proc(dead_scene: Scene) {
	entity_clear_all()
}
