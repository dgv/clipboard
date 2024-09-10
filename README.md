# clipboard
[![reference Zig](https://img.shields.io/badge/zig%20-0.13.0-orange)](https://github.com/dgv/clipboard/blob/main/build.zig.zon)
[![reference Zig](https://img.shields.io/badge/zigdoc%20-pages-orange)](https://dgv.dev.br/clipboard/)
[![reference Zig](https://img.shields.io/badge/deps%20-0-green)](https://github.com/dgv/clipboard/blob/main/build.zig.zon)
[![0 dependencies!](https://0dependencies.dev/0dependencies.svg)](https://0dependencies.dev)
[![build](https://github.com/dgv/clipboard/actions/workflows/build.yml/badge.svg)](https://github.com/dgv/clipboard/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Provide copying and pasting text (UTF-8) to the clipboard for Zig.

### platform support
- MacOS
- Linux, Unix (requires 'xclip' or 'xsel' command to be installed)
- Windows

### usage
#### install
```
zig fetch --save https://github.com/dgv/clipboard/archive/refs/heads/main.zip
```
#### import (build.zig)
```zig
...
exe.root_module.addImport("clipboard", b.dependency("clipboard", .{}).module("clipboard"));
b.installArtifact(exe);
```

#### sample
```zig
const clipboard = @import("clipboard");
const std = @import("std");

pub fn main() !void {
    try clipboard.write("Zig ⚡");
    std.debug.print("{s}\n", .{clipboard.read() catch ""});
}
```
