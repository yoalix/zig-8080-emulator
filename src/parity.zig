const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;

/// Asserts at compile time that `T` is an integer, returns `T`
pub fn requireInt(comptime T: type) type {
    comptime assert(@typeInfo(T) == .Int);
    return T;
}

/// Asserts at compile time that `T` is an unsigned integer, returns `T`
pub fn requireUnsignedInt(comptime T: type) type {
    _ = requireInt(T);
    comptime assert(@typeInfo(T).Int.signedness == .unsigned);
    return T;
}

pub fn parityParallel(val: anytype) bool {
    const T = requireUnsignedInt(@TypeOf(val));
    return 0 != switch (@typeInfo(T).Int.bits) {
        8 => res: {
            var v: u8 = @as(u8, @intCast(val));
            v ^= v >> 4;
            v ^= v >> 2;
            v ^= v >> 1;
            v &= 0xf;
            break :res v & 1;
        },
        16 => res: {
            var v: u16 = @as(u16, @intCast(val));
            v ^= v >> 8;
            v ^= v >> 4;
            v ^= v >> 2;
            v ^= v >> 1;
            v &= 0xf;
            break :res v & 1;
        },
        else => @panic("Invalid integer size"),
    };
}

test "Compute parity in parallel" {
    try expect(parityParallel(@as(u8, 2)));
    try expect(parityParallel(@as(u8, 4)));
    try expect(parityParallel(@as(u8, 7)));
    try expect(!parityParallel(@as(u8, 0)));
    try expect(!parityParallel(@as(u16, 3)));
    try expect(!parityParallel(@as(u16, 0xffff)));
    try expect(parityParallel(@as(u8, 2)));
    try expect(parityParallel(@as(u8, 4)));
    try expect(parityParallel(@as(u8, 7)));
    try expect(!parityParallel(@as(u8, 0)));
    try expect(!parityParallel(@as(u8, 3)));
    try expect(!parityParallel(@as(u8, 0xff)));
    try expect(parityParallel(@as(u16, 2)));
    try expect(parityParallel(@as(u16, 4)));
    try expect(parityParallel(@as(u16, 7)));
    try expect(!parityParallel(@as(u16, 0)));
    try expect(!parityParallel(@as(u16, 3)));
}
