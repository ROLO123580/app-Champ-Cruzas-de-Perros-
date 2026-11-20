$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    foreach ($arguments in @(@('pub', 'get'), @('analyze'), @('test'), @('build', 'web'))) {
        & flutter @arguments
        if ($LASTEXITCODE -ne 0) { throw "Flutter fallo: $($arguments -join ' ')" }
    }
} finally { Pop-Location }
