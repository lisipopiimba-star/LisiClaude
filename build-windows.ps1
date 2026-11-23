# Сборка ISO на Windows через Docker Desktop:  powershell -ExecutionPolicy Bypass -File build-windows.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw "Docker Desktop не найден. Используйте сборку через GitHub Actions (см. README)." }
New-Item -ItemType Directory -Force -Path out | Out-Null
docker run --rm --privileged -v "${PWD}:/src:ro" -v "${PWD}\out:/out" archlinux:latest bash /src/scripts/build-in-container.sh
Write-Host "ISO лежит в: $PWD\out"
