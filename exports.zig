const builtin = @import("builtin");

pub const bpf_arch = switch (builtin.cpu.arch) {
    .bpfel, .bpfeb => @import("src/kern.zig"),
    else => @import("src/user.zig"),
};

pub const flags = @import("src/flags.zig");
pub const common = @import("src/common.zig");
