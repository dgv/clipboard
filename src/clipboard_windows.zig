const std = @import("std");
const windows = std.os.windows;

const cf_unicode_text: windows.UINT = 13;
const gmem_moveable: windows.UINT = 0x0002;

pub extern "user32" fn OpenClipboard(hwnd: ?windows.HWND) callconv(windows.WINAPI) windows.BOOL;
pub extern "user32" fn CloseClipboard() callconv(windows.WINAPI) windows.BOOL;
pub extern "user32" fn IsClipboardFormatAvailable(format: windows.UINT) callconv(windows.WINAPI) windows.BOOL;
pub extern "user32" fn GetClipboardData(format: windows.UINT) callconv(windows.WINAPI) ?windows.HANDLE;
pub extern "user32" fn SetClipboardData(format: windows.UINT) callconv(windows.WINAPI) ?windows.HANDLE;
pub extern "kernel32" fn GlobalLock(handle: windows.HANDLE) callconv(windows.WINAPI) ?*anyopaque;
pub extern "kernel32" fn GlobalUnlock(handle: windows.HANDLE) callconv(windows.WINAPI) windows.BOOL;
// pub extern "kernel32" fn GlobalAlloc(handle: windows.HANDLE) callconv(windows.WINAPI) ?*anyopaque;
// pub extern "kernel32" fn GlobalFree(handle: windows.HANDLE) callconv(windows.WINAPI) windows.BOOL;
// pub extern "kernel32" fn lstrcpyW(handle: windows.HANDLE) callconv(windows.WINAPI) ?*anyopaque;

pub fn read() ![]u8 {
    if (IsClipboardFormatAvailable(cf_unicode_text) == 0) {
        return;
    }

    const success = OpenClipboard(null);
    if (success == 0) {
        return error.OpenClipboard;
    }
    defer _ = CloseClipboard();

    const h_data = GetClipboardData(cf_unicode_text) orelse return error.GetClipboardData;
    const raw_data = GlobalLock(h_data) orelse return error.GlobalLock;
    defer _ = GlobalUnlock(h_data);

    const w_data: [*c]const u16 = @alignCast(@ptrCast(raw_data));
    const data = std.mem.span(w_data);

    const string = try std.unicode.utf16leToUtf8Alloc(std.heap.page_allocator, data);
    return std.mem.replaceOwned(u8, std.heap.page_allocator, string, "\r", "") catch "";
}

fn write(string: []u8) !void {
    _ = string;
}

test "copy/paste on windows" {
    try write("zig zag ⚡");
    try std.testing.expect(std.mem.eql([]u8, read(), "zig zag ⚡"));
}
