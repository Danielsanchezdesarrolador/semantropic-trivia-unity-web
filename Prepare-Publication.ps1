param([Parameter(Mandatory=$true)][string]$BuildPath,[switch]$Replace)
$ErrorActionPreference='Stop'
$source=(Resolve-Path -LiteralPath $BuildPath).Path
$target=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'site'))
if((Split-Path $target -Parent) -ne [IO.Path]::GetFullPath($PSScriptRoot)){throw 'Destino fuera de la carpeta de publicación'}
foreach($item in @('index.html','Build','TemplateData')){if(!(Test-Path -LiteralPath (Join-Path $source $item))){throw "Falta $item"}}
$sourceFiles=@(Get-ChildItem -LiteralPath $source -File -Recurse)
if($sourceFiles | Where-Object {$_.Length -ge 100MB}){throw 'Un archivo alcanza 100 MiB: revisar distribución antes de usar GitHub'}
$unexpected=@($sourceFiles | Where-Object {$_.Name -match '^\.env|\.pfx$|\.pem$|\.key$|accounts|sessions|rankings|credentials'})
if($unexpected.Count){throw 'Se detectaron archivos potencialmente sensibles; no se copiará la compilación'}
if(Test-Path -LiteralPath $target){if(!$Replace){throw 'site ya existe. Usa -Replace para reemplazar únicamente la copia de publicación'}; Remove-Item -LiteralPath $target -Recurse -Force}
New-Item -ItemType Directory -Path $target | Out-Null
foreach($item in @('index.html','Build','TemplateData','StreamingAssets')){$origin=Join-Path $source $item; if(Test-Path -LiteralPath $origin){Copy-Item -LiteralPath $origin -Destination $target -Recurse}}
$inventory=@(Get-ChildItem -LiteralPath $target -Recurse -File | ForEach-Object {
 $relative=$_.FullName.Substring($target.Length+1).Replace('\','/')
 $original=Join-Path $source $relative
 $digest=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
 if($digest -ne (Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash){throw "Copia distinta: $relative"}
 [pscustomobject]@{path=$relative;bytes=$_.Length;sha256=$digest}
})
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'manifest.json'),($inventory | ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
& (Join-Path $PSScriptRoot 'Verify-Publication.ps1')