/// Windows clipboard via Win32 API (user32 / kernel32).

const std = @import("std");
const windows = std.os.windows;
const cf_unicode_text: windows.UINT = 13;
const gmem_moveable: windows.UINT = 0x0002;

pub extern "user32" fn OpenClipboard(hwnd: ?windows.HWND) callconv(.winapi) windows.BOOL;
pub extern "user32" fn CloseClipboard() callconv(.winapi) windows.BOOL;
pub extern "user32" fn EmptyClipboard() callconv(.winapi) windows.BOOL;
pub extern "user32" fn IsClipboardFormatAvailable(format: windows.UINT) callconv(.winapi) windows.BOOL;
pub extern "user32" fn GetClipboardData(format: windows.UINT) callconv(.winapi) ?windows.HANDLE;
pub extern "user32" fn SetClipboardData(format: windows.UINT, handle: windows.HANDLE) callconv(.winapi) ?windows.HANDLE;
pub extern "kernel32" fn GlobalLock(handle: windows.HANDLE) callconv(.winapi) ?*anyopaque;
pub extern "kernel32" fn GlobalUnlock(handle: windows.HANDLE) callconv(.winapi) windows.BOOL;
pub extern "kernel32" fn GlobalAlloc(flags: windows.UINT, size: windows.SIZE_T) callconv(.winapi) ?*anyopaque;
pub extern "kernel32" fn GlobalFree(handle: windows.HANDLE) callconv(.winapi) windows.BOOL;
pub extern "kernel32" fn RtlMoveMemory(out: *anyopaque, in: *anyopaque, size: windows.SIZE_T) callconv(.winapi) void;

/// Spin until clipboard is available (no timeout — TODO).
fn open_clipboard() void {
    while (true) {
        const success = OpenClipboard(null);
        if (success == 0) continue else break;
    }
}

/// Read plain text from the Windows clipboard.
/// Intermediate UTF-16→UTF-8 conversion uses an arena; the final
/// string (with `\r` stripped) uses `std.heap.smp_allocator`.
pub fn read() ![]u8 {
    if (IsClipboardFormatAvailable(cf_unicode_text) == 0) {
        return error.UnicodeFormatUnavailable;
    }
    open_clipboard();
    defer _ = CloseClipboard();

    const h_data = GetClipboardData(cf_unicode_text) orelse return error.GetClipboardData;
    const raw_data = GlobalLock(h_data) orelse return error.GlobalLock;
    defer _ = GlobalUnlock(h_data);

    const w_data: [*c]const u16 = @alignCast(@ptrCast(raw_data));
    const data = std.mem.span(w_data);

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const aalloc = arena.allocator();

    const text = try std.unicode.utf16LeToUtf8Alloc(aalloc, data);
    return std.mem.replaceOwned(u8, std.heap.smp_allocator, text, "\r", "") catch "";
}

/// Write plain text to the Windows clipboard.
/// The UTF-16 conversion buffer uses an arena.
pub fn write(text: []const u8) !void {
    if (text.len == 0) return;
    open_clipboard();
    defer _ = CloseClipboard();

    const success = EmptyClipboard();
    if (success == 0) {
        return error.EmptyClipboard;
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const aalloc = arena.allocator();

    const text_utf16 = try std.unicode.utf8ToUtf16LeAllocZ(aalloc, text);
    const h_data = GlobalAlloc(gmem_moveable, @sizeOf(@TypeOf(text_utf16[0])) * text_utf16.len + gmem_moveable) orelse return error.GlobalAlloc;
    const raw_data = GlobalLock(h_data) orelse return error.GlobalLock;
    defer _ = GlobalUnlock(h_data);
    const w_data: [*:0]u16 = @alignCast(@ptrCast(raw_data));
    const s_data = std.mem.span(w_data);

    RtlMoveMemory(s_data.ptr, text_utf16.ptr, @sizeOf(@TypeOf(text_utf16[0])) * text_utf16.len + gmem_moveable);
    _ = SetClipboardData(cf_unicode_text, h_data) orelse return error.SetClipboardData;
}
