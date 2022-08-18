pub usingnamespace @import("compress.zig");
pub usingnamespace @import("error.zig");

const std = @import("std");
const c = @import("c.zig");
const comp = @import("compress.zig");
const decomp = @import("decompress.zig");
const testing = std.testing;

pub const frame_header_size_max = c.ZSTD_FRAMEHEADERSIZE_MAX;
pub const skippable_header_size = c.ZSTD_SKIPPABLEHEADERSIZE;

pub fn version() std.SemanticVersion {
    return .{
        .major = 1,
        .minor = 5,
        .patch = 2,
    };
}

test "refernece decls" {
    testing.refAllDeclsRecursive(comp);
}

test "version" {
    try testing.expectEqual(std.SemanticVersion{
        .major = c.ZSTD_VERSION_MAJOR,
        .minor = c.ZSTD_VERSION_MINOR,
        .patch = c.ZSTD_VERSION_RELEASE,
    }, version());
}

const hello = "hello";

test "compress/decompress" {
    var comp_out: [20]u8 = undefined;
    var decomp_out: [20]u8 = undefined;

    const compressed = try comp.compress(&comp_out, hello, comp.minCompressionLevel());
    const decompressed = try decomp.decompress(&decomp_out, compressed);
    try testing.expectEqualStrings(hello, decompressed);
}

test "compress with context" {
    var out: [20]u8 = undefined;

    const compressor = try comp.Compressor.init(.{});
    defer compressor.deinit();

    _ = try compressor.compress(&out, hello, comp.minCompressionLevel());
}
