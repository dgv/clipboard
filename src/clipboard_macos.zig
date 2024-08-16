const std = @import("std");

const read_cmd = "pbpaste";
const write_cmd = "pbcopy";

pub fn read() ![]u8 {
    const result = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            read_cmd,
        },
    });
    return result.stdout;
}

pub fn write(text: []const u8) !void {
    var proc = std.process.Child.init(
        &[_][]const u8{write_cmd},
        std.heap.page_allocator,
    );
    proc.stdin_behavior = .Pipe;
    proc.stdout_behavior = .Ignore;
    proc.stderr_behavior = .Ignore;

    try proc.spawn();
    try proc.stdin.?.writeAll(text);
    proc.stdin.?.close();
    proc.stdin = null;
    const term = proc.wait() catch unreachable;
    if (term != .Exited or term.Exited != 0) unreachable;
}
