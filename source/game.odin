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

PIXEL_WINDOW_HEIGHT :: 180
DEBUG :: true


Camera :: struct {}
GameState :: struct {
	// Entity
	entity_top_count:           int,
	latest_entity_id:           int,
	entities:                   [MAX_ENTITIES]Entity,
	entity_free_list:           [dynamic]int,
	// Collision Shape
	collision_shapes_count:     int,
	latest_collision_shape_id:  int,
	collision_shapes:           [MAX_COLLISION_SHAPES]CollisionShape,
	collision_shapes_free_list: [dynamic]int,
	// Collision Event
	collision_events:           [MAX_COLLISION_EVENTS]CollisionEvent,
	collision_event_count:      int,
	// Stuff
	game_camera:                Camera,
	ui_camera:                  Camera,
	player_handle:              EntityHandle,
	run:                        bool,
	scratch:                    struct {
		all_entities:          []EntityHandle,
		all_collisions_shapes: []CollisionShape,
		all_collision_events:  []CollisionEvent,
	},
}

game_state: ^GameState

rebuild_scratch :: proc() {
	game_state.scratch = {} // auto-zero scratch for each update

	/*
	* Entities
	*/
	all_ents := make([dynamic]EntityHandle, 0, len(game_state.entities))
	for &e in game_state.entities {
		if !entity_is_valid(e) do continue
		append(&all_ents, e.handle)
	}
	game_state.scratch.all_entities = all_ents[:]

	/*
	* Collision Shapes
	*/
	all_shapes := make([dynamic]CollisionShape, 0, len(game_state.collision_shapes))
	for &shape in game_state.collision_shapes {
		if !collision_shape_is_valid(shape) do continue
		append(&all_shapes, shape)
	}
	game_state.scratch.all_collisions_shapes = all_shapes[:]

	/*
	* Collision Events
	*/
	all_events := make([dynamic]CollisionEvent, 0, len(game_state.collision_events))
	for &event in game_state.collision_events {
		if event.kind == nil do continue
		append(&all_events, event)
	}
	game_state.scratch.all_collision_events = all_events[:]
}

get_player :: proc() -> ^Entity {
	return entity_get(game_state.player_handle)
}

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {zoom = h / PIXEL_WINDOW_HEIGHT, target = get_player().pos, offset = {w / 2, h / 2}}
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
	// reset the collision buffers
	game_state.collision_event_count = 0

	rebuild_scratch()

	for type in CollisionShapeType {
		check_collisions_for_type(type)
	}

	// big :update time
	for handle in entity_get_all() {
		e := entity_get(handle)

		switch e.kind {
		case .NIL:
		case .PLAYER:
			player_update(e)
		case .COOKIE:
		}
	}

	if DEBUG {
		if rl.IsKeyPressed(.E) {
			fmt.println(game_state.scratch.all_collisions_shapes)
		}
	}

	if rl.IsKeyPressed(.ESCAPE) {
		game_state.run = false
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.GRAY)

	rl.BeginMode2D(game_camera())
	// big :update time
	for handle in entity_get_all() {
		e := entity_get(handle)

		switch e.kind {
		case .NIL:
		case .PLAYER:
			player_draw(e^)
		case .COOKIE:
			cookie_draw(e^)
		}

	}
	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	rl.DrawText(fmt.ctprintf("player_pos: %v", get_player().pos), 5, 5, 8, rl.WHITE)

	rl.EndMode2D()

	rl.EndDrawing()
}

draw_entity_default :: proc(e: Entity) {
	rl.DrawTextureEx(e.texture, e.pos, e.rotation, e.scale, rl.WHITE)
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
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "ogda august rl")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {

	entity_init_core() // Initialize the safe default entity
	game_state = new(GameState)
	game_state^ = GameState {
		run = true,
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

	if game_state.player_handle.id == 0 {
		player := entity_create(.PLAYER)
		game_state.player_handle = player.handle
	}

	// entity_create(.COOKIE)
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
