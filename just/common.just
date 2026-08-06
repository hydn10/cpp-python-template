external-toolchain := env_var_or_default("CMAKE_TOOLCHAIN_FILE", "")
vcpkg-root := env_var_or_default("VCPKG_ROOT", "")
provider-prefix := if external-toolchain != "" { "" } else if vcpkg-root != "" { "vcpkg-" } else { "" }

default-quality-preset := provider-prefix + "quality"
default-python-quality-preset := provider-prefix + "python-quality"
default-release-preset := provider-prefix + "release"

vcpkg-adapter := justfile_directory() + "/cmake/toolchains/vcpkg.cmake"

[private]
[unix]
run-uv preset *args:
    {{ if preset =~ "^vcpkg-" { "CMAKE_TOOLCHAIN_FILE='" + vcpkg-adapter + "' " } else { "" } }}uv {{ args }}

[private]
[windows]
run-uv preset *args:
    {{ if preset =~ "^vcpkg-" { "$env:CMAKE_TOOLCHAIN_FILE = '" + vcpkg-adapter + "'; " } else { "" } }}uv {{ args }}
