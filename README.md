# Yomitan PDF Viewer

A self-contained, offline PDF.js viewer suitable for using Yomitan dictionary
lookups on PDF text. It is also an installable Progressive Web App (PWA).

## Install as an app

Start the local server as described below, open
<http://localhost:8000/web/>, then use the browser's **Install app** control
(typically in the address bar or browser menu). Installation is supported from
`localhost` and HTTPS origins; it does not work when opening files with
`file://`.

The PWA saves its viewer shell for offline use. Open it once while online (or
while this local server is running) before relying on it offline. PDF files
selected through the Open File button stay local and are never uploaded.

## Run offline

Start a local web server from this directory:

```bash
./run.sh
```

Then open <http://localhost:8000/> in a browser. The root page redirects to the
viewer at <http://localhost:8000/web/>.

If you do not use the helper script, the equivalent command is:

```bash
python3 -m http.server --bind localhost
```

Do not open a PDF by double-clicking it or by using a `file://` URL: that uses
the browser's built-in PDF viewer instead. Open the viewer URL first, then use
its Open File button to select a PDF. For a PDF served by the same local
server, it can also be opened directly:

```text
http://localhost:8000/web/?file=relative/path/to/book.pdf
```

The viewer deliberately looks like a standard PDF.js browser viewer. To get
Yomitan popups, install and enable the Yomitan browser extension, add
`http://localhost:8000` to its allowed site access, and use its normal scan
shortcut over selectable text.

## Files

- `web/` contains the viewer interface, fonts, CMaps, localization files, and
  the default document (`web/yomitan-pdf-viewer.pdf`).
- `build/` contains the PDF.js renderer, worker, and sandbox bundles required
  for offline operation.
- `yomitan-pdf-viewer.pdf` is copied into `web/` when updating the bundled
  PDF.js distribution.

Keep `web/` and `build/` together: the viewer loads the renderer and worker
using relative paths.

## Update PDF.js

Run the following from this directory:

```bash
./update.sh
```

It downloads the latest PDF.js distribution, replaces `web/` and `build/`, and
reapplies this project's default-document customization. The script requires
`curl`, `jq`, `wget`, and `unzip`.

It also restores the PWA manifest and service-worker registration in
`web/index.html`.
