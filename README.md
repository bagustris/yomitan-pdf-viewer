# PDF Viewer for Yomitan

A self-contained, offline PDF.js viewer suitable for using Yomitan dictionary
lookups on PDF text. It is also an installable Progressive Web App (PWA).

Not affiliated with or endorsed by the Yomitan project. This is an
independent PDF viewer built to work alongside pop-up dictionary browser
extensions — it renders PDFs with a normal, selectable text layer (unlike a
browser's built-in PDF viewer), so any extension that works on ordinary web
page text works here too. It's built and tested primarily with
[Yomitan](https://github.com/yomidevs/yomitan), but also works with
[10ten Japanese Reader](https://github.com/birchill/10ten-ja-reader) and
similar pop-up dictionary extensions.

## Install as an app (recommended)

Open <https://bagustris.github.io/yomitan-pdf-viewer/web/> and use the
browser's **Install app** control (typically in the address bar or browser
menu). You only need an internet connection for this one-time visit: the
service worker caches the entire viewer shell, so the installed app keeps
working fully offline afterward.

PDF files selected through the Open File button stay local and are never
uploaded — the hosted page only serves the static viewer, not your documents.

To get popups, add `https://bagustris.github.io` to your dictionary
extension's allowed site access (for Yomitan: its extension options' "allowed
sites" list; 10ten Japanese Reader works on all sites by default) and use its
normal scan shortcut over selectable text.

### Multiple documents (tabbed PWA window)

`manifest.webmanifest` opts into Chrome's tabbed PWA mode
(`display_override: ["tabbed", ...]` and `tab_strip.new_tab_button`), which
gives the *installed app window* its own tab strip with a "+" button for
opening additional documents — separate from your regular browser tabs. This
only applies to the installed app, not to the page opened in a normal browser
tab.

- Ships stable on ChromeOS.
- On desktop Chrome (Windows/Mac/Linux) it's still experimental: enable
  `chrome://flags/#enable-desktop-pwas-tab-strip`, relaunch Chrome, then
  reinstall (or relaunch) the installed app for the tab strip to appear.

## Run from source

Use this if you're developing the viewer, want to serve your own PDFs from a
local path via `?file=`, or don't want to depend on the hosted GitHub Pages
copy. Installation as a PWA also works from `localhost`, just not from
`file://`.

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
popups, install and enable your pop-up dictionary extension (Yomitan, 10ten
Japanese Reader, etc.), add `http://localhost:8000` to its allowed site
access if it requires one, and use its normal scan shortcut over selectable
text.

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
