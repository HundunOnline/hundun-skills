# GET /aia/api/v1/skill/modules/:module_key (auth)
param(
    [Parameter(Mandatory=$true, Position=0)][string]$ModuleKey,
    [Parameter(Position=1)][string]$SkillId = "hd_skill"
)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
$path = "/aia/api/v1/skill/modules/$(Get-UrlEncode $ModuleKey)?skill_id=$(Get-UrlEncode $SkillId)"
$raw = Invoke-ApiGet $path
Parse-Response $raw
