# clipboard
clipboard for zig

### usage

```zig
const clipboard = @import("clipboard");
const std = @import("std");

pub fn main() !void {
    _ = try clipboard.write("=)");
    from_paste = clipboard.read() catch "";
    std.debug.print("{s}\n", from_paste);
}
```
