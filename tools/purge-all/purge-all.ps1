[CmdletBinding()]
param(
    [Alias("d")]
    [switch] $DryRun,

    [Parameter(Mandatory)]
    [string] $RepositoryRoot
)

$ErrorActionPreference = "Stop"

$repositoryRootPath = (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath
if (
    -not (Test-Path -LiteralPath (Join-Path $repositoryRootPath "CMakeLists.txt") -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $repositoryRootPath "justfile") -PathType Leaf)
) {
    throw "Not a repository root: $repositoryRootPath"
}

function Read-EntryList {
    param([string] $Path)

    foreach ($line in Get-Content -LiteralPath $Path) {
        $entry = $line.Trim()
        if ($entry -and -not $entry.StartsWith("#")) {
            $entry
        }
    }
}

function Assert-ValidName {
    param(
        [string] $Name,
        [string] $Kind
    )

    if ($Name -eq "." -or $Name -eq ".." -or $Name.Contains("/") -or $Name.Contains("\")) {
        throw "Invalid ${Kind}: $Name"
    }
}

$rootNames = @(Read-EntryList (Join-Path $PSScriptRoot "root-paths.txt"))
foreach ($name in $rootNames) {
    Assert-ValidName $name "root name"
    $path = Join-Path $repositoryRootPath $name
    if (Test-Path -LiteralPath $path) {
        if ($DryRun) {
            Write-Output "Would remove: $name"
        } else {
            Write-Output "Removing: $name"
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
}

$recursivePatterns = @(Read-EntryList (Join-Path $PSScriptRoot "recursive-patterns.txt"))
foreach ($pattern in $recursivePatterns) {
    Assert-ValidName $pattern "recursive pattern"
}

$repositoryEntries = @(
    foreach ($entry in Get-ChildItem -LiteralPath $repositoryRootPath -Force) {
        if ($entry.Name -eq ".git") {
            continue
        }

        $entry
        if ($entry.PSIsContainer) {
            Get-ChildItem -LiteralPath $entry.FullName -Force -Recurse
        }
    }
)

$matches = foreach ($entry in $repositoryEntries) {
    foreach ($pattern in $recursivePatterns) {
        if ($entry.Name -clike $pattern) {
            $entry
            break
        }
    }
}

foreach ($entry in ($matches | Sort-Object -Property FullName -Descending)) {
    $relativePath = $entry.FullName.Substring($repositoryRootPath.Length).TrimStart("\", "/")
    if ($DryRun) {
        Write-Output "Would remove: $relativePath"
    } else {
        Write-Output "Removing: $relativePath"
        Remove-Item -LiteralPath $entry.FullName -Recurse -Force
    }
}
