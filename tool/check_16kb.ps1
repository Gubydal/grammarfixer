param(
  [string]$AabPath = "build\app\outputs\bundle\release\app-release.aab"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$workspace = (Get-Location).Path
$aab = Join-Path $workspace $AabPath
if (-not (Test-Path -LiteralPath $aab)) {
  throw "AAB not found: $aab"
}

$scratch = Join-Path $workspace ".scratch\16kb-check"
if (Test-Path -LiteralPath $scratch) {
  Remove-Item -LiteralPath $scratch -Recurse -Force
}
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

$zip = [System.IO.Compression.ZipFile]::OpenRead($aab)
$entries = @($zip.Entries | Where-Object { $_.FullName -like "base/lib/*/lib*.so" })
$results = @()

try {
  foreach ($entry in $entries) {
    $outPath = Join-Path $scratch ([System.IO.Path]::GetFileName($entry.FullName))
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $outPath, $true)

    $fs = [System.IO.File]::OpenRead($outPath)
    $reader = New-Object System.IO.BinaryReader($fs)
    try {
      $null = $reader.ReadInt32() # ELF magic
      $class = $reader.ReadByte() # 1 = 32-bit, 2 = 64-bit
      $is64 = $class -eq 2

      if ($is64) {
        $null = $fs.Seek(32, [System.IO.SeekOrigin]::Begin)
        $phoff = [int64]$reader.ReadUInt64()
        $null = $fs.Seek(54, [System.IO.SeekOrigin]::Begin)
        $phentsize = $reader.ReadUInt16()
        $null = $fs.Seek(56, [System.IO.SeekOrigin]::Begin)
        $phnum = $reader.ReadUInt16()
      } else {
        $null = $fs.Seek(28, [System.IO.SeekOrigin]::Begin)
        $phoff = [int64]$reader.ReadUInt32()
        $null = $fs.Seek(42, [System.IO.SeekOrigin]::Begin)
        $phentsize = $reader.ReadUInt16()
        $null = $fs.Seek(44, [System.IO.SeekOrigin]::Begin)
        $phnum = $reader.ReadUInt16()
      }

      $aligns = @()
      for ($i = 0; $i -lt $phnum; $i++) {
        $base = [int64]($phoff + $i * $phentsize)
        $null = $fs.Seek($base, [System.IO.SeekOrigin]::Begin)
        $ptype = $reader.ReadUInt32()
        if ($ptype -eq 1) { # PT_LOAD
          if ($is64) {
            $null = $fs.Seek($base + 48, [System.IO.SeekOrigin]::Begin)
            $aligns += $reader.ReadUInt64()
          } else {
            $null = $fs.Seek($base + 28, [System.IO.SeekOrigin]::Begin)
            $aligns += $reader.ReadUInt32()
          }
        }
      }

      $minAlign = if ($aligns.Count -gt 0) { ($aligns | Measure-Object -Minimum).Minimum } else { 0 }
      $results += [pscustomobject]@{
        Lib      = $entry.FullName
        MinAlign = $minAlign
        Pass     = ($minAlign -ge 16384)
      }
    } finally {
      $reader.Dispose()
      $fs.Dispose()
    }
  }
} finally {
  $zip.Dispose()
}

$results | Format-Table -AutoSize
$failed = @($results | Where-Object { -not $_.Pass })
if ($failed.Count -gt 0) {
  Write-Output "FAILED: $($failed.Count) libraries are not 16KB-aligned."
  exit 1
}

Write-Output "PASS: all native libraries have PT_LOAD alignment >= 16384 (16KB)."

$resolvedScratch = (Resolve-Path -LiteralPath $scratch).Path
if ($resolvedScratch.StartsWith($workspace)) {
  Remove-Item -LiteralPath $resolvedScratch -Recurse -Force
}
