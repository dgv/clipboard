# clipboard
clipboard for zig

### usage

```zig
const clipboard = @import("clipboard");
const std = @import("std");

pub fn main() !void {
    try clipboard.write("=)");
    text = clipboard.read() catch "";
    std.debug.print("{s}\n", text);
}
```
