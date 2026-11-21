// Gate tests for tools/asset_library.mjs (Studio slice S1). Written from the spec, never from the script.
// Run from the repo root: node --test tools/asset_library.test.mjs
//
// Contract under test (see production/briefs/2026-11-20/S1-deepseek.md):
//   node tools/asset_library.mjs [--dry-run] [--src <repoRoot>] [--out <studioDir>]
//   default src = the repo root, default out = <src>/prototypes/feel-v3/studio
//   sources copied into <out>/library/<category path>: <src>/prototypes/feel-v3/assets, <src>/assets, <src>/design/art/concepts
//   catalog only (never copied): <src>/prototypes/feel-v3/tools/models/bank (kind "3d"), <src>/inbox (kind "inbox")
//   writes <out>/catalog.json; --dry-run writes nothing and prints the catalog JSON on stdout
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import zlib from "node:zlib";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "..");
const SCRIPT = path.join(HERE, "asset_library.mjs");
const KINDS = ["image", "audio", "source", "3d", "inbox"];
const PLACEABLE = ["tiles", "props", "backdrops", null];

// ---- helpers (independent of the script) ----
function crc32(buf) {
  let c, crc = 0xffffffff;
  for (let n = 0; n < buf.length; n++) {
    c = (crc ^ buf[n]) & 0xff;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    crc = (crc >>> 8) ^ c;
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}
function png(w, h) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2;
  const raw = Buffer.alloc((w * 3 + 1) * h, 0x7f);
  return Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]);
}
function put(root, rel, data) {
  const p = path.join(root, ...rel.split("/"));
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, data);
}
function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out); else out.push(p);
  }
  return out;
}
function snapshot(dir) {
  return walk(dir).map((p) => `${path.relative(dir, p).split(path.sep).join("/")}|${fs.statSync(p).size}|${fs.statSync(p).mtimeMs}`).sort();
}
function run(args, opts = {}) {
  return spawnSync(process.execPath, [SCRIPT, ...args], { encoding: "utf8", maxBuffer: 256 * 1024 * 1024, timeout: 240000, ...opts });
}
const A = "prototypes/feel-v3/assets";
function fixture() {
  const base = fs.mkdtempSync(path.join(os.tmpdir(), "assetlib-"));
  const src = path.join(base, "src");
  const out = path.join(base, "out");
  const files = {
    [`${A}/pandora/idle.png`]: png(4, 5),
    [`${A}/sprites-pandora/walk.png`]: png(3, 3),
    [`${A}/2x/pandora/idle.png`]: png(8, 10),
    [`${A}/moth/a.png`]: png(2, 2),
    [`${A}/2x/moth/a.png`]: png(4, 4),
    [`${A}/boss/b.png`]: png(5, 5),
    [`${A}/2x/boss/b.png`]: png(10, 10),
    [`${A}/env/e.png`]: png(6, 6),
    [`${A}/2x/env/e.png`]: png(12, 12),
    [`${A}/fx/f.png`]: png(2, 3),
    [`${A}/weapon/w.png`]: png(3, 2),
    [`${A}/items/i.png`]: png(2, 2),
    [`${A}/palettes/p.png`]: png(1, 1),
    [`${A}/audio/music/m.ogg`]: Buffer.from("OggS-fixture-music"),
    [`${A}/audio/sfx/special/s.wav`]: Buffer.from("RIFF-fixture-sfx"),
    [`${A}/references/r.png`]: png(2, 2),
    [`${A}/hero_2d_base/h.png`]: png(2, 2),
    [`${A}/zzz/o.png`]: png(2, 2),
    [`${A}/zzz/model.aseprite`]: Buffer.from("ase-fixture"),
    [`${A}/zzz/notes.txt`]: Buffer.from("not an asset"),
    "assets/art/x.png": png(2, 2),
    "assets/audio/y.wav": Buffer.from("RIFF-root-audio"),
    "design/art/concepts/c.jpg": Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
    "prototypes/feel-v3/tools/models/bank/m.glb": Buffer.from("glTF-fixture"),
    "inbox/raw.png": png(2, 2),
  };
  for (const [rel, data] of Object.entries(files)) put(src, rel, data);
  return { base, src, out, files };
}
function catalogOf(out) { return JSON.parse(fs.readFileSync(path.join(out, "catalog.json"), "utf8")); }
function byName(cat, rel) { return cat.entries.find((e) => e.source === rel); }

// ---- the fixture run ----
test("the script exists and a real run writes catalog.json and a library", () => {
  const f = fixture();
  const r = run(["--src", f.src, "--out", f.out]);
  assert.equal(r.status, 0, `exit ${r.status}\n${r.stderr}\n${r.stdout}`);
  assert.ok(fs.existsSync(path.join(f.out, "catalog.json")), "catalog.json written");
  assert.ok(fs.existsSync(path.join(f.out, "library")), "library folder written");
});

test("catalog schema: version, generated, categories with counts, entries with every field and a valid type", () => {
  const f = fixture(); run(["--src", f.src, "--out", f.out]);
  const cat = catalogOf(f.out);
  assert.equal(typeof cat.version, "number");
  assert.equal(typeof cat.generated, "string");
  assert.ok(!Number.isNaN(Date.parse(cat.generated)), "generated is a date string");
  assert.ok(Array.isArray(cat.categories) && Array.isArray(cat.entries) && cat.entries.length > 0);
  const ids = new Set();
  for (const e of cat.entries) {
    for (const k of ["id", "name", "category", "sub", "kind", "path", "source", "w", "h", "bytes", "tags", "placeable", "help_key"]) {
      assert.ok(Object.hasOwn(e, k), `entry ${e.source} lacks ${k}`);
    }
    assert.equal(typeof e.id, "string"); assert.ok(e.id.length > 0);
    assert.ok(!ids.has(e.id), `duplicate id ${e.id}`); ids.add(e.id);
    assert.ok(KINDS.includes(e.kind), `bad kind ${e.kind}`);
    assert.ok(PLACEABLE.includes(e.placeable), `bad placeable ${e.placeable}`);
    assert.ok(Array.isArray(e.tags) && e.tags.every((t) => typeof t === "string"));
    assert.equal(e.help_key, `asset:${e.id}`);
    assert.equal(e.name, path.posix.basename(e.source));
    assert.ok(!e.source.includes("\\") && !e.path.includes("\\"), "forward slashes only");
  }
  for (const c of cat.categories) {
    assert.equal(c.count, cat.entries.filter((e) => e.category === c.id).length, `count of ${c.id}`);
  }
  assert.equal(cat.categories.reduce((n, c) => n + c.count, 0), cat.entries.length, "every entry is in exactly one category");
});

test("the category map: every fixture file lands in the right category and library folder", () => {
  const f = fixture(); run(["--src", f.src, "--out", f.out]);
  const cat = catalogOf(f.out);
  const want = [
    [`${A}/pandora/idle.png`, "characters", "characters/pandora/"],
    [`${A}/sprites-pandora/walk.png`, "characters", "characters/pandora/"],
    [`${A}/2x/pandora/idle.png`, "characters", "characters/pandora/"],
    [`${A}/moth/a.png`, "enemies", "enemies/moth/1x/"],
    [`${A}/2x/moth/a.png`, "enemies", "enemies/moth/2x/"],
    [`${A}/boss/b.png`, "bosses", "bosses/"],
    [`${A}/2x/boss/b.png`, "bosses", "bosses/"],
    [`${A}/env/e.png`, "environment", "environment/1x/"],
    [`${A}/2x/env/e.png`, "environment", "environment/2x/"],
    [`${A}/fx/f.png`, "fx", "fx/"],
    [`${A}/weapon/w.png`, "weapon", "weapon/"],
    [`${A}/items/i.png`, "items", "items/"],
    [`${A}/palettes/p.png`, "palettes", "palettes/"],
    [`${A}/audio/music/m.ogg`, "audio", "audio/music/"],
    [`${A}/audio/sfx/special/s.wav`, "audio", "audio/sfx/special/"],
    [`${A}/references/r.png`, "source", "source/references/"],
    [`${A}/hero_2d_base/h.png`, "source", "source/hero_2d_base/"],
    ["assets/art/x.png", "root-assets", "root-assets/art/"],
    ["assets/audio/y.wav", "root-assets", "root-assets/audio/"],
    ["design/art/concepts/c.jpg", "concepts", "concepts/"],
    [`${A}/zzz/o.png`, "other", "other/"],
  ];
  for (const [rel, category, prefix] of want) {
    const e = byName(cat, rel);
    assert.ok(e, `no entry for ${rel}`);
    assert.equal(e.category, category, `${rel} category`);
    assert.ok(e.path.startsWith(prefix), `${rel} path ${e.path} should start with ${prefix}`);
  }
});

test("kinds, sizes and dimensions: images, audio and source files are told apart; non-assets are skipped", () => {
  const f = fixture(); run(["--src", f.src, "--out", f.out]);
  const cat = catalogOf(f.out);
  assert.equal(byName(cat, `${A}/pandora/idle.png`).kind, "image");
  assert.equal(byName(cat, `${A}/audio/music/m.ogg`).kind, "audio");
  assert.equal(byName(cat, "assets/audio/y.wav").kind, "audio");
  assert.equal(byName(cat, `${A}/zzz/model.aseprite`).kind, "source");
  assert.equal(byName(cat, "design/art/concepts/c.jpg").kind, "image");
  assert.equal(byName(cat, `${A}/zzz/notes.txt`), undefined, "a .txt file is not an asset");
  const p = byName(cat, `${A}/pandora/idle.png`);
  assert.equal(p.w, 4); assert.equal(p.h, 5);
  assert.equal(p.bytes, f.files[`${A}/pandora/idle.png`].length);
  assert.equal(byName(cat, `${A}/audio/music/m.ogg`).w, null);
  assert.equal(byName(cat, `${A}/audio/music/m.ogg`).h, null);
});

test("every copied file exists in the library with the same bytes as its source", () => {
  const f = fixture(); run(["--src", f.src, "--out", f.out]);
  const cat = catalogOf(f.out);
  let copied = 0;
  for (const e of cat.entries.filter((x) => x.kind !== "3d" && x.kind !== "inbox")) {
    const lib = path.join(f.out, "library", ...e.path.split("/"));
    assert.ok(fs.existsSync(lib), `missing library file ${e.path}`);
    assert.ok(fs.readFileSync(lib).equals(fs.readFileSync(path.join(f.src, ...e.source.split("/")))), `bytes differ for ${e.path}`);
    copied++;
  }
  assert.ok(copied >= 21, `expected at least 21 copied files, got ${copied}`);
  assert.equal(walk(path.join(f.out, "library")).length, copied, "the library holds exactly the copied entries and nothing else");
});

test("the 3D bank and the inbox are catalogued but never copied", () => {
  const f = fixture(); run(["--src", f.src, "--out", f.out]);
  const cat = catalogOf(f.out);
  const m = byName(cat, "prototypes/feel-v3/tools/models/bank/m.glb");
  const i = byName(cat, "inbox/raw.png");
  assert.ok(m && i, "both catalog-only files have entries");
  assert.equal(m.kind, "3d"); assert.equal(i.kind, "inbox");
  assert.equal(m.path, ""); assert.equal(i.path, "");
  const all = walk(path.join(f.out, "library")).map((p) => p.split(path.sep).join("/"));
  assert.ok(!all.some((p) => /glb|inbox|raw\.png|bank/.test(p)), `library must not hold bank or inbox files: ${all.filter((p) => /glb|inbox|raw|bank/.test(p))}`);
});

test("a second run changes nothing (same bytes, same modification times, same catalog but the date)", () => {
  const f = fixture(); run(["--src", f.src, "--out", f.out]);
  // Windows CopyFile keeps the source time, so a rewrite is invisible unless the copies start with an old time.
  const OLD = new Date("2001-01-01T00:00:00Z");
  for (const p of walk(path.join(f.out, "library"))) fs.utimesSync(p, OLD, OLD);
  const before = snapshot(path.join(f.out, "library"));
  const cat1 = catalogOf(f.out);
  const r = run(["--src", f.src, "--out", f.out]);
  assert.equal(r.status, 0, r.stderr);
  assert.deepEqual(snapshot(path.join(f.out, "library")), before, "library files rewritten");
  const cat2 = catalogOf(f.out);
  delete cat1.generated; delete cat2.generated;
  assert.deepEqual(cat2, cat1);
});

test("a changed source file is copied again on the next run", () => {
  const f = fixture(); run(["--src", f.src, "--out", f.out]);
  put(f.src, `${A}/pandora/idle.png`, png(9, 9));
  run(["--src", f.src, "--out", f.out]);
  const e = byName(catalogOf(f.out), `${A}/pandora/idle.png`);
  assert.equal(e.w, 9);
  assert.ok(fs.readFileSync(path.join(f.out, "library", ...e.path.split("/"))).equals(png(9, 9)));
  // same size, different content: the copy must still be refreshed (size alone is not enough)
  const same = Buffer.from("OggS-fixture-other");
  assert.equal(same.length, f.files[`${A}/audio/music/m.ogg`].length, "fixture sanity: same length");
  put(f.src, `${A}/audio/music/m.ogg`, same);
  run(["--src", f.src, "--out", f.out]);
  const o = byName(catalogOf(f.out), `${A}/audio/music/m.ogg`);
  assert.ok(fs.readFileSync(path.join(f.out, "library", ...o.path.split("/"))).equals(same), "same-size change not copied");
});

test("--dry-run writes nothing and prints the same catalog a real run writes", () => {
  const f = fixture();
  const srcBefore = snapshot(f.src);
  const r = run(["--dry-run", "--src", f.src, "--out", f.out]);
  assert.equal(r.status, 0, r.stderr);
  assert.ok(!fs.existsSync(f.out), "--dry-run must not create the out folder");
  assert.deepEqual(snapshot(f.src), srcBefore, "--dry-run must not touch the sources");
  const dry = JSON.parse(r.stdout);
  run(["--src", f.src, "--out", f.out]);
  const real = catalogOf(f.out);
  delete dry.generated; delete real.generated;
  assert.deepEqual(dry, real);
});

test("it never writes outside --out and never changes the sources", () => {
  const f = fixture();
  const srcBefore = snapshot(f.src);
  run(["--src", f.src, "--out", f.out]);
  assert.deepEqual(snapshot(f.src), srcBefore, "sources changed");
  assert.deepEqual(fs.readdirSync(f.base).sort(), ["out", "src"], "nothing else appeared next to src and out");
});

test("a missing source folder is not an error (the run succeeds and catalogues what exists)", () => {
  const base = fs.mkdtempSync(path.join(os.tmpdir(), "assetlib-empty-"));
  const src = path.join(base, "src");
  put(src, `${A}/fx/f.png`, png(2, 2));
  const r = run(["--src", src, "--out", path.join(base, "out")]);
  assert.equal(r.status, 0, r.stderr);
  const cat = catalogOf(path.join(base, "out"));
  assert.equal(cat.entries.length, 1);
  assert.equal(cat.entries[0].category, "fx");
});

// ---- the real repository ----
test("real repo, dry run: the image and audio counts equal an independent count of the source folders", () => {
  const roots = [path.join(ROOT, A), path.join(ROOT, "assets"), path.join(ROOT, "design", "art", "concepts")];
  const IMG = new Set([".png", ".jpg", ".jpeg", ".gif", ".webp"]);
  const AUD = new Set([".wav", ".ogg", ".mp3"]);
  let img = 0, aud = 0;
  for (const root of roots) for (const p of walk(root)) {
    const ext = path.extname(p).toLowerCase();
    if (IMG.has(ext)) img++; else if (AUD.has(ext)) aud++;
  }
  assert.ok(img > 500 && aud > 50, `sanity: the repo should hold many assets (img ${img}, audio ${aud})`);
  const r = run(["--dry-run"], { cwd: ROOT });
  assert.equal(r.status, 0, r.stderr);
  const cat = JSON.parse(r.stdout);
  const copiedImg = cat.entries.filter((e) => e.kind === "image").length;
  const copiedAud = cat.entries.filter((e) => e.kind === "audio").length;
  assert.equal(copiedImg, img, "image entries");
  assert.equal(copiedAud, aud, "audio entries");
  const ids = new Set(cat.entries.map((e) => e.id));
  assert.equal(ids.size, cat.entries.length, "ids are unique across the real repo");
});

test("the Studio folder keeps the game export small: .gdignore exists, the library folder is git-ignored", () => {
  const studio = path.join(ROOT, "prototypes", "feel-v3", "studio");
  assert.ok(fs.existsSync(path.join(studio, ".gdignore")), "prototypes/feel-v3/studio/.gdignore is mandatory");
  assert.ok(fs.existsSync(path.join(studio, "README.md")), "studio/README.md");
  const ignore = fs.readFileSync(path.join(ROOT, ".gitignore"), "utf8").split(/\r?\n/).map((l) => l.trim());
  assert.ok(ignore.some((l) => l === "prototypes/feel-v3/studio/library/" || l === "prototypes/feel-v3/studio/library"),
    ".gitignore must list prototypes/feel-v3/studio/library/");
});
