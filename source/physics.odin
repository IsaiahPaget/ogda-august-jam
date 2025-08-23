package game

import box "vendor:box2d"

init_default_physics :: proc(
	e: ^Entity,
	density: f32,
	friction: f32,
	kind: box.BodyType = .staticBody,
) {

	body_def := box.DefaultBodyDef()
	body_def.type = kind
	body_def.position = e.pos
	e.body_id = box.CreateBody(game_state.world_id, body_def)

	// TODO: make this work with offsets so that it's not always completely centred
	box_extent := box.Vec2 {
		f32(e.animation.texture.width) * 0.5,
		f32(e.animation.texture.height) * 0.5,
	}
	e.body_polygon = box.MakeBox(box_extent.x, box_extent.y)
	shape_def := box.DefaultShapeDef()
	shape_def.density = density
	shape_def.material.friction = friction
	e.body_shape_id = box.CreatePolygonShape(e.body_id, shape_def, e.body_polygon)
}
