set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

# Advance the vcpkg registry baselines to their latest commits.
bump:
    vcpkg x-update-baseline
