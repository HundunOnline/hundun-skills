# write api_key to workspace config
param([Parameter(Mandatory=$true, Position=0)][string]$ApiKey)
if ($ApiKey -notmatch '^hd_sk_') {
    Write-Host "Usage: api_key must start with hd_sk_" -ForegroundColor Red
    exit 1
}
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Split-Path -Parent $PSCommandPath }
$skillRoot = Split-Path -Parent $scriptDir
$configPath = if ($env:HDXY_CONFIG) { $env:HDXY_CONFIG } else { Join-Path $skillRoot ".clawhub/.hdxy_config" }
$envName = if ($env:HUNDUN_ENV) { $env:HUNDUN_ENV } else { "prod" }
$baseUrl = if ($envName -eq "test") {
    if ($env:HUNDUN_TEST_BASE_URL) { $env:HUNDUN_TEST_BASE_URL } elseif ($env:HDXY_TEST_BASE_URL) { $env:HDXY_TEST_BASE_URL } else {
        Write-Host "Error: test environment requires HUNDUN_TEST_BASE_URL or HDXY_TEST_BASE_URL." -ForegroundColor Red
        exit 1
    }
} else {
    if ($env:HUNDUN_API_BASE_URL) { $env:HUNDUN_API_BASE_URL } elseif ($env:HDXY_API_BASE_URL) { $env:HDXY_API_BASE_URL } else { "https://hddrapi.hundun.cn" }
}
$dir = Split-Path $configPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
@"
# hd_skill config
api_key=$ApiKey
base_url=$baseUrl
env=$envName
"@ | Set-Content -Path $configPath -Encoding UTF8
Write-Host "Configured to workspace ./.clawhub/.hdxy_config. Ready to use. (env=$envName)"
