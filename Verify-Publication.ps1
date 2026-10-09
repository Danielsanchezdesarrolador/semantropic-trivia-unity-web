$ErrorActionPreference='Stop'
$site=Join-Path $PSScriptRoot 'site'
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
foreach($entry in $manifest){$file=Join-Path $site $entry.path; if(!(Test-Path -LiteralPath $file)){throw "Falta $($entry.path)"}; if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $entry.sha256){throw "Hash distinto: $($entry.path)"}; if((Get-Item -LiteralPath $file).Length -ge 100MB){throw 'Archivo demasiado grande para GitHub'}}
$html=Get-Content -LiteralPath (Join-Path $site 'index.html') -Raw
foreach($match in [regex]::Matches($html,'(?:buildUrl \+ "/|(?:href|src)=")([^"?]+)')){
 $relative=$match.Groups[1].Value
 if($match.Value.StartsWith('buildUrl')){$relative='Build/'+$relative}
 if(!(Test-Path -LiteralPath (Join-Path $site $relative))){throw "Referencia inexistente: $relative"}
}
foreach($file in Get-ChildItem (Join-Path $site 'Build') -Filter '*.gz'){$stream=[IO.File]::OpenRead($file.FullName); try{if($stream.ReadByte() -ne 31 -or $stream.ReadByte() -ne 139){throw 'Cabecera Gzip inválida'}}finally{$stream.Dispose()}}
Write-Output "OK: $(@($manifest).Count) archivos; $([math]::Round((($manifest | Measure-Object bytes -Sum).Sum)/1MB,2)) MiB; hashes, referencias y cabeceras Gzip válidos."
foreach($file in Get-ChildItem (Join-Path $site 'Build') -Filter '*.gz'){
 $inputStream=[IO.File]::OpenRead($file.FullName)
 $gzip=[IO.Compression.GZipStream]::new($inputStream,[IO.Compression.CompressionMode]::Decompress)
 try{$gzip.CopyTo([IO.Stream]::Null)}finally{$gzip.Dispose();$inputStream.Dispose()}
}
$questions=Get-Content -LiteralPath (Join-Path $site 'StreamingAssets/general_questions.json') -Raw | ConvertFrom-Json
if(@($questions).Count -ne 1410){throw 'El banco de preguntas no contiene 1410 entradas'}
$render=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'render.yaml') -Raw
foreach($required in @('staticPublishPath: ./site','path: /Build/*.gz','name: Content-Encoding','value: gzip','path: /Build/*.wasm.gz','value: application/wasm','path: /Build/*.framework.js.gz','value: application/javascript','path: /Build/*.data.gz','value: application/octet-stream')){if(!$render.Contains($required)){throw "Falta configuración Render: $required"}}
Write-Output 'OK: descompresión Gzip completa; 1410 preguntas; cabeceras Render Gzip/MIME configuradas.'