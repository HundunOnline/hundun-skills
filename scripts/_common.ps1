# hd_skill common logic (PowerShell) - equivalent to _common.sh
$script:CommonScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$script:SkillRoot = Split-Path -Parent $script:CommonScriptDir
$script:SkillVersion = if ($env:HUNDUN_SKILL_VERSION) { $env:HUNDUN_SKILL_VERSION } else { "1.0.2" }

# Force UTF-8 output to avoid garbled Chinese on Windows
$OutputEncoding = [System.Text.Encoding]::UTF8
if ([Console]::OutputEncoding -ne [System.Text.Encoding]::UTF8) {
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script:ConfigPath = if ($env:HDXY_CONFIG) { $env:HDXY_CONFIG } else { Join-Path $script:SkillRoot ".clawhub/.hdxy_config" }
$script:DefaultBaseUrl = "https://hddrapi.hundun.cn"
$script:DefaultTestBaseUrl = ""
$script:DefaultTestHost = ""
$script:BaseUrl = if ($env:HUNDUN_API_BASE_URL) { $env:HUNDUN_API_BASE_URL } elseif ($env:HDXY_API_BASE_URL) { $env:HDXY_API_BASE_URL } else { $script:DefaultBaseUrl }
$script:ApiKey = if ($env:HUNDUN_API_KEY) { $env:HUNDUN_API_KEY } elseif ($env:HDXY_API_KEY) { $env:HDXY_API_KEY } else { "" }
$script:ApiHostHeader = ""
$script:ApiOrigin = ""
$script:ApiIsTest = $false
$script:ApiNeedHostHeader = $false

function Load-Config {
    if (Test-Path $script:ConfigPath) {
        $lines = Get-Content $script:ConfigPath -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if (-not $script:ApiKey -and $line -match '^api_key=(.*)$') { $script:ApiKey = $matches[1].Trim() }
            if ($line -match '^base_url=(.*)$') { $script:BaseUrl = $matches[1].Trim() }
            if (-not $env:HUNDUN_ENV -and $line -match '^env=(.*)$') { $env:HUNDUN_ENV = $matches[1].Trim() }
        }
    }
    if ($env:HUNDUN_API_KEY) { $script:ApiKey = $env:HUNDUN_API_KEY }
    elseif ($env:HDXY_API_KEY) { $script:ApiKey = $env:HDXY_API_KEY }
    if ($env:HUNDUN_ENV -eq "test") {
        $script:ApiIsTest = $true
        if ($env:HUNDUN_TEST_BASE_URL) { $script:BaseUrl = $env:HUNDUN_TEST_BASE_URL }
        elseif ($env:HDXY_TEST_BASE_URL) { $script:BaseUrl = $env:HDXY_TEST_BASE_URL }
        else { $script:BaseUrl = $script:DefaultTestBaseUrl }
        if (-not $script:BaseUrl) {
            Write-Host "Error: test environment requires HUNDUN_TEST_BASE_URL or HDXY_TEST_BASE_URL." -ForegroundColor Red
            return $false
        }
    } elseif ($env:HUNDUN_API_BASE_URL) {
        $script:BaseUrl = $env:HUNDUN_API_BASE_URL
    } elseif ($env:HDXY_API_BASE_URL) {
        $script:BaseUrl = $env:HDXY_API_BASE_URL
    }
    $script:BaseUrl = $script:BaseUrl.TrimEnd('/')
    try {
        $uri = [System.Uri]$script:BaseUrl
        $script:ApiOrigin = $uri.GetLeftPart([System.UriPartial]::Authority)
        if ($env:HUNDUN_TEST_HOST) { $script:ApiHostHeader = $env:HUNDUN_TEST_HOST }
        elseif ($env:HDXY_TEST_HOST) { $script:ApiHostHeader = $env:HDXY_TEST_HOST }
        else { $script:ApiHostHeader = $uri.Authority }
        if ($script:ApiIsTest -and $script:DefaultTestHost -and ($uri.Host -eq "127.0.0.1" -or $uri.Host -eq "localhost")) {
            $script:ApiHostHeader = $script:DefaultTestHost
            $script:ApiOrigin = "https://$script:ApiHostHeader"
        }
        $script:ApiNeedHostHeader = ($script:ApiIsTest -and $script:ApiHostHeader -and $script:ApiHostHeader -ne $uri.Authority)
    } catch {
        $script:ApiOrigin = $script:DefaultBaseUrl
    }
    return $true
}

function Get-UrlEncode([string]$s) {
    if ($s -eq $null) { return "" }
    [System.Uri]::EscapeDataString($s)
}

function Write-AuthGuidance {
    Write-Host "当前凭证可能已失效、无权限或未完成登录。请打开 https://tools.hundun.cn/h5Bin/aia/#/keys 登录混沌会员账号后，重新生成一个 hd_sk_ 开头的密钥发给 AI。拿到有效密钥后，我会继续当前任务。" -ForegroundColor Yellow
}

function Test-AuthError([string]$errNo, [string]$errMsg, [string]$body, [string]$httpCode) {
    if ($errNo -eq "-2004" -or $errNo -eq "-2005") { return $true }
    $hint = "$httpCode $errMsg $body"
    return ($hint -match 'api[_ -]?key|密钥|鉴权|权限|401|403|unauthorized|forbidden|失效|未登录|未携带')
}

# PS 5.x: use DownloadData + UTF-8 decode (more reliable than DownloadString for JSON with CJK).
function Read-WebClientUtf8([string]$url, [hashtable]$extraHeaders) {
    $wc = New-Object System.Net.WebClient
    foreach ($h in $extraHeaders.GetEnumerator()) {
        $wc.Headers.Add($h.Key, $h.Value)
    }
    $utf8 = [System.Text.Encoding]::UTF8
    $respBody = ""
    $respCode = 200
    try {
        $bytes = $wc.DownloadData($url)
        $respBody = $utf8.GetString($bytes)
    } catch {
        $ex = $_.Exception
        $respCode = 0
        if ($ex.Response) {
            $respCode = [int]$ex.Response.StatusCode
            try {
                $sr = New-Object System.IO.StreamReader($ex.Response.GetResponseStream(), $utf8)
                $respBody = $sr.ReadToEnd()
                $sr.Close()
            } catch { }
        }
    }
    $out = New-Object PSCustomObject
    $out | Add-Member -NotePropertyName Body -NotePropertyValue $respBody -Force
    $out | Add-Member -NotePropertyName StatusCode -NotePropertyValue $respCode -Force
    return $out
}

function Get-CommonHeaders {
    $headers = @{}
    if ($script:ApiIsTest) {
        if ($script:ApiNeedHostHeader) { $headers["Host"] = $script:ApiHostHeader }
        if ($script:ApiOrigin) {
            $headers["Origin"] = $script:ApiOrigin
            $headers["Referer"] = "$script:ApiOrigin/"
        }
    }
    return $headers
}

function Invoke-ApiGetNoAuth([string]$path) {
    $path = Add-ClientVersion $path
    $url = "$script:BaseUrl$path"
    $result = Read-WebClientUtf8 $url (Get-CommonHeaders)
    return "$($result.Body)`n$($result.StatusCode)"
}

function Invoke-ApiGet([string]$path) {
    if (-not $script:ApiKey) {
        Write-Host "Error: api_key not configured. Send api_key (hd_sk_...) to AI." -ForegroundColor Red
        Write-AuthGuidance
        return $null
    }
    $path = Add-ClientVersion $path
    $url = "$script:BaseUrl$path"
    $headers = Get-CommonHeaders
    $headers["X-API-Key"] = $script:ApiKey
    $result = Read-WebClientUtf8 $url $headers
    return "$($result.Body)`n$($result.StatusCode)"
}

function Add-ClientVersion([string]$path) {
    if (-not $path) { return $path }
    if ($path -match '(^|[?&])client_version=') { return $path }
    $sep = if ($path.Contains("?")) { "&" } else { "?" }
    return "$path${sep}client_version=$([System.Uri]::EscapeDataString($script:SkillVersion))"
}

function Invoke-ApiGetQuery([string]$path, [string]$key, [string]$value) {
    $encoded = Get-UrlEncode $value
    Invoke-ApiGet "$path`?$key=$encoded"
}

function Invoke-ApiPost([string]$path, [string]$body) {
    if (-not $script:ApiKey) {
        Write-Host "Error: api_key not configured." -ForegroundColor Red
        Write-AuthGuidance
        return $null
    }
    $url = "$script:BaseUrl$path"
    $wc = New-Object System.Net.WebClient
    $wc.Encoding = [System.Text.Encoding]::UTF8
    $headers = Get-CommonHeaders
    if (-not $script:ApiIsTest -and $script:ApiOrigin) { $headers["Origin"] = $script:ApiOrigin }
    foreach ($h in $headers.GetEnumerator()) {
        $wc.Headers.Add($h.Key, $h.Value)
    }
    $wc.Headers.Add("X-API-Key", $script:ApiKey)
    $wc.Headers.Add("Content-Type", "application/json; charset=utf-8")
    $utf8 = [System.Text.Encoding]::UTF8
    try {
        $resp = $wc.UploadString($url, "POST", $body)
        return "$resp`n200"
    } catch {
        $ex = $_.Exception
        $status = 0
        $respBody = ""
        if ($ex.Response) {
            $status = [int]$ex.Response.StatusCode
            try {
                $sr = New-Object System.IO.StreamReader($ex.Response.GetResponseStream(), $utf8)
                $respBody = $sr.ReadToEnd()
                $sr.Close()
            } catch { }
        }
        return "${respBody}`n$status"
    }
}

function New-IntentExtraJson(
    [string]$Route = "",
    [string]$Stage = "",
    [string]$Tool = "",
    [string]$RawUserInput = "",
    [string]$NormalizedIntent = "",
    [string]$PreviousRequestId = ""
) {
    $payload = [ordered]@{
        source = "hundun_skill"
        client = "powershell"
    }
    $sessionId = if ($env:HUNDUN_SESSION_ID) { $env:HUNDUN_SESSION_ID } else { $env:AIA_SESSION_ID }
    $requestId = if ($env:HUNDUN_REQUEST_ID) { $env:HUNDUN_REQUEST_ID } else { $env:AIA_REQUEST_ID }
    $turnId = if ($env:HUNDUN_TURN_ID) { $env:HUNDUN_TURN_ID } else { $env:AIA_TURN_ID }
    if ($sessionId) { $payload.session_id = $sessionId }
    if ($requestId) { $payload.request_id = $requestId }
    if ($turnId) { $payload.turn_id = $turnId }
    if (-not $Route -and $env:HUNDUN_INTENT_ROUTE) { $Route = $env:HUNDUN_INTENT_ROUTE }
    if (-not $Stage -and $env:HUNDUN_INTENT_STAGE) { $Stage = $env:HUNDUN_INTENT_STAGE }
    if (-not $Tool -and $env:HUNDUN_INTENT_TOOL) { $Tool = $env:HUNDUN_INTENT_TOOL }
    if (-not $RawUserInput -and $env:HUNDUN_RAW_USER_INPUT) { $RawUserInput = $env:HUNDUN_RAW_USER_INPUT }
    if (-not $NormalizedIntent -and $env:HUNDUN_NORMALIZED_INTENT) { $NormalizedIntent = $env:HUNDUN_NORMALIZED_INTENT }
    if (-not $PreviousRequestId -and $env:HUNDUN_PREVIOUS_REQUEST_ID) { $PreviousRequestId = $env:HUNDUN_PREVIOUS_REQUEST_ID }
    if ($Route) { $payload.route = $Route }
    if ($Stage) { $payload.stage = $Stage }
    if ($Tool) { $payload.tool = $Tool }
    if ($RawUserInput) { $payload.raw_user_input = $RawUserInput }
    if ($NormalizedIntent) { $payload.normalized_intent = $NormalizedIntent }
    if ($PreviousRequestId) { $payload.previous_request_id = $PreviousRequestId }
    return ($payload | ConvertTo-Json -Compress -Depth 5)
}

function Invoke-CollectIntent([string]$intentDesc, [string]$sceneValue, [string]$sceneDesc, [string]$extra) {
    if (-not $script:ApiKey) { return }
    try {
        if (-not $extra) { $extra = New-IntentExtraJson }
        $body = @{ intent_desc = $intentDesc; scene_value = $sceneValue; scene_desc = $sceneDesc; extra_related_content = $extra } | ConvertTo-Json
        Invoke-ApiPost "/aia/api/v1/intent/collect" $body | Out-Null
    } catch {
        # intent collect must not block search and other main flows
    }
}

function Invoke-CollectSkillIntent(
    [string]$intentDesc,
    [string]$sceneValue,
    [string]$sceneDesc,
    [string]$route,
    [string]$stage,
    [string]$tool,
    [string]$rawUserInput = "",
    [string]$normalizedIntent = "",
    [string]$previousRequestId = ""
) {
    if (-not $rawUserInput) { $rawUserInput = $intentDesc }
    if (-not $normalizedIntent) { $normalizedIntent = $intentDesc }
    $extra = New-IntentExtraJson $route $stage $tool $rawUserInput $normalizedIntent $previousRequestId
    Invoke-CollectIntent $intentDesc $sceneValue $sceneDesc $extra
}

function Parse-Response([string]$raw) {
    if (-not $raw) {
        exit 1
    }
    $lines = $raw -split "`n"
    $httpCode = $lines[-1]
    $body = ($lines[0..($lines.Count-2)] -join "`n")
    if ($httpCode -ne "200") {
        Write-Host "HTTP $httpCode" -ForegroundColor Red
        Write-Host $body.Substring(0, [Math]::Min(500, $body.Length)) -ForegroundColor Red
        if (Test-AuthError "" "" $body $httpCode) { Write-AuthGuidance }
        exit 1
    }
    $errNo = if ($body -match '"error_no"\s*:\s*(-?\d+)') { $matches[1] } else { $null }
    $errMsg = if ($body -match '"error_msg"\s*:\s*"([^"]*)"') { $matches[1] } else { "Unknown error" }
    if ($errNo -and $errNo -ne "0") {
        Write-Host $errMsg -ForegroundColor Red
        if (Test-AuthError $errNo $errMsg $body $httpCode) { Write-AuthGuidance }
        exit 1
    }
    if ($body -match '"compressed"\s*:\s*true') {
        try {
            $json = $body | ConvertFrom-Json
            $data = $json.data
            if (-not $data) { throw "no data" }
            $bytes = [Convert]::FromBase64String($data)
            $utf8 = [System.Text.Encoding]::UTF8
            # 1) Try zstd CLI
            $zstd = Get-Command zstd -ErrorAction SilentlyContinue
            if ($zstd) {
                $tmpIn = [System.IO.Path]::GetTempFileName()
                $tmpOut = [System.IO.Path]::GetTempFileName()
                [System.IO.File]::WriteAllBytes($tmpIn, $bytes)
                & zstd -d $tmpIn -o $tmpOut 2>$null
                if (Test-Path $tmpOut) {
                    $decoded = [System.IO.File]::ReadAllText($tmpOut, $utf8)
                    Remove-Item $tmpIn, $tmpOut -Force -ErrorAction SilentlyContinue
                    Write-Output $decoded
                    return
                }
                Remove-Item $tmpIn -Force -ErrorAction SilentlyContinue
            }
            # 2) Fallback: Python + zstandard (pip install zstandard)
            $py = (Get-Command python -ErrorAction SilentlyContinue).Source
            if (-not $py) { $py = (Get-Command python3 -ErrorAction SilentlyContinue).Source }
            $pyScript = Join-Path $script:CommonScriptDir "_decompress.py"
            if ($py -and (Test-Path $pyScript)) {
                $tmpJson = [System.IO.Path]::GetTempFileName()
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($tmpJson, $body, $utf8NoBom)
                $decoded = & $py $pyScript $tmpJson 2>$null
                Remove-Item $tmpJson -Force -ErrorAction SilentlyContinue
                $decStr = if ($decoded -is [array]) { $decoded -join "`n" } else { [string]$decoded }
                if ($decStr.Length -gt 10) { Write-Output $decStr; return }
            }
        } catch { }
    }
    Write-Output $body
}
