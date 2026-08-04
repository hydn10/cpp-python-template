set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

mod format 'check/format.just'
mod lint 'check/lint.just'

# Run every read-only formatting and lint check.
[default]
all: format::all lint::all
