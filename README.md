# zig-8080-emulator

Build and run using `zig build run`

# Testing
Currently I am testing the cpu using a asmdiag file and comparing the instructions. When an error in the test occurs, an error message will be displayed as well as the jump command that lead to this error.

# TODO
- [x] Emulate 8080 CPU
- [ ] Create I/O interface
- [ ] Handle interups/timing
- [ ] Create WASM bridge
- [ ] Render HTML 
