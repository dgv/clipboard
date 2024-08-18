const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = b.addModule("clipboard", .{
        .root_source_file = b.path("src/clipboard.zig"),
    });
    const lib = b.addStaticLibrary(.{
        .name = "clipboard",
        .root_source_file = b.path("src/clipboard.zig"),
        .target = target,
        .optimize = optimize,
    });
    const docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "../docs",
    });
    b.getInstallStep().dependOn(&docs.step);
    b.installArtifact(lib);
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/clipboard.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(lib_unit_tests).step);
}
