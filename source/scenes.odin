package game

SceneKind :: enum {
	MAIN_MENU,
	GAME,
}


scene_setup :: proc(kind: SceneKind) {
	game_state.scene_kind = kind
	switch kind {
	case .MAIN_MENU:
		main_menu_setup()
	case .GAME:
		game_setup()
	}
}
