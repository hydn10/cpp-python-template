set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

# Advance fuzzy selectors and refresh one platform's lock data.
# Run this on the target OS. A complete refresh requires running it on all platforms.
bump platform:
    mise lock --bump --platform {{ platform }}
