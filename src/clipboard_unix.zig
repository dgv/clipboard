/// Linux/BSD clipboard via xclip, xsel, or wl-clipboard.

const std = @import("std");
const io_helper = @import("clipboard.zig");

const xsel: []const u8 = "xsel";
const xclip: []const u8 = "xclip";
const wlpaste: []const u8 = "wl-paste";
const wlcopy: []const u8 = "wl-copy";

const xsel_write = [_][]const u8{ xsel, "--input", "--clipboard" };
const xsel_read = [_][]const u8{ xsel, "--output", "--clipboard" };
const xclip_write = [_][]const u8{ xclip, "-in", "-selection", "clipboard" };
const xclip_read = [_][]const u8{ xclip, "-out", "-selection", "clipboard" };
const wlpaste_read = [_][]const u8{ wlpaste, "--no-newline" };
const wlcopy_write = [_][]const u8{wlcopy};

const op = enum {
    read,
    write,
};

/// Pick the clipboard command based on the desktop environment.
/// Prefers Wayland (wl-clipboard), then X11 (xclip), then fallback (xsel).
fn getCmd(t: op) ![]const []const u8 {
    if (std.c.getenv("WAYLAND_DISPLAY")) |_| {
        return if (t == op.read) &wlpaste_read else &wlcopy_write;
    }
    if (std.c.getenv("DISPLAY")) |_| {
        return if (t == op.read) &xclip_read else &xclip_write;
    }
    return if (t == op.read) &xsel_read else &xsel_write;
}

/// Read plain text from the system clipboard.
/// Caller owns the returned memory (freed with `std.heap.smp_allocator`).
pub fn read() ![]u8 {
    const cmd = try getCmd(.read);
    const io = io_helper.get();
    const result = try std.process.run(std.heap.smp_allocator, io, .{
        .argv = cmd,
    });
    return result.stdout;
}

/// Write plain text to the system clipboard.
pub fn write(text: []const u8) !void {
    const cmd = try getCmd(.write);
    const io = io_helper.get();

    var child = try std.process.spawn(io, .{
        .argv = cmd,
        .stdin = .pipe,
        .stdout = .ignore,
        .stderr = .ignore,
    });
    defer child.kill(io);

    try std.Io.File.writeStreamingAll(child.stdin.?, io, text);
    child.stdin.?.close(io);
    child.stdin = null;

    const term = try child.wait(io);
    if (term != .exited or term.exited != 0) return error.ClipboardCmdFailed;
}
