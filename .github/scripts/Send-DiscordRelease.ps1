param(
    [Parameter(Mandatory)][string]$Version,
    [Parameter(Mandatory)][string]$ReleaseUrl,
    [Parameter(Mandatory)][string]$NotesPath
)

$ErrorActionPreference = 'Stop'
$webhook = $null
if (-not [uri]::TryCreate($env:DISCORD_WEBHOOK_URL, [UriKind]::Absolute, [ref]$webhook) -or $webhook.Scheme -ne 'https') {
    throw 'Configure o secret DISCORD_WEBHOOK_URL com a URL HTTPS do webhook.'
}

$endpoint = [UriBuilder]::new($webhook)
$query = [System.Web.HttpUtility]::ParseQueryString($endpoint.Query)
$query['wait'] = 'true'
$endpoint.Query = $query.ToString()

$notes = Get-Content -LiteralPath $NotesPath -Raw -Encoding utf8
$description = $notes
$attachNotes = $notes.Length -gt 4096
if ($attachNotes) {
    $suffix = "`n`n… Leia as notas completas no arquivo anexado."
    $length = 4096 - $suffix.Length
    if ([char]::IsHighSurrogate($notes[$length - 1])) { $length-- }
    $description = $notes.Substring(0, $length).TrimEnd() + $suffix
}

$payload = @{
    allowed_mentions = @{ parse = @() }
    embeds = @(@{
        author = @{ name = 'Tech Repair Simulator' }
        title = '🚀 NOVA ATUALIZAÇÃO DISPONÍVEL!'
        url = $ReleaseUrl
        color = 0x25B8A6
        description = $description
        fields = @(
            @{ name = 'Versão'; value = $Version; inline = $true }
            @{ name = 'GitHub'; value = "[Abrir release]($ReleaseUrl)"; inline = $true }
        )
    })
}
$json = ConvertTo-Json -InputObject $payload -Depth 6 -Compress
$request = @{
    Uri = $endpoint.Uri
    Method = 'Post'
    ConnectionTimeoutSeconds = 20
    OperationTimeoutSeconds = 20
    MaximumRedirection = 0
    MaximumRetryCount = 0
    SkipHttpErrorCheck = $true
    Verbose = $false
    Debug = $false
}
if ($attachNotes) {
    $request.Form = @{ payload_json = $json; 'files[0]' = Get-Item -LiteralPath $NotesPath }
} else {
    $request.ContentType = 'application/json; charset=utf-8'
    $request.Body = $json
}

try {
    $response = Invoke-WebRequest @request
} catch {
    throw 'Falha de conexão ao anunciar a release no Discord.'
}
if ([int]$response.StatusCode -ne 200) {
    throw "O Discord não confirmou o anúncio (HTTP $([int]$response.StatusCode))."
}
Write-Output "Discord confirmou o anúncio da release $Version."
