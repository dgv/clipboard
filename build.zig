const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("clipboard", .{
        .root_source_file = b.path("src/clipboard.zig"),
        .target = target,
        .optimize = optimize,
    });
    // const lib = b.addStaticLibrary(.{
    //     .name = "clipboard",
    //     .root_source_file = b.path("src/clipboard.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // const docs = b.addInstallDirectory(.{
    //     .source_dir = lib.getEmittedDocs(),
    //     .install_dir = .prefix,
    //     .install_subdir = "../docs",
    // });
    // b.getInstallStep().dependOn(&docs.step);
    // b.installArtifact(lib);
    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_tests.step);
}
