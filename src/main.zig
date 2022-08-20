pub usingnamespace @import("compress.zig");
pub usingnamespace @import("decompress.zig");
pub usingnamespace @import("types.zig");
pub usingnamespace @import("error.zig");

const std = @import("std");
const c = @import("c.zig");
const comp = @import("compress.zig");
const types = @import("types.zig");
const decomp = @import("decompress.zig");
const testing = std.testing;

pub const frame_header_size_max = c.ZSTD_FRAMEHEADERSIZE_MAX;
pub const skippable_header_size = c.ZSTD_SKIPPABLEHEADERSIZE;
pub const window_log_max_32 = c.ZSTD_WINDOWLOG_MAX_32;
pub const window_log_max_64 = c.ZSTD_WINDOWLOG_MAX_64;
pub const window_log_max = c.ZSTD_WINDOWLOG_MAX;
pub const window_log_min = c.ZSTD_WINDOWLOG_MIN;
pub const hash_log_max = c.ZSTD_HASHLOG_MAX;
pub const hash_log_min = c.ZSTD_HASHLOG_MIN;
pub const chain_log_max_32 = c.ZSTD_CHAINLOG_MAX_32;
pub const chain_log_max_64 = c.ZSTD_CHAINLOG_MAX_64;
pub const chain_log_max = c.ZSTD_CHAINLOG_MAX;
pub const chain_log_min = c.ZSTD_CHAINLOG_MIN;
pub const search_log_max = c.ZSTD_SEARCHLOG_MAX;
pub const search_log_min = c.ZSTD_SEARCHLOG_MIN;
pub const min_match_max = c.ZSTD_MINMATCH_MAX;
pub const min_match_min = c.ZSTD_MINMATCH_MIN;
pub const target_length_max = c.ZSTD_TARGETLENGTH_MAX;
pub const target_length_min = c.ZSTD_TARGETLENGTH_MIN;
pub const strategy_min = c.ZSTD_STRATEGY_MIN;
pub const strategy_max = c.ZSTD_STRATEGY_MAX;
pub const overlap_log_min = c.ZSTD_OVERLAPLOG_MIN;
pub const overlap_log_max = c.ZSTD_OVERLAPLOG_MAX;
pub const window_log_limit_default = c.ZSTD_WINDOWLOG_LIMIT_DEFAULT;
pub const ldm_hash_log_min = c.ZSTD_LDM_HASHLOG_MIN;
pub const ldm_hash_log_max = c.ZSTD_LDM_HASHLOG_MAX;
pub const ldm_min_match_min = c.ZSTD_LDM_MINMATCH_MIN;
pub const ldm_min_match_max = c.ZSTD_LDM_MINMATCH_MAX;
pub const ldm_bucket_size_log_min = c.ZSTD_LDM_BUCKETSIZELOG_MIN;
pub const ldm_bucket_size_log_max = c.ZSTD_LDM_BUCKETSIZELOG_MAX;
pub const ldm_hash_rate_log_min = c.ZSTD_LDM_HASHRATELOG_MIN;
pub const ldm_hash_rate_log_max = c.ZSTD_LDM_HASHRATELOG_MAX;
pub const target_cblock_size_min = c.ZSTD_TARGETCBLOCKSIZE_MIN;
pub const target_cblock_size_max = c.ZSTD_TARGETCBLOCKSIZE_MAX;
pub const src_size_hint_min = c.ZSTD_SRCSIZEHINT_MIN;
pub const src_size_hint_max = c.ZSTD_SRCSIZEHINT_MAX;

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

test "streaming compress" {
    const in_data = [_]u8{ 'h', 'e', 'l', 'l', 'o' } ** 200_000;
    var in_fbs = std.io.fixedBufferStream(&in_data);

    var out_data: [in_data.len]u8 = undefined;
    var out_fbs = std.io.fixedBufferStream(&out_data);

    var in_buf = try testing.allocator.alloc(u8, comp.Compressor.recommInSize());
    var out_buf = try testing.allocator.alloc(u8, comp.Compressor.recommOutSize());
    defer testing.allocator.free(in_buf);
    defer testing.allocator.free(out_buf);

    const ctx = try comp.Compressor.init(.{
        .compression_level = 1,
        .checksum_flag = 1,
    });

    while (true) {
        const read = try in_fbs.read(in_buf);
        const is_last_chunk = (read < in_buf.len);

        var input = types.InBuffer{
            .src = in_buf.ptr,
            .size = read,
            .pos = 0,
        };

        while (true) {
            var output = types.OutBuffer{
                .dst = out_buf.ptr,
                .size = out_buf.len,
                .pos = 0,
            };
            const remaining = try ctx.compressStream(&input, &output, if (is_last_chunk) .end else .continue_);
            _ = try out_fbs.write(out_buf[0..output.pos]);

            if ((is_last_chunk and remaining == 0) or input.pos == read)
                break;
        }

        if (is_last_chunk)
            break;
    }

    var decomp_out: [in_data.len]u8 = undefined;
    const decompressed = try decomp.decompress(&decomp_out, out_fbs.getWritten());
    try std.testing.expectEqualStrings(&in_data, decompressed);
}
