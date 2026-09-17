# fetch_site.ps1 - SSEMarket static asset fetcher (round 1)
# Usage:  powershell -ExecutionPolicy Bypass -File .\fetch_site.ps1
#         (run from the site_crawl folder, or any folder - output goes to .\raw)
# GET-only, 1s delay between requests, skips already-downloaded files (re-runnable).
# After it finishes, tell Claude so it can grep the JS and give you a round-2 URL list.

$ErrorActionPreference = "Continue"
$base  = "https://ssemarket.cn"
$out   = Join-Path $PSScriptRoot "raw"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$ua    = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"

function Get-Url($url, $dest) {
  $name = Split-Path $dest -Leaf
  if (Test-Path $dest) { Write-Host "SKIP $name"; return }
  Write-Host "GET  $url"
  & curl.exe -sL -f --compressed -A $ua -o $dest $url 2>$null
  if ((Test-Path $dest) -and ((Get-Item $dest).Length -eq 0)) { Remove-Item $dest }
  Start-Sleep -Seconds 1
}

# --- 1) entry page + robots/sitemap ---
Get-Url "$base/new/"        (Join-Path $out "index.html")
Get-Url "$base/robots.txt"  (Join-Path $out "robots.txt")
Get-Url "$base/sitemap.xml" (Join-Path $out "sitemap.xml")

# --- 2) parse index.html for JS/CSS assets ---
$indexPath = Join-Path $out "index.html"
if (Test-Path $indexPath) {
  $html = Get-Content $indexPath -Raw
  $refs = [regex]::Matches($html, '(?:src|href)\s*=\s*["'']([^"'' ]+?\.(?:js|mjs|css)(?:\?[^"'' ]*)?)["'']') |
          ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
  Write-Host ("found {0} asset refs" -f @($refs).Count)
  foreach ($r in $refs) {
    if     ($r -match "^https?://") { $u = $r }
    elseif ($r -match "^/")        { $u = $base + $r }
    else                            { $u = "$base/new/" + $r }
    $file = ($r -replace '\?.*$','') -split '/' | Where-Object { $_ } | Select-Object -Last 1
    if ($file) { Get-Url $u (Join-Path $out $file) }
  }
} else {
  Write-Host "WARN: index.html not downloaded - check network/URL"
}

# --- 3) probe source maps (jackpot if present) ---
Get-ChildItem $out -Filter *.js -ErrorAction SilentlyContinue | ForEach-Object {
  Get-Url ($_.FullName + ".map") ($_.FullName + ".map")
}

Write-Host ""
Write-Host "=== done. files in raw\ ==="
Get-ChildItem $out | Select-Object Name, Length | Format-Table -AutoSize
