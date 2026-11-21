import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { writeAssetPreviews } from './studio_asset_previews.mjs';

test('renders GIF and audio, caches, invalidates, and confines writes', () => {
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'studio-preview-'));
  try {
    const lib = path.join(out, 'library'); fs.mkdirSync(lib);
    const gif = path.join(lib, 'a.gfi');
    fs.writeFileSync(gif, Buffer.from('R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==', 'base64'));
    const wav = path.join(lib, 'a.wav');
    const made = spawnSync('ffmpeg', ['-v','error','-f','lavfi','-i','sine=frequency=440:duration=0.1','-y',wav]);
    assert.equal(made.status, 0);
    const catalog = {entries:[{path:'a.gfi',origin:'references'}, {path:'a.wav',origin:'references'}, {path:'../escape.gif'}]};
    const safe = (root, dest) => { assert.ok(dest.startsWith(root + path.sep)); };
    writeAssetPreviews(out,catalog,safe);
    for (const entry of catalog.entries.slice(0,2)) {
      assert.match(entry.preview, /^\.previews\/.+\.png$/);
      assert.deepEqual([...fs.readFileSync(path.join(lib,entry.preview)).subarray(0,8)], [137,80,78,71,13,10,26,10]);
    }
    assert.equal(catalog.entries[2].preview, undefined);
    const first = catalog.entries[0].preview;
    writeAssetPreviews(out,catalog,safe); assert.equal(catalog.entries[0].preview, first);
    fs.appendFileSync(gif, Buffer.from([0])); writeAssetPreviews(out,catalog,safe);
    assert.notEqual(catalog.entries[0].preview, first);
  } finally { fs.rmSync(out,{recursive:true,force:true}); }
});

test('Windows PDF first page renders to PNG', {skip: process.platform !== 'win32'}, () => {
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'studio-pdf-'));
  try {
    const objects = ['<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [3 0 R] /Count 1 >>','<< /Type /Page /Parent 2 0 R /MediaBox [0 0 100 100] /Resources << >> /Contents 4 0 R >>','<< /Length 0 >>\nstream\n\nendstream'];
    let pdf = '%PDF-1.4\n', offsets = [0];
    for (const [i, obj] of objects.entries()) { offsets.push(Buffer.byteLength(pdf)); pdf += `${i+1} 0 obj\n${obj}\nendobj\n`; }
    const xref = Buffer.byteLength(pdf);
    pdf += `xref\n0 ${offsets.length}\n0000000000 65535 f \n` + offsets.slice(1).map(n => `${String(n).padStart(10,'0')} 00000 n \n`).join('') + `trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
    const lib = path.join(out,'library'); fs.mkdirSync(lib); fs.writeFileSync(path.join(lib,'page.pdf'),pdf);
    const catalog = {entries:[{path:'page.pdf',origin:'references'}]};
    writeAssetPreviews(out,catalog,(root,dest) => assert.ok(dest.startsWith(root + path.sep)));
    assert.ok(catalog.entries[0].preview, 'Windows PDF preview should be generated');
    assert.deepEqual([...fs.readFileSync(path.join(lib,catalog.entries[0].preview)).subarray(0,8)], [137,80,78,71,13,10,26,10]);
  } finally { fs.rmSync(out,{recursive:true,force:true}); }
});
