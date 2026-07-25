if (-not $env:VCPKG_ROOT) {
    throw "VCPKG_ROOT must point to a vcpkg checkout."
}

$vcpkgToolchain = Join-Path $env:VCPKG_ROOT "scripts/buildsystems/vcpkg.cmake"
if (-not (Test-Path -LiteralPath $vcpkgToolchain -PathType Leaf)) {
    throw "vcpkg toolchain not found: $vcpkgToolchain"
}

$env:CMAKE_TOOLCHAIN_FILE = (Resolve-Path -LiteralPath $vcpkgToolchain).Path
Remove-Variable vcpkgToolchain
Write-Host "Activated vcpkg for CMake in this shell."
