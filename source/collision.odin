package game

import "core:math"
import rl "vendor:raylib"

CollisionShape :: struct {
	is_active: bool,
	rectangle: rl.Rectangle,
	offset:    CollisionShapeOffset,
}

CollisionShapeOffset :: enum {
	CENTER,
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

collision_box_update :: proc(e: ^Entity) {
	switch e.collision.offset {
	case .CENTER:
		e.collision.rectangle.x = e.pos.x - (e.collision.rectangle.width / 2)
		e.collision.rectangle.y = e.pos.y - (e.collision.rectangle.height / 2)
	case .TOP:
		e.collision.rectangle.x = e.pos.x - (e.collision.rectangle.width / 2)
		e.collision.rectangle.y = e.pos.y
	case .BOTTOM:
		e.collision.rectangle.x = e.pos.x - (e.collision.rectangle.width / 2)
		e.collision.rectangle.y = e.pos.y - e.collision.rectangle.height
	case .LEFT:
		e.collision.rectangle.x = e.pos.x
		e.collision.rectangle.y = e.pos.y - (e.collision.rectangle.height / 2)
	case .RIGHT:
		e.collision.rectangle.x = e.pos.x - e.collision.rectangle.width
		e.collision.rectangle.y = e.pos.y - (e.collision.rectangle.height / 2)
	}

}


get_rect_overlap :: proc(a, b: rl.Rectangle) -> rl.Vector2 {
    overlap_x := f32(math.min(a.x + a.width,  b.x + b.width)  - math.max(a.x, b.x))
    overlap_y := f32(math.min(a.y + a.height, b.y + b.height) - math.max(a.y, b.y))
    return rl.Vector2{overlap_x, overlap_y}
}

process_collisions :: proc(entity_a: ^Entity, cb: proc(e_a: ^Entity, entity_b: ^Entity)) {
	if entity_a.collision.is_active {
		collision_box_update(entity_a)
		for entity_handle in entity_get_all() {
			ent := entity_get(entity_handle)
			if ent.collision.is_active != true do continue
			if ent.handle.id == entity_a.handle.id do continue
			if rl.CheckCollisionRecs(entity_a.collision.rectangle, ent.collision.rectangle) {
				cb(entity_a, ent)
			}
		}
	}
}
