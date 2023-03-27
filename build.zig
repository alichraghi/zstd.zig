const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    // library

    const lib = b.addStaticLibrary(.{
        .name = "zstd",
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath("vendor/include");
    const config_header = b.addConfigHeader(
        .{
            .style = .{ .autoconf = .{ .path = "config.h.in" } },
        },
        .{
            .ZSTD_MULTITHREAD_SUPPORT_DEFAULT = null,
            .ZSTD_LEGACY_SUPPORT = null,
        },
    );
    lib.addConfigHeader(config_header);
    lib.addCSourceFiles(&.{
        "vendor/lib/common/debug.c",
        "vendor/lib/common/entropy_common.c",
        "vendor/lib/common/error_private.c",
        "vendor/lib/common/fse_decompress.c",
        "vendor/lib/common/pool.c",
        "vendor/lib/common/threading.c",
        "vendor/lib/common/xxhash.c",
        "vendor/lib/common/zstd_common.c",

        "vendor/lib/compress/zstd_double_fast.c",
        "vendor/lib/compress/zstd_compress_literals.c",
        "vendor/lib/compress/zstdmt_compress.c",
        "vendor/lib/compress/zstd_opt.c",
        "vendor/lib/compress/zstd_compress_sequences.c",
        "vendor/lib/compress/zstd_lazy.c",
        "vendor/lib/compress/hist.c",
        "vendor/lib/compress/zstd_ldm.c",
        "vendor/lib/compress/huf_compress.c",
        "vendor/lib/compress/zstd_compress_superblock.c",
        "vendor/lib/compress/zstd_compress.c",
        "vendor/lib/compress/fse_compress.c",
        "vendor/lib/compress/zstd_fast.c",

        "vendor/lib/decompress/zstd_decompress.c",
        "vendor/lib/decompress/zstd_ddict.c",
        "vendor/lib/decompress/zstd_decompress_block.c",
        "vendor/lib/decompress/huf_decompress.c",
    }, &.{});
    lib.addAssemblyFile("vendor/lib/decompress/huf_decompress_amd64.S");
    lib.linkLibC();
    lib.install();

    // tests

    const main_tests = b.addTest(.{
        .name = "zstd-tests",
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/main.zig" },
    });

    main_tests.linkLibrary(lib);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.run().step);
}
