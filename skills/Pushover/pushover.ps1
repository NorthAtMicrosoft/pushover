<#
.SYNOPSIS
    Send a push notification via the Pushover API.

.DESCRIPTION
    Portable PowerShell script (works on PowerShell 5.1+ and PowerShell Core 7+).
    Reads PUSHOVER_USER_KEY and PUSHOVER_API_TOKEN from environment variables.

.EXAMPLE
    .\pushover.ps1 -Message "Hello world"

.EXAMPLE
    .\pushover.ps1 -Message "Build failed!" -Title "CI Alert" -Priority 1 -Sound "siren"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Notification message body")]
    [string]$Message,

    [string]$Title = "Copilot Notification",

    [ValidateRange(-2, 2)]
    [int]$Priority = 0,

    [string]$Sound,

    [string]$Url,

    [string]$UrlTitle,

    [string]$Device,

    [switch]$Html
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Validate environment ─────────────────────────────────────────────────────

$UserKey  = $env:PUSHOVER_USER_KEY
$ApiToken = $env:PUSHOVER_API_TOKEN

if (-not $UserKey) {
    Write-Error "PUSHOVER_USER_KEY is not set. Set it with: `$env:PUSHOVER_USER_KEY = 'your-key'"
    exit 1
}

if (-not $ApiToken) {
    Write-Error "PUSHOVER_API_TOKEN is not set. Set it with: `$env:PUSHOVER_API_TOKEN = 'your-token'"
    exit 1
}

# ── Build request body ───────────────────────────────────────────────────────

$Body = @{
    token    = $ApiToken
    user     = $UserKey
    message  = $Message
    title    = $Title
    priority = $Priority
}

if ($Sound)    { $Body["sound"]     = $Sound }
if ($Url)      { $Body["url"]       = $Url }
if ($UrlTitle) { $Body["url_title"] = $UrlTitle }
if ($Device)   { $Body["device"]    = $Device }
if ($Html)     { $Body["html"]      = "1" }

# Emergency priority requires retry and expire
if ($Priority -eq 2) {
    $Body["retry"]  = 60
    $Body["expire"] = 3600
}

# ── Send request ─────────────────────────────────────────────────────────────

$ApiUrl = "https://api.pushover.net/1/messages.json"

try {
    # Invoke-RestMethod is available in PowerShell 3.0+ (ships with Win 8+)
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body
}
catch {
    $StatusCode = $null
    if ($_.Exception.Response) {
        $StatusCode = [int]$_.Exception.Response.StatusCode
    }
    Write-Error "Pushover API request failed. HTTP status: $StatusCode — $_"
    exit 2
}

# ── Report result ────────────────────────────────────────────────────────────

if ($Response.status -eq 1) {
    Write-Host "OK: Notification sent successfully."
    Write-Host ($Response | ConvertTo-Json -Compress)
    exit 0
}
else {
    $json = $Response | ConvertTo-Json -Compress
    Write-Error "Pushover API returned an error: $json"
    exit 2
}
