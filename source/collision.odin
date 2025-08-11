package game

import rl "vendor:raylib"

MAX_COLLISION_SHAPES :: 2048
MAX_COLLISION_EVENTS :: 2048

zero_shape: CollisionShape // #readonly for zeroing shapes

CollisionShapeType :: enum {
	HIT,
	INTERACT,
}

CollisionShapeHandle :: struct {
	index: int,
	id: int,
}

CollisionShape :: struct {
	handle: CollisionShapeHandle,
	entity_handle: EntityHandle,
	kind: CollisionShapeType,
	rectangle: rl.Rectangle,
}

CollisionEvent :: struct {
	a_handle: EntityHandle,
	b_handle: EntityHandle,
	kind: CollisionShapeType,
}

collision_event_add :: proc(a: EntityHandle, b: EntityHandle, kind: CollisionShapeType) {
    ev := game_state.collision_events[game_state.collision_event_count]
    ev.a_handle = a
    ev.b_handle = b
    ev.kind = kind
    game_state.collision_event_count += 1
}

check_collisions_for_type :: proc(collision_type: CollisionShapeType) {
    shapes := game_state.collision_shapes
    count  := game_state.collision_shapes_count

    for i in 0..<count {
        if shapes[i].kind != collision_type do continue
        for j in i+1..<count {
            if shapes[j].kind != collision_type do continue

            if rl.CheckCollisionRecs(shapes[i].rectangle, shapes[j].rectangle) {
                collision_event_add(shapes[i].entity_handle, shapes[j].entity_handle, collision_type)
            }
        }
    }
}

collision_shape_create :: proc(kind: CollisionShapeType, entity_handle: EntityHandle, rectangle: rl.Rectangle) -> ^CollisionShape {

	index := -1
	if len(game_state.collision_shapes_free_list) > 0 {
		index = pop(&game_state.collision_shapes_free_list)
	}

	if index == -1 {
		assert(
			game_state.collision_shapes_count + 1 < MAX_COLLISION_SHAPES,
			"ran out of collision shapes, increase size",
		)
		game_state.collision_shapes_count += 1
		index = game_state.collision_shapes_count
	}

	shape := &game_state.collision_shapes[index]
	shape.rectangle = rectangle
	shape.handle.index = index
	shape.handle.id = game_state.latest_entity_id + 1
	game_state.latest_collision_shape_id = shape.handle.id

	return shape
}

collision_shape_is_valid :: proc {
	collision_shape_is_valid_no_ptr,
	collision_shape_is_valid_ptr,
}
collision_shape_is_valid_no_ptr :: proc(collision_shape: CollisionShape) -> bool {
	return collision_shape.handle.id != 0
}
collision_shape_is_valid_ptr :: proc(collision_shape: ^CollisionShape) -> bool {
	return collision_shape != nil && collision_shape_is_valid(collision_shape^)
}
collision_shape_destroy :: proc(collision_shape: ^CollisionShape) {
	append(&game_state.collision_shapes_free_list, collision_shape.handle.index)
	collision_shape^ = {}
}

