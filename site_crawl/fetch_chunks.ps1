$ErrorActionPreference = "Continue"
$base = "https://ssemarket.cn/new/assets"
$out  = Join-Path $PSScriptRoot "raw"
$ua   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
$chunks = Get-Content "$PSScriptRoot\chunks.txt"
$i = 0
foreach ($c in $chunks) {
  $i++
  $dest = Join-Path $out $c
  if (Test-Path $dest) { continue }
  & curl.exe -sL -f --compressed -A $ua -o $dest "$base/$c" 2>$null
  if ((Test-Path $dest) -and ((Get-Item $dest).Length -eq 0)) { Remove-Item $dest; Write-Host "FAIL $c" }
  Start-Sleep -Milliseconds 1000
}
Write-Host "done"
Get-ChildItem $out -Filter *.js | Measure-Object | Select-Object Count
