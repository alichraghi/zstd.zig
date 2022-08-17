const std = @import("std");
const c = @import("c.zig");
const Error = @import("error.zig").Error;
const checkError = @import("error.zig").checkError;
const testing = std.testing;

// TODO: https://github.com/ziglang/zig/issues/12465
pub const ZSTD_CONTENTSIZE_UNKNOWN = @as(c_ulonglong, 0) -% @as(c_int, 1);
pub const ZSTD_CONTENTSIZE_ERROR = @as(c_ulonglong, 0) -% @as(c_int, 2);

/// When compressing many times,
/// it is recommended to allocate a context just once,
/// and re-use it for each successive compression operation.
/// This will make workload friendlier for system's memory.
/// NOTE:
/// - re-using context is just a speed / resource optimization.
///   It doesn't change the compression ratio, which remains identical.
/// - In multi-threaded environments,
///   use one different context per thread for parallel execution.
pub const Compressor = struct {
    handle: *c.ZSTD_CCtx,

    pub fn init() Compressor {
        return .{ .handle = c.ZSTD_createCCtx() };
    }

    pub fn deinit(self: Compressor) void {
        _ = c.ZSTD_freeCCtx();
    }
};

/// Compresses `src` content as a single zstd compressed frame into already allocated `dest`.
/// Returns an slice of written data, which points to `dest`
pub fn compress(dest: []u8, src: []const u8, compression_level: i32) Error![]const u8 {
    return dest[0..try checkError(c.ZSTD_compress(
        @ptrCast(*anyopaque, dest),
        dest.len,
        @ptrCast(*const anyopaque, src),
        src.len,
        @intCast(c_int, compression_level),
    ))];
}

/// `src` should point to the start of a ZSTD encoded frame.
/// `src.len` must be at least as large as the frame header.
/// hint: any size >= `frame_header_size_max` is large enough.
///
/// Returns:
/// - decompressed size of `src` frame content, if known
/// - error.Unknown if the size cannot be determined
/// - error.Generic if an error occurred (e.g. invalid magic number, `src.len` too small)
///
/// NOTE:
/// - a 0 return value means the frame is valid but "empty".
/// - decompressed size is an optional field, it may not be present, typically in streaming mode.
///   When `error.Unknown` returned, data to decompress could be any size.
///   In which case, it's necessary to use streaming mode to decompress data.
///   Optionally, application can rely on some implicit limit,
///   as `decompress()` only needs an upper bound of decompressed size.
///   (For example, data could be necessarily cut into blocks <= 16 KB).
/// - decompressed size is always present when compression is completed using single-pass functions,
///   such as `compress()`, `Compressor.compress()`, `compressUsingDict()` or `compressUsingCDict()`.
/// - decompressed size can be very large (64-bits value),
///   potentially larger than what local system can handle as a single memory segment.
///   In which case, it's necessary to use streaming mode to decompress data.
/// - If source is untrusted, decompressed size could be wrong or intentionally modified.
///   Always ensure return value fits within application's authorized limits.
///   Each application can set its own limits.
pub fn getFrameContentSize(src: []const u8) error{ Unknown, Generic }!usize {
    return switch (c.ZSTD_getFrameContentSize(@ptrCast(*const anyopaque, src), src.len)) {
        ZSTD_CONTENTSIZE_UNKNOWN => error.Unknown,
        ZSTD_CONTENTSIZE_ERROR => error.Generic,
        else => |v| v,
    };
}

/// `src` should point to the start of a ZSTD frame or skippable frame.
/// `src.len` must be >= first frame size
///
/// Returns the compressed size of the first frame starting at `src`,
/// suitable to pass as `srcSize` to `ZSTD_decompress` or similar,
/// or an error code if input is invalid
pub fn findFrameCompressedSize(src: []const u8) usize {
    return c.ZSTD_findFrameCompressedSize(@ptrCast(*const anyopaque, src), src.len);
}

pub fn minCompressionLevel() i32 {
    return @intCast(i32, c.ZSTD_minCLevel());
}

pub fn maxCompressionLevel() i32 {
    return @intCast(i32, c.ZSTD_maxCLevel());
}

pub fn defaultCompressionLevel() i32 {
    return @intCast(i32, c.ZSTD_defaultCLevel());
}

/// Returns maximum compressed size in worst case single-pass scenario
pub fn compressBound(src_size: usize) usize {
    return c.ZSTD_compressBound(src_size);
}
