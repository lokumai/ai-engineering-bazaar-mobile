// node make_draft.mjs <web draft index> <scratch out dir> <source.mmd>...
import { createHash } from 'node:crypto'
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
const [webDraft, out, ...sources] = process.argv.slice(2)
const web = JSON.parse(readFileSync(webDraft, 'utf8'))
const id = (source, variant) => createHash('sha256').update(source + '\u0000' + variant).digest('hex').slice(0, 32)
const diagrams = []
for (const file of sources) {
  const source = readFileSync(file, 'utf8')
  for (const variant of ['light', 'dark']) diagrams.push({ id: id(source, variant), variant, source })
}
mkdirSync(join(out, 'api/v1'), { recursive: true })
writeFileSync(join(out, 'api/v1/index.draft.json'), JSON.stringify({ schemaVersion: 1, contentVersion: '',
  publishedAt: web.publishedAt, diagramThemes: web.diagramThemes, files: {}, images: {}, diagrams, render: web.render }))
for (const d of diagrams) console.log(d.variant, d.id)
