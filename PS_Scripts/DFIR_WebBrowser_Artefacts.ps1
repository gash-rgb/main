# =========================================
# DFIR Browser Artifact Collector
# - Chrome / Edge / Firefox
# - Manifest CSV + Errors.log + Artifacts zipped
# By SecOps Team
# =========================================

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$TempDir   = "C:\Temp\Browser_Artifacts_$Timestamp"
$ZipFile   = "C:\Temp\Browser_Artifacts_$Timestamp.zip"
$Manifest  = Join-Path $TempDir "Manifest.csv"
$ErrorLog  = Join-Path $TempDir "Errors.log"

New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
"OriginalPath,Browser,Profile,FileName,SizeBytes,CreationTimeUtc,LastWriteTimeUtc,LastAccessTimeUtc" |
    Out-File -FilePath $Manifest -Encoding UTF8

function Add-ToManifest {
    param([string]$OrigPath,[string]$Browser,[string]$Profile)
    if (Test-Path $OrigPath) {
        try {
            $fi = Get-Item $OrigPath -ErrorAction Stop
            "$($fi.FullName),$Browser,$Profile,$($fi.Name),$($fi.Length),$($fi.CreationTimeUtc),$($fi.LastWriteTimeUtc),$($fi.LastAccessTimeUtc)" |
                Out-File -FilePath $Manifest -Append -Encoding UTF8
        } catch {
            "$OrigPath,$Browser,$Profile,ERROR,$($_.Exception.Message)" | Out-File -FilePath $ErrorLog -Append -Encoding UTF8
        }
    }
}

function Copy-IfExists {
    param([string]$SourcePath,[string]$DestinationPath,[string]$Browser,[string]$Profile,[switch]$UseRoboCopy)
    if (Test-Path $SourcePath) {
        try {
            $destDir = Split-Path $DestinationPath
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }

            if ($UseRoboCopy) {
                # Robocopy
                $cmd = "robocopy `"$SourcePath`" `"$DestinationPath`" /E /COPYALL /R:0 /W:0 /NFL /NDL /NJH /NJS /nc /ns /np"
                cmd.exe /c $cmd | Out-Null
            } else {
                Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force -ErrorAction Stop
            }
            Add-ToManifest -OrigPath $SourcePath -Browser $Browser -Profile $Profile
        } catch {
            "$SourcePath,$Browser,$Profile,COPY_ERROR,$($_.Exception.Message)" | Out-File -FilePath $ErrorLog -Append -Encoding UTF8
        }
    }
}

# For Each Local Users
$UserProfiles = Get-ChildItem "C:\Users" -Directory |
    Where-Object { $_.Name -notin @("Default", "Default User", "Public", "All Users") }

foreach ($User in $UserProfiles) {
    $UserOut = Join-Path $TempDir $User.Name
    New-Item -ItemType Directory -Force -Path $UserOut | Out-Null

    # ---------- Chrome ----------
    $ChromeDefault = Join-Path $User.FullName "AppData\Local\Google\Chrome\User Data\Default"
    if (Test-Path $ChromeDefault) {
        $ChromeOut = Join-Path $UserOut "Chrome\Default"
        $ChromeItems = @(
            "History","Cookies","Login Data","Bookmarks","Preferences","Secure Preferences",
            "Top Sites","Favicons","Visited Links","Web Data"
        )
        foreach ($item in $ChromeItems) {
            Copy-IfExists -SourcePath (Join-Path $ChromeDefault $item) -DestinationPath (Join-Path $ChromeOut $item) -Browser "Chrome" -Profile "Default"
        }
        # Extensions (robocopy)
        $ChromeExtensions = Join-Path $ChromeDefault "Extensions"
        Copy-IfExists -SourcePath $ChromeExtensions -DestinationPath (Join-Path $ChromeOut "Extensions") -Browser "Chrome" -Profile "Default" -UseRoboCopy

        # Local State
        $LocalState = Join-Path $User.FullName "AppData\Local\Google\Chrome\User Data\Local State"
        Copy-IfExists -SourcePath $LocalState -DestinationPath (Join-Path $UserOut "Chrome\Local State") -Browser "Chrome" -Profile "Default"
    }

    # ---------- Edge ----------
    $EdgeDefault = Join-Path $User.FullName "AppData\Local\Microsoft\Edge\User Data\Default"
    if (Test-Path $EdgeDefault) {
        $EdgeOut = Join-Path $UserOut "Edge\Default"
        $EdgeItems = @(
            "History","Cookies","Login Data","Bookmarks","Preferences","Secure Preferences",
            "Top Sites","Favicons","Visited Links","Web Data"
        )
        foreach ($item in $EdgeItems) {
            Copy-IfExists -SourcePath (Join-Path $EdgeDefault $item) -DestinationPath (Join-Path $EdgeOut $item) -Browser "Edge" -Profile "Default"
        }
        # Extensions (robocopy)
        $EdgeExtensions = Join-Path $EdgeDefault "Extensions"
        Copy-IfExists -SourcePath $EdgeExtensions -DestinationPath (Join-Path $EdgeOut "Extensions") -Browser "Edge" -Profile "Default" -UseRoboCopy

        # Local State
        $LocalState = Join-Path $User.FullName "AppData\Local\Microsoft\Edge\User Data\Local State"
        Copy-IfExists -SourcePath $LocalState -DestinationPath (Join-Path $UserOut "Edge\Local State") -Browser "Edge" -Profile "Default"
    }

    # ---------- Firefox ----------
    $FirefoxProfiles = Join-Path $User.FullName "AppData\Roaming\Mozilla\Firefox\Profiles"
    if (Test-Path $FirefoxProfiles) {
        foreach ($Profile in Get-ChildItem $FirefoxProfiles -Directory -ErrorAction SilentlyContinue) {
            $ProfileOut = Join-Path $UserOut ("Firefox_" + $Profile.Name)
            $targets = @(
                "places.sqlite","cookies.sqlite","logins.json","key4.db","prefs.js","extensions.json",
                "downloads.sqlite","favicons.sqlite","sessionstore.jsonlz4","permissions.sqlite"
            )
            $copiedAny = $false
            foreach ($t in $targets) {
                $src = Join-Path $Profile.FullName $t
                if (Test-Path $src) {
                    Copy-IfExists -SourcePath $src -DestinationPath (Join-Path $ProfileOut $t) -Browser "Firefox" -Profile $Profile.Name
                    $copiedAny = $true
                }
            }
            if (-not $copiedAny -and (Test-Path $ProfileOut)) {
                Remove-Item $ProfileOut -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# ---------- Final ZIP ----------
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::CreateFromDirectory($TempDir, $ZipFile)

# ---------- Delete temporary folder ----------
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "Artifacts : $ZipFile"
Write-Output "Manifest : $Manifest"
Write-Output "Error logs : $ErrorLog"
