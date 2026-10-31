# PowerShell Test Runner Wrapper for CAGE ZERO Animation E2E Suite
param(
    [string]$Tier = "1,2,3,4",
    [switch]$Smoke,
    [string]$Slug = "",
    [string]$JsonReport = "",
    [switch]$AllowPending
)

$ErrorActionPreference = "Stop"

# Locate Python binary: Prefer uv run, fallback to cpython or python in PATH
$uvPath = "C:\Users\Stang\AppData\Local\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe"
$cpythonPath = "C:\Users\Stang\AppData\Roaming\uv\python\cpython-3.15-windows-x86_64-none\python.exe"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$testRunnerPy = Join-Path $scriptDir "test_runner.py"

$pythonArgs = @($testRunnerPy, "--tier", $Tier)
if ($Smoke) { $pythonArgs += "--smoke" }
if ($Slug -ne "") { $pythonArgs += @("--slug", $Slug) }
if ($JsonReport -ne "") { $pythonArgs += @("--json-report", $JsonReport) }
if ($AllowPending) { $pythonArgs += "--allow-pending" }

if (Test-Path $uvPath) {
    & $uvPath run python @pythonArgs
    exit $LASTEXITCODE
} elseif (Test-Path $cpythonPath) {
    & $cpythonPath @pythonArgs
    exit $LASTEXITCODE
} else {
    python @pythonArgs
    exit $LASTEXITCODE
}
