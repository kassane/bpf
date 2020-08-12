usingnamespace @import("common.zig");

const std = @import("std");
const perf = @import("perf.zig");
const Link = @import("link.zig");

const c = @cImport({
    @cInclude("perf_event.h");
});

const fd_t = std.os.fd_t;

const Self = @This();

fd: fd_t,
name: []const u8,
type: Type,
insns: []Insn,
loaded: bool,
expected_attach_type: AttachType,

pub const Type = enum(u32) {
    unspec,
    socket_filter,
    kprobe,
    sched_cls,
    sched_act,
    tracepoint,
    xdp,
    perf_event,
    cgroup_skb,
    cgroup_sock,
    lwt_in,
    lwt_out,
    lwt_xmit,
    sock_ops,
    sk_skb,
    cgroup_device,
    sk_msg,
    raw_tracepoint,
    cgroup_sock_addr,
    lwt_seg6local,
    lirc_mode2,
    sk_reuseport,
    flow_dissector,
    cgroup_sysctl,
    raw_tracepoint_writable,
    cgroup_sockopt,
    tracing,
    struct_ops,
    ext,
    lsm,
};

// TODO: name vs title
pub fn load(self: *Self, license: []const u8, kern_version: u32) !void {
    if (self.loaded) {
        return error.AlreadyLoaded;
    }

    // TODO: finish
}

pub fn unload(self: *Self) void {
    for (self.instances) |instance| {
        try std.os.close(instance);
    }

    self.instances.len = 0;
}

pub fn pin_instance(self: *Self, path: []const u8, instance: fd_t) !void {}
pub fn unpin_instance(self: *Self, path: []const u8, instance: fd_t) !void {}

pub fn pin(self: *Self, path: []const u8) !void {}
pub fn unpin(self: *Self, path: []const u8) !void {}

// attach functions
pub fn attach(self: *Self) !*Link {}

fn bpf_link_detach_perf_event(link: *Link) !void {
    try perf.event_disable(link.fd);
    try std.os.close(link.fd);
}

pub fn attach_perf_event(self: *Self, pfd: fd_t) !Link {
    try perf.event_set_bpf(pfd, self.fd);
    try perf.event_enable(pfd);
    return Link{
        .fd = pfd,
        .detach = bpf_link_detach_perf_event,
    };
}

pub fn attach_kprobe(self: *Self, retprobe: bool, func_name: []const u8) !Link {
    // TODO: I don't like how janky this function is, give it more meaning --
    // might as well specialize it for u and k probes
    const pfd = try perf.event_open_probe(false, retprobe, func_name, 0, -1);
    errdefer std.os.close(pfd);

    return self.attach_perf_event(pfd);
}

pub fn attach_uprobe(self: *Self, retprobe: bool, pid: pid_t, binary_path: []const u8, func_offset: usize) !*Link {
    const pfd = try perf.event_open_probe(true, retprobe, binary_path, func_offset, pid);
    errdefer std.os.close(pfd);

    return self.attach_perf_event(pfd);
}

pub fn attach_tracepoint(self: *Self, category: []const u8, name: []const u8) !Link {
    return self.attach_perf_event(try perf.event_open_tracepoint(category, name));
}

pub fn attach_raw_tracepoint(self: *Self, tp_name: []const u8) !*Link {}
pub fn attach_trace(self: *Self) !*Link {}
pub fn attach_lsm(self: *Self) !*Link {}
pub fn attach_cgroup(self: *Self, cgroup: fd_t) !*Link {}
pub fn attach_netns(self: *Self, netns: fd_t) !*Link {}
pub fn attach_xdp(self: *Self, ifindex: isize) !*Link {}
pub fn attach_iter(self: *Self, opts: *IterAttachOps) !*Link {}
// TODO: do we need fd? or is that just an instance?
pub fn set_attach_target(self: *Self, prog: fd_t, attach_func_name: []const u8) !void {}
