/**
 * Tests for the Claude Code hook adapter (.claude/hooks/ocgs-hooks.mjs).
 *
 * Each test runs the adapter as Claude Code would — hook input as JSON on
 * stdin — against a throwaway git repository selected with OCGS_PROJECT_ROOT.
 * Events that need the shared TypeScript module load it through tsx, so these
 * tests need `npm install`.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

import { gateEnv } from '../../tools/git-hooks/pre-commit.mjs';

const REPO = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const ADAPTER = join(REPO, '.claude', 'hooks', 'ocgs-hooks.mjs');
// Without git's repo-pinning variables, so a run inside a git hook cannot touch this repo.
const CLEAN_ENV = gateEnv();

function git(cwd, ...args) {
  const result = spawnSync('git', args, { cwd, encoding: 'utf-8', env: CLEAN_ENV });
  assert.equal(result.status, 0, `git ${args.join(' ')} failed: ${result.stderr}`);
}

function makeRepo(t) {
  const root = mkdtempSync(join(tmpdir(), 'ocgs-claude-hooks-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  git(root, 'init', '-q');
  git(root, 'config', 'user.email', 'test@example.com');
  git(root, 'config', 'user.name', 'Test');
  git(root, 'config', 'core.autocrlf', 'false');
  git(root, 'commit', '-q', '--allow-empty', '-m', 'init');
  const write = (rel, content) => {
    mkdirSync(dirname(join(root, rel)), { recursive: true });
    writeFileSync(join(root, rel), content);
  };
  return { root, write };
}

function runHook(root, event, input) {
  const result = spawnSync(process.execPath, [ADAPTER, event], {
    input: JSON.stringify(input),
    encoding: 'utf-8',
    env: { ...CLEAN_ENV, OCGS_PROJECT_ROOT: root },
    timeout: 30000,
  });
  return { code: result.status, stdout: result.stdout, stderr: result.stderr };
}

function contextOf(stdout) {
  return JSON.parse(stdout).hookSpecificOutput.additionalContext;
}

test('session-start prints project context and gaps for a new project', (t) => {
  const { root } = makeRepo(t);

  const result = runHook(root, 'session-start', { source: 'startup' });

  assert.equal(result.code, 0, result.stderr);
  assert.match(result.stdout, /^OCGS session context:/);
  assert.match(result.stdout, /NEW PROJECT: No engine configured/);
});

test('session-start after compaction points at the session state file', (t) => {
  const { root, write } = makeRepo(t);
  write('production/session-state/active.md', '# Task\n- [ ] step\n');

  const result = runHook(root, 'session-start', { source: 'compact' });

  assert.equal(result.code, 0, result.stderr);
  assert.match(result.stdout, /Session state restored: production\/session-state\/active\.md/);
});

test('pre-compact emits the session state for the compaction summary', (t) => {
  const { root, write } = makeRepo(t);
  write('production/session-state/active.md', '# Current task: wall-jump tuning\n');

  const result = runHook(root, 'pre-compact', { trigger: 'auto' });

  assert.equal(result.code, 0, result.stderr);
  assert.match(result.stdout, /SESSION STATE BEFORE COMPACTION/);
  assert.match(result.stdout, /wall-jump tuning/);
  assert.ok(result.stdout.length <= 10000, 'stays under the PreCompact output cap');
});

test('session-end archives the session state', (t) => {
  const { root, write } = makeRepo(t);
  write('production/session-state/active.md', '# Current task: save system\n');

  const result = runHook(root, 'session-end', { reason: 'other' });

  assert.equal(result.code, 0, result.stderr);
  assert.match(readFileSync(join(root, 'production/session-logs/session-log.md'), 'utf-8'), /save system/);
});

test('pre-tool-use ignores Bash commands that are not git commit or push', (t) => {
  const { root } = makeRepo(t);

  for (const command of ['ls -la', 'git log --grep commit', 'git status && git diff']) {
    const result = runHook(root, 'pre-tool-use', { tool_name: 'Bash', tool_input: { command } });
    assert.deepEqual(result, { code: 0, stdout: '', stderr: '' }, command);
  }
});

test('pre-tool-use checks commits run with git global options', (t) => {
  const { root, write } = makeRepo(t);
  write('assets/data/enemies.json', '{ "hp": ');
  git(root, 'add', 'assets/data/enemies.json');

  for (const command of ['git -C . commit -m x', 'git --no-pager -c core.quotepath=false commit -m x']) {
    const result = runHook(root, 'pre-tool-use', { tool_name: 'Bash', tool_input: { command } });
    assert.equal(result.code, 2, command);
  }
});

test('pre-tool-use blocks a commit with invalid staged data JSON', (t) => {
  const { root, write } = makeRepo(t);
  write('assets/data/enemies.json', '{ "hp": ');
  git(root, 'add', 'assets/data/enemies.json');

  const result = runHook(root, 'pre-tool-use', {
    tool_name: 'Bash',
    tool_input: { command: 'git add -A && git commit -m "feat: enemies"' },
  });

  assert.equal(result.code, 2);
  assert.match(result.stderr, /BLOCKED: assets\/data\/enemies\.json is not valid JSON/);
});

test('pre-tool-use passes design-doc warnings to Claude without blocking', (t) => {
  const { root, write } = makeRepo(t);
  write('design/gdd/movement.md', '# Movement\n\n## Overview\n');
  git(root, 'add', 'design/gdd/movement.md');

  const result = runHook(root, 'pre-tool-use', { tool_name: 'Bash', tool_input: { command: 'git commit -m x' } });

  assert.equal(result.code, 0, result.stderr);
  assert.match(contextOf(result.stdout), /DESIGN: design\/gdd\/movement\.md missing required section: Formulas/);
});

test('pre-tool-use and post-tool-use log Agent calls to the audit log', (t) => {
  const { root } = makeRepo(t);
  const input = { tool_name: 'Agent', tool_input: { subagent_type: 'producer' } };

  assert.equal(runHook(root, 'pre-tool-use', input).code, 0);
  assert.equal(runHook(root, 'post-tool-use', input).code, 0);

  const log = readFileSync(join(root, 'production/session-logs/agent-audit.log'), 'utf-8');
  assert.match(log, /Agent invoked: producer\n.*Agent completed: producer\n$/);
});

test('post-tool-use blocks on invalid data JSON and warns on asset naming', (t) => {
  const { root, write } = makeRepo(t);
  write('assets/data/Boss Stats.json', '{ nope');

  const result = runHook(root, 'post-tool-use', {
    tool_name: 'Write',
    tool_input: { file_path: join(root, 'assets', 'data', 'Boss Stats.json') },
  });

  assert.equal(result.code, 0, result.stderr);
  const output = JSON.parse(result.stdout);
  assert.equal(output.decision, 'block');
  assert.match(output.reason, /FORMAT: assets\/data\/Boss Stats\.json is not valid JSON/);
  assert.match(output.hookSpecificOutput.additionalContext, /NAMING: .*must be lowercase/);
});

test('post-tool-use warns when a generated .claude/ file is edited', (t) => {
  const { root, write } = makeRepo(t);
  write('.claude/ocgs-sync.json', JSON.stringify({ files: { '.claude/skills/demo/SKILL.md': '.agents/skills/demo/SKILL.md' } }));
  write('.claude/skills/demo/SKILL.md', '# Demo\n');

  const result = runHook(root, 'post-tool-use', {
    tool_name: 'Edit',
    tool_input: { file_path: join(root, '.claude', 'skills', 'demo', 'SKILL.md') },
  });

  assert.equal(result.code, 0, result.stderr);
  assert.match(contextOf(result.stdout), /generated from \.agents\/skills\/demo\/SKILL\.md/);
});

test('post-tool-use ignores files outside the project', (t) => {
  const { root } = makeRepo(t);

  const result = runHook(root, 'post-tool-use', {
    tool_name: 'Write',
    tool_input: { file_path: join(tmpdir(), 'elsewhere', 'assets', 'Bad Name.png') },
  });

  assert.deepEqual(result, { code: 0, stdout: '', stderr: '' });
});

test('unknown events exit 1 without blocking', (t) => {
  const { root } = makeRepo(t);

  const result = runHook(root, 'bogus', {});

  assert.equal(result.code, 1);
  assert.match(result.stderr, /Unknown OCGS hook event 'bogus'/);
  assert.ok(!existsSync(join(root, 'production')), 'nothing is written');
});
