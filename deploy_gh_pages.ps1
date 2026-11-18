# Deploy CPAL Web App to GitHub Pages
param(
    [switch]$Push = $false
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " CPAL: Building Web App for GitHub Pages  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Build Flutter Web with base-href /cpal/
Write-Host "`n[1/3] Compiling Flutter Web with base href /cpal/..." -ForegroundColor Yellow
flutter build web --release --base-href /cpal/

# 2. Add 404.html and .nojekyll
Write-Host "[2/3] Adding 404.html and .nojekyll for GitHub Pages SPA support..." -ForegroundColor Yellow
Copy-Item build\web\index.html build\web\404.html -Force
New-Item -ItemType File -Path build\web\.nojekyll -Force | Out-Null

Write-Host "`n[3/3] Build completed successfully in build\web!" -ForegroundColor Green
Write-Host "Base href: /cpal/" -ForegroundColor Gray
Write-Host "Offline Cache: Service Worker (sw.js) active" -ForegroundColor Gray
Write-Host "PWA Shortcut: Instagram-style Add-to-Home-Screen active" -ForegroundColor Gray

# 3. Optional direct push to gh-pages branch
if ($Push) {
    Write-Host "`nDeploying directly to origin gh-pages branch..." -ForegroundColor Cyan
    $tempDir = Join-Path $env:TEMP ("cpal_deploy_" + [System.Guid]::NewGuid().ToString("N"))
    try {
        Copy-Item -Recurse -Force build\web $tempDir
        Push-Location $tempDir
        git init -b gh-pages
        git add -A
        git commit -m "Deploy CPAL web app with PWA and offline caching"
        git remote add origin https://github.com/Dipesh1997/cpal.git
        git push origin gh-pages --force
        Write-Host "`nSuccessfully pushed to gh-pages branch!" -ForegroundColor Green
        Write-Host "Your web app will be live at: https://dipesh1997.github.io/cpal/" -ForegroundColor Green
    }
    finally {
        Pop-Location
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "`nTo push directly to GitHub Pages branch, run:" -ForegroundColor Yellow
    Write-Host "  .\deploy_gh_pages.ps1 -Push" -ForegroundColor White
    Write-Host "`nOr simply push your code to the 'main' branch to trigger the automatic GitHub Actions workflow:" -ForegroundColor Yellow
    Write-Host "  git add ." -ForegroundColor White
    Write-Host "  git commit -m 'Configure GitHub Pages PWA with offline caching and Android WebView'" -ForegroundColor White
    Write-Host "  git push origin main" -ForegroundColor White
}
