/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
	pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g` global
	variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"
import "core:math"

PIXEL_WINDOW_HEIGHT :: 180
DEBUG :: true
SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
GRAVITY :: 1000
// GLSL_VERSION :: 330

Handle :: struct {
	index: int,
	// Makes trying to debug thingame_state.a bit easier if we know for a fact
	// an entity cannot have the same ID as another one.
	id:    int,
}

GameState :: struct {
	// Entity
	entity_top_count: int,
	latest_entity_id: int,
	entities:         [MAX_ENTITIES]Entity,
	entity_free_list: [dynamic]int,
	// Scenes
	scenes:           [dynamic]Scene,
	// Stuff
	player_handle:    Handle,
	run:              bool,
	scratch:          struct {
		all_entities: []Handle,
	},
	is_screen_shaking: bool,
	screen_shake_time: f64,
	screen_shake_timeElapsed: f64,
	screen_shake_dropOff : f64,
	screen_shake_speed : f64,
}

game_state: ^GameState


rebuild_scratch :: proc() {
	/*
	* Entities
	*/
	all_ents := make([dynamic]Handle, 0, len(game_state.entities), context.temp_allocator)
	for &e in game_state.entities {
		if !entity_is_valid(e) do continue
		append(&all_ents, e.handle)
	}
	game_state.scratch.all_entities = all_ents[:]
}

get_player :: proc() -> (player: ^Entity, ok: bool) #optional_ok {
	return entity_get(game_state.player_handle)
}

screen_shake :: proc(target: ^rl.Vector2) {
	game_state.screen_shake_timeElapsed -= f64(rl.GetFrameTime()) * game_state.screen_shake_dropOff

	target.x = target.x + f32(game_state.screen_shake_timeElapsed) * math.sin_f32(f32(rl.GetTime()) * f32(game_state.screen_shake_speed))
	target.y = target.y + f32(game_state.screen_shake_timeElapsed) * math.sin_f32(f32(rl.GetTime()) * f32(game_state.screen_shake_speed) * 1.3 + 1.7)

	if(game_state.screen_shake_timeElapsed <= 0) {
		game_state.is_screen_shaking = false
	}
}

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	player, ok := get_player()
	
	target : rl.Vector2 = player.pos if ok else rl.Vector2(0)

	if game_state.is_screen_shaking { 
		screen_shake(&target) 
	}

	return {zoom = h / PIXEL_WINDOW_HEIGHT, target = target, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

input_dir_normalized :: proc() -> rl.Vector2 {

	input: rl.Vector2

	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	input = linalg.normalize0(input)
	return input
}

update :: proc() {

	game_state.scratch = {}
	rebuild_scratch()

	// big :update time
	for handle in entity_get_all() {
		e := entity_get(handle)

		// animation for every entity
		animate(e)

		switch e.kind {
		case .NIL:
		case .PLAYER:
			player_update(e)
		case .CRAB:
			crab_update(e)
		case .GROUND:
			ground_update(e)
		case .PLAY_BUTTON:
			play_button_update(e)
		case .CRAB_SPAWNER:
			crab_spawner_update(e)
		case .FOREGROUND:
			foreground_update(e)
		case .BACKGROUND:
			background_update(e)
		}
	}

	if rl.IsKeyPressed(.ESCAPE) {
		game_state.run = false
	}
}

draw :: proc() {

	// draw to the window
	rl.BeginDrawing()

	rl.ClearBackground(rl.Color{155, 219, 245, 1})

	rl.BeginMode2D(game_camera())
	// big :update time
	for handle in entity_get_all() {
		e := entity_get(handle)
		if e.hidden do continue

		switch e.kind {
		case .NIL:
		case .PLAYER:
			player_draw(e^)
		case .CRAB:
			crab_draw(e^)
		case .GROUND:
			ground_draw(e^)
		case .PLAY_BUTTON:
			play_button_draw(e^)
		case .CRAB_SPAWNER:
			crab_spawner_draw(e^)
		case .FOREGROUND:
			foreground_draw(e^)
		case .BACKGROUND:
			background_draw(e^)
		}
	}

	rl.EndMode2D()
	// This is the ui that will not be effected by the shader
	rl.BeginMode2D(ui_camera())
	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	if DEBUG {
		player, ok := get_player()
		if ok {
			rl.DrawText(fmt.ctprintf("player_pos: %v", player.pos), 5, 5, 8, rl.WHITE)
		}
	}
	rl.EndMode2D()

	rl.EndDrawing()
}


@(export)
game_update :: proc() {
	update()
	draw()

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "ogda august rl")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(144)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {


	entity_init_core() // Initialize the safe default entity
	game_state = new(GameState)
	game_state^ = GameState {
		run            = true,
		screen_shake_time = 4.0,
		screen_shake_dropOff = 5.1,
		screen_shake_speed = 40.0,
	}

	if len(game_state.scenes) == 0 {
		scene_push(.MAIN_MENU)
	}

	game_hot_reloaded(game_state)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return game_state.run
}

@(export)
game_shutdown :: proc() {
	delete(game_state.scenes) // free the scenes array
	delete(game_state.entity_free_list) // free the entity freelist
	free(game_state)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return game_state
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(GameState)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	game_state = (^GameState)(mem)

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside `g`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
