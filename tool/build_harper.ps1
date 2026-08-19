# PowerShell script to cross-compile Harper Rust bridge for Android ABIs
# Requires cargo and cargo-ndk installed (`cargo install cargo-ndk`)

param(
    [string]$TargetAbi = "all", # "arm64-v8a", "armeabi-v7a", "x86_64", "all"
    [string]$NdkPath = $env:ANDROID_NDK_HOME
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\.."
$RustBridgeDir = "$ProjectRoot\native\harper_bridge"
$JniLibsDir = "$ProjectRoot\android\app\src\main\jniLibs"

Write-Host "=== GrammarFix Harper Native Build ===" -ForegroundColor Green

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Warning "Rust toolchain (cargo) is not installed or not in PATH."
    Write-Warning "The app will use the high-performance Dart Rules Fallback engine."
    exit 0
}

$Targets = @{
    "arm64-v8a" = "aarch64-linux-android"
    "armeabi-v7a" = "armv7-linux-androideabi"
    "x86_64" = "x86_64-linux-android"
}

Push-Location $RustBridgeDir
try {
    foreach ($abi in $Targets.Keys) {
        if ($TargetAbi -ne "all" -and $TargetAbi -ne $abi) {
            continue
        }

        $targetTriple = $Targets[$abi]
        $outDir = "$JniLibsDir\$abi"
        if (-not (Test-Path $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }

        Write-Host "Building for $abi ($targetTriple)..." -ForegroundColor Cyan
        
        # Build with cargo-ndk if available, else regular cargo target
        if (Get-Command cargo-ndk -ErrorAction SilentlyContinue) {
            cargo ndk --target $targetTriple --platform 24 build --release
            $srcPath = "$RustBridgeDir\target\$targetTriple\release\libharper_bridge.so"
        } else {
            cargo build --target $targetTriple --release
            $srcPath = "$RustBridgeDir\target\$targetTriple\release\libharper_bridge.so"
        }

        if (Test-Path $srcPath) {
            Copy-Item $srcPath "$outDir\libharper_bridge.so" -Force
            Write-Host " Copied libharper_bridge.so to $outDir" -ForegroundColor Green
        }
    }
}
finally {
    Pop-Location
}

Write-Host "=== Harper Build Complete ===" -ForegroundColor Green
