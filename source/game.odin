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
import "core:math"
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 180
DEBUG :: false
SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
GRAVITY :: 1000
DEFAULT_MOVE_SPEED :: 150 // negative because world is moving not player
MIN_SPEED :: 75
SUN_DAMAGE :: 5
SPAWNER_DISTANCE :: 300

Handle :: struct {
	index: int,
	// Makes trying to debug thingame_state.a bit easier if we know for a fact
	// an entity cannot have the same ID as another one.
	id:    int,
}

GameState :: struct {
	// Entity
	entity_top_count:         int,
	latest_entity_id:         int,
	entities:                 [MAX_ENTITIES]Entity,
	entity_free_list:         [dynamic]int,
	// Scenes
	scene_kind:               SceneKind,
	// Stuff
	player_handle:            Handle,
	run:                      bool,
	scratch:                  struct {
		all_entities: []Handle,
	},
	// screen shake
	is_screen_shaking:        bool,
	screen_shake_time:        f64,
	screen_shake_timeElapsed: f64,
	screen_shake_dropOff:     f64,
	screen_shake_speed:       f64,
	// player move speed, but really the world
	total_distance_metres:    int,
	textures:                 Textures,
	sounds:                   Sounds,
	soundtrack:               rl.Music,
}

Sounds :: struct {
	rocket_sfx:            rl.Sound,
	jump_sfx:              rl.Sound,
	dog_pain_sfx:          rl.Sound,
	game_over:             rl.Sound,
	cooler_box_sfx:        rl.Sound,
	parasol_bounce_sfx:    rl.Sound,
	popsicle_sfx:          rl.Sound,
	seagull_takeoff_sfx:   rl.Sound,
	seagull_airborne_sfx:  rl.Sound,
	sandcastle_impact_sfx: rl.Sound,
	rocket_pickup_sfx:     rl.Sound,
}

// WARNING: if you add a texture you MUST also unload it game_shutdown
Textures :: struct {
	rocket_icon_powerup: rl.Texture2D,
	round_cat:           rl.Texture2D,
	corgi_run:           rl.Texture2D,
	corgi_jump:          rl.Texture2D,
	corgi_fall:          rl.Texture2D,
	corgi_rocket_fire:   rl.Texture2D,
	crab_run:            rl.Texture2D,
	background:          rl.Texture2D,
	foreground:          rl.Texture2D,
	ground:              rl.Texture2D,
	sun:                 rl.Texture2D,
	towel_green:         rl.Texture2D,
	towel_red:           rl.Texture2D,
	towel_yellow:        rl.Texture2D,
	pidgeon_flying:      rl.Texture2D,
	parasol:             rl.Texture2D,
	parasol_bounce:      rl.Texture2D,
	jump_poof:           rl.Texture2D,
	popsicle:            rl.Texture2D,
	title:               rl.Texture2D,
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
	// Greedy selection sort by z
	for i in 0 ..< len(all_ents) {
		min_index := i
		for j in i + 1 ..< len(all_ents) {
			ea := entity_get(all_ents[j])
			em := entity_get(all_ents[min_index])
			if ea.z_index < em.z_index {
				min_index = j
			}
		}
		if min_index != i {
			all_ents[i], all_ents[min_index] = all_ents[min_index], all_ents[i]
		}
	}
	// Sort entities by their z value (lower z drawn first, higher on top)
	game_state.scratch.all_entities = all_ents[:]
}

get_player :: proc() -> (player: ^Entity, ok: bool) #optional_ok {
	return entity_get(game_state.player_handle)
}

do_screen_shake :: proc(time_s, drop_off, speed: f64) {
	game_state.screen_shake_time = time_s
	game_state.screen_shake_dropOff = drop_off
	game_state.screen_shake_speed = speed
	game_state.is_screen_shaking = true
	game_state.screen_shake_timeElapsed = game_state.screen_shake_time
}

screen_shake :: proc(target: ^rl.Vector2) {
	game_state.screen_shake_timeElapsed -= f64(rl.GetFrameTime()) * game_state.screen_shake_dropOff

	target.x =
		target.x +
		f32(game_state.screen_shake_timeElapsed) *
			math.sin_f32(f32(rl.GetTime()) * f32(game_state.screen_shake_speed))
	target.y =
		target.y +
		f32(game_state.screen_shake_timeElapsed) *
			math.sin_f32(f32(rl.GetTime()) * f32(game_state.screen_shake_speed) * 1.3 + 1.7)

	if (game_state.screen_shake_timeElapsed <= 0) {
		game_state.is_screen_shaking = false
	}
}

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())


	target: rl.Vector2

	player := get_player()
	target = player.pos
	target.y -= 40 // negative because raylib draws upside down

	if game_state.is_screen_shaking {
		screen_shake(&target)
	}


	return {zoom = h / PIXEL_WINDOW_HEIGHT, target = target, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}


update :: proc() {

	game_state.scratch = {}
	rebuild_scratch()
	rl.UpdateMusicStream(game_state.soundtrack)
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
		case .SUN:
			sun_update(e)
		case .PLAYER_HEALTH_BAR:
			player_health_bar_update(e)
		case .TOWEL_SPAWNER:
			towel_spawner_update(e)
		case .TOWEL:
			towel_update(e)
		case .PIDGEON_SPAWNER:
			pidgeon_spawner_update(e)
		case .PIDGEON:
			pidgeon_update(e)
		case .PARASOL:
			parasol_update(e)
		case .PARASOL_SPAWNER:
			parasol_spawner_update(e)
		case .JUMP_POOF:
			jump_poof_update(e)
		case .POPSICLE:
			popsicle_update(e)
		case .POPSICLE_SPAWNER:
			popsicle_spawner_update(e)
		case .ROCKET_PICKUP:
			rocket_pickup_update(e)
		case .ROCKET_PICKUP_SPAWNER:
			rocket_pickup_spawner_update(e)
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
		case .SUN:
			sun_draw(e^)
		case .PLAYER_HEALTH_BAR:
			player_health_bar_draw(e^)
		case .TOWEL_SPAWNER:
			towel_spawner_draw(e^)
		case .TOWEL:
			towel_draw(e^)
		case .PLAYER:
			player_draw(e^)
		case .PIDGEON_SPAWNER:
			pidgeon_spawner_draw(e^)
		case .PIDGEON:
			pidgeon_draw(e^)
		case .PARASOL:
			parasol_draw(e^)
		case .PARASOL_SPAWNER:
			parasol_spawner_draw(e^)
		case .JUMP_POOF:
			jump_poof_draw(e^)
		case .POPSICLE_SPAWNER:
			popsicle_spawner_draw(e^)
		case .POPSICLE:
			popsicle_draw(e^)
		case .ROCKET_PICKUP:
			rocket_pickup_draw(e^)
		case .ROCKET_PICKUP_SPAWNER:
			rocket_pickup_spawner_draw(e^)
		}
	}

	rl.EndMode2D()
	// This is the ui that will not be effected by the shader
	rl.BeginMode2D(ui_camera())
	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	player := get_player()
	game_state.total_distance_metres = int(player.pos.x / 10)
	rl.DrawText(fmt.ctprintf("Distance: %v", game_state.total_distance_metres), 5, 5, 8, rl.WHITE)

	if DEBUG {
		rl.DrawText(fmt.ctprintf("Velocity: %v", player.velocity.x), 5, 20, 8, rl.PINK)
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

	rl.InitAudioDevice()
	entity_init_core() // Initialize the safe default entity
	game_state = new(GameState)
	game_state^ = GameState {
		run = true,
		screen_shake_time = 4.0,
		screen_shake_dropOff = 5.1,
		screen_shake_speed = 40.0,
		sounds = {
			rocket_sfx = rl.LoadSound("assets/SFX/RocketLaunch_SFX_quick.wav"),
			jump_sfx = rl.LoadSound("assets/SFX/Sand-Jump.wav"),
			dog_pain_sfx = rl.LoadSound("assets/SFX/Sad_Dog_Bark_Single.wav"),
			game_over = rl.LoadSound("assets/SFX/Sad_Dog_Barking.wav"),
			cooler_box_sfx = rl.LoadSound("assets/SFX/CoolerBox_SFX.wav"),
			parasol_bounce_sfx = rl.LoadSound("assets/SFX/Parasol_SFX_3.wav"),
			popsicle_sfx = rl.LoadSound("assets/SFX/popsicle_SFX_1.wav"),
			seagull_takeoff_sfx = rl.LoadSound("assets/SFX/Seagull Grounded SFX.wav"),
			seagull_airborne_sfx = rl.LoadSound("assets/SFX/Seagull Flying SFX.wav"),
			sandcastle_impact_sfx = rl.LoadSound("assets/SFX/Sandcastle-Impact.wav"),
			rocket_pickup_sfx = rl.LoadSound("assets/SFX/Rocket_pickup.wav"),
		},
		soundtrack = rl.LoadMusicStream("assets/SFX/Endless Scamper.mp3"),
		textures = {
			// Load all textures
			// WARNING: if you add a texture you MUST also unload it game_shutdown
			rocket_icon_powerup = rl.LoadTexture("assets/rocket-icon-powerup.png"),
			round_cat           = rl.LoadTexture("assets/round_cat.png"),
			corgi_run           = rl.LoadTexture("assets/CorgiRun.png"),
			corgi_jump          = rl.LoadTexture("assets/CorgiJump.png"),
			corgi_fall          = rl.LoadTexture("assets/CorgiFall.png"),
			corgi_rocket_fire   = rl.LoadTexture("assets/CorgiRocketFire.png"),
			crab_run            = rl.LoadTexture("assets/crab/crab_run.png"),
			background          = rl.LoadTexture("assets/ground/background.png"),
			foreground          = rl.LoadTexture("assets/ground/foreground.png"),
			ground              = rl.LoadTexture("assets/ground/ground.png"),
			sun                 = rl.LoadTexture("assets/sun.png"),
			towel_green         = rl.LoadTexture("assets/GreenTowel.png"),
			towel_red           = rl.LoadTexture("assets/RedTowel.png"),
			towel_yellow        = rl.LoadTexture("assets/YellowTowel.png"),
			pidgeon_flying      = rl.LoadTexture("assets/pidgeon_flying.png"),
			parasol             = rl.LoadTexture("assets/parasol.png"),
			parasol_bounce      = rl.LoadTexture("assets/parasol-bounce.png"),
			jump_poof           = rl.LoadTexture("assets/jump-poof.png"),
			popsicle            = rl.LoadTexture("assets/Popsicle.png"),
			title               = rl.LoadTexture("assets/CorgiTitle.png"),
		},
	}


	scene_setup(.MAIN_MENU)

	game_hot_reloaded(game_state)
	rl.PlayMusicStream(game_state.soundtrack)
	rl.SetSoundVolume(game_state.sounds.jump_sfx, .2)
	rl.SetSoundVolume(game_state.sounds.popsicle_sfx, 1.2)
	rl.SetSoundVolume(game_state.sounds.rocket_pickup_sfx, .2)
	rl.SetSoundVolume(game_state.sounds.seagull_airborne_sfx, .4)
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
	// Unload all textures
	rl.UnloadTexture(game_state.textures.rocket_icon_powerup)
	rl.UnloadTexture(game_state.textures.round_cat)
	rl.UnloadTexture(game_state.textures.corgi_run)
	rl.UnloadTexture(game_state.textures.corgi_jump)
	rl.UnloadTexture(game_state.textures.corgi_fall)
	rl.UnloadTexture(game_state.textures.corgi_rocket_fire)
	rl.UnloadTexture(game_state.textures.crab_run)
	rl.UnloadTexture(game_state.textures.background)
	rl.UnloadTexture(game_state.textures.foreground)
	rl.UnloadTexture(game_state.textures.ground)
	rl.UnloadTexture(game_state.textures.sun)
	rl.UnloadTexture(game_state.textures.towel_green)
	rl.UnloadTexture(game_state.textures.towel_red)
	rl.UnloadTexture(game_state.textures.towel_yellow)
	rl.UnloadTexture(game_state.textures.pidgeon_flying)
	rl.UnloadTexture(game_state.textures.parasol)
	rl.UnloadTexture(game_state.textures.parasol_bounce)
	rl.UnloadTexture(game_state.textures.jump_poof)
	rl.UnloadTexture(game_state.textures.popsicle)
	rl.UnloadTexture(game_state.textures.title)

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
