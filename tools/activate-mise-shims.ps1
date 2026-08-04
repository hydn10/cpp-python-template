if (-not (Get-Command mise -CommandType Application -ErrorAction SilentlyContinue)) {
    throw "Mise must be installed and available on PATH."
}

$miseActivation = & mise activate pwsh --shims
if ($LASTEXITCODE -ne 0) {
    throw "Failed to activate Mise shims."
}

$miseActivation | Out-String | Invoke-Expression
Remove-Variable miseActivation
Write-Host "Activated Mise shims in this shell."
