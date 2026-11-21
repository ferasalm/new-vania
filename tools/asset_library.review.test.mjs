import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import test from "node:test";

const script = fileURLToPath(new URL("./asset_library.mjs", import.meta.url));
const scratch = fileURLToPath(new URL("../prototypes/feel-v3/tests_v4/logs/", import.meta.url));
const prefix = "prototypes/feel-v3/assets/";
fs.mkdirSync(scratch, { recursive: true });

function fixture() {
  const base = fs.mkdtempSync(path.join(scratch, "library-review-"));
  return { src: path.join(base, "source"), out: path.join(base, "output") };
}

function put(root, name, text) {
  const file = path.join(root, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
}

function run({ src, out }, ...extra) {
  return spawnSync(process.execPath, [script, "--src", src, "--out", out, ...extra], {
    encoding: "utf8",
  });
}

test("a present source root that cannot be scanned fails before replacing the catalog", () => {
  const dirs = fixture();
  put(dirs.src, prefix.slice(0, -1), "This path is a file.");
  put(dirs.out, "catalog.json", "existing catalog");
  const result = run(dirs);
  assert.notEqual(result.status, 0);
  assert.equal(fs.readFileSync(path.join(dirs.out, "catalog.json"), "utf8"), "existing catalog");
});

test("JPEG remains in the catalog without a placement kind", () => {
  const dirs = fixture();
  put(dirs.src, prefix + "env/lamp.jpg", "test image");
  const result = run(dirs, "--dry-run");
  assert.equal(result.status, 0, result.stderr);
  const [entry] = JSON.parse(result.stdout).entries;
  assert.equal(entry.kind, "image");
  assert.equal(entry.placeable, null);
});

test("case-only names map to unique paths and retain their own bytes", () => {
  const dirs = fixture();
  put(dirs.src, prefix + "pandora/idle.png", "first");
  put(dirs.src, prefix + "2x/pandora/Idle.png", "second");
  const result = run(dirs);
  assert.equal(result.status, 0, result.stderr);
  const { entries } = JSON.parse(fs.readFileSync(path.join(dirs.out, "catalog.json"), "utf8"));
  assert.equal(new Set(entries.map((entry) => entry.path.toLowerCase())).size, 2);
  for (const entry of entries) {
    assert.deepEqual(
      fs.readFileSync(path.join(dirs.out, "library", entry.path)),
      fs.readFileSync(path.join(dirs.src, entry.source)),
    );
  }
});

test("a linked output directory is refused before copying", () => {
  const dirs = fixture();
  put(dirs.src, prefix + "env/lamp.png", "fixture");
  const target = path.join(path.dirname(dirs.out), "link-target");
  fs.mkdirSync(target);
  fs.mkdirSync(dirs.out);
  fs.symlinkSync(target, path.join(dirs.out, "library"), process.platform === "win32" ? "junction" : "dir");
  const result = run(dirs);
  assert.notEqual(result.status, 0);
  assert.deepEqual(fs.readdirSync(target), []);
});
