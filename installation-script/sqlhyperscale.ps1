#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log-Info([string]$Message) {
  Write-Host "[ info ] $Message" -ForegroundColor Blue
}

function Log-Ok([string]$Message) {
  Write-Host "[  ok ] $Message" -ForegroundColor Green
}

function Log-Warn([string]$Message) {
  Write-Host "[warn ] $Message" -ForegroundColor Yellow
}

function Log-ErrorAndExit([string]$Message) {
  Write-Host "[error] $Message" -ForegroundColor Red
  exit 1
}

function Write-Hr {
  Write-Host "------------------------------------------------------------"
}

function Show-Usage {
  @"
sqlhyperscale.ps1 - create dedicated SQL server + Hyperscale Azure SQL Database

Usage (PowerShell):
  ./sqlhyperscale.ps1 --rg RG --ai-endpoint EP --ai-key KEY

Required parameters:
  --rg RG             Resource group (alias: --server-rg, --resource-group)
  --ai-endpoint EP    Azure Foundry endpoint host or URL (for SQL bootstrap)
  --ai-key KEY        Azure Foundry API key (for SQL bootstrap)

Optional shortcuts / overrides:
  --instance ID    Fills in rg-lab513-ID, faq-ai-server-ID, admin-ID
  --server NAME    Dedicated SQL server name (default: faq-ai-server-<shared-random>)
  --location LOC   Server location (default: indonesiacentral)
  --database NAME  Database name (default: faq-ai-assistant-db-<shared-random>)
  --admin USER     SQL admin username
  --env-file FILE  Output env file (default: ./sqldbhyperscale.env)
  --no-sql-bootstrap
  --subscription SUB
  --yes

Notes:
  - The script creates a NEW dedicated SQL server and database.
  - It does not create resource groups; target RG must already exist.
  - It auto-generates the SQL admin password and stores it in env files.
  - SQL bootstrap applies: 01_schema.sql, 02_seed_faq.sql,
    03_generate_embeddings.sql, 04_search_proc.sql.
  - If --ai-endpoint/--ai-key are not passed, the script asks during runtime.
"@
}

function Require-Command([string]$Name, [string]$Hint = "") {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    if ($Hint) {
      Log-ErrorAndExit "Required command '$Name' not found in PATH. $Hint"
    }
    Log-ErrorAndExit "Required command '$Name' not found in PATH."
  }
}

function Invoke-Az {
  param([string[]]$CommandArgs)
  & az @CommandArgs
  if ($LASTEXITCODE -ne 0) {
    throw "Azure CLI command failed: az $($CommandArgs -join ' ')"
  }
}

function Get-AzTsv([string]$Query) {
  $value = & az account show --query $Query -o tsv
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to query az account show --query $Query"
  }
  return ($value | Out-String).Trim()
}

function Get-HttpCodeWithCurl([string]$Url) {
  $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
  if (-not $curlCmd) {
    return '000'
  }

  $code = & $curlCmd.Source -sS -m 8 -o NUL -w '%{http_code}' $Url 2>$null
  if ($LASTEXITCODE -ne 0) {
    return '000'
  }
  return ($code | Out-String).Trim()
}

function Test-TcpReachable {
  param(
    [string]$HostName,
    [int]$Port,
    [int]$TimeoutMs = 8000
  )

  try {
    [void][System.Net.Dns]::GetHostAddresses($HostName)
  }
  catch {
    return [pscustomobject]@{ Reachable = $false; Reason = "DNS resolution failed for $HostName." }
  }

  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $asyncResult = $client.BeginConnect($HostName, $Port, $null, $null)
    if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
      $client.Close()
      return [pscustomobject]@{ Reachable = $false; Reason = "TCP timeout to ${HostName}:$Port." }
    }

    $client.EndConnect($asyncResult)
    return [pscustomobject]@{ Reachable = $true; Reason = "" }
  }
  catch {
    return [pscustomobject]@{ Reachable = $false; Reason = $_.Exception.Message }
  }
  finally {
    try { $client.Close() } catch {}
  }
}

function Is-IPv4([string]$Ip) {
  if (-not $Ip) { return $false }
  $m = [regex]::Match($Ip, '^(?<a>\d{1,3})\.(?<b>\d{1,3})\.(?<c>\d{1,3})\.(?<d>\d{1,3})$')
  if (-not $m.Success) { return $false }
  foreach ($name in @('a', 'b', 'c', 'd')) {
    $octet = [int]$m.Groups[$name].Value
    if ($octet -lt 0 -or $octet -gt 255) { return $false }
  }
  return $true
}

function Get-CurrentPublicIp {
  $sources = @('https://api.ipify.org', 'https://ifconfig.me/ip')
  foreach ($uri in $sources) {
    try {
      $ip = (Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 8).ToString().Trim()
      if (Is-IPv4 $ip) {
        return $ip
      }
    }
    catch {
      continue
    }
  }
  return $null
}

function New-Suffix {
  return (-join (1..6 | ForEach-Object { '{0:x}' -f (Get-Random -Minimum 0 -Maximum 16) }))
}

function New-FirewallRuleName([string]$Ip) {
  $ipSlug = $Ip -replace '\.', '-'
  $ts = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
  $rnd = '{0:x4}' -f (Get-Random -Minimum 0 -Maximum 65536)
  return "AllowClientIP-$ipSlug-$ts-$rnd"
}

function New-Password {
  $alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  $body = -join (1..21 | ForEach-Object { $alphabet[(Get-Random -Minimum 0 -Maximum $alphabet.Length)] })
  return "Aa1$body"
}

function Normalize-AiEndpointHost([string]$Endpoint) {
  $clean = $Endpoint.Replace("`r", "").Trim()
  $clean = $clean -replace '^https?://', ''
  return ($clean.Split('/')[0]).Trim()
}

function Prompt-AiCredentials {
  param(
    [string]$Endpoint,
    [string]$Key
  )

  $resolvedEndpoint = $Endpoint
  if ([string]::IsNullOrWhiteSpace($resolvedEndpoint)) {
    $resolvedEndpoint = Read-Host 'Azure Foundry endpoint host or URL'
  }
  $resolvedEndpoint = $resolvedEndpoint.Replace("`r", '').Trim()
  if ([string]::IsNullOrWhiteSpace($resolvedEndpoint)) {
    throw 'Azure Foundry endpoint is required for SQL bootstrap.'
  }

  $resolvedKey = $Key
  if ([string]::IsNullOrWhiteSpace($resolvedKey)) {
    $secure = Read-Host 'Azure Foundry API key' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
      $resolvedKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
  }
  $resolvedKey = $resolvedKey.Replace("`r", '').Trim()
  if ([string]::IsNullOrWhiteSpace($resolvedKey)) {
    throw 'Azure Foundry API key is required for SQL bootstrap.'
  }

  return [pscustomobject]@{
    Endpoint = $resolvedEndpoint
    Key = $resolvedKey
    Host = Normalize-AiEndpointHost $resolvedEndpoint
  }
}

function ConvertTo-BashQuoted([string]$Value) {
  $escaped = $Value -replace "'", "'\\''"
  return "'$escaped'"
}

function ConvertTo-PsSingleQuoted([string]$Value) {
  return ($Value -replace "'", "''")
}

function Write-EnvFiles {
  param(
    [string]$BashEnvFile,
    [string]$PsEnvFile,
    [hashtable]$Values
  )

  $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

  $bashLines = @("# Generated $timestamp")
  foreach ($key in $Values.Keys) {
    $bashLines += "$key=$(ConvertTo-BashQuoted $Values[$key])"
  }
  Set-Content -LiteralPath $BashEnvFile -Value ($bashLines -join [Environment]::NewLine) -NoNewline

  $psLines = @("# Generated $timestamp")
  foreach ($key in $Values.Keys) {
    $psLines += "`$env:$key = '$(ConvertTo-PsSingleQuoted $Values[$key])'"
  }
  Set-Content -LiteralPath $PsEnvFile -Value ($psLines -join [Environment]::NewLine) -NoNewline
}

function Confirm-Yes([string]$Prompt, [bool]$AutoYes) {
  if ($AutoYes) { return $true }
  $reply = Read-Host "$Prompt [type 'yes' to continue]"
  return $reply -eq 'yes'
}

function Ensure-File([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Required file not found: $Path"
  }
}

function Render-BootstrapSql {
  param(
    [string]$SqlDir,
    [string]$GeneratedDir,
    [string]$EndpointHost,
    [string]$ApiKey
  )

  if (-not (Test-Path -LiteralPath $GeneratedDir -PathType Container)) {
    New-Item -ItemType Directory -Path $GeneratedDir | Out-Null
  }

  $embeddingSrc = Join-Path $SqlDir '03_generate_embeddings.sql'
  $searchSrc = Join-Path $SqlDir '04_search_proc.sql'
  $embeddingOut = Join-Path $GeneratedDir '03_generate_embeddings.sql'
  $searchOut = Join-Path $GeneratedDir '04_search_proc.sql'

  $embeddingContent = (Get-Content -LiteralPath $embeddingSrc -Raw).Replace('<YOUR_FOUNDRY_API_KEY>', $ApiKey).Replace('<YOUR_FOUNDRY_ENDPOINT>', $EndpointHost)
  $searchContent = (Get-Content -LiteralPath $searchSrc -Raw).Replace('<YOUR_FOUNDRY_API_KEY>', $ApiKey).Replace('<YOUR_FOUNDRY_ENDPOINT>', $EndpointHost)

  Set-Content -LiteralPath $embeddingOut -Value $embeddingContent -NoNewline
  Set-Content -LiteralPath $searchOut -Value $searchContent -NoNewline
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = $scriptRoot
$sqlDir = Join-Path $rootDir 'sql'
$generatedDir = Join-Path $rootDir '.generated'

$instance = ''
$serverRg = 'workshop-microsoft-august'
$sqlServer = ''
$location = 'indonesiacentral'
$sqlDb = 'faq-ai-assistant-db'
$sqlAdmin = 'adminuser'
$sqlPassword = ''
$envFile = Join-Path $rootDir 'sqldbhyperscale.env'
$aiEndpoint = ''
$aiKey = ''
$subscription = ''
$autoYes = $false
$doSqlBootstrap = $true
$showHelp = $false

$serverRgExplicit = $false
$serverExplicit = $false
$dbExplicit = $false
$adminExplicit = $false

$argList = @($args)
for ($i = 0; $i -lt $argList.Count; $i++) {
  $token = $argList[$i]
  switch ($token) {
    '--instance' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --instance" }; $instance = $argList[$i] }
    '--server-rg' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --server-rg" }; $serverRg = $argList[$i]; $serverRgExplicit = $true }
    '--rg' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --rg" }; $serverRg = $argList[$i]; $serverRgExplicit = $true }
    '--resource-group' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --resource-group" }; $serverRg = $argList[$i]; $serverRgExplicit = $true }
    '--server' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --server" }; $sqlServer = $argList[$i]; $serverExplicit = $true }
    '--location' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --location" }; $location = $argList[$i] }
    '--database' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --database" }; $sqlDb = $argList[$i]; $dbExplicit = $true }
    '--admin' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --admin" }; $sqlAdmin = $argList[$i]; $adminExplicit = $true }
    '--env-file' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --env-file" }; $envFile = $argList[$i] }
    '--ai-endpoint' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --ai-endpoint" }; $aiEndpoint = $argList[$i] }
    '--ai-key' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --ai-key" }; $aiKey = $argList[$i] }
    '--no-sql-bootstrap' { $doSqlBootstrap = $false }
    '--subscription' { $i++; if ($i -ge $argList.Count) { Log-ErrorAndExit "Missing value for --subscription" }; $subscription = $argList[$i] }
    '--yes' { $autoYes = $true }
    '-y' { $autoYes = $true }
    '-h' { $showHelp = $true }
    '--help' { $showHelp = $true }
    default { Log-ErrorAndExit "Unknown argument: $token (use --help)" }
  }
}

if ($showHelp) {
  Show-Usage
  exit 0
}

$envFilePs1 = "$envFile.ps1"

$phaseTimings = @()
$currentPhaseName = $null
$currentPhaseStart = $null

function Start-Phase([string]$Name) {
  if ($script:currentPhaseName) {
    $duration = [int]((Get-Date) - $script:currentPhaseStart).TotalSeconds
    $script:phaseTimings += [pscustomobject]@{ Name = $script:currentPhaseName; Seconds = $duration }
  }

  $script:currentPhaseName = $Name
  $script:currentPhaseStart = Get-Date
  Write-Hr
  Log-Info $Name
  Write-Hr
}

function Close-Phase {
  if ($script:currentPhaseName) {
    $duration = [int]((Get-Date) - $script:currentPhaseStart).TotalSeconds
    $script:phaseTimings += [pscustomobject]@{ Name = $script:currentPhaseName; Seconds = $duration }
    $script:currentPhaseName = $null
    $script:currentPhaseStart = $null
  }
}

function Format-Secs([int]$Seconds) {
  $m = [math]::Floor($Seconds / 60)
  $s = $Seconds % 60
  return ('{0}m{1:d2}s' -f $m, $s)
}

function Print-TimingSummary {
  Close-Phase
  Write-Hr
  Write-Host '[ time ] phase durations' -ForegroundColor Blue
  $total = 0
  foreach ($item in $phaseTimings) {
    Write-Host ('   {0,-46} {1}' -f $item.Name, (Format-Secs $item.Seconds))
    $total += $item.Seconds
  }
  Write-Host ('   {0,-46} {1}' -f 'TOTAL', (Format-Secs $total))
  Write-Hr
}

try {
  Start-Phase '1/5  Preflight'
  Require-Command az 'Install: https://learn.microsoft.com/cli/azure/install-azure-cli'

  Log-Info 'Checking outbound connectivity to Azure (management.azure.com) ...'
  $httpCode = Get-HttpCodeWithCurl -Url 'https://management.azure.com/'
  if ($httpCode -ne '000') {
    Log-Ok "Azure control plane reachable (HTTP $httpCode)."
  }
  else {
    Log-ErrorAndExit 'Cannot reach https://management.azure.com from this shell.'
  }

  Log-Info 'Checking Azure CLI sign-in ...'
  & az account show | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Log-ErrorAndExit "Not signed in. Run: az login (or az login --use-device-code)"
  }

  if ($subscription) {
    Log-Info "Setting subscription to '$subscription' ..."
    Invoke-Az -CommandArgs @('account', 'set', '--subscription', $subscription)
  }

  $currentSubName = Get-AzTsv 'name'
  $currentSubId = Get-AzTsv 'id'
  $currentUser = Get-AzTsv 'user.name'
  Log-Ok "Signed in as $currentUser on subscription '$currentSubName'."

  if ($instance) {
    $instance = $instance.ToLowerInvariant()
    if (-not $serverRgExplicit) { $serverRg = "rg-lab513-$instance" }
    if (-not $serverExplicit) { $sqlServer = "faq-ai-server-$instance" }
    if (-not $adminExplicit) { $sqlAdmin = "admin-$instance" }
  }

  if ([string]::IsNullOrWhiteSpace($serverRg)) {
    Log-ErrorAndExit 'Missing required --server-rg/--rg/--resource-group value.'
  }

  $runSuffix = $null
  if (-not $serverExplicit -or -not $dbExplicit) {
    $runSuffix = New-Suffix
  }

  if (-not $serverExplicit) {
    $sqlServer = "faq-ai-server-$runSuffix"
  }
  $sqlServer = $sqlServer.ToLowerInvariant()

  if (-not $dbExplicit) {
    $sqlDb = "$sqlDb-$runSuffix"
  }

  if ([string]::IsNullOrWhiteSpace($sqlPassword)) {
    $sqlPassword = New-Password
  }

  Start-Phase '2/5  Create dedicated SQL server'
  & az group show -n $serverRg -o none 1>$null 2>$null
  if ($LASTEXITCODE -eq 0) {
    Log-Ok "Resource group $serverRg already exists."
  }
  else {
    Log-ErrorAndExit "Resource group '$serverRg' not found. Create it first, then rerun this script."
  }

  $existingServerCountRaw = & az sql server list -g $serverRg --query "[?name=='$sqlServer'] | length(@)" -o tsv
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to check existing SQL servers in resource group '$serverRg'."
  }
  $existingServerCount = 0
  [void][int]::TryParse(($existingServerCountRaw | Out-String).Trim(), [ref]$existingServerCount)

  if ($existingServerCount -gt 0) {
    Log-ErrorAndExit "SQL server '$sqlServer' already exists in '$serverRg'. Pick another --server name for a dedicated server."
  }

  Invoke-Az -CommandArgs @(
    'sql', 'server', 'create',
    '-g', $serverRg,
    '-n', $sqlServer,
    '-l', $location,
    '--admin-user', $sqlAdmin,
    '--admin-password', $sqlPassword,
    '--enable-public-network', 'true',
    '-o', 'none'
  )
  Log-Ok "Dedicated SQL server $sqlServer created."

  Start-Phase '3/5  Whitelist current client IP'
  $clientIp = Get-CurrentPublicIp
  if (-not (Is-IPv4 $clientIp)) {
    Log-ErrorAndExit 'Could not determine current public IPv4 address for SQL firewall whitelist.'
  }

  $fwRuleName = New-FirewallRuleName $clientIp
  Invoke-Az -CommandArgs @(
    'sql', 'server', 'firewall-rule', 'create',
    '-g', $serverRg,
    '-s', $sqlServer,
    '-n', $fwRuleName,
    '--start-ip-address', $clientIp,
    '--end-ip-address', $clientIp,
    '-o', 'none'
  )
  Log-Ok "SQL firewall rule $fwRuleName set to $clientIp."

  Write-Hr
  Write-Host 'Database plan' -ForegroundColor White
  Write-Hr
  Write-Host "  Subscription : $currentSubName ($currentSubId)"
  Write-Host "  Server RG    : $serverRg"
  Write-Host "  Location     : $location"
  Write-Host "  SQL server   : $sqlServer"
  Write-Host "  Database     : $sqlDb"
  Write-Host "  SQL admin    : $sqlAdmin"
  Write-Host "  Password     : auto-generated for this dedicated server and saved to $envFile"
  Write-Hr

  if (-not (Confirm-Yes -Prompt 'Proceed with Hyperscale database creation?' -AutoYes:$autoYes)) {
    Log-ErrorAndExit 'Aborted by user.'
  }

  Start-Phase '4/5  Create Hyperscale database'
  $existingDbCountRaw = & az sql db list -g $serverRg -s $sqlServer --query "[?name=='$sqlDb'] | length(@)" -o tsv
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to check existing SQL databases on server '$sqlServer'."
  }
  $existingDbCount = 0
  [void][int]::TryParse(($existingDbCountRaw | Out-String).Trim(), [ref]$existingDbCount)

  if ($existingDbCount -gt 0) {
    Log-Ok "Database $sqlDb already exists on $sqlServer; skipping create."
  }
  else {
    Invoke-Az -CommandArgs @(
      'sql', 'db', 'create',
      '-g', $serverRg,
      '-s', $sqlServer,
      '-n', $sqlDb,
      '--edition', 'Hyperscale',
      '--family', 'Gen5',
      '--capacity', '2',
      '--compute-model', 'Serverless',
      '--ha-replicas', '0',
      '--backup-storage-redundancy', 'Local',
      '-o', 'none'
    )
    Log-Ok "Database $sqlDb created on $sqlServer."
  }

  $envValues = [ordered]@{
    SERVER_RG = $serverRg
    LOCATION = $location
    SQL_SERVER = $sqlServer
    SQL_FQDN = "$sqlServer.database.windows.net"
    SQL_DB = $sqlDb
    SQL_ADMIN = $sqlAdmin
    SQL_PASSWORD = $sqlPassword
  }

  Write-EnvFiles -BashEnvFile $envFile -PsEnvFile $envFilePs1 -Values $envValues
  Log-Ok "Connection details written to $envFile (Bash) and $envFilePs1 (PowerShell)."

  if ($doSqlBootstrap) {
    Start-Phase '5/5  SQL bootstrap'
    Require-Command sqlcmd 'Install sqlcmd: https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility'

    Ensure-File (Join-Path $sqlDir '01_schema.sql')
    Ensure-File (Join-Path $sqlDir '02_seed_faq.sql')
    Ensure-File (Join-Path $sqlDir '03_generate_embeddings.sql')
    Ensure-File (Join-Path $sqlDir '04_search_proc.sql')

    $creds = Prompt-AiCredentials -Endpoint $aiEndpoint -Key $aiKey
    if ([string]::IsNullOrWhiteSpace($creds.Host)) {
      Log-ErrorAndExit "Unable to parse Azure Foundry endpoint host from '$($creds.Endpoint)'."
    }

    Render-BootstrapSql -SqlDir $sqlDir -GeneratedDir $generatedDir -EndpointHost $creds.Host -ApiKey $creds.Key

    $sqlCmdCommon = @(
      '-S', "tcp:$sqlServer.database.windows.net,1433",
      '-d', $sqlDb,
      '-U', $sqlAdmin,
      '-P', $sqlPassword,
      '-C',
      '-l', '60'
    )

    Log-Info 'Applying 01_schema.sql ...'
    & sqlcmd @sqlCmdCommon -i (Join-Path $sqlDir '01_schema.sql')
    if ($LASTEXITCODE -ne 0) { throw 'Failed applying 01_schema.sql' }

    Log-Info 'Applying 02_seed_faq.sql ...'
    & sqlcmd @sqlCmdCommon -i (Join-Path $sqlDir '02_seed_faq.sql')
    if ($LASTEXITCODE -ne 0) { throw 'Failed applying 02_seed_faq.sql' }

    Log-Info 'Applying 03_generate_embeddings.sql ...'
    & sqlcmd @sqlCmdCommon -i (Join-Path $generatedDir '03_generate_embeddings.sql')
    if ($LASTEXITCODE -ne 0) { throw 'Failed applying 03_generate_embeddings.sql' }

    Log-Info 'Applying 04_search_proc.sql ...'
    & sqlcmd @sqlCmdCommon -i (Join-Path $generatedDir '04_search_proc.sql')
    if ($LASTEXITCODE -ne 0) { throw 'Failed applying 04_search_proc.sql' }

    Log-Ok "SQL bootstrap finished for $sqlDb."
    Log-Info "Rendered SQL files saved in $generatedDir."
  }
  else {
    Log-Info 'SQL bootstrap skipped (--no-sql-bootstrap).'
  }

  Print-TimingSummary
  Write-Hr
  Log-Ok 'Hyperscale database setup complete.'
  Write-Hr
  Write-Host 'SQL credentials'
  Write-Host "  Server   : $sqlServer.database.windows.net"
  Write-Host "  Database : $sqlDb"
  Write-Host "  Login    : $sqlAdmin"
  Write-Host "  Password : $sqlPassword"
  Write-Hr
  Write-Host '  Next step (PowerShell):'
  Write-Host "    . `"$envFilePs1`""
  Write-Host '    sqlcmd -S "tcp:$env:SQL_SERVER.database.windows.net,1433" -d "$env:SQL_DB" -U "$env:SQL_ADMIN" -P "$env:SQL_PASSWORD" -C'
}
catch {
  Log-ErrorAndExit $_.Exception.Message
}
