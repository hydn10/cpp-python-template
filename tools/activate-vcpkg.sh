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

export CMAKE_TOOLCHAIN_FILE="$vcpkg_toolchain"
unset vcpkg_toolchain
echo "Activated vcpkg for CMake in this shell."
