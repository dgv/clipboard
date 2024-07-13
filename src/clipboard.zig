const std = @import("std");
const builtin = @import("builtin");
const win = @import("clipboard_windows.zig");
const testing = std.testing;

pub fn read() ![]const u8 {
    switch (builtin.os.tag) {
        .windows => return try win.read(),
        //.macos => macos.read(),
        //.unix => unix.read(),
        else => @compileError("platform not currently supported"),
    }
}

pub fn write(string: []const u8) !void {
    switch (builtin.os.tag) {
        .windows => try win.write(string),
        //.macos => macos.read(),
        //.unix => unix.read(),
        else => @compileError("platform not currently supported"),
    }
}

test "copy/paste" {
    const text = "zig zag ⚡";
    try write(text);
    const r = try read();
    try std.testing.expect(std.mem.eql(u8, r, text));
}
