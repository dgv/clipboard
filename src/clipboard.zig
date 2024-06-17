const std = @import("std");
const win = @import("clipboard_windows.zig");
const testing = std.testing;

pub fn read() ![]u8 {
    switch (std.builtin.os.tag) {
        .windows => return win.read(),
        //.macos => macos.read(),
        //.unix => unix.read(),
        else => @compileError("platform not currently supported"),
    }
}

pub fn write(string: []const u8) !void {
    switch (std.builtin.os.tag) {
        .windows => win.write(string),
        //.macos => macos.read(),
        //.unix => unix.read(),
        else => @compileError("platform not currently supported"),
    }
}
