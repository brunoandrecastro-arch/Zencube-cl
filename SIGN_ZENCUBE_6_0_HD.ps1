# ZenCube 3D 6.0 HD - local Windows signing with the EXISTING Google Play upload key only.
[CmdletBinding()]
param(
  [string]$Bundle = (Join-Path $PSScriptRoot 'ZenCube-3D-6.0-HD-unsigned.aab'),
  [string]$Keystore,
  [string]$Alias,
  [string]$Bundletool = (Join-Path $PSScriptRoot 'bundletool-all-1.18.3.jar'),
  [string]$ExpectedPackageId = 'com.zencube.game.play',
  [Parameter(Mandatory=$true)][string]$ExpectedUploadSha256,
  [Parameter(Mandatory=$true)][int]$LastPlayVersionCode
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-JdkTool([string]$Name) {
  if ($env:JAVA_HOME) {
    $candidate=Join-Path $env:JAVA_HOME ('bin\' + $Name + '.exe')
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  $command=Get-Command ($Name+'.exe') -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }
  throw "Missing ${Name}: install Java JDK 17+ and configure JAVA_HOME."
}
if (-not $Keystore) { $Keystore=(Read-Host 'Pfad zur vorhandenen Upload-Keystore-Datei').Trim().Trim([char]34) }
if (-not $Alias) { $Alias=Read-Host 'Alias des vorhandenen Upload-Schluessels' }
if (-not $Keystore -or -not $Alias -or $Alias.StartsWith('-')) { throw 'Valid keystore path and alias required.' }
$fingerprint=($ExpectedUploadSha256 -replace '[:\s]','').ToUpperInvariant()
if ($fingerprint -notmatch '^[0-9A-F]{64}$') { throw 'Invalid Play upload certificate SHA256.' }
$source=(Resolve-Path -LiteralPath $Bundle).ProviderPath
$store=(Resolve-Path -LiteralPath $Keystore).ProviderPath
$jar=(Resolve-Path -LiteralPath $Bundletool).ProviderPath
if ([IO.Path]::GetFileName($source) -cne 'ZenCube-3D-6.0-HD-unsigned.aab') { throw 'Wrong bundle file.' }
$dest=Join-Path (Split-Path -Parent $source) 'ZenCube-3D-6.0-HD.aab'
if (Test-Path -LiteralPath $dest) { throw 'Signed destination already exists. Refusing overwrite.' }
$java=Find-JdkTool 'java'
$jarsigner=Find-JdkTool 'jarsigner'
$keytool=Find-JdkTool 'keytool'
& $java -jar $jar validate "--bundle=$source"
if ($LASTEXITCODE -ne 0) { throw 'Bundletool validation failed.' }
$manifestText=& $java -jar $jar dump manifest "--bundle=$source"
if ($LASTEXITCODE -ne 0) { throw 'Failed to inspect AAB manifest.' }
[xml]$manifest=$manifestText -join [Environment]::NewLine
$android='http://schemas.android.com/apk/res/android'
$root=$manifest.DocumentElement
$package=$root.GetAttribute('package')
$name=$root.GetAttribute('versionName',$android)
$code=[int]$root.GetAttribute('versionCode',$android)
$sdk=[int]$manifest.SelectSingleNode('/manifest/uses-sdk').GetAttribute('targetSdkVersion',$android)
$debuggable=$manifest.SelectSingleNode('/manifest/application').GetAttribute('debuggable',$android)
if ($package -cne 'com.zencube.game.play' -or $package -cne $ExpectedPackageId) { throw "STOP: AAB package $package does not equal Play Console $ExpectedPackageId." }
if ($name -ne '6.0' -or $code -ne 60 -or $LastPlayVersionCode -lt 1 -or $code -le $LastPlayVersionCode) { throw "STOP: invalid version $name ($code), prior Play code $LastPlayVersionCode." }
if ($sdk -ne 36 -or $debuggable -eq 'true') { throw 'STOP: not a non-debug API 36 release.' }
$alignment=& $java -jar $jar dump config "--bundle=$source"
if ($LASTEXITCODE -ne 0 -or (($alignment -join [Environment]::NewLine) -notmatch 'PAGE_ALIGNMENT_16K')) { throw 'STOP: missing 16 KB ZIP page alignment.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[System.IO.Compression.ZipFile]::OpenRead($source)
try {
  if (@($zip.Entries | Where-Object { $_.FullName -match '^META-INF/[^/]+\.(SF|RSA|DSA|EC)$' }).Count -gt 0) {
    throw 'Input AAB already signed.'
  }
} finally { $zip.Dispose() }
$tmp=Join-Path (Split-Path -Parent $source) ('.signing-' + [guid]::NewGuid().ToString('N') + '.aab')
try {
  # jarsigner prompts locally: no password arguments, saved files, or new keys.
  & $jarsigner -keystore $store -signedjar $tmp $source $Alias
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmp)) { throw 'Signing failed.' }
  $verify=& $jarsigner '-J-Duser.language=en' -verify $tmp
  if ($LASTEXITCODE -ne 0 -or (($verify -join [Environment]::NewLine) -notmatch '(?m)^jar verified\.\s*$')) {
    throw 'jarsigner verification failed.'
  }
  if (($verify -join [Environment]::NewLine) -match '(?i)contains unsigned entries') { throw 'Unsigned payload entries in signed AAB.' }
  $cert=& $keytool '-J-Duser.language=en' -printcert -jarfile $tmp
  if ($LASTEXITCODE -ne 0) { throw 'Signing certificate read failed.' }
  $match=[regex]::Match(($cert -join [Environment]::NewLine),'(?im)^\s*SHA256:\s*([A-F0-9:]{95})\s*$')
  if (-not $match.Success -or (($match.Groups[1].Value -replace ':','').ToUpperInvariant() -ne $fingerprint)) {
    throw 'STOP: certificate does not match the EXISTING Play upload certificate.'
  }
  & $java -jar $jar validate "--bundle=$tmp"
  if ($LASTEXITCODE -ne 0) { throw 'Signed AAB did not pass bundletool validation.' }
  [IO.File]::Move($tmp,$dest)
  Write-Host 'ERFOLG: ZenCube 3D 6.0 HD lokal signiert und überprüft.' -ForegroundColor Green
  Write-Host "Paket $package | Version $name ($code) | targetSdk $sdk"
  Write-Host "Datei: $dest"
  Write-Host ("SHA-256: " + (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash)
  $digest=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant()
  $bytes=(Get-Item -LiteralPath $dest).Length
  $report=@("File: $([IO.Path]::GetFileName($dest))", "SHA-256: $digest", "Bytes: $bytes", "Package: $package", "Version: $name ($code)", "Target SDK: $sdk", "Upload certificate SHA-256: $fingerprint", 'Signature: jarsigner verified; upload certificate matched; bundletool validated', 'Publication: none')
  $report | Set-Content -LiteralPath ($dest+'.verification.txt') -Encoding UTF8
  ($digest+'  '+[IO.Path]::GetFileName($dest)) | Set-Content -LiteralPath ($dest+'.sha256') -Encoding ASCII
  Write-Host "Dateigröße: $bytes Bytes"
  Write-Host 'Kein Upload, keine Veröffentlichung, kein neuer Uploadschlüssel.'
} finally { if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force } }
