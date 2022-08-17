pub usingnamespace @import("compress.zig");
pub usingnamespace @import("error.zig");

const std = @import("std");
const c = @import("c.zig");
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
    testing.refAllDeclsRecursive(@import("compress.zig"));
}

test "version" {
    try testing.expectEqual(std.SemanticVersion{
        .major = c.ZSTD_VERSION_MAJOR,
        .minor = c.ZSTD_VERSION_MINOR,
        .patch = c.ZSTD_VERSION_RELEASE,
    }, version());
}

test "compress/decompress" {
    const hello = "hello";
    var comp_out: [20]u8 = undefined;
    var decomp_out: [20]u8 = undefined;

    const compressed = try @import("compress.zig").compress(&comp_out, hello, minCompressionLevel());
    const decompressed = try @import("decompress.zig").decompress(&decomp_out, compressed);
    try testing.expectEqualStrings(hello, decompressed);
}
