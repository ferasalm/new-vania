#!/usr/bin/env node
// SYS-03 Save & Serialization — the real-file round-trip twin (the authoring gate).
//
// WHAT THIS PROVES: the *format contract* — canonical serialization, the state hash,
// the schema gate + migration chain, the number-normalization pass, the integrity
// verdict, the absent-key defaults, and F-WME-01's pending predicate — against REAL
// FILES on disk:
//   write -> close -> discard the in-memory store -> read the bytes back -> rebuild
//   from those bytes only -> hash compare.
//
// WHAT THIS DOES NOT PROVE: the engine path (Godot FileAccess/JSON, user://, the
// worker Thread) and the float-typed JSON parse (JavaScript has one number type, so
// the normalization pass's coercion branch is only simulable in-engine). That half
// lands with the first SYS-03 implementation story under the SAME fixtures
// (OQ-SAV-1 option (a); the GDD's gate record names the split).
//
// Run: node tests/save-twin/save_twin.mjs

import { createHash } from 'node:crypto';
import { mkdtempSync, writeFileSync, readFileSync, existsSync, renameSync, rmSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// ---------------------------------------------------------------- constants (the law)
const CURRENT_SCHEMA_VERSION = 1;
const MAX_EPOCH = 1; // SYS-02's max_epoch at MVP
const TRIGGER_FLAG = 'sanctum_log_read';
const THRESHOLD_EPOCH = 1; // REVEAL_CISTERN.to_epoch
const GAME_VERSION = '0.1.0';

// the v1 payload shape: `world` only. `cache` is registered but ABSENT until v2 (TR-SAV-004).
const WORLD_KEYS = ['cells_discovered', 'doors_opened', 'memories_collected', 'truth_epoch', 'truth_flags'];
const PAYLOAD_KEYS_BY_VERSION = { 1: ['world'] };

// ---------------------------------------------------------------- canonical form (F-SAV-01)
function canon(v) {
  if (Array.isArray(v)) {
    const items = v.map(canon);
    items.sort(); // the family arrays are sets: canonical order is the element's canonical string
    return '[' + items.join(',') + ']';
  }
  if (v !== null && typeof v === 'object') {
    const keys = Object.keys(v).sort();
    return '{' + keys.map((k) => JSON.stringify(k) + ':' + canon(v[k])).join(',') + '}';
  }
  if (typeof v === 'number') {
    if (!Number.isInteger(v)) throw new Error('REFUSE_FLOAT'); // the no-floats law
    return String(v);
  }
  if (typeof v === 'string') return JSON.stringify(v);
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  throw new Error('REFUSE_TYPE');
}

function stateHash(schemaVersion, payload) {
  // the hash covers {schema_version, payload}: the version is part of the record,
  // so a version downgrade edit is a hash mismatch, not a gate bypass.
  return createHash('sha256').update(canon({ payload, schema_version: schemaVersion }), 'utf8').digest('hex');
}

// ---------------------------------------------------------------- the envelope (TR-SAV-008)
function envelope(payload, savedAt, version = CURRENT_SCHEMA_VERSION) {
  return (
    '{"schema_version":' + version +
    ',"game_version":' + JSON.stringify(GAME_VERSION) +
    ',"saved_at_utc":' + JSON.stringify(savedAt) +
    ',"state_hash":' + JSON.stringify(stateHash(version, payload)) +
    ',"payload":' + canon(payload) + '}'
  );
}

// ---------------------------------------------------------------- F-SAV-02 schema gate
function schemaGate(v, current) {
  if (!Number.isInteger(v) || v < 1) return 'REFUSE_SCHEMA_INVALID';
  if (v > current) return 'REFUSE_SCHEMA_AHEAD';
  if (v === current) return 'ACCEPT';
  return 'MIGRATE';
}

// ---------------------------------------------------------------- TR-SAV-026 the normalization pass
// Godot's JSON parses every number as a float; the pass coerces schema-declared ints
// and refuses non-integral numbers. Schema-driven, never heuristic.
function normalize(payload) {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) return { ok: false, code: 'REFUSE_TYPE' };
  const allowed = PAYLOAD_KEYS_BY_VERSION[CURRENT_SCHEMA_VERSION] ?? [];
  for (const k of Object.keys(payload)) if (!allowed.includes(k)) return { ok: false, code: 'REFUSE_UNKNOWN_KEY' };
  const world = payload.world;
  if (!world || typeof world !== 'object' || Array.isArray(world)) return { ok: false, code: 'REFUSE_TYPE' };
  for (const k of Object.keys(world)) if (!WORLD_KEYS.includes(k)) return { ok: false, code: 'REFUSE_UNKNOWN_KEY' };

  const out = { world: {} };
  // the three set-arrays of strings
  for (const k of ['doors_opened', 'memories_collected']) {
    if (!(k in world)) continue;
    if (!Array.isArray(world[k])) return { ok: false, code: 'REFUSE_TYPE' };
    for (const e of world[k]) if (typeof e !== 'string') return { ok: false, code: 'REFUSE_TYPE' };
    out.world[k] = world[k];
  }
  // cells_discovered: pairs of ints
  if ('cells_discovered' in world) {
    if (!Array.isArray(world.cells_discovered)) return { ok: false, code: 'REFUSE_TYPE' };
    out.world.cells_discovered = [];
    for (const pair of world.cells_discovered) {
      if (!Array.isArray(pair) || pair.length !== 2) return { ok: false, code: 'REFUSE_TYPE' };
      for (const n of pair) {
        if (typeof n !== 'number') return { ok: false, code: 'REFUSE_TYPE' };
        if (!Number.isInteger(n) || n < 0) return { ok: false, code: 'REFUSE_FLOAT' };
      }
      out.world.cells_discovered.push([Number(pair[0]) | 0, Number(pair[1]) | 0]); // the coercion
    }
  }
  // truth_flags: a dict of bools
  if ('truth_flags' in world) {
    if (typeof world.truth_flags !== 'object' || world.truth_flags === null || Array.isArray(world.truth_flags)) {
      return { ok: false, code: 'REFUSE_TYPE' };
    }
    for (const [k, v] of Object.entries(world.truth_flags)) if (typeof v !== 'boolean') return { ok: false, code: 'REFUSE_TYPE' };
    out.world.truth_flags = { ...world.truth_flags };
  }
  // truth_epoch: an int in [0, max_epoch]
  if ('truth_epoch' in world) {
    const v = world.truth_epoch;
    if (typeof v !== 'number') return { ok: false, code: 'REFUSE_TYPE' };
    if (!Number.isInteger(v)) return { ok: false, code: 'REFUSE_FLOAT' };
    if (v < 0 || v > MAX_EPOCH) return { ok: false, code: 'REFUSE_EPOCH_RANGE' };
    out.world.truth_epoch = Number(v) | 0; // the coercion (identity in JS; a real int in Godot)
  }
  return { ok: true, payload: out };
}

// ---------------------------------------------------------------- the migration table (TR-SAV-019)
// v1 is the only shipped version: MIGRATIONS is empty. The twin registers TEST-ONLY
// synthetic steps to prove the machinery. The chain is exercised BELOW the gate
// (a synthetic CURRENT=3 harness); a v0 file is a refusal fixture, never a migration input.
const TEST_CURRENT = 3;
const TEST_MIGRATIONS = {
  1: (p) => { // v1 -> v2: add the cache namespace (the SYS-15 registration case)
    const q = structuredClone(p);
    q.cache = q.cache ?? {};
    return q;
  },
  2: (p) => { // v2 -> v3: the rename case (the value MOVES; only a new key takes the default)
    const q = structuredClone(p);
    const f = { ...q.world.truth_flags };
    if ('sanctum_log_read' in f) { f.sanctum_log_consumed = f.sanctum_log_read; delete f.sanctum_log_read; }
    q.world.truth_flags = f;
    return q;
  },
};

function contiguity(table, current) {
  for (let n = 1; n < current; n++) if (typeof table[n] !== 'function') return false;
  return true;
}

function migrate(payload, from, to, table) {
  if (!contiguity(table, to)) return { ok: false, code: 'REFUSE_MIGRATION_GAP' };
  let p = payload;
  for (let n = from; n < to; n++) {
    try { p = table[n](p); } catch { return { ok: false, code: 'REFUSE_MIGRATION_FAILED' }; }
  }
  return { ok: true, payload: p };
}

// ---------------------------------------------------------------- F-SAV-04 integrity verdict
function integrityVerdict(bytes) {
  // 0. mechanical: parse + the envelope's keys
  let env;
  try { env = JSON.parse(bytes); } catch { return { code: 'REFUSE_TRUNCATED' }; }
  if (!env || typeof env !== 'object' || !env.payload || !('schema_version' in env) || typeof env.state_hash !== 'string') {
    return { code: 'REFUSE_TRUNCATED' };
  }
  // 1. schema_version is an integer
  if (!Number.isInteger(env.schema_version)) return { code: 'REFUSE_SCHEMA_INVALID' };
  // 2. the normalization pass (the engine's float-typed numbers)
  const norm = normalize(env.payload);
  if (!norm.ok) return { code: norm.code };
  // 3. hash (integrity before interpretation; the version is part of the record)
  if (stateHash(env.schema_version, norm.payload) !== env.state_hash) return { code: 'REFUSE_HASH_MISMATCH' };
  // 4. the version gate
  const gate = schemaGate(env.schema_version, CURRENT_SCHEMA_VERSION);
  if (gate === 'REFUSE_SCHEMA_INVALID' || gate === 'REFUSE_SCHEMA_AHEAD') return { code: gate };
  // 5-6. the shape/type checks ran inside normalize()
  // 7. the epoch is not defaultable
  if (!('truth_epoch' in norm.payload.world)) return { code: 'REFUSE_MISSING_EPOCH' };
  return { code: gate === 'MIGRATE' ? 'MIGRATE' : 'ACCEPT', env: { ...env, payload: norm.payload } };
}

// ---------------------------------------------------------------- the absent-key defaults (TR-SAV-023)
function restoreDefaults(world) {
  return {
    doors_opened: world.doors_opened ?? [],
    truth_flags: world.truth_flags ?? {},
    truth_epoch: world.truth_epoch, // absent refuses before this point
    memories_collected: world.memories_collected ?? [],
    cells_discovered: world.cells_discovered ?? [],
  };
}

// ---------------------------------------------------------------- F-WME-01 (consumed, not authored)
function pendingFlip(sources) {
  const flag = sources.truth_flags[TRIGGER_FLAG] ?? false; // absent key reads unset
  return flag === true && sources.truth_epoch < THRESHOLD_EPOCH;
}

// ---------------------------------------------------------------- the atomic write (TR-SAV-010, six steps)
function atomicWrite(dir, slot, bytes, opts = {}) {
  const sav = join(dir, slot + '.sav');
  const bak = join(dir, slot + '.bak');
  const tmp = join(dir, slot + '.tmp');
  writeFileSync(tmp, bytes, 'utf8');                                          // 1-2. write the temp
  const tmpEnv = JSON.parse(readFileSync(tmp, 'utf8'));                       // 3. verify the temp
  const tmpHash = opts.corruptTemp ? 'x' : stateHash(tmpEnv.schema_version, tmpEnv.payload);
  if (tmpHash !== tmpEnv.state_hash) throw new Error('SAVE_FAILED_VERIFY');
  if (existsSync(sav)) renameSync(sav, bak);                                  // 4. rotate the previous good file
  renameSync(tmp, sav);                                                       // 5. the commit point
  const rb = JSON.parse(readFileSync(sav, 'utf8'));                           // 6. the read-back verify
  if (stateHash(rb.schema_version, rb.payload) !== rb.state_hash) throw new Error('SAVE_FAILED_VERIFY');
  return sav;
}

// ---------------------------------------------------------------- the harness
const results = [];
function check(id, name, fn) {
  try { fn(); results.push({ id, name, pass: true, detail: '' }); }
  catch (e) { results.push({ id, name, pass: false, detail: e.message }); }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

const root = mkdtempSync(join(tmpdir(), 'sys03-twin-'));
mkdirSync(join(root, 'saves'), { recursive: true });
const S = join(root, 'saves');

const FIX = {
  pre_flip: { world: { doors_opened: ['b1', 'b2'], truth_flags: { sanctum_log_read: false }, truth_epoch: 0, memories_collected: [], cells_discovered: [[0, 0], [0, 1]] } },
  deferral_gap: { world: { doors_opened: ['b1', 'b2'], truth_flags: { sanctum_log_read: true }, truth_epoch: 0, memories_collected: [], cells_discovered: [[0, 0], [0, 1]] } },
  post_flip: { world: { doors_opened: ['b1', 'b2', 'b3'], truth_flags: { sanctum_log_read: true }, truth_epoch: 1, memories_collected: ['m1'], cells_discovered: [[0, 0], [0, 1], [1, 0]] } },
};

// --- 1..3: the round-trip, on real files, with the in-memory store discarded
for (const [name, payload] of Object.entries(FIX)) {
  check(`RT-${name}`, `round-trip: ${name} (write -> close -> reload -> hash)`, () => {
    const written = stateHash(CURRENT_SCHEMA_VERSION, payload);
    const path = atomicWrite(S, name, envelope(payload, '2026-11-14T12:00:00Z'));
    // DISCARD: nothing in memory is used below. The bytes come off disk.
    const v = integrityVerdict(readFileSync(path, 'utf8'));
    assert(v.code === 'ACCEPT', `verdict ${v.code}`);
    const restored = restoreDefaults(v.env.payload.world);
    assert(stateHash(CURRENT_SCHEMA_VERSION, { world: restored }) === written, 'hash mismatch after round-trip');
  });
}

check('RT-hash-stable', 'a re-save of an unchanged state hashes identically (the timestamp is not hashed)', () => {
  const a = JSON.parse(envelope(FIX.pre_flip, '2026-11-14T12:00:00Z'));
  const b = JSON.parse(envelope(FIX.pre_flip, '2027-01-02T03:04:05Z'));
  assert(a.state_hash === b.state_hash, 'the hash depends on the timestamp');
  assert(a.saved_at_utc !== b.saved_at_utc, 'the fixture did not vary the timestamp');
});

check('CANON-order', 'canonical form: key insertion order and array order do not change the hash', () => {
  const a = { world: { truth_epoch: 0, truth_flags: {}, doors_opened: ['b2', 'b1'], memories_collected: [], cells_discovered: [[0, 1], [0, 0]] } };
  const b = { world: { cells_discovered: [[0, 0], [0, 1]], doors_opened: ['b1', 'b2'], memories_collected: [], truth_flags: {}, truth_epoch: 0 } };
  assert(stateHash(1, a) === stateHash(1, b), 'canonicalization is not order-independent');
});

// --- 4: the corrupted fixtures
check('COR-truncated', 'corrupted: truncated file -> REFUSE_TRUNCATED', () => {
  const p = join(S, 'trunc.sav');
  writeFileSync(p, envelope(FIX.pre_flip, 'x').slice(0, 40), 'utf8');
  const before = readFileSync(p);
  assert(integrityVerdict(readFileSync(p, 'utf8')).code === 'REFUSE_TRUNCATED', 'wrong code');
  assert(readFileSync(p).equals(before), 'the file was modified');
});

check('COR-bitflip', 'corrupted: one payload value edited with the stale hash -> REFUSE_HASH_MISMATCH', () => {
  const p = join(S, 'flip.sav');
  writeFileSync(p, envelope(FIX.pre_flip, 'x').replace('"truth_epoch":0', '"truth_epoch":1'), 'utf8');
  const before = readFileSync(p);
  assert(integrityVerdict(readFileSync(p, 'utf8')).code === 'REFUSE_HASH_MISMATCH', 'wrong code');
  assert(readFileSync(p).equals(before), 'the file was modified');
});

check('COR-schema-ahead', 'corrupted: a legitimate v99 file (valid hash at its own version) -> REFUSE_SCHEMA_AHEAD', () => {
  const p = join(S, 'ahead.sav');
  writeFileSync(p, envelope(FIX.pre_flip, 'x', 99), 'utf8'); // a real newer build's file, hash-valid
  const before = readFileSync(p);
  assert(integrityVerdict(readFileSync(p, 'utf8')).code === 'REFUSE_SCHEMA_AHEAD', 'wrong code');
  assert(readFileSync(p).equals(before), 'the file was modified');
});

check('COR-downgrade', 'corrupted: a version downgrade edit (v99 -> 1) -> REFUSE_HASH_MISMATCH (the version is hashed)', () => {
  const p = join(S, 'down.sav');
  writeFileSync(p, envelope(FIX.pre_flip, 'x', 99).replace('"schema_version":99', '"schema_version":1'), 'utf8');
  assert(integrityVerdict(readFileSync(p, 'utf8')).code === 'REFUSE_HASH_MISMATCH', 'the downgrade edit passed');
});

check('COR-epoch-range', 'corrupted: epoch 2 with a recomputed hash -> REFUSE_EPOCH_RANGE (never clamped)', () => {
  const p = join(S, 'range.sav');
  writeFileSync(p, envelope({ world: { ...FIX.pre_flip.world, truth_epoch: 2 } }, 'x'), 'utf8');
  const before = readFileSync(p);
  assert(integrityVerdict(readFileSync(p, 'utf8')).code === 'REFUSE_EPOCH_RANGE', 'wrong code');
  assert(readFileSync(p).equals(before), 'the file was modified');
});

check('COR-unknown-key', 'corrupted: a pending_flip key -> REFUSE_UNKNOWN_KEY (no such field exists)', () => {
  const p = join(S, 'unk.sav');
  writeFileSync(p, envelope({ world: { ...FIX.deferral_gap.world, pending_flip: true } }, 'x'), 'utf8');
  assert(integrityVerdict(readFileSync(p, 'utf8')).code === 'REFUSE_UNKNOWN_KEY', 'wrong code');
});

check('COR-cache-at-v1', 'corrupted: a cache key at v1 -> REFUSE_UNKNOWN_KEY (registered but absent until v2)', () => {
  const p = join(S, 'cache1.sav');
  writeFileSync(p, envelope({ world: { ...FIX.pre_flip.world }, cache: {} }, 'x'), 'utf8');
  assert(integrityVerdict(readFileSync(p, 'utf8')).code === 'REFUSE_UNKNOWN_KEY', 'wrong code');
});

check('COR-missing-epoch', 'corrupted: absent truth_epoch -> REFUSE_MISSING_EPOCH (the truth is not defaultable)', () => {
  const p = join(S, 'noepoch.sav');
  writeFileSync(p, envelope({ world: { doors_opened: [], truth_flags: {}, memories_collected: [], cells_discovered: [] } }, 'x'), 'utf8');
  assert(integrityVerdict(readFileSync(p, 'utf8')).code === 'REFUSE_MISSING_EPOCH', 'wrong code');
});

// --- the reconciliation predicate (F-WME-01, consumed)
check('REC-a', 'state (a) epoch 0 + flag unset -> pending false', () => assert(pendingFlip(restoreDefaults(FIX.pre_flip.world)) === false, 'wrong'));
check('REC-b', 'state (b) epoch 0 + flag set -> pending TRUE (the deferral gap)', () => assert(pendingFlip(restoreDefaults(FIX.deferral_gap.world)) === true, 'wrong'));
check('REC-c', 'state (c) epoch 1 + flag set -> pending false (cross-session single-shot)', () => assert(pendingFlip(restoreDefaults(FIX.post_flip.world)) === false, 'wrong'));
check('REC-absent-flag', 'absent trigger flag -> unset -> pending false (the predicate never guesses)', () => {
  const s = restoreDefaults({ doors_opened: [], truth_flags: {}, truth_epoch: 0, memories_collected: [], cells_discovered: [] });
  assert(pendingFlip(s) === false, 'wrong');
});
check('REC-gate', 'post-flip derivation: gate_open = epoch >= to_epoch -> OPEN at epoch 1', () => {
  assert((restoreDefaults(FIX.post_flip.world).truth_epoch >= THRESHOLD_EPOCH) === true, 'gate did not derive open');
});

// --- the absent-key matrix
check('ABS-defaults', 'absent arrays default empty; the restored hash equals the written hash', () => {
  const v = integrityVerdict(envelope({ world: { truth_epoch: 0 } }, 'x'));
  assert(v.code === 'ACCEPT', v.code);
  const restored = restoreDefaults(v.env.payload.world);
  assert(restored.doors_opened.length === 0 && restored.memories_collected.length === 0 && restored.cells_discovered.length === 0, 'defaults wrong');
  assert(Object.keys(restored.truth_flags).length === 0, 'flags wrong');
});

// --- the normalization pass (TR-SAV-026)
check('NORM-float', 'normalization: a non-integral number -> REFUSE_FLOAT', () => {
  const v = integrityVerdict(envelope({ world: { ...FIX.pre_flip.world, truth_epoch: 0 } }, 'x').replace('"truth_epoch":0', '"truth_epoch":0.5'));
  assert(v.code === 'REFUSE_FLOAT', 'wrong code: ' + v.code);
});
check('NORM-identity', 'normalization: an integral value normalizes to the same hash (idempotent)', () => {
  const v = integrityVerdict(envelope(FIX.pre_flip, 'x'));
  assert(v.code === 'ACCEPT', v.code);
  assert(stateHash(1, v.env.payload) === stateHash(1, FIX.pre_flip), 'the pass changed the hash');
  const again = normalize(v.env.payload);
  assert(again.ok && stateHash(1, again.payload) === stateHash(1, v.env.payload), 'not idempotent');
});
check('NORM-type', 'normalization: a string at an int key -> REFUSE_TYPE', () => {
  const v = integrityVerdict(envelope({ world: { ...FIX.pre_flip.world, truth_epoch: '0' } }, 'x'));
  assert(v.code === 'REFUSE_TYPE', 'wrong code: ' + v.code);
});

// --- the schema gate + the migration chain (test-only synthetic versions, below the gate)
check('MIG-gate', 'schema gate: v1/current1 ACCEPT · v99 AHEAD · v0 INVALID · v1/current3 MIGRATE', () => {
  assert(schemaGate(1, 1) === 'ACCEPT', 'a');
  assert(schemaGate(99, 1) === 'REFUSE_SCHEMA_AHEAD', 'b');
  assert(schemaGate(0, 1) === 'REFUSE_SCHEMA_INVALID', 'c');
  assert(schemaGate(1, 3) === 'MIGRATE', 'd');
});
check('MIG-one-step', 'v1 -> v2 (test-only): adds the cache namespace', () => {
  const r = migrate({ world: { truth_epoch: 0 } }, 1, 2, TEST_MIGRATIONS);
  assert(r.ok && r.payload.cache && Object.keys(r.payload.cache).length === 0, 'wrong');
});
check('MIG-rename', 'v2 -> v3 (test-only): the rename case MOVES the value (TR-WME-006)', () => {
  const r = migrate({ world: { truth_epoch: 0, truth_flags: { sanctum_log_read: true } } }, 2, 3, TEST_MIGRATIONS);
  assert(r.ok && r.payload.world.truth_flags.sanctum_log_consumed === true && !('sanctum_log_read' in r.payload.world.truth_flags), 'wrong');
});
check('MIG-chain', 'v1 -> v3 below the gate: the two-step chain composes', () => {
  const r = migrate({ world: { truth_epoch: 0, truth_flags: { sanctum_log_read: true } } }, 1, 3, TEST_MIGRATIONS);
  assert(r.ok, 'chain failed: ' + (r.code || ''));
  assert(r.payload.cache !== undefined, 'the cache step did not run');
  assert(r.payload.world.truth_flags.sanctum_log_consumed === true, 'the rename did not compose');
});
check('MIG-gap', 'a contiguity gap fails (a chain with a hole is not a chain)', () => {
  const holey = { 1: TEST_MIGRATIONS[1] }; // no step 2
  assert(contiguity(holey, 3) === false, 'the gap passed');
});

// --- the atomic write's failure paths
check('WRITE-fail', 'a failed commit leaves the previous good file intact and the .bak recovers', () => {
  atomicWrite(S, 'crash', envelope(FIX.pre_flip, '1'));
  const good = readFileSync(join(S, 'crash.sav'));
  renameSync(join(S, 'crash.sav'), join(S, 'crash.bak')); // simulate a crash after step 4, before step 5
  writeFileSync(join(S, 'crash.tmp'), 'garbage', 'utf8');
  assert(!existsSync(join(S, 'crash.sav')), 'setup wrong');
  assert(readFileSync(join(S, 'crash.bak')).equals(good), 'the backup is not the last good file');
  renameSync(join(S, 'crash.bak'), join(S, 'crash.sav')); // the boot sweep
  rmSync(join(S, 'crash.tmp'));
  assert(integrityVerdict(readFileSync(join(S, 'crash.sav'), 'utf8')).code === 'ACCEPT', 'recovery failed');
});
check('WRITE-verify-temp', 'step 3: a temp whose hash does not verify aborts before the rotation', () => {
  atomicWrite(S, 'vt', envelope(FIX.pre_flip, '1'));
  const before = readFileSync(join(S, 'vt.sav'));
  let threw = false;
  try { atomicWrite(S, 'vt', envelope(FIX.post_flip, '2'), { corruptTemp: true }); } catch (e) { threw = /SAVE_FAILED_VERIFY/.test(e.message); }
  assert(threw, 'the verify did not fire');
  assert(readFileSync(join(S, 'vt.sav')).equals(before), 'the good file was touched');
});

// ---------------------------------------------------------------- report
console.log('\nSYS-03 real-file round-trip twin — ' + root + '\n');
let pass = 0;
for (const r of results) {
  console.log((r.pass ? 'PASS  ' : 'FAIL  ') + r.id.padEnd(18) + r.name + (r.detail ? '  <- ' + r.detail : ''));
  if (r.pass) pass++;
}
console.log(`\n${pass}/${results.length} PASS\n`);
console.log('F-SAV-01 worked-example hashes (cited in the GDD):');
for (const [k, v] of Object.entries(FIX)) console.log('  ' + k.padEnd(14) + stateHash(1, v));
console.log('\ncanonical pre_flip payload:\n  ' + canon(FIX.pre_flip) + '\n');
process.exit(pass === results.length ? 0 : 1);
