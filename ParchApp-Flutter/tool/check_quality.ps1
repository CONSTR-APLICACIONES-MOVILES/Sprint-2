param([switch]$Scan)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
  flutter analyze --no-pub
  if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
  flutter test --no-pub --coverage
  if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
  dart run tool/coverage_summary.dart
  if ($LASTEXITCODE -ne 0) { throw 'Coverage summary failed.' }
  if ($Scan) {
    if (-not $env:SONAR_HOST_URL -or -not $env:SONAR_TOKEN) {
      throw 'Set SONAR_HOST_URL and SONAR_TOKEN for your authorized SonarQube instance.'
    }
    $languages = Invoke-RestMethod -Uri "$($env:SONAR_HOST_URL.TrimEnd('/'))/api/languages/list" -Headers @{ Authorization = "Bearer $env:SONAR_TOKEN" }
    if (-not ($languages.languages | Where-Object { $_.key -eq 'dart' })) {
      throw 'This SonarQube instance has no Dart analyzer. Do not interpret an empty Dart scan as a clean report.'
    }
    if (-not (Get-Command sonar-scanner -ErrorAction SilentlyContinue)) {
      throw 'Install the official SonarScanner CLI before requesting -Scan.'
    }
    sonar-scanner
    if ($LASTEXITCODE -ne 0) { throw 'SonarQube analysis or quality gate failed.' }
  }
} finally { Pop-Location }
