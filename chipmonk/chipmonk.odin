package chipmonk

foreign import chipmonk {
	"libchipmonk.a",
}
// Opaque forward-declared types
cpSpace :: struct {}  // treated as opaque pointer
cpBody  :: struct {}
cpShape :: struct {}

// Actual struct for cpVect (because you need its fields)
cpVect :: struct {
    x: f64,
    y: f64,
}

@(default_calling_convention="c")
foreign chipmonk {
    cpSpaceNew       :: proc() -> ^cpSpace ---
    cpSpaceFree      :: proc(space: ^cpSpace) ---

    cpBodyNew        :: proc(mass: f64, moment: f64) -> ^cpBody ---
    cpBodyFree       :: proc(body: ^cpBody) ---

    cpShapeNewCircle :: proc(body: ^cpBody, radius: f64, offset: cpVect) -> ^cpShape ---
    cpShapeFree      :: proc(shape: ^cpShape) ---

    cpSpaceAddBody   :: proc(space: ^cpSpace, body: ^cpBody) ---
    cpSpaceAddShape  :: proc(space: ^cpSpace, shape: ^cpShape) ---

    cpSpaceStep      :: proc(space: ^cpSpace, dt: f64) ---
}
