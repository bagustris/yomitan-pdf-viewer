# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A thin, self-contained wrapper around a stock PDF.js distribution, packaged as an
installable offline-first PWA so that the Yomitan browser extension can perform
dictionary lookups on PDF text (something Yomitan cannot do against a browser's
native PDF viewer or a `file://` URL). Almost all code under `web/` and `build/`
is vendored PDF.js — do not hand-edit it except through `update.sh`'s
customization step.

## Commands

Run a local server (required — Yomitan lookups and PWA install do not work over `file://`):

```bash
./run.sh                                   # serves on http://localhost:8000
python3 -m http.server --bind localhost 8000  # equivalent, if not using the script
```

Then open `http://localhost:8000/` (redirects to `web/`), or open a specific PDF
served locally via `http://localhost:8000/web/?file=relative/path/to/book.pdf`.

Update the vendored PDF.js distribution:

```bash
./update.sh   # requires curl, jq, unzip
```

There is no build step, linter, or test suite — this repo has no `package.json`;
it's static assets plus these two shell scripts.

## Architecture

- `index.html` (repo root) — redirect-only stub that forwards `/` to `/web/`.
- `web/` — the PDF.js viewer UI (`index.html`, `viewer.mjs`, `viewer.css`,
  locale files, cmaps, fonts) plus the bundled default document
  `web/yomitan-pdf-viewer.pdf`.
- `build/` — the PDF.js renderer/worker/sandbox bundles (`pdf.mjs`,
  `pdf.worker.mjs`, `pdf.sandbox.mjs`). `web/` and `build/` must stay together;
  the viewer loads these using relative paths.
- `manifest.webmanifest`, `pwa-register.js`, `service-worker.js`, `icons/` — the
  PWA layer added on top of stock PDF.js. `service-worker.js` cache-first-caches
  everything in its `APP_SHELL` list except `.pdf` requests (a locally served
  PDF can change independently of the cached viewer shell, so PDFs are always
  fetched fresh). `CACHE_NAME` embeds the PDF.js version so an update can't
  serve mixed old/new assets from a stale cache.
- `yomitan-pdf-viewer.pdf` (repo root) — source copy of the default document;
  `update.sh` copies it into a freshly staged `web/` on every update.

### `update.sh` mechanics

This is the one script worth understanding before touching it. It downloads the
latest PDF.js release into a temp dir, stages and validates `web/`+`build/`
there (fails loudly if the archive doesn't look like a complete distribution),
then only replaces the checked-in `web/`/`build/` after staging succeeds — so a
failed download/extraction never leaves a half-updated viewer. While staging it
also reapplies this project's changes on top of the fresh vendor code:
- renames `viewer.html` → `index.html`
- copies in `yomitan-pdf-viewer.pdf` as the bundled default document and
  patches `viewer.mjs` to reference it instead of PDF.js's own sample PDF
- injects the PWA `<meta theme-color>`, manifest `<link>`, and
  `pwa-register.js` `<script>` tags into `web/index.html`
- bumps the version embedded in `service-worker.js`'s `CACHE_NAME`

Any future customization of the vendored viewer needs to be added to this
script (not just to the working tree), or it will be silently lost on the next
`./update.sh` run.

## Constraints to keep in mind

- Do not open PDFs via `file://` or by double-clicking — that invokes the
  browser's built-in viewer and bypasses this one (and PWA install requires
  `localhost`/HTTPS, not `file://`).
- Yomitan lookups require adding `http://localhost:8000` to Yomitan's allowed
  site access and using its normal scan shortcut over selectable PDF text.
- Versioning is CalVer `YYYY.MM.DD`, tracked in `CHANGELOG.md`.
