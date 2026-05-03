$BuildsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServiceSuffix = " - Steam Update"
$TempDir = Join-Path $BuildsDir "__SteamUpdateTemp"

Set-Location $BuildsDir

$builds = Get-ChildItem -LiteralPath $BuildsDir -Directory |
    Where-Object {
        -not $_.Name.EndsWith($ServiceSuffix) -and
        -not $_.Name.StartsWith("__")
    } |
    Sort-Object Name

Write-Host "Available builds:"
Write-Host ""

if ($builds.Count -eq 0) {
    Write-Host "No builds found." -ForegroundColor Yellow
    exit
}

for ($i = 0; $i -lt $builds.Count; $i++) {
    Write-Host "$($i + 1). $($builds[$i].Name)"
}

Write-Host ""

do {
    $choice = Read-Host "Select build number"
    $index = 0
    $valid = [int]::TryParse($choice, [ref]$index) -and $index -ge 1 -and $index -le $builds.Count

    if (-not $valid) {
        Write-Host "Invalid choice." -ForegroundColor Yellow
    }
} until ($valid)

$BuildName = $builds[$index - 1].Name
$SourceDir = Join-Path $BuildsDir $BuildName
$UpdateDir = Join-Path $BuildsDir "$BuildName$ServiceSuffix"

$Timestamp = Get-Date -Format "yyyy-MM-dd HH-mm-ss"

$ArchivePath = Join-Path $BuildsDir "$BuildName - $Timestamp.zip"
$ChangeLog = Join-Path $BuildsDir "$BuildName - $Timestamp - changes.txt"

Write-Host ""
Write-Host "Selected build: `"$BuildName`""
Write-Host "Source: `"$SourceDir`""
Write-Host "Steam Update: `"$UpdateDir`""
Write-Host "Archive: `"$ArchivePath`""
Write-Host "Change log: `"$ChangeLog`""
Write-Host ""

if (!(Test-Path -LiteralPath $UpdateDir)) {
    New-Item -ItemType Directory -Force -Path $UpdateDir | Out-Null
}

if (Test-Path -LiteralPath $TempDir) {
    Remove-Item -LiteralPath $TempDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

if (Test-Path -LiteralPath $ChangeLog) {
    Remove-Item -LiteralPath $ChangeLog -Force
}

$changed = @()
$deleted = @()
$sourceMap = @{}

$sourceFiles = Get-ChildItem -LiteralPath $SourceDir -Recurse -File

foreach ($file in $sourceFiles) {
    $rel = $file.FullName.Substring($SourceDir.Length).TrimStart('\', '/')
    $sourceMap[$rel.ToLowerInvariant()] = $true

    $target = Join-Path $UpdateDir $rel
    $needCopy = $false
    $status = ""

    if (!(Test-Path -LiteralPath $target)) {
        $needCopy = $true
        $status = "NEW"
    } else {
        $targetFile = Get-Item -LiteralPath $target

        if ($file.Length -ne $targetFile.Length) {
            $needCopy = $true
            $status = "CHANGED SIZE"
        } else {
            $sourceHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash

            if ($sourceHash -ne $targetHash) {
                $needCopy = $true
                $status = "CHANGED HASH"
            }
        }
    }

    if ($needCopy) {
        $dest = Join-Path $TempDir $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $dest -Force

        $changed += "$status`t$rel"
    }
}

$updateFiles = Get-ChildItem -LiteralPath $UpdateDir -Recurse -File

foreach ($file in $updateFiles) {
    $rel = $file.FullName.Substring($UpdateDir.Length).TrimStart('\', '/')

    if (!$sourceMap.ContainsKey($rel.ToLowerInvariant())) {
        $deleted += $rel
    }
}

if ($changed.Count -gt 0) {
    "NEW OR CHANGED FILES:" | Out-File -LiteralPath $ChangeLog -Encoding UTF8
    $changed | Out-File -LiteralPath $ChangeLog -Encoding UTF8 -Append
    "" | Out-File -LiteralPath $ChangeLog -Encoding UTF8 -Append
}

if ($deleted.Count -gt 0) {
    "DELETED FILES:" | Out-File -LiteralPath $ChangeLog -Encoding UTF8 -Append
    $deleted | Out-File -LiteralPath $ChangeLog -Encoding UTF8 -Append

    Write-Host ""
    Write-Host "WARNING: DELETED FILES WERE FOUND!" -ForegroundColor Red
    Write-Host "THEY WILL BE REMOVED DURING SYNC." -ForegroundColor Red
}

if ($changed.Count -eq 0) {
    Write-Host ""
    Write-Host "NO NEW OR CHANGED FILES FOUND. ARCHIVE NOT CREATED." -ForegroundColor Yellow

    if (Test-Path -LiteralPath $ChangeLog) {
        Write-Host ""
        Write-Host "CHANGE LOG:" -ForegroundColor Cyan
        Write-Host $ChangeLog -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "Syncing Steam Update folder..."
    robocopy $SourceDir $UpdateDir /MIR /R:1 /W:1 /NP | Out-Null

    Remove-Item -LiteralPath $TempDir -Recurse -Force
    exit
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path -LiteralPath $ArchivePath) {
    Remove-Item -LiteralPath $ArchivePath -Force
}

[System.IO.Compression.ZipFile]::CreateFromDirectory($TempDir, $ArchivePath)

$size = (Get-Item -LiteralPath $ArchivePath).Length

if ($size -ge 1GB) {
    $archiveSize = "{0:N2} GB" -f ($size / 1GB)
} elseif ($size -ge 1MB) {
    $archiveSize = "{0:N2} MB" -f ($size / 1MB)
} elseif ($size -ge 1KB) {
    $archiveSize = "{0:N2} KB" -f ($size / 1KB)
} else {
    $archiveSize = "$size B"
}

Write-Host ""
Write-Host "ARCHIVE IS READY:" -ForegroundColor Green
Write-Host $ArchivePath -ForegroundColor Green
Write-Host "Size: $archiveSize" -ForegroundColor Green

Write-Host ""
Write-Host "CHANGE LOG:" -ForegroundColor Cyan
Write-Host $ChangeLog -ForegroundColor Cyan

Write-Host ""
Write-Host "Syncing Steam Update folder..."
robocopy $SourceDir $UpdateDir /MIR /R:1 /W:1 /NP | Out-Null

Remove-Item -LiteralPath $TempDir -Recurse -Force

Write-Host ""
Write-Host "App is done!"