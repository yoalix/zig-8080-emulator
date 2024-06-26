const std = @import("std");
const disassembler = @import("./disassembler8080.zig");
const CPU8080 = @import("./emulator8080.zig").CPU8080;
const emulator = @import("./emulator8080.zig");

pub fn main() !void {
    // const data: []u8 = std.fs.readFile("invaders.rom") orelse {
    //     std.debug.print("Failed to read file\n");
    //     return;
    //  };

    //   const disassembler = disassembler.create(data);
    //   disassembler.disassemble();
    const file_path = "rom/invaders";
    // const file_path = "rom/cpudiag.bin";
    var file = @embedFile(file_path);
    //var codebuffer = file[0..file.len];
    //var pc: u16 = 0;
    //while (pc <= 0x3f) {
    //
    //    pc += disassembler.disassembleInstruction8080Op(codebuffer, pc);
    //}
    std.debug.print("File size: {}\n", .{file.len});
    std.debug.print("File path: {s}\n", .{file_path});
    std.debug.print("File: {any}\n", .{file[0..]});
    for (file, 0..) |byte, i| {
        if (i == 0 or i % 4 == 0) std.debug.print("\n{x:0>4} ", .{i});
        std.debug.print("{x} ", .{byte});
    }
    var state = CPU8080.init_zig(file.len, file, 0);
    // state.pc = 0x100;

    // inject "out 0,a" at 0x0000 (signal to stop the test)
    // state.memory[0x0000] = 0xD3;
    // state.memory[0x0001] = 0x00;

    // inject "out 1,a" at 0x0005 (signal to output some characters)
    // state.memory[0x0005] = 0xD3;
    // state.memory[0x0006] = 0x01;
    // state.memory[0x0007] = 0xC9;

    // state.memory[0] = 0xc3;
    // state.memory[1] = 0x00;
    // state.memory[2] = 0x01;

    // fix stack pointer from 0x6ad to 0x7ad
    // byte 112 + 0x100 = 368 in memory
    // // state.memory[368] = 0x7;

    // skip DAA test
    // state.memory[0x59c] = 0xc3;
    // state.memory[0x59d] = 0xc2;
    // state.memory[0x59e] = 0x05;
    var i: u32 = 0;
    while ((i < 20) or (state.halt == true)) {
        state.cpuStep();
        i += 1;
    }
    for (state.memory[0x2400..0x4000], 0x2400..) |byte, j| {
        if (j == 0 or j % 4 == 0) std.debug.print("\n{x:0>4} ", .{j});
        std.debug.print("{x} ", .{byte});
        // if ((j + 1) % 4 == 0) std.debug.print("\n{x:0>4} ", .{j});
    }
}
