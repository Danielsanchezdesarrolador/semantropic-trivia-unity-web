param(
 [Parameter(Mandatory=$true)][string]$RepositoryUrl,
 [string]$CheckoutPath='',
 [switch]$ExecutePush
)
$ErrorActionPreference='Stop'
if(!$CheckoutPath){$CheckoutPath=Join-Path $PSScriptRoot 'GitUploadStaging'}
$expectedRepository='https://github.com/Danielsanchezdesarrolador/semantropic-trivia-unity-web.git'
if($RepositoryUrl.TrimEnd('/') -ne $expectedRepository -and $RepositoryUrl.TrimEnd('/') -ne $expectedRepository.Substring(0,$expectedRepository.Length-4)){throw 'Solo se permite el repositorio independiente autorizado'}
$RepositoryUrl=$expectedRepository
$env:GIT_TERMINAL_PROMPT='0'
$env:GCM_INTERACTIVE='Never'
if($RepositoryUrl -notmatch '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:\.git)?$'){throw 'Usa una URL HTTPS de GitHub sin credenciales'}
if($RepositoryUrl -match '/Danielsanchezdesarrollador/semantropic-trivia(?:\.git)?$'){throw 'El repositorio Legacy está prohibido como destino'}
& (Join-Path $PSScriptRoot 'Verify-Publication.ps1')
if(!$ExecutePush){
 Write-Output 'MODO PREPARACIÓN: no se ejecutó Git ni se creó ningún repositorio.'
 Write-Output "Destino previsto: $RepositoryUrl"
 Write-Output 'Tras autorización y creación del repositorio independiente vacío, repetir con -ExecutePush.'
 exit 0
}
$checkout=[IO.Path]::GetFullPath($CheckoutPath)
$publication=[IO.Path]::GetFullPath($PSScriptRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
if(!$checkout.StartsWith($publication+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Git debe permanecer dentro de UnityWebPublication'}
if(Test-Path -LiteralPath $checkout){throw 'CheckoutPath debe ser una carpeta nueva; no se sobrescriben checkouts existentes'}
$project=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../UnityClient'))
$legacy=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../WebBackend'))
foreach($protected in @($project,$legacy)){
 if($checkout.Equals($protected,[StringComparison]::OrdinalIgnoreCase) -or $checkout.StartsWith($protected+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'No se puede preparar Git dentro de Unity ni Legacy'}
}
Get-Command git -ErrorAction Stop | Out-Null
New-Item -ItemType Directory -Path $checkout | Out-Null
$allowlist=@('site','manifest.json','render.yaml','README.md','Verify-Publication.ps1','Prepare-Publication.ps1','Upload-Site.ps1','.github')
foreach($item in $allowlist){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $item) -Destination $checkout -Recurse}
function Invoke-GitChecked([string[]]$Arguments){& git -C $checkout @Arguments; if($LASTEXITCODE -ne 0){throw 'Git falló; no se reintenta ni se fuerza la subida'}}
Invoke-GitChecked -Arguments @('init','-b','main')
Invoke-GitChecked -Arguments @('config','--local','user.name','Danielsanchezdesarrolador')
Invoke-GitChecked -Arguments @('config','--local','user.email','Danielsanchezdesarrolador@users.noreply.github.com')
Invoke-GitChecked -Arguments @('add','--','.'); Invoke-GitChecked -Arguments @('commit','-m','Publish validated Semantropic Unity Web package')
Invoke-GitChecked -Arguments @('remote','add','origin',$RepositoryUrl)
Invoke-GitChecked -Arguments @('push','--set-upstream','origin','main')
Write-Output 'Paquete subido mediante Git. El script no crea servicios ni activa despliegues.'