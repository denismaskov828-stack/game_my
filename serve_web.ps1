$root = Join-Path $PSScriptRoot "web"
if (-not (Test-Path (Join-Path $root "index.html"))) {
    Write-Host "Web build not found in:" $root
    exit 1
}

$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".js" = "application/javascript"
    ".wasm" = "application/wasm"
    ".pck" = "application/octet-stream"
    ".png" = "image/png"
    ".json" = "application/json"
    ".css" = "text/css"
    ".txt" = "text/plain"
}

$port = 8765
$listener = $null
while ($port -le 8790 -and $listener -eq $null) {
    try {
        $candidate = New-Object System.Net.HttpListener
        $candidate.Prefixes.Add("http://127.0.0.1:$port/")
        $candidate.Start()
        $listener = $candidate
    } catch {
        $port += 1
    }
}
if ($listener -eq $null) {
    Write-Host "Could not start local server on ports 8765-8790."
    exit 1
}

Write-Host ""
Write-Host "  Yg Remastered - web build"
Write-Host "  Open: http://127.0.0.1:$port/"
Write-Host "  Close this window to stop the server."
Write-Host ""
Start-Process "http://127.0.0.1:$port/"

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $path = $ctx.Request.Url.AbsolutePath.TrimStart("/")
        if ([string]::IsNullOrWhiteSpace($path)) { $path = "index.html" }
        $file = Join-Path $root $path
        if (Test-Path $file -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
            else { $ctx.Response.ContentType = "application/octet-stream" }
            $ctx.Response.Headers.Add("Cross-Origin-Opener-Policy", "same-origin")
            $ctx.Response.Headers.Add("Cross-Origin-Embedder-Policy", "require-corp")
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
        }
        $ctx.Response.Close()
    } catch {
        break
    }
}
