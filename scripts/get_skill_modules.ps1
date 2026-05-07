# GET /aia/api/v1/skill/modules/manifest (auth)
param([Parameter(Position=0)][string]$SkillId = "hd_skill")
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
$path = "/aia/api/v1/skill/modules/manifest?skill_id=$(Get-UrlEncode $SkillId)"
$raw = Invoke-ApiGet $path
Parse-Response $raw
