const std = @import("std");
const c = @import("c.zig");
const Error = @import("error.zig").Error;
const checkError = @import("error.zig").checkError;
const testing = std.testing;

/// `src.len` must be the _exact_ size of some number of compressed and/or skippable frames.
/// `dest.len` is an upper bound of originalSize to regenerate.
/// If user cannot imply a maximum upper bound, it's better to use streaming mode to decompress data.
/// Returns an slice of written data, which points to `dest`
pub fn decompress(dest: []u8, src: []const u8) Error![]const u8 {
    return dest[0..try checkError(c.ZSTD_decompress(
        @ptrCast(*anyopaque, dest),
        dest.len,
        @ptrCast(*const anyopaque, src),
        src.len,
    ))];
}
