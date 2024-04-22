const std = @import("std");
const builtin = std.builtin;
// const disassembler = @import("./disassembler8080.zig");

pub fn parity(value: u8) bool {
    var ones: u8 = 0;
    for (0..8) |i| {
        ones += ((value >> @intCast(i)) & 1);
    }

    return (ones & 1) == 0;
}

const CYCLES = [_]u8{
    4, 10, 7, 5, 5, 5, 7, 4, 4, 10, 7, 5, 5, 5, 7, 4, //0x00..0x0f
    4, 10, 7, 5, 5, 5, 7, 4, 4, 10, 7, 5, 5, 5, 7, 4, //0x10..0x1f
    4, 10, 16, 5, 5,  5,  7,  4, 4, 10, 16, 5, 5, 5, 7, 4, //etc
    4, 10, 13, 5, 10, 10, 10, 4, 4, 10, 13, 5, 5, 5, 7,
    4,
    //
    5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5, //0x40..0x4f
    5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5,
    5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5,
    7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 5, 5, 5, 5, 7,
    5,
    //
    4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, //0x80..8x4f
    4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
    4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
    4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7,
    4,
    //
    11, 10, 10, 10, 17, 11, 7, 11, 11, 10, 10, 10, 10, 17, 7, 11, //0xc0..0xcf
    11, 10, 10, 10, 17, 11, 7, 11, 11, 10, 10, 10, 10, 17, 7, 11,
    11, 10, 10, 18, 17, 11, 7, 11, 11, 5,  10, 5,  17, 17, 7, 11,
    11, 10, 10, 4,  17, 11, 7, 11, 11, 5,  10, 4,  17, 17, 7, 11,
};

const ConditionCode = struct {
    z: bool,
    s: bool,
    p: bool,
    cy: bool,
    ac: bool,
    pad: u8,
};

pub const CPU8080 = struct {
    const Self = @This();

    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    h: u8,
    l: u8,
    sp: u16,
    pc: u16,
    memory: [0x10_000]u8,
    cc: ConditionCode,
    int_enable: bool,
    last_interrupt: f64,
    next_interrupt: f64,
    which_interrupt: u8,
    shift_offset: u4,
    shift0: u8,
    shift1: u8,
    halt: bool,
    in_port1: u8,

    pub fn init(self: *Self, code: []const u8) void {
        var memory = [_]u8{0} ** 0x10_000;
        for (code, 0..) |byte, i| {
            memory[i] = byte;
        }
        // @memcpy(memory, code);
        self.* = .{
            .a = 0,
            .b = 0,
            .c = 0,
            .d = 0,
            .e = 0,
            .h = 0,
            .l = 0,
            .sp = 0,
            .pc = 0,
            .memory = memory,
            .cc = ConditionCode{ .z = false, .s = false, .p = false, .cy = false, .ac = false, .pad = 0 },
            .int_enable = true,
            .last_interrupt = 0,
            .next_interrupt = 0,
            .which_interrupt = 0,
            .shift_offset = 0,
            .shift0 = 0,
            .shift1 = 0,
            .halt = false,
            .in_port1 = 0,
        };
    }

    pub fn init_zig(comptime len: comptime_int, code: *const [len]u8, start_add: usize) Self {
        var memory = [_]u8{0} ** 0x10_000;
        for (code, start_add..) |byte, i| {
            memory[i] = byte;
        }
        const self = Self{
            .a = 0,
            .b = 0,
            .c = 0,
            .d = 0,
            .e = 0,
            .h = 0,
            .l = 0,
            .sp = 0,
            .pc = 0,
            .memory = memory,
            .cc = ConditionCode{ .z = false, .s = false, .p = false, .cy = false, .ac = false, .pad = 0 },
            .int_enable = true,
            .last_interrupt = 0,
            .next_interrupt = 0,
            .which_interrupt = 0,
            .shift_offset = 0,
            .shift0 = 0,
            .shift1 = 0,
            .halt = false,
            .in_port1 = 0,
        };
        return self;
    }

    fn unimplemented(self: *Self) void {
        _ = self;
        // print("Error: Unimplemented instruction\n");
        std.debug.assert(false);
    }

    pub fn emulate_op(self: *Self) u8 {
        var opcode: u8 = self.memory[self.pc];
        // _ = disassembler.disassembleInstruction8080Op(self.memory, self.pc);
        _ = switch (opcode) {
            0x00 => null, // NOP
            0x01 => { // LXI B,addr
                // B <- byte 3, C <- byte 2
                self.c = self.memory[self.pc + 1];
                self.b = self.memory[self.pc + 2];
                self.pc += 2;
            },
            0x02 => { // STAX B
                // (BC) <- A
                self.memory[@as(u16, @as(u16, self.b) << 8 | self.c)] = self.a;
            },
            0x03 => { // INX B
                var bc: u16 = @as(u16, @as(u16, self.b) << 8 | self.c);
                bc +%= 1;
                self.b = @truncate(bc >> 8);
                self.c = @truncate(bc);
            },
            0x04 => { // INR B
                self.b = self.inr(self.b);
            },
            0x05 => { // DCR B
                self.b = self.dcr(self.b);
            },
            0x06 => { // MVI B,byte
                self.b = self.memory[self.pc + 1];
                self.pc += 1;
            },
            0x07 => {
                // RLC
                // A = A << 1; bit 0 = prev bit 7; cy = prev bit 7
                var x = self.a;
                self.a = x << 1 | x >> 7;
                self.cc.cy = (x & 0x80) == 0x80;
            },
            0x08 => null,

            0x09 => { // DAD B
                // HL = HL + Bc
                var hl: u16 = @as(u16, @as(u16, self.h) << 8 | self.l);
                var bc: u16 = @as(u16, @as(u16, self.b) << 8 | self.c);
                var ov = @addWithOverflow(hl, bc);
                hl +%= bc;
                self.h = @truncate(hl >> 8);
                self.l = @truncate(hl);
                self.cc.cy = ov[1] == 1;
            },
            0x0a => { // LDAX b
                self.a = self.memory[@as(u16, @as(u16, self.b) << 8 | self.c)];
            },
            0x0b => { // DCX B
                var bc: u16 = @as(u16, @as(u16, self.b) << 8 | self.c);
                bc -%= 1;
                self.b = @truncate(bc >> 8);
                self.c = @truncate(bc);
            },
            0x0c => { // INR C
                self.c = self.inr(self.c);
            },
            0x0d => { // DCR C
                self.c = self.dcr(self.c);
            },
            0x0e => { // MVI C,byte
                self.c = self.memory[self.pc + 1];
                self.pc += 1;
            },
            0x0f => { // RRC
                // A = A >> 1; bit 7 = prev bit 0; cy = prev bit 0
                var x = self.a;
                self.a = x >> 1 | (x & 1) << 7;
                self.cc.cy = (x & 1) == 1;
            },

            0x10 => null,
            0x11 => { // LXI D,addr
                // D <- byte 3, e <- byte 2
                self.e = self.memory[self.pc + 1];
                self.d = self.memory[self.pc + 2];
                self.pc += 2;
            },
            0x12 => { // STAX d
                // (DE) <- A
                self.memory[@as(u16, @as(u16, self.d) << 8 | self.e)] = self.a;
            },
            0x13 => { // INX D
                var de: u16 = @as(u16, @as(u16, self.d) << 8 | self.e);
                de +%= 1;
                self.d = @truncate(de >> 8);
                self.e = @truncate(de);
            },
            0x14 => { // INR D
                self.d = self.inr(self.d);
            },
            0x15 => { // DCR D
                self.d = self.dcr(self.d);
            },
            0x16 => { // MVI D,byte
                self.d = self.memory[self.pc + 1];
                self.pc += 1;
            },
            0x17 => { //RAL
                // A = A << 1; bit 0 = prev cy; cy = prev bit 7}
                var x = self.a;
                self.a = x << 1 | @as(u8, @intFromBool(self.cc.cy));
                self.cc.cy = (x & 0x80) == 0x80;
            },

            0x18 => null,
            0x19 => { // DAD D
                var hl: u16 = @as(u16, @as(u16, self.h) << 8 | self.l);
                var de: u16 = @as(u16, @as(u16, self.d) << 8 | self.e);
                var ov = @addWithOverflow(hl, de);
                hl +%= de;
                self.h = @truncate(hl >> 8);
                self.l = @truncate(hl);
                self.cc.cy = ov[1] == 1;
            },
            0x1a => { // LDAX d
                self.a = self.memory[@as(u16, @as(u16, self.d) << 8 | self.e)];
            },
            0x1b => { // DCX D
                var de: u16 = @as(u16, @as(u16, self.d) << 8 | self.e);
                de -%= 1;
                self.d = @truncate(de >> 8);
                self.e = @truncate(de);
            },
            0x1c => { // INR E
                self.e = self.inr(self.e);
            },
            0x1d => { // DCR E
                self.e = self.dcr(self.e);
            },
            0x1e => { // MVI E,byte
                // E <- byte 2
                self.e = self.memory[self.pc + 1];
                self.pc += 1;
            },
            0x1f => {
                // RAR
                // A = A >> 1; bit 7 = prev bit 7; cy = prev bit 0
                var x = self.a;
                self.a = @as(u8, @intFromBool(self.cc.cy)) << 7 | x >> 1;
                self.cc.cy = (x & 1) == 1;
            },

            0x20 => null,
            0x21 => { // LXI H,addr
                // H <- byte 3, l <- byte 2
                self.h = self.memory[self.pc + 2];
                self.l = self.memory[self.pc + 1];
                self.pc += 2;
            },
            0x22 => { // SHLD addr
                // (addr) <- L; (addr+1) <- h
                var offset: u16 = @as(u16, @as(u16, self.memory[self.pc + 2]) << 8 | self.memory[self.pc + 1]);
                self.memory[offset] = self.l;
                self.memory[offset + 1] = self.h;
                self.pc += 2;
            },
            0x23 => { // INX H
                // HL <- HL + 1
                var hl: u16 = @as(u16, @as(u16, self.h) << 8 | self.l);
                hl += 1;
                self.h = @truncate(hl >> 8);
                self.l = @truncate(hl);
            },
            0x24 => { // INR H
                // H <- H + 1
                self.h = self.inr(self.h);
            },
            0x25 => { // DCR H
                // H <- H - 1
                self.h = self.dcr(self.h);
            },
            0x26 => { // MVI H,byte
                // H <- byte 2
                self.h = self.memory[self.pc + 1];
                self.pc += 1;
            },
            0x27 => {
                // Daa special
                if ((self.a & 0x0f) > 9 or self.cc.ac) {
                    self.a += 6;
                    self.cc.ac = (self.a & 0x0f) < 6;
                }
                if ((self.a & 0xf0) > 0x90 or self.cc.cy) {
                    var result: u16 = @as(u16, self.a) + 0x60;
                    self.a = @truncate(result & 0xff);
                    self.cc.cy = result > 0xff;
                    self.cc.z = self.a == 0;
                    self.cc.s = (self.a & 0x80) == 0x80;
                    self.cc.p = parity(self.a);
                }
            },
            0x28 => null,
            0x29 => { // DAD H
                // HL <- HL + hl
                var hl: u16 = @as(u16, @as(u16, self.h) << 8 | self.l);
                var ov = @addWithOverflow(hl, hl);
                hl +%= hl;
                self.h = @truncate(hl >> 8);
                self.l = @truncate(hl);
                self.cc.cy = ov[1] == 1;
            },
            0x2a => { // LHLD addr
                // L <- (addr); h <- (addr+1)
                var offset: u16 = @as(u16, @as(u16, self.memory[self.pc + 2]) << 8 | self.memory[self.pc + 1]);
                self.l = self.memory[offset];
                self.h = self.memory[offset + 1];
                self.pc += 2;
            },
            0x2b => { // DCX H
                // HL <- HL - 1
                var hl: u16 = @as(u16, @as(u16, self.h) << 8 | self.l);
                hl -%= 1;
                self.h = @truncate(hl >> 8);
                self.l = @truncate(hl);
            },
            0x2c => { // INR L
                // L <- L + 1
                self.l = self.inr(self.l);
            },
            0x2d => { // DCR L
                // L <- L - 1
                self.l = self.dcr(self.l);
            },
            0x2e => { // MVI L,byte
                // L <- byte 2
                self.l = self.memory[self.pc + 1];
                self.pc += 1;
            },
            0x2f => { // CMA
                // A <- !A
                self.a = ~self.a;
            },
            0x30 => null,
            0x31 => { // LXI Sp,addr
                // SP.hi <- byte 3, sp.lo <- byte 2
                self.sp = @as(u16, @as(u16, self.memory[self.pc + 2]) << 8 | self.memory[self.pc + 1]);
                self.pc += 2;
            },
            0x32 => { // STA addr
                // (addr) <- A
                var offset: u16 = @as(u16, @as(u16, self.memory[self.pc + 2]) << 8 | self.memory[self.pc + 1]);
                self.memory[offset] = self.a;
                self.pc += 2;
            },
            0x33 => { // INX Sp
                // SP <- SP + 1
                self.sp += 1;
            },
            0x34 => { // INR M
                // (HL) <- (HL) + 1
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.inr(self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)]);
            },
            0x35 => { // DCR M
                // (HL) <- (HL) - 1
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.dcr(self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)]);
            },
            0x36 => { // MVI M,byte
                // (HL) <- byte 2
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.memory[self.pc + 1];
                self.pc += 1;
            },
            0x37 => { // STC
                // CY = 1
                self.cc.cy = true;
            },
            0x38 => null, // NOOP
            0x39 => { // DAD SP
                // HL = HL + SP
                var hl: u16 = @as(u16, @as(u16, self.h) << 8 | self.l);
                var ov = @addWithOverflow(hl, self.sp);
                hl +%= self.sp;
                self.h = @truncate(hl >> 8);
                self.l = @truncate(hl);
                self.cc.cy = ov[1] == 1;
            },
            0x3a => { // LDA addr
                // A <- (addr)
                var offset: u16 = @as(u16, @as(u16, self.memory[self.pc + 2]) << 8 | self.memory[self.pc + 1]);
                self.a = self.memory[offset];
                self.pc += 2;
            },
            0x3b => { // DCX SP
                // SP <- SP - 1
                self.sp -%= 1;
            },
            0x3c => { // INR A
                // A <- A + 1
                self.a = self.inr(self.a);
            },
            0x3d => { // DCR A
                // A <- A - 1
                self.a = self.dcr(self.a);
            },
            0x3e => { // MVI A,byte
                // A <- byte 2
                self.a = self.memory[self.pc + 1];
                self.pc += 1;
            },
            0x3f => { // CMC
                // CY = !CY
                self.cc.cy = !self.cc.cy;
            },
            0x40 => { // MOV B,B
                self.b = self.b;
            },
            0x41 => { // MOV B,C
                self.b = self.c;
            },
            0x42 => { // MOV B,D
                self.b = self.d;
            },
            0x43 => { // MOV B,E
                self.b = self.e;
            },
            0x44 => { // MOV B,H
                self.b = self.h;
            },
            0x45 => { // MOV B,L
                self.b = self.l;
            },
            0x46 => { // MOV B,M
                self.b = self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)];
            },
            0x47 => { // MOV B,A
                self.b = self.a;
            },
            0x48 => { // MOV C,B
                self.c = self.b;
            },
            0x49 => { // MOV C,C
                self.c = self.c;
            },
            0x4a => { // MOV C,D
                self.c = self.d;
            },
            0x4b => { // MOV C,E
                self.c = self.e;
            },
            0x4c => { // MOV C,H
                self.c = self.h;
            },
            0x4d => { // MOV C,L
                self.c = self.l;
            },
            0x4e => { // MOV C,M
                self.c = self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)];
            },
            0x4f => { // MOV C,A
                self.c = self.a;
            },
            0x50 => { // MOV D,B
                self.d = self.b;
            },
            0x51 => { // MOV D,C
                self.d = self.c;
            },
            0x52 => { // MOV D,D
                self.d = self.d;
            },
            0x53 => { // MOV D,E
                self.d = self.e;
            },
            0x54 => { // MOV D,H
                self.d = self.h;
            },
            0x55 => { // MOV D,L
                self.d = self.l;
            },
            0x56 => { // MOV D,M
                self.d = self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)];
            },
            0x57 => { // MOV D,A
                self.d = self.a;
            },
            0x58 => { // MOV E,B
                self.e = self.b;
            },
            0x59 => { // MOV E,C
                self.e = self.c;
            },
            0x5a => { // MOV E,D
                self.e = self.d;
            },
            0x5b => { // MOV E,E
                self.e = self.e;
            },
            0x5c => { // MOV E,H
                self.e = self.h;
            },
            0x5d => { // MOV E,L
                self.e = self.l;
            },
            0x5e => { // MOV E,M
                self.e = self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)];
            },
            0x5f => { // MOV E,A
                self.e = self.a;
            },
            0x60 => { // MOV H,B
                self.h = self.b;
            },
            0x61 => { // MOV H,C
                self.h = self.c;
            },
            0x62 => { // MOV H,D
                self.h = self.d;
            },
            0x63 => { // MOV H,E
                self.h = self.e;
            },
            0x64 => { // MOV H,H
                self.h = self.h;
            },
            0x65 => { // MOV H,L
                self.h = self.l;
            },
            0x66 => { // MOV H,M
                self.h = self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)];
            },
            0x67 => { // MOV H,A
                self.h = self.a;
            },
            0x68 => { // MOV L,B
                self.l = self.b;
            },
            0x69 => { // MOV L,C
                self.l = self.c;
            },
            0x6a => { // MOV L,D
                self.l = self.d;
            },
            0x6b => { // MOV L,E
                self.l = self.e;
            },
            0x6c => { // MOV L,H
                self.l = self.h;
            },
            0x6d => { // MOV L,L
                self.l = self.l;
            },
            0x6e => { // MOV L,M
                self.l = self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)];
            },
            0x6f => { // MOV L,A
                self.l = self.a;
            },
            0x70 => { // MOV M,B
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.b;
            },
            0x71 => { // MOV M,C
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.c;
            },
            0x72 => { // MOV M,D
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.d;
            },
            0x73 => { // MOV M,E
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.e;
            },
            0x74 => { // MOV M,H
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.h;
            },
            0x75 => { // MOV M,L
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.l;
            },
            0x76 => self.halt = true, // HLT

            0x77 => { // MOV M,A
                self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] = self.a;
            },
            0x78 => { // MOV A,B
                self.a = self.b;
            },
            0x79 => { // MOV A,C
                self.a = self.c;
            },
            0x7a => { // MOV A,D
                self.a = self.d;
            },
            0x7b => { // MOV A,E
                self.a = self.e;
            },
            0x7c => { // MOV A,H
                self.a = self.h;
            },
            0x7d => { // MOV A,L
                self.a = self.l;
            },
            0x7e => { // MOV A,M
                self.a = self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)];
            },
            0x7f => { // MOV A,A
                self.a = self.a;
            },
            0x80 => { // ADD B
                self.a = self.add(self.a, self.b);
            },
            0x81 => { // ADD C
                self.a = self.add(self.a, self.c);
            },
            0x82 => { // ADD D
                self.a = self.add(self.a, self.d);
            },
            0x83 => { // ADD E
                self.a = self.add(self.a, self.e);
            },
            0x84 => { // ADD H
                self.a = self.add(self.a, self.h);
            },
            0x85 => { // ADD L
                self.a = self.add(self.a, self.l);
            },
            0x86 => { // ADD M
                self.a = self.add(self.a, self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)]);
            },
            0x87 => { // ADD A
                self.a = self.add(self.a, self.a);
            },
            0x88 => { // ADC B
                self.a = self.add(self.a, self.b + @intFromBool(self.cc.cy));
            },
            0x89 => { // ADC C
                self.a = self.add(self.a, self.c + @intFromBool(self.cc.cy));
            },
            0x8a => { // ADC D
                self.a = self.add(self.a, self.d + @intFromBool(self.cc.cy));
            },
            0x8b => { // ADC E
                self.a = self.add(self.a, self.e + @intFromBool(self.cc.cy));
            },
            0x8c => { // ADC H
                self.a = self.add(self.a, self.h + @intFromBool(self.cc.cy));
            },
            0x8d => { // ADC L
                self.a = self.add(self.a, self.l + @intFromBool(self.cc.cy));
            },
            0x8e => { // ADC M
                self.a = self.add(self.a, self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] + @intFromBool(self.cc.cy));
            },
            0x8f => { // ADC A
                self.a = self.add(self.a, self.a + @intFromBool(self.cc.cy));
            },
            0x90 => { // SUB B
                self.a = self.sub(self.a, self.b);
            },
            0x91 => { // SUB C
                self.a = self.sub(self.a, self.c);
            },
            0x92 => { // SUB D
                self.a = self.sub(self.a, self.d);
            },
            0x93 => { // SUB E
                self.a = self.sub(self.a, self.e);
            },
            0x94 => { // SUB H
                self.a = self.sub(self.a, self.h);
            },
            0x95 => { // SUB L
                self.a = self.sub(self.a, self.l);
            },
            0x96 => { // SUB M
                self.a = self.sub(self.a, self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)]);
            },
            0x97 => { // SUB A
                self.a = self.sub(self.a, self.a);
            },
            0x98 => { // SBB B
                self.a = self.sub(self.a, self.b + @intFromBool(self.cc.cy));
            },
            0x99 => { // SBB C
                self.a = self.sub(self.a, self.c + @intFromBool(self.cc.cy));
            },
            0x9a => { // SBB D
                self.a = self.sub(self.a, self.d + @intFromBool(self.cc.cy));
            },
            0x9b => { // SBB E
                self.a = self.sub(self.a, self.e + @intFromBool(self.cc.cy));
            },
            0x9c => { // SBB H
                self.a = self.sub(self.a, self.h + @intFromBool(self.cc.cy));
            },
            0x9d => { // SBB L
                self.a = self.sub(self.a, self.l + @intFromBool(self.cc.cy));
            },
            0x9e => { // SBB M
                self.a = self.sub(self.a, self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)] + @intFromBool(self.cc.cy));
            },
            0x9f => { // SBB A
                self.a = self.sub(self.a, self.a + @intFromBool(self.cc.cy));
            },
            0xa0 => { // ANA B
                self.a = self.ana(self.a, self.b);
            },
            0xa1 => {
                // ANA C
                self.a = self.ana(self.a, self.c);
            },
            0xa2 => {
                // ANA D
                self.a = self.ana(self.a, self.d);
            },
            0xa3 => {
                // ANA E
                self.a = self.ana(self.a, self.e);
            },
            0xa4 => {
                // ANA H
                self.a = self.ana(self.a, self.h);
            },
            0xa5 => {
                // ANA L
                self.a = self.ana(self.a, self.l);
            },
            0xa6 => {
                // ANA M
                self.a = self.ana(self.a, self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)]);
            },
            0xa7 => {
                // ANA A
                self.a = self.ana(self.a, self.a);
            },
            0xa8 => {
                // XRA B
                self.a = self.xra(self.a, self.b);
            },
            0xa9 => {
                // XRA C
                self.a = self.xra(self.a, self.c);
            },
            0xaa => {
                // XRA D
                self.a = self.xra(self.a, self.d);
            },
            0xab => {
                // XRA E
                self.a = self.xra(self.a, self.e);
            },
            0xac => {
                // XRA H
                self.a = self.xra(self.a, self.h);
            },
            0xad => {
                // XRA L
                self.a = self.xra(self.a, self.l);
            },
            0xae => {
                // XRA M
                self.a = self.xra(self.a, self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)]);
            },
            0xaf => {
                // XRA A
                self.a = self.xra(self.a, self.a);
            },
            0xb0 => {
                // ORA B
                self.a = self.ora(self.a, self.b);
            },
            0xb1 => {
                // ORA C
                self.a = self.ora(self.a, self.c);
            },
            0xb2 => {
                // ORA D
                self.a = self.ora(self.a, self.d);
            },
            0xb3 => {
                // ORA E
                self.a = self.ora(self.a, self.e);
            },
            0xb4 => {
                // ORA H
                self.a = self.ora(self.a, self.h);
            },
            0xb5 => {
                // ORA L
                self.a = self.ora(self.a, self.l);
            },
            0xb6 => {
                // ORA M
                self.a = self.ora(self.a, self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)]);
            },
            0xb7 => {
                // ORA A
                self.a = self.ora(self.a, self.a);
            },
            0xb8 => {
                // CMP B
                _ = self.sub(self.a, self.b);
            },
            0xb9 => {
                // CMP C
                _ = self.sub(self.a, self.c);
            },
            0xba => {
                // CMP D
                _ = self.sub(self.a, self.d);
            },
            0xbb => {
                // CMP E
                _ = self.sub(self.a, self.e);
            },
            0xbc => {
                // CMP H
                _ = self.sub(self.a, self.h);
            },
            0xbd => {
                // CMP L
                _ = self.sub(self.a, self.l);
            },
            0xbe => {
                // CMP M
                _ = self.sub(self.a, self.memory[@as(u16, @as(u16, self.h) << 8 | self.l)]);
            },
            0xbf => {
                // CMP A
                _ = self.sub(self.a, self.a);
            },
            0xc0 => { // RNZ
                self.ret(!self.cc.z);
            },
            0xc1 => { // POP B
                // C <- (SP); B <- (SP+1); SP <- SP+2
                self.c = self.memory[self.sp];
                self.b = self.memory[self.sp + 1];
                self.sp += 2;
            },

            0xc2 => { // JNZ address
                self.jmp(!self.cc.z);
            },
            0xc3 => { // JMP address
                self.jmp(true);
            },
            0xc4 => { // CNZ address
                // if NZ, CALL addr
                self.callAddr(!self.cc.z);
            },
            0xc5 => {
                // PUSH BC
                // (SP-2) <- C; (SP-1) <- B; SP <- SP - 2
                self.memory[self.sp - 2] = self.c;
                self.memory[self.sp - 1] = self.b;
                self.sp -= 2;
            },
            0xc6 => { // ADI byte
                self.a = self.add(self.a, self.memory[self.pc + 1]);
                self.pc += 1;
            },
            0xc7 => { // RST 0
                self.memory[self.sp - 1] = @as(u8, @truncate(self.pc + 1 >> 8)) & 0xff;
                self.memory[self.sp - 2] = @as(u8, @truncate(self.pc + 1)) & 0xff;
                self.sp -= 2;
                self.pc = 0;
            },
            0xc8 => { // RZ
                self.ret(self.cc.z);
            },
            0xc9 => { // RET
                self.ret(true);
            },
            0xca => { // JZ address
                self.jmp(self.cc.z);
            },
            0xcb => null,
            0xcc => { // CZ address
                self.callAddr(self.cc.z);
            },
            0xcd => { // CALL address
                // print("CALL {x}\n", .{@as(u16, @as(u16, self.memory[self.pc + 2]) << 8 | self.memory[self.pc + 1])});
                // if (5 == (@as(u16, @as(u16, self.memory[self.pc + 2]) << 8) | self.memory[self.pc + 1])) {
                // if (self.c == 9) {
                // var offset: u16 = @as(u16, @as(u16, self.d) << 8 | self.e);
                // var i: u16 = offset + 3;
                // var char: u8 = self.memory[i];
                // print("---------------------------------------------------\n", .{});
                // while (char != '$') {
                // print("{c}", .{char});
                // i +%= 1;
                // char = self.memory[i];
                // }
                // var addr = (self.memory[self.sp + 4] | @as(u16, @as(u16, self.memory[self.sp + 5]) << 8)) -% 2;
                // _ = addr;
                // _ = disassembler.disassembleInstruction8080Op(self.memory, addr);
                // print("\n---------------------------------------------------\n", .{});
                // print("\n", .{});
                // } else if (self.c == 2) {
                // print("print char routine called", .{});
                // }
                // self.pc += 2;
                // } else if (0 == (@as(u16, @as(u16, self.memory[self.pc + 2]) << 8) | self.memory[self.pc + 1])) {
                // std.os.exit(0);
                // self.halt = true;
                // } else {
                self.callAddr(true);
                // }
            },
            0xce => { // ACI byte
                self.a = self.add(self.a, self.memory[self.pc + 1] + @intFromBool(self.cc.cy));
                self.pc += 1;
            },
            0xcf => { // RST 1
                self.memory[self.sp - 1] = @truncate(self.pc + 1 >> 8);
                self.memory[self.sp - 2] = @truncate(self.pc + 1);
                self.sp -= 2;
                self.pc = 0x08;
            },
            0xd0 => { // RNC
                // if NCY, RET
                self.ret(!self.cc.cy);
            },
            0xd1 => {
                // POP D
                // E <- (SP); D <- (SP+1); SP <- SP+2
                self.e = self.memory[self.sp];
                self.d = self.memory[self.sp + 1];
                self.sp += 2;
            },

            0xd2 => { // JNC adr
                // if NCY, PC <- adr
                self.jmp(!self.cc.cy);
            },
            0xd3 => null // OUT byte special
            ,
            0xd4 => { // CNC addr
                // if NCY, CALL addr
                self.callAddr(!self.cc.cy);
            },
            0xd5 => {
                // PUSH DE
                // (sp-2) <-E; (sp-1) <- D; SP <- SP-2
                self.memory[self.sp - 2] = self.e;
                self.memory[self.sp - 1] = self.d;
                self.sp -= 2;
            },
            0xd6 => { // SUI byte
                self.a = self.sub(self.a, self.memory[self.pc + 1]);
                self.pc += 1;
            },
            0xd7 => { // RST 2
                // CALL $10
                self.memory[self.sp - 1] = @truncate(self.pc + 1 >> 8);
                self.memory[self.sp - 2] = @truncate(self.pc + 1);
                self.sp -= 2;
                self.pc = 0x10;
            },
            0xd8 => { // RC
                // if CY, RET
                self.ret(self.cc.cy);
            },
            0xd9 => null,
            0xda => { // JC addr
                // if CY, PC <- addr
                self.jmp(self.cc.cy);
            },
            0xdb => null, // IN byte special
            0xdc => { // CC addr
                // if CY, CALL addr
                self.callAddr(self.cc.cy);
            },
            0xdd => null,

            0xde => { // SBI byte
                self.a = self.sub(self.a, self.memory[self.pc + 1] + @intFromBool(self.cc.cy));
                self.pc += 1;
            },
            0xdf => { // RST 3
                // CALL $18
                self.rst(0x18);
            },
            0xe0 => { // RPO
                // if PO, RET
                self.ret(!self.cc.p);
            },
            0xe1 => {
                // POP H
                // L <- (SP); H <- (SP+1); SP <- SP+2
                self.l = self.memory[self.sp];
                self.h = self.memory[self.sp + 1];
                self.sp += 2;
            },
            0xe2 => {
                // JPO addr
                // if PO, PC <- addr
                self.jmp(!self.cc.p);
            },
            0xe3 => {
                // XTHL
                // L <-> (SP); H <-> (SP+1)
                var l = self.l;
                var h = self.h;
                self.l = self.memory[self.sp];
                self.h = self.memory[self.sp + 1];
                self.memory[self.sp] = l;
                self.memory[self.sp + 1] = h;
            },
            0xe4 => {
                // CPO addr
                // if PO, CALL addr
                self.callAddr(!self.cc.p);
            },
            0xe5 => {
                // PUSH H
                // (SP-2) <- L; (SP-1) <- H; SP <- SP-2
                self.memory[self.sp - 2] = self.l;
                self.memory[self.sp - 1] = self.h;
                self.sp -= 2;
            },
            0xe6 => {
                // ANI byte
                // A <- A & byte
                var x = self.a & self.memory[self.pc + 1];
                self.cc.z = x == 0;
                self.cc.s = (x & 0x80) == 0x80;
                self.cc.p = parity(x);
                self.cc.cy = false;
                self.a = x;
                self.pc += 1;
            },
            0xe7 => {
                // RST 4
                // CALL $20
                self.rst(0x20);
            },

            0xe8 => {
                // RPE
                // if PE, RET
                self.ret(self.cc.p);
            },
            0xe9 => {
                // PCHL
                // PC.hi <- H; PC.lo <- L
                self.pc = @as(u16, @as(u16, self.h) << 8 | self.l);
                return CYCLES[0xe9];
            },
            0xea => {
                // JPE addr
                // if PE, PC <- addr
                self.jmp(self.cc.p);
            },
            0xeb => {
                // XCHG
                // H <-> D; L <-> E
                var l = self.l;
                var h = self.h;
                self.l = self.e;
                self.h = self.d;
                self.e = l;
                self.d = h;
            },
            0xec => {
                // CPE addr
                // if PE, CALL addr
                self.callAddr(self.cc.p);
            },
            0xed => null,
            0xee => {
                // XRI byte
                // A <- A ^ byte
                self.a = self.xra(self.a, self.memory[self.pc + 1]);
                self.pc += 1;
            },
            0xef => {
                // RST 5
                // CALL $28
                self.rst(0x28);
            },
            0xf0 => {
                // RP
                // if P, RET
                self.ret(!self.cc.s);
            },
            0xf1 => { // POP PSW
                // flags <- (SP); A <- (SP+1); SP <- SP+2
                var psw = self.memory[self.sp];
                self.a = self.memory[self.sp + 1];
                self.cc.z = (psw & 0x01) == 0x01;
                self.cc.s = (psw & 0x02) == 0x02;
                self.cc.p = (psw & 0x04) == 0x04;
                self.cc.cy = (psw & 0x08) == 0x08;
                self.cc.ac = (psw & 0x10) == 0x10;
                self.sp += 2;
            },
            0xf2 => {
                // JP addr
                // if P, PC <- addr
                self.jmp(!self.cc.s);
            },
            0xf3 => self.int_enable = false, // DI special
            0xf4 => {
                // CP addr
                // if P, CALL addr
                self.callAddr(!self.cc.s);
            },
            0xf5 => { // PUSH PSW
                // (SP-1) <- A; (SP-2) <- flags; SP <- SP-2
                self.memory[self.sp - 1] = self.a;
                //self.memory[self.sp - 2] = (u8)(self.cc.z << 7 |
                //    self.cc.s << 6 |
                //    self.cc.p << 2 |
                //    self.cc.cy << 0);
                self.memory[self.sp - 2] = @as(u8, @intFromBool(self.cc.z) |
                    @as(u8, @intFromBool(self.cc.s)) << 1 |
                    @as(u8, @intFromBool(self.cc.p)) << 2 |
                    @as(u8, @intFromBool(self.cc.cy)) << 3 |
                    @as(u8, @intFromBool(self.cc.ac)) << 4);
                self.sp -= 2;
            },
            0xf6 => {
                // ORI byte
                // A <- A | byte
                self.a = self.ora(self.a, self.memory[self.pc + 1]);
                self.pc += 1;
            },
            0xf7 => self.rst(0x30), // RST 6
            0xf8 => {
                // RM
                // if M, RET
                self.ret(self.cc.s);
            },
            0xf9 => {
                // SPHL
                // SP.hi <- H; SP.lo <- L
                self.sp = @as(u16, @as(u16, self.h) << 8 | self.l);
            },
            0xfa => {
                // JM addr
                // if M, PC <- addr
                self.jmp(self.cc.s);
            },
            0xfb => {
                // EI
                self.int_enable = true;
            },
            0xfc => {
                // CM addr
                // if M, CALL addr
                self.callAddr(self.cc.s);
            },
            0xfd => null,
            0xfe => {
                // CPI byte
                // A - byte
                // var x = self.a -% self.memory[self.pc + 1];
                // self.cc.z = x == 0;
                // self.cc.s = (x & 0x80) == 0x80;
                // self.cc.p = parity(x);
                // self.cc.cy = self.a < self.memory[self.pc + 1];
                _ = self.sub(self.a, self.memory[self.pc + 1]);

                self.pc += 1;
            },
            0xff => self.rst(0x38), // RST 7 CALL $38

        };

        self.pc += 1;
        return CYCLES[opcode];
        // print("\tC={} P={} S={} Z={} CY={} AC={}\n", .{ self.cc.cy, self.cc.p, self.cc.s, self.cc.z, self.cc.cy, self.cc.ac });
        // print("\tA 0x{x:0>2} B 0x{x:0>2} C 0x{x:0>2} D 0x{x:0>2} E 0x{x:0>2} H 0x{x:0>2} L 0x{x:0>2} SP 0x{x:0>4} PC 0x{x:0>4}\n", .{ self.a, self.b, self.c, self.d, self.e, self.h, self.l, self.sp, self.pc });
    }

    pub fn add(self: *Self, a: u8, b: u8) u8 {
        var result: u16 = @as(u16, a) +% @as(u16, b);
        self.cc.z = (result & 0xff) == 0;
        self.cc.s = (result & 0x80) != 0;
        self.cc.cy = result > 0xff;
        self.cc.p = parity(@truncate(result));
        return @truncate(result);
    }

    pub fn inr(self: *Self, a: u8) u8 {
        var result: u8 = a +% 1;
        self.cc.z = (result & 0xff) == 0;
        self.cc.s = (result & 0x80) != 0;
        self.cc.p = parity(result);
        return @truncate(result);
    }

    pub fn dcr(self: *Self, a: u8) u8 {
        var result: u8 = a -% 1;
        self.cc.z = (result & 0xff) == 0;
        self.cc.s = (result & 0x80) != 0;
        self.cc.p = parity(result);
        return @truncate(result);
    }

    pub fn sub(self: *Self, a: u8, b: u8) u8 {
        var result: u8 = a -% b;
        self.cc.z = (result & 0xff) == 0;
        self.cc.s = (result & 0x80) != 0;
        self.cc.cy = b > a;
        self.cc.p = parity(result);
        return @truncate(result);
    }

    pub fn ana(self: *Self, a: u8, b: u8) u8 {
        var result: u8 = a & b;
        self.cc.z = result == 0;
        self.cc.s = (result & 0x80) != 0;
        self.cc.p = parity(result);
        self.cc.cy = false;
        return result;
    }

    pub fn xra(self: *Self, a: u8, b: u8) u8 {
        var result: u8 = a ^ b;
        self.cc.z = result == 0;
        self.cc.s = (result & 0x80) != 0;
        self.cc.p = parity(result);
        self.cc.cy = false;
        return result;
    }

    pub fn ora(self: *Self, a: u8, b: u8) u8 {
        var result: u8 = a | b;
        self.cc.z = result == 0;
        self.cc.s = (result & 0x80) != 0;
        self.cc.p = parity(result);
        self.cc.cy = false;
        return result;
    }

    pub fn callAddr(self: *Self, condition: bool) void {
        if (condition) {
            // (SP-1) <- PC.hi; (SP-2) <- PC.lo; SP <- SP-2; PC=adr
            self.push(@truncate(self.pc + 2 >> 8), @truncate(self.pc + 2));
            self.pc = @as(u16, @as(u16, self.memory[self.pc + 2]) << 8 | self.memory[self.pc + 1]);
            self.pc -%= 1;
        } else {
            self.pc += 2;
        }
    }

    pub fn jmp(self: *Self, condition: bool) void {
        if (condition) {
            self.pc = @as(u16, @as(u16, self.memory[self.pc + 2]) << 8 | self.memory[self.pc + 1]);
            self.pc -%= 1;
        } else {
            self.pc += 2;
        }
    }

    pub fn ret(self: *Self, condition: bool) void {
        if (condition) {
            // PC.lo <- (sp); PC.hi <- (sp+1); sp <- sp+2
            self.pc = self.memory[self.sp] | @as(u16, @as(u16, self.memory[self.sp + 1]) << 8);
            self.sp += 2;
        }
    }

    pub fn rst(self: *Self, addr: u16) void {
        // CALL $addr
        self.push(@truncate(self.pc >> 8), @truncate(self.pc));
        self.pc = addr;
    }

    pub fn push(self: *Self, a: u8, b: u8) void {
        self.memory[self.sp - 1] = a;
        self.memory[self.sp - 2] = b;
        self.sp -= 2;
    }

    pub fn generateInterrupt(self: *Self, interrupt_num: u8) void {
        // print("Interrupt {x}\n", .{interrupt_num});
        if (!self.int_enable) return;
        self.rst(8 * interrupt_num);
        self.int_enable = false;
    }
    pub fn inSpaceInvaders(self: *Self, port: u8) u8 {
        // _ = disassembler.disassembleInstruction8080Op(self.memory, self.pc);
        self.pc += 2;
        return switch (port) {
            1 => 1,
            3 => {
                var v: u16 = @as(u16, self.shift1) << 8 | self.shift0;
                return @truncate(v >> (8 - self.shift_offset));
            },
            else => 0,
        };
    }

    pub fn outSpaceInvaders(self: *Self, port: u8, value: u8) void {
        // _ = disassembler.disassembleInstruction8080Op(self.memory, self.pc);
        switch (port) {
            2 => self.shift_offset = @truncate(value & 0x7),
            4 => {
                self.shift0 = self.shift1;
                self.shift1 = value;
            },
            else => {},
        }
        self.pc += 2;
    }

    // pub fn cpuStep(cpu: *Self) void {
    pub fn cpuStep(cpu: *Self, now: f64) void {
        // var now = jsTime();
        // var now = if (std.builtin.cpu.arch.isWasm()) jsTime() else @as(f64, @floatFromInt(std.time.microTimestamp()));

        if (cpu.last_interrupt == 0) {
            cpu.last_interrupt = now;
            cpu.next_interrupt = cpu.last_interrupt + 16000;
            cpu.which_interrupt = 1;
        }

        if (cpu.int_enable and now > cpu.next_interrupt) {
            cpu.generateInterrupt(cpu.which_interrupt);
            cpu.which_interrupt = if (cpu.which_interrupt == 1) 2 else 1;
            cpu.next_interrupt += 8000;
        }

        var since_last: f64 = now - cpu.last_interrupt;
        var cycles_to_catch_up: f64 = since_last * 2;
        var cycles: f64 = 0;

        // printHex(@intFromFloat(cycles_to_catch_up), @intFromFloat(since_last), 0, 0);
        while (cycles < cycles_to_catch_up) {
            // printHex(cpu.pc, cpu.memory[cpu.pc], cpu.memory[cpu.pc + 1], cpu.memory[cpu.pc + 2]);
            switch (cpu.memory[cpu.pc]) {
                // 0x76 => return, //HLT
                0xdb => { // IN
                    cpu.a = cpu.inSpaceInvaders(cpu.memory[cpu.pc + 1]);
                    cycles += 3;
                },
                0xd3 => { // OUT
                    cpu.outSpaceInvaders(cpu.memory[cpu.pc + 1], cpu.a);
                    cycles += 3;
                },
                else => cycles += @floatFromInt(cpu.emulate_op()),
            }
        }

        cpu.last_interrupt = now;
    }

    pub fn step(cpu: *Self) i64 {
        // printHex(cpu.pc, cpu.memory[cpu.pc], cpu.memory[cpu.pc + 1], cpu.memory[cpu.pc + 2]);
        switch (cpu.memory[cpu.pc]) {
            // 0x76 => return, //HLT
            0xdb => { // IN
                cpu.a = cpu.inSpaceInvaders(cpu.memory[cpu.pc + 1]);
                return 3;
            },
            0xd3 => { // OUT
                cpu.outSpaceInvaders(cpu.memory[cpu.pc + 1], cpu.a);
                return 3;
            },
            else => return cpu.emulate_op(),
        }
    }

    pub fn keyDown(cpu: *Self, key: u8) void {
        cpu.in_port1 |= key;
    }

    pub fn keyUp(cpu: *Self, key: u8) void {
        cpu.in_port1 &= ~key;
    }
};

const alloc = std.heap.wasm_allocator;
pub export fn cpuInit(len: usize, rom: [*]const u8) ?[*]u8 {
    const cpu = alloc.alignedAlloc(u8, @alignOf(CPU8080), @sizeOf(CPU8080)) catch return null;
    CPU8080.init(@ptrCast(@alignCast(cpu)), rom[0..len]);
    return cpu.ptr;
}

pub export fn cpuSize() usize {
    return @sizeOf(CPU8080);
}

pub export fn cpuDestroy(cpu: *CPU8080) void {
    alloc.destroy(cpu);
}

pub export fn wasmAlloc(size: usize) ?[*]u8 {
    return (alloc.alignedAlloc(u8, @import("builtin").target.maxIntAlignment(), size) catch return null).ptr;
}

pub export fn cpuStep(cpu_ptr: [*]u8, now: f64) void {
    var cpu: *CPU8080 = @ptrCast(@alignCast(cpu_ptr));
    cpu.cpuStep(now);
}

pub export fn cpuStepCycle(cpu_ptr: [*]u8) i32 {
    var cpu: *CPU8080 = @ptrCast(@alignCast(cpu_ptr));
    return @truncate(cpu.step());
}

pub export fn cpuGenerateInterrupt(cpu_ptr: [*]u8, interrupt_num: u8) void {
    var cpu: *CPU8080 = @ptrCast(@alignCast(cpu_ptr));
    cpu.generateInterrupt(interrupt_num);
}

pub export fn keyDown(cpu_ptr: [*]u8, key: u8) void {
    var cpu: *CPU8080 = @ptrCast(@alignCast(cpu_ptr));
    cpu.keyDown(key);
}

pub export fn keyUp(cpu_ptr: [*]u8, key: u8) void {
    var cpu: *CPU8080 = @ptrCast(@alignCast(cpu_ptr));
    cpu.keyUp(key);
}

// pub export fn cpuMemory(cpu: *CPU8080) ?*[65536]u8 {
// pub export fn cpuMemory(cpu_ptr: [*]u8) ?*[65536]u8 {
pub export fn cpuMemory(cpu_ptr: [*]u8) ?*u8 {
    var cpu: *CPU8080 = @ptrCast(@alignCast(cpu_ptr));
    return &cpu.memory[0];
    // var memory = alloc.alignedAlloc(u8, 8, 65536) catch return null;
    // for (cpu.memory[0..], 0..) |byte, i| {
    // memory[i] = byte;
    // }
    // @memcpy(memory.ptr, cpu.memory[0..]);
    // return @ptrCast(memory.ptr);
}

// pub export fn cpuScreen(cpu: *CPU8080) ?*[7168]u8 {
// pub export fn cpuScreen(cpu: *CPU8080) ?[*]align(8) u8 {
// pub export fn cpuScreen(cpu_ptr: [*]u8, screen: [*]u8) ?*u8 {
pub export fn cpuScreen(cpu_ptr: [*]u8) ?*u8 {
    var cpu: *CPU8080 = @ptrCast(@alignCast(cpu_ptr));
    // var i: usize = 0;
    // while (i < 7168) {
    // printHex(cpu.memory[0x2400 + i + 0], cpu.memory[0x2400 + i + 1], cpu.memory[0x2400 + i + 2], cpu.memory[0x2400 + i + 3]);
    // i += 4;
    // }
    return &cpu.memory[0x2400];
}

extern fn time() f64;
pub inline fn jsTime() f64 {
    return time();
}

extern fn print([*:0]const u8, usize) void;
pub fn log(comptime str: []const u8, args: anytype) void {
    var buf: [1024:0]u8 = undefined;
    const string = std.fmt.bufPrintZ(&buf, str, args) catch &buf;
    print(string, string.len);
}

extern fn printHex(u32, u32, u32, u32) void;
