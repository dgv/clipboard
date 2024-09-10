/// Library clipboard read/write on clipboard
const std = @import("std");
const builtin = @import("builtin");
const win = @import("clipboard_windows.zig");
const macos = @import("clipboard_macos.zig");
const unix = @import("clipboard_unix.zig");
const testing = std.testing;

/// read string from clipboard
pub fn read() ![]const u8 {
    switch (builtin.os.tag) {
        .windows => return try win.read(),
        .macos => return try macos.read(),
        .linux, .freebsd, .openbsd, .netbsd, .dragonfly => return try unix.read(),
        else => @compileError("platform not currently supported"),
    }
}

/// write string to clipboard
pub fn write(text: []const u8) !void {
    switch (builtin.os.tag) {
        .windows => try win.write(text),
        .macos => try macos.write(text),
        .linux, .freebsd, .openbsd, .netbsd, .dragonfly => try unix.write(text),
        else => @compileError("platform not currently supported"),
    }
}

test "utf8 copy/paste" {
    const text = "zig zag ⚡";
    try write(text);
    const r = try read();
    try std.testing.expect(std.mem.eql(u8, r, text));
}

test "write copy/paste" {
    const text = "#" ** 1180;
    try write(text);
    const r = try read();
    try std.testing.expect(std.mem.eql(u8, r, text));
}
