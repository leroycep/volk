const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const use_wayland = b.option(bool, "wayland", "Enable the wayland platform") orelse (target.result.os.tag == .linux);
    const use_win32 = b.option(bool, "win32", "Enable the win32 platform") orelse (target.result.os.tag == .windows);

    const vulkan_headers = b.dependency("Vulkan-Headers", .{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "volk",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .target = target,
        .optimize = optimize,
    });
    lib.addCSourceFile(.{ .file = .{ .path = "volk.c" } });
    lib.installHeader("volk.h", "volk.h");
    lib.root_module.linkLibrary(vulkan_headers.artifact("vulkan-headers"));
    lib.installLibraryHeaders(vulkan_headers.artifact("vulkan-headers"));
    lib.linkLibC();
    if (use_wayland) lib.root_module.addCMacro("VK_USE_PLATFORM_WAYLAND_KHR", "1");
    if (use_win32) lib.root_module.addCMacro("VK_USE_PLATFORM_WIN32_KHR", "1");

    b.installArtifact(lib);

    // Excutables to that volkInitialize works
    const test_static_link = b.addExecutable(.{
        .name = "test_static_link",
        .target = target,
        .optimize = optimize,
    });
    if (use_wayland) test_static_link.root_module.addCMacro("VK_USE_PLATFORM_WAYLAND_KHR", "1");
    if (use_win32) test_static_link.root_module.addCMacro("VK_USE_PLATFORM_WIN32_KHR", "1");
    test_static_link.addCSourceFile(.{ .file = .{ .path = "./test/cmake_using_subdir_static/main.c" } });
    test_static_link.linkLibrary(lib);

    const run_test_static_link = b.addRunArtifact(test_static_link);

    const test_step = b.step("test", "Run test executable");
    test_step.dependOn(&run_test_static_link.step);
}
