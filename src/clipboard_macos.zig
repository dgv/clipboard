/// macOS clipboard via pbpaste/pbcopy.

const std = @import("std");
const io_helper = @import("clipboard.zig");

const read_cmd = "pbpaste";
const write_cmd = "pbcopy";

/// Read plain text from the system clipboard.
/// Caller owns the returned memory (freed with `std.heap.smp_allocator`).
pub fn read() ![]u8 {
    const io = io_helper.get();
    const result = try std.process.run(std.heap.smp_allocator, io, .{
        .argv = &[_][]const u8{read_cmd},
    });
    return result.stdout;
}

/// Write plain text to the system clipboard.
pub fn write(text: []const u8) !void {
    const io = io_helper.get();

    var child = try std.process.spawn(io, .{
        .argv = &[_][]const u8{write_cmd},
        .stdin = .pipe,
        .stdout = .ignore,
        .stderr = .ignore,
    });
    defer child.kill(io);

    try std.Io.File.writeStreamingAll(child.stdin.?, io, text);
    child.stdin.?.close(io);
    child.stdin = null;

    const term = try child.wait(io);
    if (term != .exited or term.exited != 0) unreachable;
}
