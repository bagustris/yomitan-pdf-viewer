#!/usr/bin/env bash

# Download and stage a complete PDF.js release before replacing the checked-in
# distribution. This avoids leaving a half-updated viewer after a failed
# download or extraction.
set -euo pipefail

for command in curl jq unzip; do
  command -v "$command" >/dev/null || {
    echo "Required command not found: $command" >&2
    exit 1
  }
done

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$repo_root"

temp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT

pdfjs_version=$(curl --fail --silent --show-error \
  "https://api.github.com/repos/mozilla/pdf.js/releases/latest" \
  | jq -er '.tag_name | ltrimstr("v")')
archive="$temp_dir/pdfjs-$pdfjs_version-dist.zip"

curl --fail --location --silent --show-error \
  "https://github.com/mozilla/pdf.js/releases/download/v$pdfjs_version/pdfjs-$pdfjs_version-dist.zip" \
  --output "$archive"
unzip -q "$archive" "web/*" "build/*" -d "$temp_dir/staged"

staged_web="$temp_dir/staged/web"
staged_build="$temp_dir/staged/build"
[[ -f "$staged_web/viewer.html" && -f "$staged_web/viewer.mjs" && -f "$staged_build/pdf.mjs" ]] || {
  echo "The downloaded archive does not contain a complete PDF.js distribution." >&2
  exit 1
}

mv "$staged_web/viewer.html" "$staged_web/index.html"
cp "$repo_root/yomitan-pdf-viewer.pdf" "$staged_web/yomitan-pdf-viewer.pdf"

sed -i 's/"compressed.tracemonkey-pldi-09.pdf"/"yomitan-pdf-viewer.pdf"/g' "$staged_web/viewer.mjs"
sed -i '/<title>PDF.js viewer<\/title>/a\
    <meta name="theme-color" content="#1f4b7a">\
    <link rel="manifest" href="../manifest.webmanifest">\
    <script src="../pwa-register.js" defer></script>' "$staged_web/index.html"
rm -f "$staged_web/compressed.tracemonkey-pldi-09.pdf"

# Replace whole directories so obsolete files from an older PDF.js release do
# not survive the update. The cache revision is updated at the same time.
mv web "$temp_dir/previous-web"
mv build "$temp_dir/previous-build"
mv "$staged_web" web
mv "$staged_build" build
sed -i -E "s/(const CACHE_NAME = \\\"yomitan-pdf-viewer-pdfjs-)[^\\\"]+(\\\";)/\\1$pdfjs_version\\2/" service-worker.js

echo "Updated PDF.js to $pdfjs_version."
