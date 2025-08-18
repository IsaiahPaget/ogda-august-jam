package game

/*
* Main Menu
*/
main_menu_setup :: proc(scene: ^Scene) {
	entity_create(.COOKIE)
}

main_menu_destroy :: proc(dead_scene: Scene) {
	entity_clear_all()
}

/*
* Game
*/
game_setup :: proc(scene: ^Scene) {
	entity_clear_all()
	entity_create(.PLAYER)	
}

game_destroy :: proc(dead_scene: Scene) {
	entity_clear_all()
}
