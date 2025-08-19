package game

import "core:fmt"
MAX_SCENES :: 48

Scene :: struct {
	kind: SceneKind,
}

SceneKind :: enum {
	MAIN_MENU,
	GAME,
}

scene_push :: proc(kind: SceneKind) -> ^Scene {

	fmt.assertf(
		len(game_state.scenes) <= MAX_SCENES,
		"too many scenes on the stack, increase the size",
	)
	if len(game_state.scenes) > 0 {
		current_scene := &game_state.scenes[len(game_state.scenes) - 1]
		switch current_scene.kind {
		case .GAME:
			game_transition(current_scene)
		case .MAIN_MENU:
			main_menu_transition(current_scene)
		}
	}

	scene: Scene
	_, err := append(&game_state.scenes, scene)
	fmt.assertf(err == .None, "error: ", err)

	index := len(game_state.scenes) - 1

	scene_setup(&game_state.scenes[index], kind)

	return &game_state.scenes[index]
}

scene_pop :: proc() -> Scene {
	scene := pop(&game_state.scenes)
	switch scene.kind {
	case .MAIN_MENU:
		main_menu_destroy(scene)
	case .GAME:
		game_destroy(scene)
	}
	return scene
}

scene_get :: proc() -> ^Scene {
	fmt.assertf(len(game_state.scenes) > 0, "scene stack is empty")
	return &game_state.scenes[len(game_state.scenes) - 1]
}

scene_setup :: proc(scene: ^Scene, kind: SceneKind) {
	// scene defaults
	scene.kind = kind

	switch kind {
	case .MAIN_MENU:
		main_menu_setup(scene)
	case .GAME:
		game_setup(scene)
	}
}
