package game

import "core:fmt"
import rl "vendor:raylib"

MAX_ENTITIES :: 2048
MAX_COLLIDABLE :: 3

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

Entity :: struct {
	handle:             EntityHandle,
	kind:               EntityKind,
	collision:          Collision,
	pos:                rl.Vector2,
	rotation:           f32,
	scale:              f32,
	flip_x:             bool,
	entities_colliding: [dynamic]EntityHandle,
	texture:            rl.Texture,
	// animation: Animation,
}

Collision :: struct {
	has_collision: bool,
	rect:          rl.Rectangle,
}

entity_set_collisions :: proc(entity: ^Entity, game_state: ^GameState) {
	all_ents := make([dynamic]^Entity, 0, len(game_state.scratch.all_entities))
	for handle in game_state.scratch.all_entities {
		other_entity := entity_get(handle, game_state)
		if other_entity.collision.has_collision && other_entity.handle.id != entity.handle.id {
			append(&all_ents, other_entity)
		}
	}

	for i in 0 ..< len(all_ents) {
		if i >= MAX_COLLIDABLE {
			break
		}
		other_entity: ^Entity = all_ents[i]
		if rl.CheckCollisionRecs(entity.collision.rect, other_entity.collision.rect) {
			append(&entity.entities_colliding, other_entity.handle)
		}
	}
}


is_valid :: proc {
	entity_is_valid,
	entity_is_valid_ptr,
}
entity_is_valid :: proc(entity: Entity) -> bool {
	return entity.handle.id != 0
}
entity_is_valid_ptr :: proc(entity: ^Entity) -> bool {
	return entity != nil && entity_is_valid(entity^)
}
entity_init_core :: proc() {
	// make sure the zero entity has good defaults, so we don't crash on stuff like functions pointers
	entity_setup(&zero_entity, .NIL)
}

entity_get_all :: proc(game_state: ^GameState) -> []EntityHandle {
	return game_state.scratch.all_entities
}
rebuild_scratch :: proc(game_state: ^GameState) {
	// construct the list of all entities on the temp allocator
	// that way it's easier to loop over later on
	all_ents := make([dynamic]EntityHandle, 0, len(game_state.entities))
	for &e in game_state.entities {
		if !is_valid(e) do continue
		append(&all_ents, e.handle)
	}
	game_state.scratch.all_entities = all_ents[:]
}
entity_get :: proc(
	handle: EntityHandle,
	game_state: ^GameState,
) -> (
	entity: ^Entity,
	ok: bool,
) #optional_ok {
	if handle.index <= 0 || handle.index > game_state.entity_top_count {
		return &zero_entity, false
	}

	ent := &game_state.entities[handle.index]
	if ent.handle.id != handle.id {
		return &zero_entity, false
	}

	return ent, true
}

entity_create :: proc(kind: EntityKind, game_state: ^GameState) -> ^Entity {

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

entity_destroy :: proc(e: ^Entity, game_state: ^GameState) {
	append(&game_state.entity_free_list, e.handle.index)
	e^ = {}
}
entity_setup :: proc(e: ^Entity, kind: EntityKind) {
	// entity defaults
	e.scale = 1
	e.entities_colliding = make([dynamic]EntityHandle, 0, MAX_COLLIDABLE)

	switch kind {
	case .NIL:
	case .PLAYER:
		player_setup(e)
	case .COOKIE:
		cookie_setup(e)
	}
}
