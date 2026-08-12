param(
  [string]$AppName,
  [string]$PackageId,
  [string]$Destination,
  [switch]$NoPubGet
)

$ErrorActionPreference = "Stop"

$TemplateRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($AppName)) {
  $AppName = Read-Host "App name (e.g. My App)"
}

# Slug convention: lowercase, non-alphanumeric characters removed
# (valid Dart package name), e.g. "My App" -> "myapp".
$Slug = ($AppName.ToLowerInvariant() -replace "[^a-z0-9]+", "")

if ([string]::IsNullOrWhiteSpace($Slug)) {
  throw "Could not derive a slug from the app name."
}

if ([string]::IsNullOrWhiteSpace($PackageId)) {
  $PackageId = "com.mo.$Slug"
}

if ([string]::IsNullOrWhiteSpace($Destination)) {
  $Destination = Join-Path (Split-Path -Parent $TemplateRoot) $Slug
}

$Destination = [System.IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $Destination) {
  throw "Destination already exists: $Destination"
}

$Schema = "app_$Slug"

Write-Host "Creating $AppName ($Slug) at $Destination" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $Destination -Force | Out-Null

Get-ChildItem -LiteralPath $TemplateRoot -Force | Where-Object {
  $_.Name -notin @(".git", ".dart_tool", "build", ".idea", ".scratch") -and
  $_.FullName -ne $Destination
} | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
}

function Replace-InFile([string]$Path, [string]$Old, [string]$New) {
  $content = Get-Content -LiteralPath $Path -Raw
  $content = $content.Replace($Old, $New)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $content, $utf8NoBom)
}

# ---------------------------------------------------------------- identity --

# Dart package + config defaults
Replace-InFile "$Destination\pubspec.yaml" "name: app_starter" "name: $Slug"
Replace-InFile "$Destination\lib\core\config\app_config.dart" "defaultValue: 'App Starter'" "defaultValue: '$AppName'"
Replace-InFile "$Destination\lib\core\config\app_config.dart" "defaultValue: 'starter'" "defaultValue: '$Slug'"
Replace-InFile "$Destination\lib\core\config\app_config.dart" "defaultValue: 'com.mo.starter'" "defaultValue: '$PackageId'"
Replace-InFile "$Destination\lib\core\config\app_config.dart" "defaultValue: 'app_starter'" "defaultValue: '$Schema'"

# Rewrite Dart package references (lib + test imports)
Get-ChildItem -LiteralPath "$Destination\lib", "$Destination\test" -Recurse -Filter *.dart | ForEach-Object {
  Replace-InFile $_.FullName "package:app_starter" "package:$Slug"
}

# Android identity
Replace-InFile "$Destination\android\app\build.gradle" "com.mo.starter" $PackageId
Replace-InFile "$Destination\android\app\src\main\AndroidManifest.xml" "App Starter" $AppName
Replace-InFile "$Destination\android\app\src\main\AndroidManifest.xml" "com.mo.starter" $PackageId

# Move MainActivity to the new package path
$OldKotlinDir = "$Destination\android\app\src\main\kotlin\com\mo\starter"
$NewKotlinPath = $PackageId.Replace(".", "\")
$NewKotlinDir = Join-Path "$Destination\android\app\src\main\kotlin" $NewKotlinPath
if ($OldKotlinDir -ne $NewKotlinDir) {
  New-Item -ItemType Directory -Path $NewKotlinDir -Force | Out-Null
  Move-Item -LiteralPath "$OldKotlinDir\MainActivity.kt" -Destination "$NewKotlinDir\MainActivity.kt" -Force
  Remove-Item -LiteralPath $OldKotlinDir -Recurse -Force
}
Replace-InFile "$NewKotlinDir\MainActivity.kt" "package com.mo.starter" "package $PackageId"

# -------------------------------------------------------------- supabase --

Replace-InFile "$Destination\supabase\sql\app_schema.sql" "app_starter" $Schema
Replace-InFile "$Destination\supabase\functions\delete-account\index.ts" '"app_starter"' ('"' + $Schema + '"')

# ------------------------------------------------------------ per-app json --

$ExampleConfig = "$Destination\dart_defines\example.json"
$AppConfigPath = "$Destination\dart_defines\$Slug.json"
Copy-Item -LiteralPath $ExampleConfig -Destination $AppConfigPath -Force
Replace-InFile $AppConfigPath '"APP_NAME": "App Starter"' ('"APP_NAME": "' + $AppName + '"')
Replace-InFile $AppConfigPath '"APP_SLUG": "starter"' ('"APP_SLUG": "' + $Slug + '"')
Replace-InFile $AppConfigPath '"APPLICATION_ID": "com.mo.starter"' ('"APPLICATION_ID": "' + $PackageId + '"')
Replace-InFile $AppConfigPath '"SUPABASE_SCHEMA": "app_starter"' ('"SUPABASE_SCHEMA": "' + $Schema + '"')
Replace-InFile $AppConfigPath '"DEEP_LINK_SCHEME": "com.mo.starter"' ('"DEEP_LINK_SCHEME": "' + $PackageId + '"')

$ConfigJson = Get-Content -LiteralPath $AppConfigPath -Raw | ConvertFrom-Json
Replace-InFile "$Destination\android\app\src\main\AndroidManifest.xml" "ca-app-pub-3940256099942544~3347511713" $ConfigJson.ADMOB_APP_ID

# ------------------------------------------------------------- setup doc --

$SetupDoc = "$Destination\docs\setup\$Slug-setup.md"
New-Item -ItemType Directory -Path (Split-Path -Parent $SetupDoc) -Force | Out-Null
$setupLines = @(
  "# $AppName Setup Checklist",
  "",
  "Fill in the real values below after copying the template with tool/new_app.ps1.",
  "",
  "## 1. Supabase",
  "",
  "- Create one Supabase project (or reuse the shared one).",
  "- Run supabase/sql/app_schema.sql in the SQL editor (schema: $Schema).",
  "- Add $Schema to Project Settings -> API -> Exposed schemas.",
  "- Authentication -> Providers: enable Email and Google; add the Google web client ID.",
  "- Authentication -> URL Configuration -> Redirect URLs: add ${PackageId}://callback.",
  "- Deploy the deletion function: supabase functions deploy delete-account.",
  "",
  "## 2. Google Sign-In",
  "",
  "- Create a Web client ID in Google Cloud Console and put it in dart_defines/$Slug.json (GOOGLE_WEB_CLIENT_ID).",
  "- Register Android clients for $PackageId with debug, upload, and Play App Signing SHA-1 fingerprints.",
  "",
  "## 3. RevenueCat",
  "",
  "- Create a project, an SDK key, a pro entitlement, and a current offering with monthly/annual packages. Put the SDK key in REVENUECAT_API_KEY.",
  "",
  "## 4. AdMob",
  "",
  "- Create an app + ad units and put the IDs in dart_defines/$Slug.json. Test IDs are the defaults.",
  "",
  "## 5. Legal URLs",
  "",
  "- Legal URLs default to https://$Slug.mogate.tech/privacy, https://$Slug.mogate.tech/terms, and https://$Slug.mogate.tech/delete-account.",
  "- Set explicit overrides in dart_defines/$Slug.json if needed.",
  "",
  "## 6. Run",
  "",
  '```powershell',
  "flutter run --dart-define-from-file=dart_defines/$Slug.json",
  '```'
)
$setupContent = $setupLines -join "`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($SetupDoc, $setupContent, $utf8NoBom)

# ------------------------------------------------------------- pub get --

if (-not $NoPubGet) {
  Push-Location $Destination
  try {
    flutter pub get
  }
  finally {
    Pop-Location
  }
}

Write-Host ""
Write-Host "Next steps for ${AppName}:" -ForegroundColor Green
Write-Host "  1. Edit dart_defines\${Slug}.json with your Supabase, Google, RevenueCat, and AdMob values."
Write-Host "  2. Run: flutter run --dart-define-from-file=dart_defines\${Slug}.json"
Write-Host "  3. Run supabase\sql\app_schema.sql (schema ${Schema})."
Write-Host "  4. Deploy supabase\functions\delete-account and add ${PackageId}://callback as a Supabase redirect URL."
Write-Host "  5. Replace the paywall benefits in lib\features\subscriptions\domain\entities\paywall_content.dart and the Home feature section."
Write-Host "  6. Replace the launcher icon and docs\legal placeholder pages with app-specific content."
