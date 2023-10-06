const std = @import("std");
const network = @import("network");
//const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gp_allocator = gpa.allocator();

    const args = try std.process.argsAlloc(gp_allocator);
    defer std.process.argsFree(gp_allocator, args);

    if (args.len != 3) {  // args.len includes the program name and URL, PORT, image_path
        std.debug.print("Invalid arguments.", .{});
        std.os.exit(1);
    }

    const port = try std.fmt.parseInt(u16, args[2], 10);

    const width:u32 = 800;
    const height:u32 = 600;
    // var x = 0;
    // var y = 0;
    var color:u32 = 0;
    var i:u16 = 0;

    // const file = try myOpenFile(args[3]);
    // defer file.close();

    // var stream_source = std.io.StreamSource{ .file = file };

    // var img_buf



    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    try network.init();
    defer network.deinit();

    const sock = try network.connectToHost(std.heap.page_allocator, args[1], port, .tcp);
    defer sock.close();

    const writer = sock.writer();
    var msg_bw = std.io.bufferedWriter(writer);




    while (true) {
        // Sending pixels
        // for (image.iterator(), 0..) |current_color, i| {
        //     std.debug.print("{d}", .{current_color.toU32Rgba()});
        //     i += 1;
        // }
        i = i % 16 + 4;

        for (0..width) |x| {
            for (0..height) |y| {
                const tx: u32 =@truncate(x);
                const ty: u32 = @truncate(y);
                color = ((tx / 1) * i + (ty / 1) * i) & 0xffffff;
                _ = arena.reset(std.heap.ArenaAllocator.ResetMode.retain_capacity);
                const arena_allocator = arena.allocator();
                const msg = try std.fmt.allocPrint(arena_allocator, "PX {d} {d} {x:0>6}\n", .{x, y, color});
                //std.debug.print("{s}", .{msg});
                try msg_bw.writer().writeAll(msg);
            }
        }
        i += 4;
    }

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Finished.\n", .{});

    try bw.flush(); // don't forget to flush!
}

pub fn myOpenFile(file_path: []const u8) !std.fs.File {
    return std.fs.cwd().openFile(file_path, .{}) catch |err|
        if (err == error.FileNotFound) return error.SkipZigTest else return err;
}
