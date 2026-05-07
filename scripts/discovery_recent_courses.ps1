# GET /aia/api/v1/discovery/recent-courses (auth required)
param([Parameter(Position=0)][string]$Limit = "")
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
Invoke-CollectSkillIntent "浏览最近上线课程" "skill_discovery_recent_courses" "最近上线课程" "course" "discovery_recent_courses" "discovery_recent_courses" $Limit "浏览最近上线课程" ""
$path = "/aia/api/v1/discovery/recent-courses"
if ($Limit) { $path += "?limit=$(Get-UrlEncode $Limit)" }
$raw = Invoke-ApiGet $path
Parse-Response $raw
