# Odin + Raylib + Hot Reload template

This is an [Odin](https://github.com/odin-lang/Odin) + [Raylib](https://github.com/raysan5/raylib) game template with [Hot Reloading](http://zylinski.se/posts/hot-reload-gameplay-code/) pre-setup. It makes it possible to reload gameplay code while the game is running.
I have made as a mix of [Karl Zylinski Odin Template](https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template) and [Randy Prime Blueprint](https://github.com/baldgg/blueprint)

1. Run `build_hot_reload.sh` to create `game_hot_reload.bin` (located at the root of the project) and `game.so` (located in `build/hot_reload`). Note: It expects odin compiler to be part of your PATH environment variable.
2. Run `game_hot_reload.bin`, leave it running.
3. Make changes to the gameplay code in `source/game.odin`. For example, change the line `rl.ClearBackground(rl.BLACK)` so that it instead uses `rl.BLUE`. Save the file.
4. Run `build_hot_reload.sh`, it will recompile `game.so`.
5. The running `game_hot_reload.bin` will see that `game.so` changed and reload it. But it will use the same `Game_Memory` (a struct defined in `source/game.odin`) as before. This will make the game use your new code without having to restart.

Note, in step 4: `build_hot_reload.sh` does not rebuild `game_hot_reload.bin`. It checks if `game_hot_reload.bin` is already running. If it is, then it skips compiling it.

## Release builds

Run `build_release.sh` to create a release build in `build/release`. That bin does not have the hot reloading stuff, since you probably do not want that in the released version of your game. This means that the release version does not use `game.so`, instead it imports the `source` folder as a normal Odin package.

`build_debug.sh` is like `build_release.sh` but makes a debuggable executable, in case you need to debug your non-hot-reload-exe.

## Web build

`build_web.sh` builds a release web executable (no hot reloading!).

### Web build requirements

- Emscripten. Download and install somewhere on your computer. Follow the instructions here: https://emscripten.org/docs/getting_started/downloads.html (follow the stuff under "Installation instructions using the emsdk (recommended)").
- Recent Odin compiler: This uses Raylib binding changes that were done on January 1, 2025.

### Web build quick start

1. Point `EMSCRIPTEN_SDK_DIR` in `build_web.sh/sh` to where you installed emscripten.
2. Run `build_web.sh/sh`.
3. Web game is in the `build/web` folder.

> [!NOTE]
> `build_web.sh` is for windows, `build_web.sh` is for Linux / macOS.

> [!WARNING]
> You can't run `build/web/index.html` directly due to "CORS policy" javascript errors. You can work around that by running a small python web server:
> - Go to `build/web` in a console.
> - Run `python -m http.server`
> - Go to `localhost:8000` in your browser.
>
> _For those who don't have python: Emscripten comes with it. See the `python` folder in your emscripten installation directory._

Build a desktop executable using `build_desktop.sh/sh`. It will end up in the `build/desktop` folder.

There's a wrapper for `read_entire_file` and `write_entire_file` from `core:os` that can files from `assets` directory, even on web. See `source/utils.odin`

### Web build troubleshooting

See the README of the [Odin + Raylib on the web repository](https://github.com/karl-zylinski/odin-raylib-web) for troubleshooting steps.

## Assets
You can put assets such as textures, sounds and music in the `assets` folder. That folder will be copied when a release build is created and also integrated into the web build.

The hot reload build doesn't do any copying, because the hot reload executable lives in the root of the repository, alongside the `assets` folder.

## RAD Debugger
You can hot reload while attached to [RAD Debugger](https://github.com/EpicGamesExt/raddebugger). Attach to your `game_hot_reload` executable, make code changes in your code editor and re-run the the `build_hot_reload` script to build and hot reload.

## Atlas builder

The template works nicely together with my [atlas builder](https://github.com/karl-zylinski/atlas-builder). The atlas builder can build an atlas texture from a folder of png or aseprite files. Using an atlas can drastically reduce the number of draw calls your game uses. There's an example in that repository on how to set it up. The atlas generation step can easily be integrated into the build `bat` / `sh` files such as `build_hot_reload.sh`

## Have a nice day! /Karl Zylinski
