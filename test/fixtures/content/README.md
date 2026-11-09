# Synthetic content fixture

This is a small content bundle in the live contract's shape, so widget and bloc tests read content without writing down a fact about the course.
Tests reach it through `contentFixtureBundle` in `test/support/content_fixture.dart`.

## Layout

`src/` holds the sources in site layout: `api/index.json`, `api/v1/index.json`, the level and module documents under `api/v1/`, and the images under `course-images/`.
The `files` and `images` maps of `src/api/v1/index.json` are placeholders; the build fills them in.
`bundle/` mirrors `assets/content/`: `index.json`, `api_index.json` and `objects/<sha256>`.
`diagrams/` holds the Mermaid sources of the two diagrams and `make_draft.mjs`, which writes the draft index the web finaliser reads.

Both `bundle/` and `src/api/v1/diagrams/*.svg` are generated.
Never edit them by hand: change a source, then run the generator.

The fixture holds three modules.
`alpha/first` is written in both tracks, with a quiz in For Engineers and one block of every type in its For Engineers document.
`alpha/second` is written For Engineers only.
`beta/third` is planned, with a For Engineers draft that has parts and written blocks.

## Regenerating

After a change to any file under `src/`, rebuild the bundle from the repository root:

```bash
fvm dart run tool/build_content_fixture.dart
```

`test/tool/content_fixture_test.dart` fails while the committed bundle differs from a fresh build.

The diagrams are drawn by the web repo's finaliser, which only reads the web repo and writes into the scratch directory it is given.
First path, the web repo's existing build (needs a stylesheet under `out/_next/static/` and the draft body `.next/server/app/api/v1/index.draft.json.body` with both `render` configs); run as one script from the repository root:

```bash
WEB=/home/cevheri/projects/lokumai/ai-minicourses
S=$(mktemp -d)
git -C "$WEB" status --porcelain > "$S/web-status-before.txt"
git -C "$WEB" log -1 --format='%H %cs'
mkdir -p "$S/out" && (cd "$WEB/out" && find _next/static -name '*.css' -exec cp --parents {} "$S/out/" \;)
node test/fixtures/content/diagrams/make_draft.mjs "$WEB/.next/server/app/api/v1/index.draft.json.body" "$S/out" test/fixtures/content/diagrams/flowchart.mmd test/fixtures/content/diagrams/mindmap.mmd
heavy node "$WEB/scripts/finalize-bundle.mjs" "$S/out"
mkdir -p test/fixtures/content/src/api/v1/diagrams && cp "$S/out/api/v1/diagrams/"*.svg test/fixtures/content/src/api/v1/diagrams/
node -p "require('$WEB/node_modules/mermaid/package.json').version"
git -C "$WEB" status --porcelain | diff "$S/web-status-before.txt" -
rm -rf "$S"
```

Fallback, when that build lacks the stylesheets or the draft body: build a clean clone and run its finaliser on a scratch directory, as one script:

```bash
W=$(mktemp -d)
git clone --quiet /home/cevheri/projects/lokumai/ai-minicourses "$W/web"
git -C "$W/web" log -1 --format='%H %cs'
heavy bash -c "cd $W/web && npm ci"
heavy bash -c "cd $W/web && node scripts/curriculum-css.mjs && node scripts/copy-course-images.mjs && npx next build"
test -f "$W/web/out/api/v1/index.draft.json"
mkdir -p "$W/fixture" && (cd "$W/web/out" && find _next/static -name '*.css' -exec cp --parents {} "$W/fixture/" \;)
node test/fixtures/content/diagrams/make_draft.mjs "$W/web/out/api/v1/index.draft.json" "$W/fixture" test/fixtures/content/diagrams/flowchart.mmd test/fixtures/content/diagrams/mindmap.mmd
heavy bash -c "cd $W/web && node scripts/finalize-bundle.mjs $W/fixture"
mkdir -p test/fixtures/content/src/api/v1/diagrams && cp "$W/fixture/api/v1/diagrams/"*.svg test/fixtures/content/src/api/v1/diagrams/
node -p "require('$W/web/node_modules/mermaid/package.json').version"
rm -rf "$W"
```

`make_draft.mjs` prints each variant with its id, and the ids are the file names of the SVGs.
An id is the first 32 hex digits of the sha256 of the Mermaid source, a NUL byte and the variant, so a changed `.mmd` file changes the ids, and the documents under `src/api/v1/modules/` must then name the new files.
If Playwright reports no Chromium, run `npx playwright install chromium` in the web directory through `heavy` and repeat the finaliser.
After new SVGs, rebuild the bundle with `fvm dart run tool/build_content_fixture.dart`.

## Recorded run

The SVGs in `src/api/v1/diagrams/` were drawn on 2026-11-09 on the first path.
Web commit `29c511cd21462e32e43c3373e66d3891aa49e7ce` of 2026-11-09, mermaid 11.17.2.
`make_draft.mjs` printed `light 77235fba878b47f1d72f180d8babf2c4`, `dark 9bb8502b0371cba0d2e5b7e98362455e`, `light c63f57d179cfa40d893a096c156c03d0` and `dark da1edd2a0129f03d838131d67f7ca336`.
The finaliser printed these two lines:

```text
finalize-bundle: drew 4 diagrams; the largest glyph move was 0.015 px
finalize-bundle: wrote api/v1/index.json, contentVersion d3833f62565f8c11dd987a78f10a2fe122869f7cffb8a218d8eff3d801224051, 4 files and 0 images
```

The web repo's working tree was unchanged afterwards.
