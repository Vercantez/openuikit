// CSDL2 shim. Owner: host module (M7).
//
// The include path comes from pkg-config ("sdl2" in Package.swift): SwiftPM
// asks pkg-config for -I flags, so <SDL2/SDL.h> resolves portably —
// /opt/homebrew/include on macOS (brew install sdl2), /usr/include on Linux
// (apt install libsdl2-dev). Never hardcode a prefix here.
//
// SDL_main.h normally #defines main to SDL_main so SDL can wrap the entry
// point; Swift executables provide their own entry point, so opt out.
#define SDL_MAIN_HANDLED 1
#include <SDL2/SDL.h>
