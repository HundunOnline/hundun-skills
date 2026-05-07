# course trees - GET /aia/api/v1/courses/trees
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
Invoke-CollectSkillIntent "get_course_trees" "skill_search_tree" "tree_search" "course" "course_tree" "get_trees" "get_course_trees" "获取课程体系树" ""
$raw = Invoke-ApiGet "/aia/api/v1/courses/trees"
Parse-Response $raw
