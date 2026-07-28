#!/usr/bin/env bash

set -euo pipefail

dry_run=false
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-d" ]]; then
    dry_run=true
    shift
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [-d|--dry-run] REPOSITORY_ROOT" >&2
    exit 2
fi

repository_root="$(cd -- "$1" && pwd -P)"
script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ ! -f "$repository_root/CMakeLists.txt" || ! -f "$repository_root/justfile" ]]; then
    echo "Not a repository root: $repository_root" >&2
    exit 2
fi

while IFS= read -r name || [[ -n "$name" ]]; do
    name="${name%$'\r'}"
    [[ -z "$name" || "$name" == \#* ]] && continue
    if [[ "$name" == "." || "$name" == ".." || "$name" == */* || "$name" == *\\* ]]; then
        echo "Invalid root name: $name" >&2
        exit 2
    fi

    path="$repository_root/$name"
    if [[ -e "$path" || -L "$path" ]]; then
        if "$dry_run"; then
            printf 'Would remove: %s\n' "$name"
        else
            printf 'Removing: %s\n' "$name"
            rm -rf -- "$path"
        fi
    fi
done < "$script_directory/root-paths.txt"

cd -- "$repository_root"
while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    pattern="${pattern%$'\r'}"
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    if [[ "$pattern" == "." || "$pattern" == ".." || "$pattern" == */* || "$pattern" == *\\* ]]; then
        echo "Invalid recursive pattern: $pattern" >&2
        exit 2
    fi
    find . \
        -path "./.git" -prune -o \
        -name "$pattern" -prune -print0 |
        while IFS= read -r -d '' path; do
            relative_path="${path#./}"
            if "$dry_run"; then
                printf 'Would remove: %s\n' "$relative_path"
            else
                printf 'Removing: %s\n' "$relative_path"
                rm -rf -- "$path"
            fi
        done
done < "$script_directory/recursive-patterns.txt"
