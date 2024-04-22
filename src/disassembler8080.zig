const std = @import("std");

pub fn disassembleInstruction8080Op(codebuffer: [0x10_000]u8, pc: u16) u8 {
    var code = codebuffer[pc];
    var opbytes: u8 = 1;
    std.debug.print("{x:0>4} {x:0>2} ", .{ pc, code });
    switch (code) {
        0x00 => std.debug.print("NOP", .{}),
        0x01 => {
            std.debug.print("LXI    B, {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0x02 => std.debug.print("STAX   B", .{}),
        0x03 => std.debug.print("INX    B", .{}),
        0x04 => std.debug.print("INR    B", .{}),
        0x05 => std.debug.print("DCR    B", .{}),
        0x06 => {
            std.debug.print("MVI    B, {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0x07 => std.debug.print("RLC", .{}),
        0x08 => std.debug.print("NOP", .{}),

        0x09 => std.debug.print("DAD    B", .{}),
        0x0a => std.debug.print("LDAX   B", .{}),
        0x0b => std.debug.print("DCX    B", .{}),
        0x0c => std.debug.print("INR    C", .{}),
        0x0d => std.debug.print("DCR    C", .{}),
        0x0e => {
            std.debug.print("MVI    C, {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0x0f => std.debug.print("RRC", .{}),
        0x10 => std.debug.print("NOP", .{}),
        0x11 => {
            std.debug.print("LXI    D, {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0x12 => std.debug.print("STAX   D", .{}),
        0x13 => std.debug.print("INX    D", .{}),
        0x14 => std.debug.print("INR    D", .{}),
        0x15 => std.debug.print("DCR    D", .{}),
        0x16 => {
            std.debug.print("MVI    D, {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0x17 => std.debug.print("RAL", .{}),
        0x18 => std.debug.print("NOP", .{}),

        0x19 => std.debug.print("DAD    D", .{}),
        0x1a => std.debug.print("LDAX   D", .{}),
        0x1b => std.debug.print("DCX    D", .{}),
        0x1c => std.debug.print("INR    E", .{}),
        0x1d => std.debug.print("DCR    E", .{}),
        0x1e => {
            std.debug.print("MVI    E, {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0x1f => std.debug.print("RAR", .{}),
        0x20 => std.debug.print("NOP", .{}),

        0x21 => {
            std.debug.print("LXI    H, {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0x22 => {
            std.debug.print("SHLD   {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0x23 => std.debug.print("INX    H", .{}),
        0x24 => std.debug.print("INR    H", .{}),
        0x25 => std.debug.print("DCR    H", .{}),
        0x26 => {
            std.debug.print("MVI    H, {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0x27 => std.debug.print("DAA", .{}),
        0x28 => std.debug.print("NOP", .{}),

        0x29 => std.debug.print("DAD    H", .{}),
        0x2a => {
            std.debug.print("LHLD   {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0x2b => std.debug.print("DCX    H", .{}),
        0x2c => std.debug.print("INR    L", .{}),
        0x2d => std.debug.print("DCR    L", .{}),
        0x2e => {
            std.debug.print("MVI    L, {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0x2f => std.debug.print("CMA", .{}),
        0x30 => std.debug.print("NOP", .{}),

        0x31 => {
            std.debug.print("LXI    SP, {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0x32 => {
            std.debug.print("STA    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0x33 => std.debug.print("INX    SP", .{}),
        0x34 => std.debug.print("INR    M", .{}),
        0x35 => std.debug.print("DCR    M", .{}),
        0x36 => {
            std.debug.print("MVI    M, {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0x37 => std.debug.print("STC", .{}),
        0x38 => std.debug.print("NOP", .{}),

        0x39 => std.debug.print("DAD    SP", .{}),
        0x3a => {
            std.debug.print("LDA    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0x3b => std.debug.print("DCX    SP", .{}),
        0x3c => std.debug.print("INR    A", .{}),
        0x3d => std.debug.print("DCR    A", .{}),
        0x3e => {
            std.debug.print("MVI    A, {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0x3f => std.debug.print("CMC", .{}),
        0x40 => std.debug.print("MOV    B, B", .{}),
        0x41 => std.debug.print("MOV    B, C", .{}),
        0x42 => std.debug.print("MOV    B, D", .{}),
        0x43 => std.debug.print("MOV    B, E", .{}),
        0x44 => std.debug.print("MOV    B, H", .{}),
        0x45 => std.debug.print("MOV    B, L", .{}),
        0x46 => std.debug.print("MOV    B, M", .{}),
        0x47 => std.debug.print("MOV    B, A", .{}),
        0x48 => std.debug.print("MOV    C, B", .{}),
        0x49 => std.debug.print("MOV    C, C", .{}),
        0x4a => std.debug.print("MOV    C, D", .{}),
        0x4b => std.debug.print("MOV    C, E", .{}),
        0x4c => std.debug.print("MOV    C, H", .{}),
        0x4d => std.debug.print("MOV    C, L", .{}),
        0x4e => std.debug.print("MOV    C, M", .{}),
        0x4f => std.debug.print("MOV    C, A", .{}),
        0x50 => std.debug.print("MOV    D, B", .{}),
        0x51 => std.debug.print("MOV    D, C", .{}),
        0x52 => std.debug.print("MOV    D, D", .{}),
        0x53 => std.debug.print("MOV    D, E", .{}),
        0x54 => std.debug.print("MOV    D, H", .{}),
        0x55 => std.debug.print("MOV    D, L", .{}),
        0x56 => std.debug.print("MOV    D, M", .{}),
        0x57 => std.debug.print("MOV    D, A", .{}),
        0x58 => std.debug.print("MOV    E, B", .{}),
        0x59 => std.debug.print("MOV    E, C", .{}),
        0x5a => std.debug.print("MOV    E, D", .{}),
        0x5b => std.debug.print("MOV    E, E", .{}),
        0x5c => std.debug.print("MOV    E, H", .{}),
        0x5d => std.debug.print("MOV    E, L", .{}),
        0x5e => std.debug.print("MOV    E, M", .{}),
        0x5f => std.debug.print("MOV    E, A", .{}),
        0x60 => std.debug.print("MOV    H, B", .{}),
        0x61 => std.debug.print("MOV    H, C", .{}),
        0x62 => std.debug.print("MOV    H, D", .{}),
        0x63 => std.debug.print("MOV    H, E", .{}),
        0x64 => std.debug.print("MOV    H, H", .{}),
        0x65 => std.debug.print("MOV    H, L", .{}),
        0x66 => std.debug.print("MOV    H, M", .{}),
        0x67 => std.debug.print("MOV    H, A", .{}),
        0x68 => std.debug.print("MOV    L, B", .{}),
        0x69 => std.debug.print("MOV    L, C", .{}),
        0x6a => std.debug.print("MOV    L, D", .{}),
        0x6b => std.debug.print("MOV    L, E", .{}),
        0x6c => std.debug.print("MOV    L, H", .{}),
        0x6d => std.debug.print("MOV    L, L", .{}),
        0x6e => std.debug.print("MOV    L, M", .{}),
        0x6f => std.debug.print("MOV    L, A", .{}),
        0x70 => std.debug.print("MOV    M, B", .{}),
        0x71 => std.debug.print("MOV    M, C", .{}),
        0x72 => std.debug.print("MOV    M, D", .{}),
        0x73 => std.debug.print("MOV    M, E", .{}),
        0x74 => std.debug.print("MOV    M, H", .{}),
        0x75 => std.debug.print("MOV    M, L", .{}),
        0x76 => std.debug.print("HLT", .{}),
        0x77 => std.debug.print("MOV    M, A", .{}),
        0x78 => std.debug.print("MOV    A, B", .{}),
        0x79 => std.debug.print("MOV    A, C", .{}),
        0x7a => std.debug.print("MOV    A, D", .{}),
        0x7b => std.debug.print("MOV    A, E", .{}),
        0x7c => std.debug.print("MOV    A, H", .{}),
        0x7d => std.debug.print("MOV    A, L", .{}),
        0x7e => std.debug.print("MOV    A, M", .{}),
        0x7f => std.debug.print("MOV    A, A", .{}),
        0x80 => std.debug.print("ADD    B", .{}),
        0x81 => std.debug.print("ADD    C", .{}),
        0x82 => std.debug.print("ADD    D", .{}),
        0x83 => std.debug.print("ADD    E", .{}),
        0x84 => std.debug.print("ADD    H", .{}),
        0x85 => std.debug.print("ADD    L", .{}),
        0x86 => std.debug.print("ADD    M", .{}),
        0x87 => std.debug.print("ADD    A", .{}),
        0x88 => std.debug.print("ADC    B", .{}),
        0x89 => std.debug.print("ADC    C", .{}),
        0x8a => std.debug.print("ADC    D", .{}),
        0x8b => std.debug.print("ADC    E", .{}),
        0x8c => std.debug.print("ADC    H", .{}),
        0x8d => std.debug.print("ADC    L", .{}),
        0x8e => std.debug.print("ADC    M", .{}),
        0x8f => std.debug.print("ADC    A", .{}),
        0x90 => std.debug.print("SUB    B", .{}),
        0x91 => std.debug.print("SUB    C", .{}),
        0x92 => std.debug.print("SUB    D", .{}),
        0x93 => std.debug.print("SUB    E", .{}),
        0x94 => std.debug.print("SUB    H", .{}),
        0x95 => std.debug.print("SUB    L", .{}),
        0x96 => std.debug.print("SUB    M", .{}),
        0x97 => std.debug.print("SUB    A", .{}),
        0x98 => std.debug.print("SBB    B", .{}),
        0x99 => std.debug.print("SBB    C", .{}),
        0x9a => std.debug.print("SBB    D", .{}),
        0x9b => std.debug.print("SBB    E", .{}),
        0x9c => std.debug.print("SBB    H", .{}),
        0x9d => std.debug.print("SBB    L", .{}),
        0x9e => std.debug.print("SBB    M", .{}),
        0x9f => std.debug.print("SBB    A", .{}),
        0xa0 => std.debug.print("ANA    B", .{}),
        0xa1 => std.debug.print("ANA    C", .{}),
        0xa2 => std.debug.print("ANA    D", .{}),
        0xa3 => std.debug.print("ANA    E", .{}),
        0xa4 => std.debug.print("ANA    H", .{}),
        0xa5 => std.debug.print("ANA    L", .{}),
        0xa6 => std.debug.print("ANA    M", .{}),
        0xa7 => std.debug.print("ANA    A", .{}),
        0xa8 => std.debug.print("XRA    B", .{}),
        0xa9 => std.debug.print("XRA    C", .{}),
        0xaa => std.debug.print("XRA    D", .{}),
        0xab => std.debug.print("XRA    E", .{}),
        0xac => std.debug.print("XRA    H", .{}),
        0xad => std.debug.print("XRA    L", .{}),
        0xae => std.debug.print("XRA    M", .{}),
        0xaf => std.debug.print("XRA    A", .{}),
        0xb0 => std.debug.print("ORA    B", .{}),
        0xb1 => std.debug.print("ORA    C", .{}),
        0xb2 => std.debug.print("ORA    D", .{}),
        0xb3 => std.debug.print("ORA    E", .{}),
        0xb4 => std.debug.print("ORA    H", .{}),
        0xb5 => std.debug.print("ORA    L", .{}),
        0xb6 => std.debug.print("ORA    M", .{}),
        0xb7 => std.debug.print("ORA    A", .{}),
        0xb8 => std.debug.print("CMP    B", .{}),
        0xb9 => std.debug.print("CMP    C", .{}),
        0xba => std.debug.print("CMP    D", .{}),
        0xbb => std.debug.print("CMP    E", .{}),
        0xbc => std.debug.print("CMP    H", .{}),
        0xbd => std.debug.print("CMP    L", .{}),
        0xbe => std.debug.print("CMP    M", .{}),
        0xbf => std.debug.print("CMP    A", .{}),
        0xc0 => std.debug.print("RNZ", .{}),
        0xc1 => std.debug.print("POP    B", .{}),
        0xc2 => {
            std.debug.print("JNZ    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xc3 => {
            std.debug.print("JMP    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xc4 => {
            std.debug.print("CNZ    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xc5 => std.debug.print("PUSH   B", .{}),
        0xc6 => {
            std.debug.print("ADI    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xc7 => std.debug.print("RST    0", .{}),
        0xc8 => std.debug.print("RZ", .{}),
        0xc9 => std.debug.print("RET", .{}),
        0xca => {
            std.debug.print("JZ     {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xcb => std.debug.print("NOP", .{}),

        0xcc => {
            std.debug.print("CZ     {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xcd => {
            std.debug.print("CALL   {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xce => {
            std.debug.print("ACI    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xcf => std.debug.print("RST    1", .{}),
        0xd0 => std.debug.print("RNC", .{}),
        0xd1 => std.debug.print("POP    D", .{}),
        0xd2 => {
            std.debug.print("JNC    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xd3 => {
            std.debug.print("OUT    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xd4 => {
            std.debug.print("CNC    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xd5 => std.debug.print("PUSH   D", .{}),
        0xd6 => {
            std.debug.print("SUI    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xd7 => std.debug.print("RST    2", .{}),
        0xd8 => std.debug.print("RC", .{}),
        0xd9 => std.debug.print("NOP", .{}),

        0xda => {
            std.debug.print("JC     {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xdb => {
            std.debug.print("IN     {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xdc => {
            std.debug.print("CC     {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xdd => std.debug.print("NOP", .{}),

        0xde => {
            std.debug.print("SBI    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xdf => std.debug.print("RST    3", .{}),
        0xe0 => std.debug.print("RPO", .{}),
        0xe1 => std.debug.print("POP    H", .{}),
        0xe2 => {
            std.debug.print("JPO    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xe3 => std.debug.print("XTHL", .{}),
        0xe4 => {
            std.debug.print("CPO    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xe5 => std.debug.print("PUSH   H", .{}),
        0xe6 => {
            std.debug.print("ANI    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xe7 => std.debug.print("RST    4", .{}),
        0xe8 => std.debug.print("RPE", .{}),
        0xe9 => std.debug.print("PCHL", .{}),
        0xea => {
            std.debug.print("JPE    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xeb => std.debug.print("XCHG", .{}),
        0xec => {
            std.debug.print("CPE    {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xed => std.debug.print("NOP", .{}),

        0xee => {
            std.debug.print("XRI    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xef => std.debug.print("RST    5", .{}),
        0xf0 => std.debug.print("RP", .{}),
        0xf1 => std.debug.print("POP    PSW", .{}),
        0xf2 => {
            std.debug.print("JP     {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xf3 => std.debug.print("DI", .{}),
        0xf4 => {
            std.debug.print("CP     {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xf5 => std.debug.print("PUSH   PSW", .{}),
        0xf6 => {
            std.debug.print("ORI    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xf7 => std.debug.print("RST    6", .{}),
        0xf8 => std.debug.print("RM", .{}),
        0xf9 => std.debug.print("SPHL", .{}),
        0xfa => {
            std.debug.print("JM     {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xfb => std.debug.print("EI", .{}),
        0xfc => {
            std.debug.print("CM     {x:0>2}{x:0>2}", .{ codebuffer[pc + 2], codebuffer[pc + 1] });
            opbytes = 3;
        },
        0xfd => std.debug.print("NOP", .{}),

        0xfe => {
            std.debug.print("CPI    {x:0>2}", .{codebuffer[pc + 1]});
            opbytes = 2;
        },
        0xff => std.debug.print("RST    7", .{}),
    }
    std.debug.print("\n", .{});
    return opbytes;
}
