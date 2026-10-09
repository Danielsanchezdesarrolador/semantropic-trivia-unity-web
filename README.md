# Semantropic Trivia — Unity Web

Paquete de producción independiente de Legacy, preparado para Render Static Site.

- Build: SemantropicWeb_20261009_182211_Production, Unity 6000.3.25f1, Succeeded, cero errores de build.
- Archivos publicables: site/ (18 archivos; 103549633 bytes; 98.75 MiB).
- Archivo mayor: Build/*.data.gz, 94195098 bytes (89.83 MiB), inferior al límite GitHub de 100 MiB.
- Incluye index.html, Build, TemplateData y StreamingAssets/general_questions.json (1410 preguntas).
- Web producción utiliza https://semantropic-trivia.onrender.com e ignora URLs guardadas en PlayerPrefs. Editor y builds locales/development conservan sus opciones.
- Verificado: pruebas de selección API; hashes SHA256; rutas HTML/loader; descompresión íntegra de los tres Gzip; preguntas y cabeceras Render.

## Render (no desplegado)

Root Directory: raíz del repositorio (dejar vacío).
Build Command: test -f site/index.html
Publish Directory: site

render.yaml contiene la configuración propuesta, con despliegues automáticos desactivados. La creación del Static Site y su primer despliegue requieren autorización aparte.

Cabeceras necesarias:

| Ruta | Cabecera | Valor |
| --- | --- | --- |
| /Build/*.gz | Content-Encoding | gzip |
| /Build/*.wasm.gz | Content-Type | application/wasm |
| /Build/*.framework.js.gz | Content-Type | application/javascript |
| /Build/*.data.gz | Content-Type | application/octet-stream |
| /Build/*.loader.js | Content-Type | application/javascript |

No aplicar gzip al HTML, loader ni StreamingAssets. No usar rewrite de archivos faltantes hacia index.html. No hay decompression fallback. Web threads desactivados.

CORS se gestionará por separado con el origen público exacto: permitir GET/POST/OPTIONS y Content-Type/X-Semantropic-Client, responder al preflight y añadir Access-Control-Allow-Origin y Vary: Origin a las respuestas API. No se modificó server.js. La prueba de login, perfil y resultados desde navegador sigue pendiente de este ajuste.

## Validación y versiones futuras

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Verify-Publication.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Prepare-Publication.ps1 -BuildPath 'RUTA_DEL_BUILD_VALIDO' -Replace
```

Prepare-Publication reemplaza exclusivamente site dentro de esta carpeta, conserva los archivos del build y genera manifest.json. No compila Unity ni despliega. Luego revisar, ejecutar la verificación y hacer un commit/push normal en este repositorio.

Upload-Site.ps1 está limitado al repositorio https://github.com/Danielsanchezdesarrolador/semantropic-trivia-unity-web.git y a un checkout nuevo dentro de la carpeta de publicación. Solo sube site y archivos explícitamente permitidos. Sin -ExecutePush no ejecuta Git. No usa push forzado ni permite autenticación interactiva; la identidad se configura exclusivamente en el checkout local. El script sirve para la importación inicial, no para sobrescribir un checkout existente.

El workflow manual verifica el paquete y genera un artefacto; no crea servicios ni despliega. Tras aprobar la primera publicación puede habilitarse la actualización automática de Render por commit.

No se incluyen UnityClient, archivos fuente del juego, datos de cuentas, bases de datos, .env, credenciales, Blender, logs ni carpetas temporales.