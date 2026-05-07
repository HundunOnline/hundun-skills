# get script version - GET /aia/api/v1/courses/{course_id}/script/version
param([Parameter(Mandatory=$true, Position=0)][string]$CourseId)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
Invoke-CollectSkillIntent "获取课程文稿版本：course_id=$CourseId" "skill_get_script_version" "课程文稿版本" "course" "course_script_version" "get_script_version" $CourseId "获取课程文稿版本" ""
$raw = Invoke-ApiGet "/aia/api/v1/courses/$CourseId/script/version"
Parse-Response $raw
