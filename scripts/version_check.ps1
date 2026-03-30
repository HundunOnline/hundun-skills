# version check - GET /aia/api/v1/version (no auth)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
$script:BaseUrl = $script:BaseUrl.TrimEnd('/')
$raw = Invoke-ApiGetNoAuth "/aia/api/v1/version"
Parse-Response $raw
