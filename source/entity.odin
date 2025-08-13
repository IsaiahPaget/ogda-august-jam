package game

import "core:fmt"
import rl "vendor:raylib"

MAX_ENTITIES :: 2048

zero_entity: Entity // #readonly for zeroing entities

EntityHandle :: struct {
	index: int,
	// Makes trying to debug thingame_state.a bit easier if we know for a fact
	// an entity cannot have the same ID as another one.
	id:    int,
}

EntityKind :: enum {
	NIL,
	PLAYER,
	COOKIE,
}

EntityTextureOffset :: enum {
	CENTER,
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

Entity :: struct {
	handle:         EntityHandle,
	kind:           EntityKind,
	collision:      CollisionShape,
	pos:            rl.Vector2,
	rotation:       f32,
	scale:          f32,
	texture_offset: EntityTextureOffset,
	animation:      Animation,
}

Animation :: struct {
	kind:          AnimationType,
	texture:       rl.Texture2D,
	frame_count:   int,
	frame_timer:   f32,
	current_frame: int,
	frame_length:  f32,
	flip_x:        bool,
}

AnimationType :: enum {
	IDLE,
	RUN,
}

entity_animate :: proc(entity: ^Entity) {
	entity.animation.frame_timer += rl.GetFrameTime()

	if entity.animation.frame_timer > entity.animation.frame_length {
		entity.animation.current_frame += 1
		entity.animation.frame_timer = 0

		if entity.animation.current_frame == entity.animation.frame_count {
			entity.animation.current_frame = 0
		}
	}
}

get_source_rect :: proc(animation: Animation) -> rl.Rectangle {
	texture_width := f32(animation.texture.width / i32(animation.frame_count))
	texture_height := f32(animation.texture.height)
	x := texture_width * f32(animation.current_frame)

	source_rect := rl.Rectangle{x, 0, texture_width, texture_height}

	return source_rect
}

entity_draw_default :: proc(e: Entity) {
	texture := e.animation.texture
	offset := get_texture_position(e)
	destination := rl.Rectangle {
		x      = offset.x,
		y      = offset.y,
		width  = f32(texture.width) * e.scale / f32(e.animation.frame_count),
		height = f32(texture.height),
	}

	if e.animation.flip_x {
		texture.width *= -1
	}

	rl.DrawTexturePro(
		texture,
		get_source_rect(e.animation),
		destination,
		e.rotation,
		e.scale,
		rl.WHITE,
	)
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
			e.pos.x - f32(texture_width / 2),
			e.pos.y - f32(texture_height / 2),
		}
	case .TOP:
		return rl.Vector2{e.pos.x - f32(texture_width / 2), e.pos.y}
	case .BOTTOM:
		return rl.Vector2 {
			e.pos.x - f32(texture_width / 2),
			e.pos.y - f32(texture_height),
		}
	case .LEFT:
		return rl.Vector2{e.pos.x, e.pos.y - f32(texture_height / 2)}
	case .RIGHT:
		return rl.Vector2 {
			e.pos.x - f32(texture_width),
			e.pos.y - f32(texture_height / 2),
		}
	case:
		return e.pos
	}
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

entity_get_all :: proc() -> []EntityHandle {
	return game_state.scratch.all_entities
}

entity_get :: proc(handle: EntityHandle) -> (entity: ^Entity, ok: bool) #optional_ok {
	if handle.index <= 0 || handle.index > game_state.entity_top_count {
		return &zero_entity, false
	}

	ent := &game_state.entities[handle.index]
	if ent.handle.id != handle.id {
		return &zero_entity, false
	}

	return ent, true
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

	switch kind {
	case .NIL:
	case .PLAYER:
		player_setup(e)
	case .COOKIE:
		cookie_setup(e)
	}
}
