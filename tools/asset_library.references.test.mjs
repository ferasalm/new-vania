import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const script = process.env.STUDIO_TEST_LIBRARY_SCRIPT
  || fileURLToPath(new URL("./asset_library.mjs", import.meta.url));
const project = "prototypes/feel-v3";
const original = "Original assets/Demon Court/arch.jpg";
const png = Buffer.from("89504e470d0a1a0a0000000d494844520000002000000040", "hex");
const files = {
  [original]: "original",
  [original + ".import"]: "import settings",
  "Original assets/save room & save point/shrine.jpg": "shrine",
  "Public assets/art/Collection/Tile.bin": "unknown format",
  "Public assets/art/Collection/Tile.png": png,
  "Public assets/audio/Collection/theme.wav": "sound",
  "Public assets/docs/Collection/LICENSE.txt": "license text",
  "Public assets/INDEX.md": "index",
};

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "studio reference gate "));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const src = path.join(root, "new-vania-studio");
  const refs = path.join(root, "new-vania", project, "references");
  const deriv = path.join(src, project, "studio", "reference-derivatives");
  const out = path.join(root, "output");
  for (const [name, bytes] of Object.entries(files)) put(refs, name, bytes);
  put(deriv, "arch clean.png", png);
  put(deriv, "arch sprite.png", png);
  manifest(deriv, [
    { source: original, path: "arch clean.png", type: "cleaned" },
    { source: original, path: "arch sprite.png", type: "sprite", room: "Grand Stair", placeable: "props" },
  ]);
  return { src, refs, out, deriv };
}

function put(root, name, content) {
  const destination = path.join(root, name);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, content);
}

function manifest(root, entries) {
  put(root, "manifest.json", JSON.stringify({ entries }));
}

function run(f, ...args) {
  return spawnSync(process.execPath, [script, "--src", f.src, "--out", f.out, ...args], { encoding: "utf8" });
}

test("Studio discovers the sibling reference tree and accounts for every source file", (t) => {
  const f = fixture(t);
  const result = run(f, "--studio");
  assert.equal(result.status, 0, result.stderr);
  const { entries } = JSON.parse(fs.readFileSync(path.join(f.out, "catalog.json"), "utf8"));
  const references = entries.filter((entry) => entry.origin === "references");
  assert.deepEqual(references.map((entry) => entry.source).sort(), Object.keys(files).sort());
  for (const entry of references) {
    assert.equal(entry.bytes, Buffer.byteLength(files[entry.source]));
    assert.deepEqual(fs.readFileSync(path.join(f.out, "library", entry.path)), Buffer.from(files[entry.source]));
    if (entry.source.endsWith(".import")) assert.equal(entry.type, "import settings");
  }
  assert.equal(references.find((entry) => entry.source === original).area, "Demon Court");
  assert.equal(references.find((entry) => entry.source.endsWith("shrine.jpg")).room, "Save Room");
  assert.equal(references.find((entry) => entry.name === "Tile.bin").type, "other file");
  assert.equal(references.find((entry) => entry.name === "Tile.png").placeable, "props");
  assert.equal(references.find((entry) => entry.name === "LICENSE.txt").type, "document");
  assert.equal(references.find((entry) => entry.name === "theme.wav").type, "audio");
  const derived = entries.filter((entry) => entry.origin === "reference-derivatives");
  assert.equal(derived.length, 2);
  assert.equal(new Set(entries.map((entry) => entry.id)).size, entries.length);
  for (const entry of derived) {
    assert.equal(entry.derived_from, original);
    assert.equal(entry.area, "Demon Court");
    assert.equal(entry.w, 32);
    assert.deepEqual(fs.readFileSync(path.join(f.out, "library", entry.path)), png);
  }
  assert.equal(derived.find((entry) => entry.type === "cleaned").placeable, null);
  const sprite = derived.find((entry) => entry.type === "sprite");
  assert.equal(sprite.placeable, "props");
  assert.equal(sprite.room, "Grand Stair");
});

test("an explicit source must exist and may not overlap the output", (t) => {
  const f = fixture(t);
  const missing = run(f, "--references", path.join(f.refs, "missing"));
  assert.notEqual(missing.status, 0);
  assert.match(missing.stderr, /reference source/);
  const overlap = run({ ...f, out: path.join(f.refs, "output") }, "--references", f.refs);
  assert.notEqual(overlap.status, 0);
  assert.match(overlap.stderr, /overlap/);
  assert.equal(fs.existsSync(path.join(f.refs, "output")), false);
});

test("a derivative manifest cannot reach outside its own directory", (t) => {
  const f = fixture(t);
  put(path.dirname(f.deriv), "outside.png", png);
  manifest(f.deriv, [{ source: original, path: "../outside.png", type: "sprite" }]);
  const result = run(f, "--references", f.refs);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /invalid derivative path/);
  assert.equal(fs.existsSync(f.out), false);
});

