/// WSL (Windows Subsystem for Linux) clipboard via clip.exe / powershell.exe.

const std = @import("std");
const io_helper = @import("clipboard.zig");

/// PowerShell command: get clipboard as UTF-8, return as base64.
const ps_cmd =
    \\[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Clipboard -Raw)))
;

/// Read plain text from the Windows clipboard via PowerShell.
/// Intermediate pipe buffers use an arena; the returned base64-decoded
/// string is allocated with `std.heap.smp_allocator`.
pub fn read() ![]u8 {
    const io = io_helper.get();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const aalloc = arena.allocator();

    const result = try std.process.run(aalloc, io, .{
        .argv = &[_][]const u8{
            "powershell.exe",
            "-noprofile",
            "-command",
            ps_cmd,
        },
    });
    if (result.stderr.len > 0) {
        return error.PowerShellError;
    }
    const trimmed = std.mem.trim(u8, result.stdout, " \n\r\t");
    const decoder = std.base64.standard.Decoder;
    const decoded_size = try decoder.calcSizeForSlice(trimmed);
    const decoded = try std.heap.smp_allocator.alloc(u8, decoded_size);
    try decoder.decode(decoded, trimmed);
    return decoded;
}

/// Write plain text to the Windows clipboard via clip.exe.
/// The UTF-16 conversion buffer uses an arena.
pub fn write(text: []const u8) !void {
    const io = io_helper.get();

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const aalloc = arena.allocator();

    var child = try std.process.spawn(io, .{
        .argv = &[_][]const u8{"clip.exe"},
        .stdin = .pipe,
        .stdout = .ignore,
        .stderr = .ignore,
    });
    defer child.kill(io);

    const utf16le = try std.unicode.utf8ToUtf16LeAlloc(aalloc, text);
    const bytes = std.mem.sliceAsBytes(utf16le);
    try std.Io.File.writeStreamingAll(child.stdin.?, io, bytes);
    child.stdin.?.close(io);
    child.stdin = null;

    const term = try child.wait(io);
    if (term != .exited or term.exited != 0) unreachable;
}
