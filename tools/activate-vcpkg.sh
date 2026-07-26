#!/usr/bin/env sh

if [ -z "${VCPKG_ROOT:-}" ]; then
    echo "VCPKG_ROOT must point to a vcpkg checkout." >&2
    return 1 2>/dev/null || exit 1
fi

vcpkg_toolchain="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
if [ ! -f "$vcpkg_toolchain" ]; then
    echo "vcpkg toolchain not found: $vcpkg_toolchain" >&2
    return 1 2>/dev/null || exit 1
fi

adapter_toolchain="$(pwd)/cmake/toolchains/vcpkg.cmake"
if [ ! -f "$adapter_toolchain" ]; then
    echo "Run this activation helper from the repository root." >&2
    unset adapter_toolchain vcpkg_toolchain
    return 1 2>/dev/null || exit 1
fi

export CMAKE_TOOLCHAIN_FILE="$adapter_toolchain"
unset adapter_toolchain vcpkg_toolchain
echo "Activated vcpkg for CMake in this shell."
