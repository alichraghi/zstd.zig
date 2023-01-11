const std = @import("std");

const vendor_dir = thisDir() ++ "/vendor";

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    link(b, main_tests, .{});

    const main_tests_exe = b.addTestExe("test-exe", "src/main.zig");
    main_tests_exe.setBuildMode(mode);
    link(b, main_tests_exe, .{});
    main_tests_exe.install();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const test_exe_step = b.step("test-exe", "Run library tests");
    test_exe_step.dependOn(b.getInstallStep());
}

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) void {
    step.linkLibrary(buildZSTD(b, options));
    step.addIncludePath(vendor_dir ++ "/lib");
}

pub fn buildZSTD(b: *std.build.Builder, options: Options) *std.build.LibExeObjStep {
    const zstd = b.addStaticLibrary("zstd", null);
    zstd.linkLibC();

    if (options.multi_threading)
        zstd.defineCMacro("ZSTD_MULTITHREAD_SUPPORT_DEFAULT", "1");
    zstd.defineCMacro("ZSTD_LEGACY_SUPPORT", "0");

    zstd.addCSourceFiles(&.{
        vendor_dir ++ "/lib/common/debug.c",
        vendor_dir ++ "/lib/common/entropy_common.c",
        vendor_dir ++ "/lib/common/error_private.c",
        vendor_dir ++ "/lib/common/fse_decompress.c",
        vendor_dir ++ "/lib/common/pool.c",
        vendor_dir ++ "/lib/common/threading.c",
        vendor_dir ++ "/lib/common/xxhash.c",
        vendor_dir ++ "/lib/common/zstd_common.c",

        vendor_dir ++ "/lib/compress/zstd_double_fast.c",
        vendor_dir ++ "/lib/compress/zstd_compress_literals.c",
        vendor_dir ++ "/lib/compress/zstdmt_compress.c",
        vendor_dir ++ "/lib/compress/zstd_opt.c",
        vendor_dir ++ "/lib/compress/zstd_compress_sequences.c",
        vendor_dir ++ "/lib/compress/zstd_lazy.c",
        vendor_dir ++ "/lib/compress/hist.c",
        vendor_dir ++ "/lib/compress/zstd_ldm.c",
        vendor_dir ++ "/lib/compress/huf_compress.c",
        vendor_dir ++ "/lib/compress/zstd_compress_superblock.c",
        vendor_dir ++ "/lib/compress/zstd_compress.c",
        vendor_dir ++ "/lib/compress/fse_compress.c",
        vendor_dir ++ "/lib/compress/zstd_fast.c",

        vendor_dir ++ "/lib/decompress/zstd_decompress.c",
        vendor_dir ++ "/lib/decompress/zstd_ddict.c",
        vendor_dir ++ "/lib/decompress/zstd_decompress_block.c",
        vendor_dir ++ "/lib/decompress/huf_decompress.c",
    }, &.{});
    zstd.addAssemblyFile(vendor_dir ++ "/lib/decompress/huf_decompress_amd64.S");
    zstd.install();
    return zstd;
}

pub const Options = struct {
    multi_threading: bool = false,
};

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
