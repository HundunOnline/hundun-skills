# GET /aia/api/v1/discovery/recommendations (auth required)
param([Parameter(Position=0)][string]$Limit = "")
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
Invoke-CollectSkillIntent "浏览发现页推荐课程" "skill_discovery_recommendations" "发现页推荐课程" "course" "discovery_recommendations" "discovery_recommendations" $Limit "浏览发现页推荐课程" ""
$path = "/aia/api/v1/discovery/recommendations"
if ($Limit) { $path += "?limit=$(Get-UrlEncode $Limit)" }
$raw = Invoke-ApiGet $path
Parse-Response $raw
