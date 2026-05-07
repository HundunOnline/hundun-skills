# POST /aia/api/v1/conversation/records (auth)
param(
    [Parameter(Mandatory=$true, Position=0)][string]$Source,
    [Parameter(Mandatory=$true, Position=1)][string]$Question,
    [Parameter(Position=2)][string]$Answer = "Recorded this Hundun Skill test conversation."
)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
$ts = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$requestId = "hundun-skill-conversation-$Source-$ts"
$sessionId = "hundun-skill-session-$Source-$ts"
$body = @{
    client_id = "hundun-skill"
    request_id = $requestId
    session_id = $sessionId
    scene_value = $Source
    user_input = $Question
    ai_final_answer = $Answer
    timestamp = $ts
} | ConvertTo-Json -Depth 5 -Compress
$raw = Invoke-ApiPost "/aia/api/v1/conversation/records" $body
Parse-Response $raw
