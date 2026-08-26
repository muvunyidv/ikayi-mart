# Builds the Flutter website with Google Sign-In and publishes it to gh-pages.
# GitHub Pages can keep tracking the gh-pages branch (no GitHub Actions Pages).
#
# Usage (from the repo root, in PowerShell):
#   $env:GOOGLE_CLIENT_ID = "your-id.apps.googleusercontent.com"
#   .\scripts\deploy-gh-pages.ps1

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$clientId = $env:GOOGLE_CLIENT_ID
if ([string]::IsNullOrWhiteSpace($clientId)) {
    throw @"
GOOGLE_CLIENT_ID is not set in this terminal.

Run this first (use your Web client ID, not the secret):
  `$env:GOOGLE_CLIENT_ID = "xxxxx.apps.googleusercontent.com"
  .\scripts\deploy-gh-pages.ps1
"@
}

$origin = git remote get-url origin
if (-not $origin) {
    throw "No git remote named origin."
}

Write-Host "Building Flutter web with Google Client ID..."
Push-Location (Join-Path $repoRoot "frontend")
try {
    flutter pub get
    flutter build web --release --base-href / --dart-define=GOOGLE_CLIENT_ID="$clientId"
}
finally {
    Pop-Location
}

$buildDir = Join-Path $repoRoot "frontend\build\web"
$indexHtml = Join-Path $buildDir "index.html"
if (-not (Test-Path $indexHtml)) {
    throw "Build failed: frontend/build/web/index.html was not created."
}

# GitHub Pages has no SPA rewrite. Serving the built app as 404.html keeps
# deep links (/vendor, /login, etc.) working after refresh or crash recovery.
Copy-Item -Path $indexHtml -Destination (Join-Path $buildDir "404.html") -Force

Set-Content -Path (Join-Path $buildDir "CNAME") -Value "mart.ikayi.app"
New-Item -Path (Join-Path $buildDir ".nojekyll") -ItemType File -Force | Out-Null

$work = Join-Path $env:TEMP "ikayi-mart-gh-pages"
if (Test-Path $work) {
    Remove-Item $work -Recurse -Force
}

Write-Host "Updating gh-pages branch..."
$cloned = $false
try {
    git clone --branch gh-pages --single-branch $origin $work
    $cloned = $true
}
catch {
    $cloned = $false
}

if (-not $cloned) {
    if (Test-Path $work) {
        Remove-Item $work -Recurse -Force
    }
    New-Item -ItemType Directory -Path $work | Out-Null
    Push-Location $work
    try {
        git init
        git checkout -b gh-pages
        git remote add origin $origin
    }
    finally {
        Pop-Location
    }
}

Get-ChildItem -Path $work -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force
Copy-Item -Path (Join-Path $buildDir "*") -Destination $work -Recurse -Force

Push-Location $work
try {
    git add -A
    $status = git status --porcelain
    if (-not $status) {
        Write-Host "gh-pages is already up to date."
        return
    }
    git -c user.email="deploy@ikayi.app" -c user.name="IKAYIMART deploy" commit -m "Deploy Flutter web with Google Sign-In"
    git push origin gh-pages
}
finally {
    Pop-Location
}

Write-Host "Done. GitHub Pages will redeploy from gh-pages. Hard-refresh mart.ikayi.app after a minute."
