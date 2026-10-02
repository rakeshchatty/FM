[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $IssueKey,

    [Parameter(Mandatory = $false)]
    [string] $CommentFile,

    [string] $CommentText,

    [string] $TokenPath
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$baseUrl = 'https://rakeshchatty.atlassian.net'
$gitEmail = & git -C $repositoryRoot config --get user.email 2>$null
$issueInput = $IssueKey.Trim()

if ($issueInput -match '^https://rakeshchatty\.atlassian\.net/browse/([A-Za-z][A-Za-z0-9_]*-[0-9]+)/?$') {
    $IssueKey = $Matches[1]
} elseif ($issueInput -notmatch '^[A-Za-z][A-Za-z0-9_]*-[0-9]+$') {
    throw 'IssueKey must be a Jira key such as CRMFM-1 or a Jira browse URL from this site.'
} else {
    $IssueKey = $issueInput
}

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitEmail)) {
    throw 'Git user.email is not configured. Set it with git config user.email <your-email>.'
}
$email = $gitEmail.Trim()

if ([string]::IsNullOrWhiteSpace($TokenPath)) {
    $TokenPath = Join-Path $repositoryRoot '.jira-token'
}

$resolvedTokenPath = [IO.Path]::GetFullPath($TokenPath)
if (-not (Test-Path -LiteralPath $resolvedTokenPath -PathType Leaf)) {
    throw "Jira token file was not found at $resolvedTokenPath."
}

$token = (Get-Content -LiteralPath $resolvedTokenPath -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($token)) {
    throw 'The Jira token file is empty.'
}

if (-not [string]::IsNullOrWhiteSpace($CommentText)) {
    $comment = $CommentText.Trim()
} elseif (-not [string]::IsNullOrWhiteSpace($CommentFile)) {
    $resolvedCommentFile = [IO.Path]::GetFullPath($CommentFile)
    if (-not (Test-Path -LiteralPath $resolvedCommentFile -PathType Leaf)) {
        throw "Comment file was not found at $resolvedCommentFile."
    }

    $comment = (Get-Content -LiteralPath $resolvedCommentFile -Raw).Trim()
} else {
    throw 'Provide either CommentText or CommentFile.'
}

if ([string]::IsNullOrWhiteSpace($comment)) {
    throw 'The Jira comment is empty.'
}

$paragraphs = foreach ($line in ($comment -split "`r?`n", -1)) {
    if ([string]::IsNullOrEmpty($line)) {
        [PSCustomObject]@{
            type = 'paragraph'
            content = @()
        }
    } else {
        [PSCustomObject]@{
            type = 'paragraph'
            content = @(
                [PSCustomObject]@{
                    type = 'text'
                    text = $line
                }
            )
        }
    }
}

$payload = @{
    body = @{
        type = 'doc'
        version = 1
        content = @($paragraphs)
    }
} | ConvertTo-Json -Depth 20

$normalizedBaseUrl = $baseUrl.TrimEnd('/')
$encodedIssueKey = [Uri]::EscapeDataString($IssueKey)
$uri = '{0}/rest/api/3/issue/{1}/comment' -f $normalizedBaseUrl, $encodedIssueKey
$credentialValue = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$email`:$token"))

try {
    $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
        Authorization = "Basic $credentialValue"
        Accept = 'application/json'
    } -ContentType 'application/json' -Body $payload

    [PSCustomObject]@{
        issueKey = $IssueKey
        commentId = $response.id
        url = '{0}/browse/{1}?focusedCommentId={2}' -f $normalizedBaseUrl, $encodedIssueKey, $response.id
    } | ConvertTo-Json -Depth 5
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401 -or $statusCode -eq 403) {
        throw "Jira comment request was not authorized for $IssueKey. Check the configured Jira account permissions."
    }
    if ($statusCode -eq 404) {
        throw "Jira issue $IssueKey was not found or is not visible to the configured Jira account."
    }
    if ($null -ne $statusCode) {
        throw "Jira comment request failed for $IssueKey with HTTP status $statusCode."
    }
    throw "Jira comment request failed for $IssueKey."
}
