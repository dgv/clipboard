/// Cross-platform clipboard read/write.
/// Uses `std.heap.smp_allocator` for persistent allocations and
/// `ArenaAllocator` for short-lived temporaries.

const std = @import("std");
const builtin = @import("builtin");
const win = @import("clipboard_windows.zig");
const macos = @import("clipboard_macos.zig");
const unix = @import("clipboard_unix.zig");
const wsl = @import("clipboard_wsl.zig");
const testing = std.testing;

/// Lazily-initialized global Io.Threaded instance for process/file I/O.
var _threaded: ?std.Io.Threaded = null;

/// Returns true when running inside WSL (Windows Subsystem for Linux)
/// by checking /proc/version for "microsoft" (case-insensitive).
fn isWSL() bool {
    const io = get();
    const file = std.Io.Dir.openFileAbsolute(io, "/proc/version", .{}) catch return false;
    defer file.close(io);

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const aalloc = arena.allocator();

    var buf: [4096]u8 = undefined;
    var reader = file.reader(io, &buf);
    const content = reader.interface.allocRemaining(aalloc, .unlimited) catch return false;
    for (content) |*c| {
        if (c.* >= 'A' and c.* <= 'Z') {
            c.* |= 0x20;
        }
    }
    return std.mem.indexOf(u8, content, "microsoft") != null;
}

/// Returns the global Io instance, initializing it on first call with the
/// process environment block for child process spawns.
pub fn get() std.Io {
    if (_threaded) |*t| return t.io();
    const env_block: std.process.Environ.Block = blk: {
        var count: usize = 0;
        while (std.c.environ[count] != null) count += 1;
        break :blk .{ .slice = std.c.environ[0..count :null] };
    };
    _threaded = std.Io.Threaded.init(std.heap.smp_allocator, .{
        .environ = .{ .block = env_block },
    });
    return _threaded.?.io();
}

/// Cleans up the global Io instance. Safe to call multiple times.
pub fn deinit() void {
    if (_threaded) |*t| {
        t.deinit();
        _threaded = null;
    }
}

/// Read plain text from the system clipboard.
/// Caller owns the returned memory (freed with `std.heap.smp_allocator`).
pub fn read() ![]const u8 {
    switch (builtin.os.tag) {
        .windows => return try win.read(),
        .macos => return try macos.read(),
        .linux, .freebsd, .openbsd, .netbsd, .dragonfly => {
            if (isWSL()) return try wsl.read();
            return try unix.read();
        },
        else => @compileError("platform not currently supported"),
    }
}

/// Write plain text to the system clipboard.
pub fn write(text: []const u8) !void {
    switch (builtin.os.tag) {
        .windows => try win.write(text),
        .macos => try macos.write(text),
        .linux, .freebsd, .openbsd, .netbsd, .dragonfly => {
            if (isWSL()) {
                try wsl.write(text);
            } else {
                try unix.write(text);
            }
        },
        else => @compileError("platform not currently supported"),
    }
}

test "utf8 copy/paste" {
    const text = "zig zag ⚡";
    try write(text);
    const r = try read();
    try testing.expect(std.mem.eql(u8, r, text));
}

test "write copy/paste larger" {
    const text = "ジグザグ ⚡" ** 1180;
    try write(text);
    const r = try read();
    try testing.expect(std.mem.eql(u8, r, text));
}
