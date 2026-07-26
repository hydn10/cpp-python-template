if (-not $env:VCPKG_ROOT) {
    throw "VCPKG_ROOT must point to a vcpkg checkout."
}

$vcpkgToolchain = Join-Path $env:VCPKG_ROOT "scripts/buildsystems/vcpkg.cmake"
if (-not (Test-Path -LiteralPath $vcpkgToolchain -PathType Leaf)) {
    throw "vcpkg toolchain not found: $vcpkgToolchain"
}

$adapterToolchain = Join-Path $PSScriptRoot "../cmake/toolchains/vcpkg.cmake"
if (-not (Test-Path -LiteralPath $adapterToolchain -PathType Leaf)) {
    throw "mylib vcpkg adapter not found: $adapterToolchain"
}

$env:CMAKE_TOOLCHAIN_FILE = (Resolve-Path -LiteralPath $adapterToolchain).Path
Remove-Variable adapterToolchain, vcpkgToolchain
Write-Host "Activated vcpkg for CMake in this shell."
