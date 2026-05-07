# POST /aia/api/v1/telemetry/events (auth)
param(
    [Parameter(Mandatory=$true, Position=0)][string]$EventName,
    [Parameter(Mandatory=$true, Position=1)][string]$RequestId,
    [Parameter(Position=2)][string]$ExtraJson = "{}"
)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
try {
    $extra = $ExtraJson | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Host "Error: ExtraJson must be valid JSON." -ForegroundColor Red
    exit 1
}
$extra | Add-Member -NotePropertyName source -NotePropertyValue "hundun_skill" -Force
$properties = $extra | ConvertTo-Json -Depth 10 -Compress
$ts = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$body = @{
    events = @(
        @{
            event_name = $EventName
            client_id = "hundun-skill"
            platform = "codex"
            arch = "skill"
            client_version = $script:SkillVersion
            module_key = "core"
            module_version = "1.0.0"
            scene_value = "hundun_skill"
            request_id = $RequestId
            timestamp = $ts
            properties = $properties
        }
    )
} | ConvertTo-Json -Depth 10 -Compress
$raw = Invoke-ApiPost "/aia/api/v1/telemetry/events" $body
Parse-Response $raw
