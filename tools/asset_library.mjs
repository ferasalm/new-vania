#!/usr/bin/env node
/**
 * asset_library.mjs
 *
 * Builds the feel-v3 Studio asset library. Every image, sound and source
 * file of the project is copied into one organised folder, and a
 * catalog.json is written that describes every file - including the files
 * that are catalogued but never copied (the 3D model bank and the inbox).
 *
 * Usage:
 *   node tools/asset_library.mjs [--dry-run] [--src <repoRoot>] [--out <studioDir>]
 *
 *   --src      repository root; defaults to the parent of tools/
 *   --out      Studio folder; defaults to <src>/prototypes/feel-v3/studio
 *   --dry-run  write nothing, print the catalog JSON on stdout
 *
 * Node built-ins only. The script never writes outside --out and never
 * modifies the source tree.
 */

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

/** Directory holding this script (the repository's tools/ folder). */
const TOOLS_DIR = path.dirname(fileURLToPath(import.meta.url));

/** Repository root used when --src is omitted: the parent of tools/. */
const DEFAULT_SRC = path.resolve(TOOLS_DIR, "..");

/** Extensions that make a file an image. */
const IMAGE_EXT = new Set([".png", ".jpg", ".jpeg", ".gif", ".webp"]);

/** Extensions that make a file audio. */
const AUDIO_EXT = new Set([".wav", ".ogg", ".mp3"]);

/** Extensions that make a file an editable source asset. */
const SOURCE_EXT = new Set([".aseprite", ".blend", ".gpl", ".psd", ".kra", ".xcf", ".svg"]);

/** Extensions catalogued from the 3D model bank. */
const MODEL_EXT = new Set([".glb", ".gltf", ".obj", ".fbx", ".blend", ".stl", ".ply"]);

/** Folders under prototypes/feel-v3/assets that hold character art. */
const CHARACTER_DIRS = new Set(["pandora", "hero", "hero_v2", "sprites-pandora"]);

/** Folders under prototypes/feel-v3/assets/2x that hold character art. */
const CHARACTER_2X = new Set(["pandora", "pandora_b"]);

/** Folders under prototypes/feel-v3/assets that hold enemy art. */
const ENEMY_DIRS = new Set([
  "hound", "ghost", "choir", "spitter", "warden",
  "crab", "leech", "moth", "organ", "scribe",
]);

/** Folders under prototypes/feel-v3/assets that hold reference/source art. */
const SOURCE_DIRS = new Set([
  "references", "hero_2d_base", "pandora_proportion_study", "hero_3d_preview",
]);

/** Top-level folders under assets/ that are copied as root-assets. */
const ROOT_ASSET_DIRS = new Set(["art", "processed", "audio", "umbrella"]);

/** Folders under prototypes/feel-v3/assets copied under their own name. */
const FLAT_DIRS = new Set(["fx", "weapon", "items", "palettes"]);

/** Roots whose files are copied into the library. */
const COPY_ROOTS = ["prototypes/feel-v3/assets", "assets", "design/art/concepts"];

/** Roots whose files are catalogued only, with the kind forced for them. */
const CATALOG_ONLY_ROOTS = [
  { root: "prototypes/feel-v3/tools/models/bank", kind: "3d" },
  { root: "inbox", kind: "inbox" },
];

/** Prefixes of the three copy roots, with a trailing slash. */
const A_PREFIX = "prototypes/feel-v3/assets/";
const ASSETS_PREFIX = "assets/";
const CONCEPTS_PREFIX = "design/art/concepts/";

/**
 * Parse the command line into options.
 * @param {string[]} argv arguments after the script name
 * @returns {{dryRun: boolean, src: string, out: string}}
 */
function parseArgs(argv) {
  const opts = { dryRun: false, src: DEFAULT_SRC, out: null };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--dry-run") {
      opts.dryRun = true;
    } else if (arg === "--src" || arg === "--out") {
      const value = argv[i + 1];
      if (value === undefined || value.startsWith("--")) {
        throw new Error(`${arg} needs a value`);
      }
      opts[arg.slice(2)] = value;
      i += 1;
    } else if (arg.startsWith("--src=")) {
      opts.src = arg.slice("--src=".length);
    } else if (arg.startsWith("--out=")) {
      opts.out = arg.slice("--out=".length);
    } else {
      throw new Error(`unknown argument: ${arg}`);
    }
  }
  if (!opts.src) throw new Error("--src needs a value");
  opts.src = path.resolve(opts.src);
  opts.out = path.resolve(opts.out ?? path.join(opts.src, "prototypes", "feel-v3", "studio"));
  return opts;
}

/**
 * Convert a platform path to a catalog path (forward slashes everywhere).
 * @param {string} value a path using the platform separator
 * @returns {string} the same path with forward slashes
 */
function toPosix(value) {
  return value.split(path.sep).join("/");
}

/**
 * Tell whether a path lives inside a folder (the folder itself counts).
 * @param {string} parent absolute folder path
 * @param {string} child absolute path to test
 * @returns {boolean} true when child is parent or below it
 */
function isInside(parent, child) {
  const rel = path.relative(parent, child);
  if (rel === "") return true;
  return rel !== ".." && !rel.startsWith(`..${path.sep}`) && !path.isAbsolute(rel);
}

/**
 * Walk a folder recursively and return every non-directory entry.
 * Missing folders yield an empty list instead of an error.
 * @param {string} rootAbs absolute folder to walk
 * @returns {string[]} absolute file paths
 */
function walkFiles(rootAbs) {
  const files = [];
  let stat;
  try {
    stat = fs.statSync(rootAbs);
  } catch (error) {
    if (error.code === "ENOENT") return files;
    throw error;
  }
  if (!stat.isDirectory()) throw new Error(`asset source is not a directory: ${rootAbs}`);
  const stack = [rootAbs];
  while (stack.length > 0) {
    const dir = stack.pop();
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    entries.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
    for (const entry of entries) {
      if (entry.isSymbolicLink()) continue; // never follow links out of the source folders
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) stack.push(abs);
      else files.push(abs);
    }
  }
  return files;
}

/**
 * Classify a file by its lower-cased extension.
 * @param {string} ext extension including the dot
 * @returns {"image"|"audio"|"source"|null} the asset kind, or null when not an asset
 */
function kindOf(ext) {
  if (IMAGE_EXT.has(ext)) return "image";
  if (AUDIO_EXT.has(ext)) return "audio";
  if (SOURCE_EXT.has(ext)) return "source";
  return null;
}

/**
 * Read width and height from a PNG header without loading the whole file.
 * @param {string} abs absolute path of the candidate file
 * @returns {[number|null, number|null]} the dimensions, or [null, null]
 */
function readPngSize(abs) {
  let fd;
  try {
    fd = fs.openSync(abs, "r");
    const buf = Buffer.alloc(24);
    const read = fs.readSync(fd, buf, 0, 24, 0);
    if (read < 24) return [null, null];
    const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    for (let i = 0; i < signature.length; i += 1) {
      if (buf[i] !== signature[i]) return [null, null];
    }
    if (buf.toString("ascii", 12, 16) !== "IHDR") return [null, null];
    return [buf.readUInt32BE(16), buf.readUInt32BE(20)];
  } catch {
    return [null, null];
  } finally {
    if (fd !== undefined) {
      try {
        fs.closeSync(fd);
      } catch {
        /* the handle is already gone */
      }
    }
  }
}

/**
 * Build search tags from the folder names and the file stem.
 * @param {string} sourceRel source path relative to the repo root
 * @returns {string[]} up to twelve lower-case, de-duplicated tags
 */
function buildTags(sourceRel) {
  const parts = sourceRel.split("/");
  const fileName = parts[parts.length - 1];
  const stem = fileName.replace(/\.[^.]*$/, "");
  const tags = [];
  for (const folder of parts.slice(0, -1)) tags.push(folder.toLowerCase());
  tags.push(stem.toLowerCase());
  const seen = new Set();
  const unique = [];
  for (const tag of tags) {
    if (tag && !seen.has(tag)) {
      seen.add(tag);
      unique.push(tag);
    }
  }
  if (unique.length <= 12) return unique;
  const stemTag = stem.toLowerCase();
  const trimmed = unique.slice(0, 11);
  if (!trimmed.includes(stemTag)) trimmed.push(stemTag);
  return trimmed;
}

/**
 * Map a source path under prototypes/feel-v3/assets to its category.
 * @param {string} rel path relative to that assets folder
 * @returns {{category: string, folder: string, rest: string}} mapping
 */
function mapFeelAsset(rel) {
  const parts = rel.split("/");
  const first = parts[0];
  const restAfter = (count) => parts.slice(count).join("/");
  if (first === "2x") {
    const second = parts[1];
    if (CHARACTER_2X.has(second)) {
      return { category: "characters", folder: "characters/pandora", rest: restAfter(2) };
    }
    if (ENEMY_DIRS.has(second)) {
      return { category: "enemies", folder: `enemies/${second}/2x`, rest: restAfter(2) };
    }
    if (second === "boss") {
      return { category: "bosses", folder: "bosses", rest: restAfter(2) };
    }
    if (second === "env") {
      return { category: "environment", folder: "environment/2x", rest: restAfter(2) };
    }
    return { category: "other", folder: "other", rest: rel };
  }
  if (CHARACTER_DIRS.has(first)) {
    return { category: "characters", folder: "characters/pandora", rest: restAfter(1) };
  }
  if (ENEMY_DIRS.has(first)) {
    return { category: "enemies", folder: `enemies/${first}/1x`, rest: restAfter(1) };
  }
  if (first === "boss") {
    return { category: "bosses", folder: "bosses", rest: restAfter(1) };
  }
  if (first === "env") {
    return { category: "environment", folder: "environment/1x", rest: restAfter(1) };
  }
  if (FLAT_DIRS.has(first)) {
    return { category: first, folder: first, rest: restAfter(1) };
  }
  if (first === "audio") {
    const second = parts[1];
    if (second === "music") {
      return { category: "audio", folder: "audio/music", rest: restAfter(2) };
    }
    if (second === "sfx") {
      if (parts[2] !== undefined && parts.length >= 4) {
        return { category: "audio", folder: `audio/sfx/${parts[2]}`, rest: restAfter(3) };
      }
      return { category: "audio", folder: "audio/sfx", rest: restAfter(2) };
    }
    return { category: "other", folder: "other", rest: rel };
  }
  if (SOURCE_DIRS.has(first)) {
    return { category: "source", folder: `source/${first}`, rest: restAfter(1) };
  }
  return { category: "other", folder: "other", rest: rel };
}

/**
 * Map a source path (relative to the repo root) to its category and folder.
 * @param {string} sourceRel source path relative to the repo root
 * @returns {{category: string, folder: string, rest: string}} mapping
 */
function mapCategory(sourceRel) {
  if (sourceRel.startsWith(A_PREFIX)) {
    return mapFeelAsset(sourceRel.slice(A_PREFIX.length));
  }
  if (sourceRel.startsWith(CONCEPTS_PREFIX)) {
    return {
      category: "concepts",
      folder: "concepts",
      rest: sourceRel.slice(CONCEPTS_PREFIX.length),
    };
  }
  if (sourceRel.startsWith(ASSETS_PREFIX)) {
    const rest = sourceRel.slice(ASSETS_PREFIX.length);
    const first = rest.split("/")[0];
    if (ROOT_ASSET_DIRS.has(first)) {
      return {
        category: "root-assets",
        folder: `root-assets/${first}`,
        rest: rest.split("/").slice(1).join("/"),
      };
    }
    return { category: "other", folder: "other", rest };
  }
  return { category: "other", folder: "other", rest: sourceRel };
}

/**
 * Choose a first-guess placement for an image.
 * @param {string} category the entry's category id
 * @param {string} kind the entry's kind
 * @param {number|null} w image width, when known
 * @param {number|null} h image height, when known
 * @returns {"tiles"|"props"|"backdrops"|null} the placement guess
 */
function placeableFor(category, kind, w, h, ext) {
  if (kind !== "image" || ext !== ".png") return null;
  if (category === "environment") {
    if (w !== null && h !== null && w <= 32 && h <= 32) return "tiles";
    if (w !== null && w >= 384) return "backdrops";
    return "props";
  }
  if (category === "items" || category === "fx" || category === "weapon") return "props";
  return null;
}

/**
 * Build a stable, unique id from the source path.
 * @param {string} sourceRel source path relative to the repo root
 * @param {Set<string>} used ids already handed out
 * @returns {string} the new id
 */
function makeId(sourceRel, used) {
  const base = sourceRel.toLowerCase().replace(/[^a-z0-9]/g, "_");
  const hash = crypto.createHash("sha1").update(sourceRel).digest("hex");
  let id = `${base}_${hash.slice(0, 6)}`;
  let length = 8;
  while (used.has(id) && length <= hash.length) {
    id = `${base}_${hash.slice(0, length)}`;
    length += 2;
  }
  let suffix = 2;
  while (used.has(id)) {
    id = `${base}_${hash}_${suffix}`;
    suffix += 1;
  }
  used.add(id);
  return id;
}

/**
 * Claim a library path, disambiguating a rare collision between roots.
 * @param {string} candidate proposed library path
 * @param {string} sourceRel source path that owns the file
 * @param {Map<string, string>} used library paths already claimed
 * @returns {string} a free library path
 */
function claimPath(candidate, sourceRel, used) {
  const key = candidate.toLowerCase();
  if (!used.has(key)) {
    used.set(key, sourceRel);
    return candidate;
  }
  const ext = path.posix.extname(candidate);
  const stem = candidate.slice(0, candidate.length - ext.length);
  const tag = crypto.createHash("sha1").update(sourceRel).digest("hex").slice(0, 6);
  let next = `${stem}-${tag}${ext}`;
  let suffix = 2;
  while (used.has(next.toLowerCase())) {
    next = `${stem}-${tag}-${suffix}${ext}`;
    suffix += 1;
  }
  used.set(next.toLowerCase(), sourceRel);
  return next;
}

/**
 * Collect the candidate files of one root into the shared list.
 * @param {{src: string, out: string}} opts resolved options
 * @param {string} rootRel root path relative to the repo root
 * @param {"3d"|"inbox"|null} forcedKind kind forced by the root, or null to use the extension
 * @param {object[]} out accumulated file records
 */
function collectFiles(opts, rootRel, forcedKind, out) {
  const rootAbs = path.join(opts.src, ...rootRel.split("/"));
  for (const abs of walkFiles(rootAbs)) {
    if (isInside(opts.out, abs)) continue;
    const stat = fs.statSync(abs);
    if (!stat.isFile()) continue;
    const rel = toPosix(path.relative(opts.src, abs));
    const ext = path.extname(rel).toLowerCase();
    const kind = forcedKind ?? kindOf(ext);
    if (!kind) continue;
    if (forcedKind === "3d" && !MODEL_EXT.has(ext)) continue;
    out.push({ rel, abs, ext, kind, bytes: stat.size, copy: forcedKind === null });
  }
}

/**
 * Turn a collected file record into a catalog entry.
 * @param {object} file collected file record
 * @param {Set<string>} usedIds ids already handed out
 * @param {Map<string, string>} usedPaths library paths already claimed
 * @returns {object} the catalog entry
 */
function makeEntry(file, usedIds, usedPaths) {
  const name = path.posix.basename(file.rel);
  const [w, h] = file.ext === ".png" ? readPngSize(file.abs) : [null, null];
  const id = makeId(file.rel, usedIds);
  let category;
  let sub = "";
  let libPath = "";
  if (file.copy) {
    const mapped = mapCategory(file.rel);
    category = mapped.category;
    sub = mapped.folder === mapped.category
      ? ""
      : mapped.folder.slice(mapped.category.length + 1);
    libPath = claimPath(`${mapped.folder}/${mapped.rest}`, file.rel, usedPaths);
  } else {
    category = file.kind;
  }
  return {
    id,
    name,
    category,
    sub,
    kind: file.kind,
    path: libPath,
    source: file.rel,
    w,
    h,
    bytes: file.bytes,
    tags: buildTags(file.rel),
    placeable: placeableFor(category, file.kind, w, h, file.ext),
    help_key: `asset:${id}`,
  };
}

/**
 * Build the whole catalog in memory.
 * @param {{src: string, out: string}} opts resolved options
 * @returns {object} the catalog object
 */
function buildCatalog(opts) {
  const files = [];
  for (const root of COPY_ROOTS) collectFiles(opts, root, null, files);
  for (const item of CATALOG_ONLY_ROOTS) collectFiles(opts, item.root, item.kind, files);
  files.sort((a, b) => (a.rel < b.rel ? -1 : a.rel > b.rel ? 1 : 0));

  const usedIds = new Set();
  const usedPaths = new Map();
  const entries = files.map((file) => makeEntry(file, usedIds, usedPaths));

  const counts = new Map();
  for (const entry of entries) {
    counts.set(entry.category, (counts.get(entry.category) ?? 0) + 1);
  }
  const categories = [...counts.entries()]
    .map(([id, count]) => ({ id, count }))
    .sort((a, b) => (a.id < b.id ? -1 : 1));

  return {
    version: 1,
    generated: new Date().toISOString(),
    categories,
    entries,
  };
}

/**
 * Compare two files by size and then by content, in chunks.
 * @param {string} a first file
 * @param {string} b second file
 * @returns {boolean} true when both files hold the same bytes
 */
function sameContent(a, b) {
  const statA = fs.statSync(a);
  const statB = fs.statSync(b);
  if (statA.size !== statB.size) return false;
  const fdA = fs.openSync(a, "r");
  const fdB = fs.openSync(b, "r");
  try {
    const bufA = Buffer.alloc(1 << 20);
    const bufB = Buffer.alloc(1 << 20);
    let pos = 0;
    while (pos < statA.size) {
      const length = Math.min(bufA.length, statA.size - pos);
      const readA = fs.readSync(fdA, bufA, 0, length, pos);
      const readB = fs.readSync(fdB, bufB, 0, length, pos);
      if (readA !== readB) return false;
      if (!bufA.subarray(0, readA).equals(bufB.subarray(0, readB))) return false;
      if (readA === 0) break;
      pos += readA;
    }
    return true;
  } finally {
    fs.closeSync(fdA);
    fs.closeSync(fdB);
  }
}

/**
 * Copy a file unless the destination already holds the same bytes.
 * @param {string} srcAbs source file
 * @param {string} destAbs destination file
 * @returns {boolean} true when a copy was written
 */
function copyIfChanged(srcAbs, destAbs) {
  if (fs.existsSync(destAbs) && sameContent(srcAbs, destAbs)) return false;
  fs.mkdirSync(path.dirname(destAbs), { recursive: true });
  fs.copyFileSync(srcAbs, destAbs);
  return true;
}

/**
 * Refuse symbolic links and junctions at the output root or below it.
 * Check each component in order before traversing into the next one.
 */
function assertUnlinkedOutput(root, dest) {
  let current = root;
  const relative = path.relative(root, dest);
  for (const component of ["", ...relative.split(path.sep).filter(Boolean)]) {
    current = path.join(current, component);
    const stat = fs.lstatSync(current, { throwIfNoEntry: false });
    if (stat?.isSymbolicLink()) throw new Error(`refusing linked output path: ${current}`);
  }
}

/**
 * Copy every copied entry into the library.
 * @param {{src: string, out: string}} opts resolved options
 * @param {object} catalog the catalog to materialise
 * @returns {{copied: number, unchanged: number, catalogOnly: number}} copy counts
 */
function writeLibrary(opts, catalog) {
  const library = path.join(opts.out, "library");
  assertUnlinkedOutput(opts.out, library);
  fs.mkdirSync(library, { recursive: true });
  let copied = 0;
  let unchanged = 0;
  let catalogOnly = 0;
  for (const entry of catalog.entries) {
    if (entry.path === "") {
      catalogOnly += 1;
      continue;
    }
    const srcAbs = path.join(opts.src, ...entry.source.split("/"));
    const destAbs = path.join(library, ...entry.path.split("/"));
    if (!isInside(library, destAbs)) throw new Error(`refusing to write outside the library: ${entry.path}`);
    assertUnlinkedOutput(opts.out, destAbs);
    if (copyIfChanged(srcAbs, destAbs)) copied += 1;
    else unchanged += 1;
  }
  return { copied, unchanged, catalogOnly };
}

/**
 * Run the command: build the catalog, then either print it or write it.
 */
function main() {
  const opts = parseArgs(process.argv.slice(2));
  const catalog = buildCatalog(opts);
  if (opts.dryRun) {
    process.stdout.write(`${JSON.stringify(catalog, null, 2)}\n`);
    return;
  }
  const catalogPath = path.join(opts.out, "catalog.json");
  assertUnlinkedOutput(opts.out, catalogPath);
  const stats = writeLibrary(opts, catalog);
  fs.writeFileSync(
    catalogPath,
    `${JSON.stringify(catalog, null, 2)}\n`,
  );
  console.log(
    `asset library: ${catalog.entries.length} entries, `
    + `${stats.copied} copied, ${stats.unchanged} unchanged, `
    + `${stats.catalogOnly} catalogued only -> ${opts.out}`,
  );
}

try {
  main();
} catch (error) {
  console.error(`asset_library: ${error.message}`);
  process.exitCode = 1;
}
