import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const imageFormats = new Set(['.gif', '.gfi', '.psd']);
const soundFormats = new Set(['.wav', '.ogg', '.mp3']);
const aseFormats = new Set(['.ase', '.aseprite']);
const signature = Buffer.from([137,80,78,71,13,10,26,10]);
const inside = (root, dest) => { const rel = path.relative(root, dest); return rel && rel !== '..' && !rel.startsWith(`..${path.sep}`) && !path.isAbsolute(rel); };

function run(command, args) {
  const result = spawnSync(command, args, { windowsHide: true, maxBuffer: 32 * 1024 * 1024, timeout: 30000 });
  return result.status === 0 && result.stdout?.subarray(0, 8).equals(signature) ? result.stdout : null;
}

function decoder(name) {
  const result = spawnSync(process.platform === 'win32' ? 'where.exe' : 'which', [name], {encoding:'utf8', windowsHide:true});
  if (result.status === 0) return result.stdout.split(/\r?\n/)[0];
  const probe = spawnSync(name, ['-version'], {windowsHide:true, stdio:'ignore'});
  return probe.error ? null : name;
}

/** Generate cached, library-relative previews from already copied assets. */
export function writeAssetPreviews(out, catalog, assertSafeOutput) {
  out = path.resolve(out);
  const library = path.join(out, 'library');
  const ffmpeg = decoder('ffmpeg');
  const aseprite = (process.env.ASEPRITE_EXE && fs.existsSync(process.env.ASEPRITE_EXE) ? process.env.ASEPRITE_EXE : null) ?? decoder('aseprite') ?? (process.platform === 'win32' ? [
    path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..', 'tools/aseprite-src/build/bin/aseprite.exe'),
    path.join(process.env.ProgramFiles ?? '', 'Aseprite', 'Aseprite.exe'),
    path.join(process.env.LOCALAPPDATA ?? '', 'Programs', 'Aseprite', 'Aseprite.exe'),
  ].find(p => fs.existsSync(p)) : null);
  const pdftoppm = decoder('pdftoppm');
  let generated = 0, cached = 0, unavailable = 0;
  for (const entry of catalog.entries) {
    const ext = path.extname(entry.path ?? '').toLowerCase();
    if (!imageFormats.has(ext) && !aseFormats.has(ext) && ext !== '.pdf' && !(soundFormats.has(ext) && entry.origin === 'references')) continue;
    const source = path.resolve(library, entry.path);
    if (!inside(library, source)) continue;
    assertSafeOutput(out, source);
    if (!fs.existsSync(source) || !fs.statSync(source).isFile()) continue;
    const hash = crypto.createHash('sha256').update(aseFormats.has(ext) ? 'preview-ase-grid\0' : 'preview-v1\0').update(ext).update(fs.readFileSync(source)).digest('hex');
    const relative = `.previews/${hash}.png`;
    const target = path.join(library, '.previews', `${hash}.png`);
    assertSafeOutput(out, target);
    if (fs.existsSync(target) && fs.readFileSync(target).subarray(0,8).equals(signature)) { entry.preview = relative; cached++; continue; }
    let data = null;
    if (ffmpeg && (imageFormats.has(ext) || soundFormats.has(ext))) {
      const filters = soundFormats.has(ext) ? ['-filter_complex','showwavespic=s=256x128:colors=0x97b9dd','-frames:v','1'] : ['-frames:v','1'];
      data = run(ffmpeg, ['-v','error','-i',source,...filters,'-f','image2pipe','-vcodec','png','pipe:1']);
    } else if (ext === '.pdf' && pdftoppm) {
      data = run(pdftoppm, ['-f','1','-l','1','-scale-to','512','-singlefile','-png',source]);
    }
    if (!data && ext === '.pdf' && process.platform === 'win32') {
      const tmp = `${target}.tmp.png`;
      assertSafeOutput(out, tmp); fs.mkdirSync(path.dirname(tmp), {recursive:true});
      const helper = path.join(path.dirname(fileURLToPath(import.meta.url)), 'studio_pdf_preview.ps1');
      const result = spawnSync('powershell.exe', ['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',helper,'-InputPath',source,'-OutputPath',tmp], {windowsHide:true, timeout:30000});
      if (result.status === 0 && fs.existsSync(tmp)) { const bytes = fs.readFileSync(tmp); if (bytes.subarray(0,8).equals(signature)) data = bytes; }
      if (fs.existsSync(tmp)) fs.unlinkSync(tmp);
    }
    // Aseprite requires an output filename, so use a validated temporary file inside the library.
    if (!data && aseFormats.has(ext) && aseprite) {
      const tmp = `${target}.tmp.png`;
      assertSafeOutput(out, tmp); fs.mkdirSync(path.dirname(tmp), {recursive:true});
      const result = spawnSync(aseprite, ['-b',source,'--sheet-type','rows','--sheet-columns','4','--sheet',tmp], {windowsHide:true, timeout:30000});
      if (result.status === 0 && fs.existsSync(tmp)) { const bytes = fs.readFileSync(tmp); if (bytes.subarray(0,8).equals(signature)) data = bytes; }
      if (fs.existsSync(tmp)) fs.unlinkSync(tmp);
    }
    if (!data) { unavailable++; continue; }
    assertSafeOutput(out, target); fs.mkdirSync(path.dirname(target), {recursive:true});
    fs.writeFileSync(target, data); entry.preview = relative; generated++;
  }
  return {generated, cached, unavailable};
}
