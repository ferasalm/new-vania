#!/usr/bin/env node
/**
 * Mirror `.agents/{agents,skills,rules}` into `.claude/` for Claude Code.
 *
 *   node tools/sync-claude.mjs           write the mirror        (npm run claude:sync)
 *   node tools/sync-claude.mjs --check   exit 1 if it is stale   (npm run claude:check)
 *   node tools/sync-claude.mjs --force   also overwrite colliding files a sync did not create
 *
 * See tools/lib/claude-mirror.mjs for what changes, and
 * docs/claude-compatibility.md for the workflow.
 */

import { dirname, resolve } from 'path';
import { fileURLToPath } from 'url';
import { MANIFEST_PATH, syncClaudeMirror } from './lib/claude-mirror.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const FLAGS = new Set(['--check', '--force', '--help', '-h']);
const LIST_LIMIT = 20;

function usage() {
  console.log('Usage: node tools/sync-claude.mjs [--check] [--force]');
  console.log('  (no flag)  write .claude/{agents,skills,rules} from .agents/');
  console.log('  --check    report drift and exit 1 instead of writing');
  console.log(`  --force    overwrite existing files not listed in ${MANIFEST_PATH}`);
}

function printList(label, items) {
  if (items.length === 0) return;
  console.log(`  ${label} (${items.length}):`);
  for (const item of items.slice(0, LIST_LIMIT)) console.log(`    ${item}`);
  if (items.length > LIST_LIMIT) console.log(`    … and ${items.length - LIST_LIMIT} more`);
}

function main(args) {
  const unknown = args.filter((arg) => !FLAGS.has(arg));
  if (unknown.length > 0 || args.includes('--help') || args.includes('-h')) {
    if (unknown.length > 0) console.error(`Unknown argument(s): ${unknown.join(' ')}`);
    usage();
    return unknown.length > 0 ? 1 : 0;
  }

  const check = args.includes('--check');
  const report = syncClaudeMirror(ROOT, { check, force: args.includes('--force') });

  printList(check ? 'Missing' : 'Added', report.added);
  printList(check ? 'Out of date' : 'Updated', report.updated);
  printList(check ? 'Stale (source removed)' : 'Removed', report.removed);
  printList('Conflicts: existing files not created by a sync (re-run with --force to overwrite)', report.conflicts);

  if (check) {
    if (report.inSync) {
      console.log(`.claude/ mirror is in sync with .agents/ (${report.total} files).`);
      return 0;
    }
    if (report.manifestChanged) console.log(`  ${MANIFEST_PATH} is out of date.`);
    console.error('.claude/ is out of date with .agents/. Run `npm run claude:sync` and commit the result.');
    return 1;
  }

  const changed = report.added.length + report.updated.length + report.removed.length;
  console.log(`Synced .claude/ from .agents/: ${report.total} files, ${changed} changed, ${report.unchanged} unchanged.`);
  if (report.conflicts.length > 0) return 1;
  if (changed > 0) console.log('Restart Claude Code (or start a new session) so it reloads agents and skills.');
  return 0;
}

process.exitCode = main(process.argv.slice(2));
