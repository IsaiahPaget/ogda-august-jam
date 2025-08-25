package game

/*
* MAIN MENU
*/
main_menu_setup :: proc() {
	entity_clear_all()
	entity_create(.PLAY_BUTTON)
}

/*
* GAME
*/
game_setup :: proc() {
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

	game_state.screen_shake_time = 4.0
	game_state.screen_shake_dropOff = 5.1
	game_state.screen_shake_speed = 40.0
	game_state.current_speed = DEFAULT_MOVE_SPEED
	game_state.target_speed = DEFAULT_MOVE_SPEED
	game_state.total_distance_metres = 0

	entity_create(.SUN)
	entity_create(.CRAB_SPAWNER)
	entity_create(.TOWEL_SPAWNER)
	entity_create(.PIDGEON_SPAWNER)
	entity_create(.PARASOL_SPAWNER)
	entity_create(.POPSICLE_SPAWNER)
	entity_create(.ROCKET_PICKUP_SPAWNER)
}
