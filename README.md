Supervivencia Online 0.1.9 tested staging Unity Web build. No Unity compilation required.
Render: repository root; build command node configure-staging.cjs; publish directory publish; auto deploy off.
Set STAGING_BACKEND_URL to the actual HTTPS staging API origin (no trailing slash).
The build command verifies the tested manifest and updates only staging-config.js and HTML CSP. It preserves all Unity binaries and emits deployment-sha256.json.
site is the verified local source package, not the Render publish directory. Missing or invalid HTTPS configuration fails the Render build.
Preserve all Gzip/MIME headers in render.yaml. No SPA rewrite to index.html.
SHA256SUMS.json covers all committed publication files except itself.