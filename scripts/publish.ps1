# publish.ps1 — อัปโปรเจกต์ Bangchak ขึ้น GitHub เพื่อให้ Actions build IPA ให้
#
#   .\scripts\publish.ps1 -RepoUrl https://github.com/<user>/<repo>.git
#
# ถ้ายังไม่มี git:  winget install --id Git.Git -e --source winget
# (หลังติดตั้งให้ปิดแล้วเปิด terminal ใหม่)

param(
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl,

    [string]$Message = "Bangchak build"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "==> project: $root"

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    # fresh installs are not on PATH until the terminal is reopened
    $fallback = "C:\Program Files\Git\cmd\git.exe"
    if (Test-Path $fallback) {
        $git = Get-Item $fallback
        $env:Path = "$(Split-Path $fallback)::$env:Path"
    }
}
if (-not $git) {
    Write-Host "git not found." -ForegroundColor Red
    Write-Host "install:  winget install --id Git.Git -e --source winget"
    Write-Host "then reopen the terminal and run this script again."
    exit 1
}

if (-not (Get-Command xcodegen -ErrorAction SilentlyContinue)) {
    Write-Host "note: xcodegen not needed, Bangchak.xcodeproj is committed." -ForegroundColor DarkGray
}

if (-not (Test-Path "Bangchak.xcodeproj\project.pbxproj")) {
    Write-Host "Bangchak.xcodeproj missing. run this script from inside the Bangchak folder." -ForegroundColor Red
    exit 1
}

$identity = (git config --global user.email) 2>$null
if (-not $identity) {
    Write-Host "==> git identity not set, using a local placeholder" -ForegroundColor Yellow
    git config --global user.email "bangchak@local"
    git config --global user.name "Bangchak Builder"
}

if (-not (Test-Path ".git")) {
    Write-Host "==> git init"
    git init | Out-Null
    git branch -M main
}

Write-Host "==> staging"
git add -A

$status = git status --porcelain
if ($status) {
    Write-Host "==> commit"
    git commit -m "$Message" | Out-Null
} else {
    Write-Host "==> nothing new to commit"
}

$currentRemote = ""
$remotes = git remote 2>$null
if ($remotes -contains "origin") {
    $currentRemote = (git remote get-url origin)
}

if ($currentRemote -ne $RepoUrl) {
    if ($currentRemote) {
        Write-Host "==> update origin -> $RepoUrl"
        git remote set-url origin $RepoUrl
    } else {
        Write-Host "==> add origin -> $RepoUrl"
        git remote add origin $RepoUrl
    }
}

Write-Host "==> push"
git push -u origin main

Write-Host ""
Write-Host "done. open:" -ForegroundColor Green
Write-Host "  $($RepoUrl -replace '\.git$','')/actions"
Write-Host "wait ~6 minutes, then download artifact 'Bangchak-ipa'."
