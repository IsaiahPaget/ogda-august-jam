package game

import rl "vendor:raylib"

TERMINAL_VELOCITY :: 30
get_applied_gravity :: proc() -> f32 {
	applied_gravity := GRAVITY * rl.GetFrameTime()
	if applied_gravity > TERMINAL_VELOCITY {
		return TERMINAL_VELOCITY
	}
	return applied_gravity
}

