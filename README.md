# zig-8080-emulator

Build using `zig build`.
Copy wasm file to invaders-frontend/public `cp zig-out/lib/cpu8080.wasm invaders-frontend/public`
Run bun server `cd invaders-frontend && bun run dev`

# Testing

Currently I am testing the cpu using a asmdiag file and comparing the instructions. When an error in the test occurs, an error message will be displayed as well as the jump command that lead to this error.

# TODO

- [x] Emulate 8080 CPU
- [ ] Create I/O interface
- [x] Handle interups/timing
- [x] Create WASM bridge
- [x] Render with ThreeJs
