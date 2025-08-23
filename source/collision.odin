package game

import "core:math"
import rl "vendor:raylib"

CollisionShapeOffset :: enum {
	CENTER,
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

collision_box_update :: proc(e: ^Entity) {
	switch e.offset {
	case .CENTER:
		e.body_rectangle.x = e.pos.x - (e.body_rectangle.width / 2)
		e.body_rectangle.y = e.pos.y - (e.body_rectangle.height / 2)
	case .TOP:
		e.body_rectangle.x = e.pos.x - (e.body_rectangle.width / 2)
		e.body_rectangle.y = e.pos.y
	case .BOTTOM:
		e.body_rectangle.x = e.pos.x - (e.body_rectangle.width / 2)
		e.body_rectangle.y = e.pos.y - e.body_rectangle.height
	case .LEFT:
		e.body_rectangle.x = e.pos.x
		e.body_rectangle.y = e.pos.y - (e.body_rectangle.height / 2)
	case .RIGHT:
		e.body_rectangle.x = e.pos.x - e.body_rectangle.width
		e.body_rectangle.y = e.pos.y - (e.body_rectangle.height / 2)
	}

}


get_rect_overlap :: proc(a, b: rl.Rectangle) -> rl.Vector2 {
	overlap_x := f32(math.min(a.x + a.width, b.x + b.width) - math.max(a.x, b.x))
	overlap_y := f32(math.min(a.y + a.height, b.y + b.height) - math.max(a.y, b.y))
	return rl.Vector2{overlap_x, overlap_y}
}

process_collisions :: proc(entity_a: ^Entity, cb: proc(e_a: ^Entity, entity_b: ^Entity)) {
	if entity_a.has_collision {
		collision_box_update(entity_a)
		for entity_handle in entity_get_all() {
			ent := entity_get(entity_handle)
			if ent.has_collision != true do continue
			if ent.handle.id == entity_a.handle.id do continue
			if rl.CheckCollisionRecs(entity_a.body_rectangle, ent.body_rectangle) {
				cb(entity_a, ent)
			}
		}
	}
}
