package game

import "core:fmt"
import rl "vendor:raylib"

MAX_ENTITIES :: 2048

zero_entity: Entity // #readonly for zeroing entities

EntityKind :: enum {
	NIL,
	PLAYER,
	CRAB,
	GROUND,
	FOREGROUND,
	BACKGROUND,
	PLAY_BUTTON,
	CRAB_SPAWNER,
	SUN,
	PLAYER_HEALTH_BAR,
}

EntityTextureOffset :: enum {
	CENTER,
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

Entity :: struct {
	handle:               Handle,
	kind:                 EntityKind,
	collision:            CollisionShape,
	pos:                  rl.Vector2,
	velocity:             rl.Vector2,
	rotation:             f32,
	scale:                f32,
	has_physics:          bool,
	texture_offset:       EntityTextureOffset,
	animation:            Animation,
	hidden:               bool,
	lifespan_s:           f64,
	is_on_ground:         bool,
	created_on:           f64,

	// SPAWNER
	last_spawn_s:         f64, // since game init
	spawner_interval_s:   f64,

	// Player
	cur_health:           f32,
	max_health:           f32,
	health_bar_width:     f32,
	health_bar_max_width: f32,
	cur_rockets:          int,
	max_rockets:          int,
}


entity_draw_default :: proc(e: Entity) {
	texture := e.animation.texture
	offset := get_texture_position(e)
	destination := rl.Rectangle {
		x      = offset.x,
		y      = offset.y,
		width  = f32(texture.width) * e.scale / f32(e.animation.frame_count),
		height = f32(texture.height) * e.scale,
	}

	src := get_source_rect(e.animation)
	if e.animation.flip_x {
		src.width = -src.width
		src.x += -src.width
	}

	rl.DrawTexturePro(texture, src, destination, e.rotation, e.scale, rl.WHITE)
	if DEBUG {
		rl.DrawCircleV(e.pos, 2, rl.PINK)
		rl.DrawRectangleRec(e.collision.rectangle, rl.ColorAlpha(rl.BLUE, .50))
	}
}

get_texture_position :: proc(e: Entity) -> rl.Vector2 {
	texture_width := f32(e.animation.texture.width / i32(e.animation.frame_count))
	texture_height := f32(e.animation.texture.height)

	switch e.texture_offset {
	case .CENTER:
		return rl.Vector2 {
			e.pos.x - texture_width / 2 * e.scale,
			e.pos.y - texture_height / 2 * e.scale,
		}
	case .TOP:
		return rl.Vector2{e.pos.x - texture_width / 2 * e.scale, e.pos.y}
	case .BOTTOM:
		return rl.Vector2{e.pos.x - texture_width / 2 * e.scale, e.pos.y - texture_height / 2}
	case .LEFT:
		return rl.Vector2{e.pos.x, e.pos.y - texture_height / 2 * e.scale}
	case .RIGHT:
		return rl.Vector2{e.pos.x - texture_width, e.pos.y - texture_height / 2 * e.scale}
	case:
		return e.pos
	}
}

entity_move_and_slide :: proc(entity_a, entity_b: ^Entity) {
	entity_a_rect := entity_a.collision.rectangle
	entity_b_rect := entity_b.collision.rectangle

	overlap := get_rect_overlap(entity_a_rect, entity_b_rect)

	if overlap.x < overlap.y {
		// Push along X axis
		if entity_a_rect.x < entity_b_rect.x {
			entity_a.pos.x -= overlap.x
		} else {
			entity_a.pos.x += overlap.x
		}
	} else {
		// Push along Y axis
		if entity_a_rect.y < entity_b_rect.y {
			entity_a.pos.y -= overlap.y
		} else {
			entity_a.pos.y += overlap.y
		}
	}

	collision_box_update(entity_a)
}

entity_is_valid :: proc {
	entity_is_valid_no_ptr,
	entity_is_valid_ptr,
}
entity_is_valid_no_ptr :: proc(entity: Entity) -> bool {
	return entity.handle.id != 0
}
entity_is_valid_ptr :: proc(entity: ^Entity) -> bool {
	return entity != nil && entity_is_valid(entity^)
}
entity_init_core :: proc() {
	// make sure the zero entity has good defaults, so we don't crash on stuff like functions pointers
	entity_setup(&zero_entity, .NIL)
}

entity_get_all :: proc() -> []Handle {
	return game_state.scratch.all_entities
}

entity_get :: proc(handle: Handle) -> (entity: ^Entity, ok: bool) #optional_ok {
	if handle.index <= 0 || handle.index > game_state.entity_top_count {
		return &zero_entity, false
	}

	ent := &game_state.entities[handle.index]
	if ent.handle.id != handle.id {
		return &zero_entity, false
	}

	return ent, true
}

entity_clear_all :: proc() {
	for ent in game_state.scratch.all_entities {
		entity_destroy(entity_get(ent))
	}
}

entity_create :: proc(kind: EntityKind) -> ^Entity {

	index := -1
	if len(game_state.entity_free_list) > 0 {
		index = pop(&game_state.entity_free_list)
	}

	if index == -1 {
		assert(
			game_state.entity_top_count + 1 < MAX_ENTITIES,
			"ran out of entities, increase size",
		)
		game_state.entity_top_count += 1
		index = game_state.entity_top_count
	}

	ent := &game_state.entities[index]
	ent.handle.index = index
	ent.handle.id = game_state.latest_entity_id + 1
	game_state.latest_entity_id = ent.handle.id
	entity_setup(ent, kind)
	fmt.assertf(ent.kind != nil, "entity %v needs to define a kind during setup", kind)

	return ent
}

entity_destroy :: proc(e: ^Entity) {
	append(&game_state.entity_free_list, e.handle.index)
	e^ = {}
}

entity_setup :: proc(e: ^Entity, kind: EntityKind) {
	// entity defaults
	e.scale = 1
	e.kind = kind
	e.created_on = rl.GetTime()

	switch kind {
	case .NIL:
	case .PLAYER:
		player_setup(e)
	case .CRAB:
		crab_setup(e)
	case .GROUND:
		ground_setup(e)
	case .PLAY_BUTTON:
		play_button_setup(e)
	case .CRAB_SPAWNER:
		crab_spawner_setup(e)
	case .FOREGROUND:
		foreground_setup(e)
	case .BACKGROUND:
		background_setup(e)
	case .SUN:
		sun_setup(e)
	case .PLAYER_HEALTH_BAR:
		player_health_bar_setup(e)
	}
}
