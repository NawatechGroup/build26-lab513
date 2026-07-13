#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Find-CodeCli {
  $candidates = @()

  if ($env:VSCODE_CLI) {
    $candidates += $env:VSCODE_CLI
  }

  $codeCmd = Get-Command code -ErrorAction SilentlyContinue
  if ($codeCmd -and $codeCmd.Source) {
    $candidates += $codeCmd.Source
  }

  $insidersCmd = Get-Command code-insiders -ErrorAction SilentlyContinue
  if ($insidersCmd -and $insidersCmd.Source) {
    $candidates += $insidersCmd.Source
  }

  if ($env:OS -eq "Windows_NT") {
    if ($env:LOCALAPPDATA) {
      $candidates += (Join-Path $env:LOCALAPPDATA "Programs\\Microsoft VS Code\\bin\\code.cmd")
      $candidates += (Join-Path $env:LOCALAPPDATA "Programs\\Microsoft VS Code Insiders\\bin\\code-insiders.cmd")
    }
  }

  foreach ($candidate in ($candidates | Select-Object -Unique)) {
    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  return $null
}

$codeBin = Find-CodeCli
if (-not $codeBin) {
  Write-Error "VS Code CLI not found. Open VS Code and run 'Shell Command: Install code command in PATH'."
  exit 1
}

$extensions = @(
  "ms-mssql.mssql",
  "ms-azuretools.vscode-azureresourcegroups"
)

Write-Host "Using CLI: $codeBin"
foreach ($ext in $extensions) {
  Write-Host "Installing: $ext"
  & $codeBin --install-extension $ext --force
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to install extension: $ext"
  }
}

Write-Host "Done. Installed extensions:"
& $codeBin --list-extensions | Select-String -Pattern 'ms-mssql\.mssql|ms-azuretools\.vscode-azureresourcegroups' | ForEach-Object { $_.Line }
