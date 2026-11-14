[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Bundle,
    [Parameter(Mandatory)] [string] $Keystore,
    [Parameter(Mandatory)] [string] $Alias,
    [Parameter(Mandatory)] [string] $Bundletool,
    [Parameter(Mandatory)] [string] $ExpectedUploadSha256,
    [Parameter(Mandatory)] [int] $LastPlayVersionCode
)

$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $Bundle).ProviderPath
$store = (Resolve-Path -LiteralPath $Keystore).ProviderPath
$bundletoolJar = (Resolve-Path -LiteralPath $Bundletool).ProviderPath
if (-not $source.EndsWith('-unsigned.aab', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Bitte das -unsigned.aab aus dem Release-Build auswählen.'
}
if ($Alias.StartsWith('-')) { throw 'Ungültiger Schlüsselalias.' }
$expected = ($ExpectedUploadSha256 -replace '[:\s]', '').ToUpperInvariant()
if ($expected -notmatch '^[0-9A-F]{64}$') { throw 'Der SHA-256-Fingerabdruck aus der Play Console ist ungültig.' }

if ($env:JAVA_HOME) {
    $java = Join-Path $env:JAVA_HOME 'bin/java'
    $jarsigner = Join-Path $env:JAVA_HOME 'bin/jarsigner'
    $keytool = Join-Path $env:JAVA_HOME 'bin/keytool'
} else {
    $java = (Get-Command java -CommandType Application).Source
    $jarsigner = (Get-Command jarsigner -CommandType Application).Source
    $keytool = (Get-Command keytool -CommandType Application).Source
}

& $java -jar $bundletoolJar validate "--bundle=$source"
if ($LASTEXITCODE -ne 0) { throw 'bundletool kann das Bundle nicht validieren.' }
$manifestText = & $java -jar $bundletoolJar dump manifest "--bundle=$source"
if ($LASTEXITCODE -ne 0) { throw 'Android-Manifest konnte nicht gelesen werden.' }
[xml] $manifest = $manifestText -join "`n"
$android = 'http://schemas.android.com/apk/res/android'
$package = $manifest.DocumentElement.GetAttribute('package')
$version = [int] $manifest.DocumentElement.GetAttribute('versionCode', $android)
$target = [int] $manifest.SelectSingleNode('/manifest/uses-sdk').GetAttribute('targetSdkVersion', $android)
$debuggable = $manifest.SelectSingleNode('/manifest/application').GetAttribute('debuggable', $android)
if ($package -ne 'com.zencube.game.play') {
    throw "Das Bundle meldet $package. Der bestehende Play-Test erwartet com.zencube.game.play."
}
if ($version -le $LastPlayVersionCode -or $target -lt 36 -or $debuggable -eq 'true') {
    throw 'Versionscode, Ziel-SDK oder Buildtyp erfüllen die Anforderungen des Test-Updates nicht.'
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($source)
try {
    if ($zip.Entries.FullName -match '^META-INF/[^/]+\.(SF|RSA|DSA|EC)$') {
        throw 'Das Eingabe-Bundle enthält bereits eine Signatur.'
    }
} finally {
    $zip.Dispose()
}

$folder = [IO.Path]::GetDirectoryName($source)
$output = Join-Path $folder (([IO.Path]::GetFileName($source)) -replace '-unsigned\.aab$', '-signed.aab')
$staging = Join-Path $folder ('.zencube-' + [guid]::NewGuid() + '.aab')
try {
    # jarsigner asks for the password interactively. Keep it out of script arguments and files.
    & $jarsigner -keystore $store -signedjar $staging $source $Alias
    if ($LASTEXITCODE -ne 0) { throw 'jarsigner konnte das Bundle nicht signieren.' }

    $verification = & $jarsigner '-J-Duser.language=en' -verify $staging
    if ($LASTEXITCODE -ne 0 -or ($verification -join "`n") -notmatch '(?m)^jar verified\.\s*$') {
        throw 'Die erzeugte Signatur ist ungültig.'
    }
    $cert = (& $keytool '-J-Duser.language=en' -printcert -jarfile $staging) -join "`n"
    $fingerprints = [regex]::Matches($cert, '(?m)^\s*SHA256:\s*((?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2})\s*$')
    if ($LASTEXITCODE -ne 0 -or $fingerprints.Count -ne 1 -or
        (($fingerprints[0].Groups[1].Value -replace ':', '').ToUpperInvariant() -ne $expected)) {
        throw 'Der verwendete Schlüssel stimmt nicht mit dem Upload-Zertifikat in Google Play überein.'
    }

    # Move fails if a signed output already exists.
    [IO.File]::Move($staging, $output)
    Write-Output "Signiertes Bundle für $package, Versionscode $version"
    Write-Output $output
} finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging }
}
