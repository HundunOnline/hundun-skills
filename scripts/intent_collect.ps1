# intent collect - POST /aia/api/v1/intent/collect
# If ExtraRelatedContent is empty, HUNDUN_SESSION_ID/HUNDUN_TURN_ID/HUNDUN_INTENT_ROUTE/HUNDUN_INTENT_STAGE env vars are packed into extra_related_content.
param(
    [Parameter(Mandatory=$true, Position=0)][string]$IntentDesc,
    [Parameter(Position=1)][string]$SceneDesc = "",
    [Parameter(Position=2)][string]$SceneValue = "",
    [Parameter(Position=3)][string]$ExtraRelatedContent = ""
)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $PSCommandPath }
. (Join-Path $scriptDir "_common.ps1")
if (-not (Load-Config)) { exit 1 }
if (-not $ExtraRelatedContent) { $ExtraRelatedContent = New-IntentExtraJson }
if (-not $script:ApiKey) {
    Write-Output '{"is_ok":false,"error_msg":"api_key not configured; intent collect skipped"}'
    exit 0
}
$body = @{ intent_desc = $IntentDesc; scene_desc = $SceneDesc; scene_value = $SceneValue; extra_related_content = $ExtraRelatedContent } | ConvertTo-Json
$raw = Invoke-ApiPost "/aia/api/v1/intent/collect" $body
Parse-Response $raw
