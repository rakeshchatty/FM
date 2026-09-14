[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $IssueKey,

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

if ([string]::IsNullOrWhiteSpace($TokenPath)) {
    $TokenPath = Join-Path $repositoryRoot '.jira-token'
}

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitEmail)) {
    throw 'Git user.email is not configured. Set it with git config user.email <your-email>.'
}
$email = $gitEmail.Trim()

$resolvedTokenPath = [IO.Path]::GetFullPath($TokenPath)
if (-not (Test-Path -LiteralPath $resolvedTokenPath -PathType Leaf)) {
    throw "Jira token file was not found at $resolvedTokenPath."
}

$token = (Get-Content -LiteralPath $resolvedTokenPath -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($token)) {
    throw 'The Jira token file is empty.'
}

$normalizedBaseUrl = $baseUrl.TrimEnd('/')
$encodedIssueKey = [Uri]::EscapeDataString($IssueKey)
$uri = '{0}/rest/api/3/issue/{1}?fields=summary,status,description,issuetype,priority,assignee,reporter,labels,comment' -f $normalizedBaseUrl, $encodedIssueKey
$credentialValue = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$email`:$token"))

try {
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{
        Authorization = "Basic $credentialValue"
        Accept = 'application/json'
    }

    [PSCustomObject]@{
        key = $response.key
        summary = $response.fields.summary
        status = $response.fields.status.name
        issueType = $response.fields.issuetype.name
        priority = $response.fields.priority.name
        assignee = $response.fields.assignee.displayName
        reporter = $response.fields.reporter.displayName
        labels = $response.fields.labels
        description = $response.fields.description
        comments = $response.fields.comment.comments
        url = "$normalizedBaseUrl/browse/$encodedIssueKey"
    } | ConvertTo-Json -Depth 20
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 404) {
        throw "Jira issue $IssueKey was not found or is not visible to the configured Jira account. Check the issue key and project permissions."
    }
    throw "Jira request failed for ${IssueKey}: $($_.Exception.Message)"
}