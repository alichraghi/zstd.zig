const c = @cImport(@cInclude("zstd.h"));
const std = @import("std");
const testing = std.testing;

pub fn version() std.SemanticVersion {
    return .{
        .major = 1,
        .minor = 5,
        .patch = 2,
    };
}

test "global functions" {
    try testing.expectEqual(std.SemanticVersion{
        .major = c.ZSTD_VERSION_MAJOR,
        .minor = c.ZSTD_VERSION_MINOR,
        .patch = c.ZSTD_VERSION_RELEASE,
    }, version());
}
