const std = @import("std");

const vendor_dir = thisDir() ++ "/vendor";

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    link(b, main_tests, .{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) void {
    _ = options;
    step.linkLibrary(buildZSTD(b));
    step.addIncludeDir(vendor_dir ++ "/lib");
}

pub fn buildZSTD(b: *std.build.Builder) *std.build.LibExeObjStep {
    const zstd = b.addStaticLibrary("zstd", null);
    zstd.linkLibC();
    zstd.install();
    return zstd;
}

pub const Options = struct {};

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
