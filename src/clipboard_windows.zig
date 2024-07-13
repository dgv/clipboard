const std = @import("std");
const windows = std.os.windows;
const cf_unicode_text: windows.UINT = 13;
const gmem_moveable: windows.UINT = 0x0002;

pub extern "user32" fn OpenClipboard(hwnd: ?windows.HWND) callconv(windows.WINAPI) windows.BOOL;
pub extern "user32" fn CloseClipboard() callconv(windows.WINAPI) windows.BOOL;
pub extern "user32" fn EmptyClipboard() callconv(windows.WINAPI) windows.BOOL;
pub extern "user32" fn IsClipboardFormatAvailable(format: windows.UINT) callconv(windows.WINAPI) windows.BOOL;
pub extern "user32" fn GetClipboardData(format: windows.UINT) callconv(windows.WINAPI) ?windows.HANDLE;
pub extern "user32" fn SetClipboardData(format: windows.UINT, handle: windows.HANDLE) callconv(windows.WINAPI) ?windows.HANDLE;
pub extern "kernel32" fn GlobalLock(handle: windows.HANDLE) callconv(windows.WINAPI) ?*anyopaque;
pub extern "kernel32" fn GlobalUnlock(handle: windows.HANDLE) callconv(windows.WINAPI) windows.BOOL;
pub extern "kernel32" fn GlobalAlloc(flags: windows.UINT, size: windows.SIZE_T) callconv(windows.WINAPI) ?*anyopaque;
pub extern "kernel32" fn GlobalFree(handle: windows.HANDLE) callconv(windows.WINAPI) windows.BOOL;
pub extern "kernel32" fn lstrcpyW(str1: windows.LPWSTR, str2: windows.LPCWSTR) callconv(windows.WINAPI) ?*anyopaque;

fn open_clipboard() !void {
    if (IsClipboardFormatAvailable(cf_unicode_text) == 0) {
        return error.UnicodeFormatUnavailable;
    }

    const success = OpenClipboard(null);
    if (success == 0) {
        return error.OpenClipboard;
    }
}

pub fn read() ![]u8 {
    try open_clipboard();
    defer _ = CloseClipboard();

    const h_data = GetClipboardData(cf_unicode_text) orelse return error.GetClipboardData;
    const raw_data = GlobalLock(h_data) orelse return error.GlobalLock;
    defer _ = GlobalUnlock(h_data);

    const w_data: [*c]const u16 = @alignCast(@ptrCast(raw_data));
    const data = std.mem.span(w_data);

    const text = try std.unicode.utf16leToUtf8Alloc(std.heap.page_allocator, data);
    return std.mem.replaceOwned(u8, std.heap.page_allocator, text, "\r", "") catch "";
}

pub fn write(text: []const u8) !void {
    try open_clipboard();
    defer _ = CloseClipboard();

    const success = EmptyClipboard();
    if (success == 0) {
        return error.EmptyClipboard;
    }
    const text_utf16 = try std.unicode.utf8ToUtf16LeAllocZ(std.heap.page_allocator, text);
    const h_data = GlobalAlloc(gmem_moveable, text_utf16.len) orelse return error.GlobalAlloc;
    const raw_data = GlobalLock(h_data) orelse return error.GlobalLock;
    defer _ = GlobalUnlock(h_data);
    const w_data: [*:0]u16 = @alignCast(@ptrCast(raw_data));
    const s_data = std.mem.span(w_data);

    _ = lstrcpyW(s_data, text_utf16) orelse return error.lstrcpyW;
    _ = SetClipboardData(cf_unicode_text, h_data) orelse return error.SetClipboardData;
}
