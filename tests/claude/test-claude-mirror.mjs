/**
 * Tests for the Claude Code mirror of `.agents/` (tools/lib/claude-mirror.mjs).
 *
 * Unit tests cover the content transforms; integration tests run a sync
 * against a throwaway project; the last test checks that the committed
 * `.claude/` mirror matches the repository's `.agents/`.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';

import {
  MANIFEST_PATH,
  claudeAgentFile,
  claudeSkillMarkdown,
  mapAllowedTools,
  mirrorSourceFor,
  planClaudeMirror,
  renameSlashCommands,
  syncClaudeMirror,
} from '../../tools/lib/claude-mirror.mjs';

const REPO = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

const AGENT_MD = `---
description: "Demo agent."
maxTurns: 10
---

Run /code-review when done.
`;

const SKILL_MD = `---
name: demo
description: "Demo skill."
user-invocable: true
allowed-tools: Read, Write, Task, question, webfetch, WebFetch
---

# Demo

Use \`question\` to ask.
`;

function makeProject(t) {
  const root = mkdtempSync(join(tmpdir(), 'ocgs-claude-mirror-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const write = (rel, content) => {
    mkdirSync(dirname(join(root, rel)), { recursive: true });
    writeFileSync(join(root, rel), content);
  };
  write('.agents/agents/demo-agent.md', AGENT_MD);
  write('.agents/skills/demo/SKILL.md', SKILL_MD);
  write('.agents/skills/help/SKILL.md', '---\nname: help\ndescription: "Help."\n---\n\n# Help\n');
  write('.agents/commands/demo.md', '---\nname: demo\nskill: demo\n---\n\nInvokes `/demo` skill.\n');
  write('.agents/rules/demo-rule.md', '---\npaths:\n  - "src/**"\n---\n\n# Rule\n');
  return { root, write, read: (rel) => readFileSync(join(root, rel), 'utf-8') };
}

// ── Transforms ─────────────────────────────────────────────────────────────

test('renameSlashCommands renames command references but not paths or longer names', () => {
  const input = [
    'Run /help or `/code-review [files]`, then (/help).',
    'See .agents/skills/code-review/SKILL.md and docs/help.md.',
    'https://example.com/help /helpful /code-reviewer',
  ].join('\n');

  const output = renameSlashCommands(input);

  assert.equal(output, [
    'Run /ocgs-help or `/ocgs-code-review [files]`, then (/ocgs-help).',
    'See .agents/skills/code-review/SKILL.md and docs/help.md.',
    'https://example.com/help /helpful /code-reviewer',
  ].join('\n'));
});

test('mapAllowedTools maps OCGS tool names to Claude Code names and drops duplicates', () => {
  assert.equal(
    mapAllowedTools('Read, Task, question, webfetch, WebFetch, Bash(git log *, git diff *)'),
    'Read, Agent, AskUserQuestion, WebFetch, Bash(git log *, git diff *)',
  );
});

test('claudeAgentFile injects name frontmatter and renames commands', () => {
  const output = claudeAgentFile(AGENT_MD.replace(/\n/g, '\r\n'), 'demo-agent.md');

  assert.match(output, /^---\nname: demo-agent\ndescription: "Demo agent\."\n/);
  assert.match(output, /Run \/ocgs-code-review when done\./);
  assert.ok(!output.includes('\r'), 'output uses LF line endings');
});

test('claudeSkillMarkdown maps allowed-tools and leaves the body unchanged', () => {
  const output = claudeSkillMarkdown(SKILL_MD);

  assert.match(output, /^allowed-tools: Read, Write, Agent, AskUserQuestion, WebFetch$/m);
  assert.ok(output.endsWith('# Demo\n\nUse `question` to ask.\n'));
});

test('claudeSkillMarkdown renames shadowed skills in their name field', () => {
  assert.match(claudeSkillMarkdown('---\nname: help\n---\n\n# Help\n'), /^name: ocgs-help$/m);
  assert.match(claudeSkillMarkdown("---\nname: 'code-review'\n---\n"), /^name: ocgs-code-review$/m);
  assert.match(claudeSkillMarkdown("---\nname: 'dev-story'\n---\n"), /^name: 'dev-story'$/m);
});

test('claudeSkillMarkdown turns a context preload block into instructions after the title', () => {
  const input = '---\nname: log\ncontext: |\n  !git log --oneline -5\n  Reads git history.\nallowed-tools: Bash\n---\n\n# Log\n\nBody.\n';

  const output = claudeSkillMarkdown(input);

  assert.ok(!/^context:/m.test(output), 'non-fork context is removed from frontmatter');
  assert.match(output, /^allowed-tools: Bash$/m, 'keys after the block are kept');
  assert.match(output, /# Log\n\n> Reads git history\.\n\n\*\*Context preload:\*\*.*\n\n- `git log --oneline -5`\n\nBody\./);
});

test('claudeSkillMarkdown keeps context: fork untouched', () => {
  const input = '---\nname: x\ncontext: fork\nagent: Explore\n---\n\nBody.\n';
  assert.equal(claudeSkillMarkdown(input), input);
});

test('claudeSkillMarkdown maps a YAML list of allowed-tools', () => {
  const output = claudeSkillMarkdown('---\nname: x\nallowed-tools:\n  - Read\n  - question\n---\n');
  assert.match(output, /allowed-tools:\n {2}- Read\n {2}- AskUserQuestion\n---/);
});

// ── Planning and sync ──────────────────────────────────────────────────────

test('planClaudeMirror maps agents, skills and rules but not commands', (t) => {
  const { root } = makeProject(t);

  const targets = [...planClaudeMirror(root).keys()].sort();

  assert.deepEqual(targets, [
    '.claude/agents/demo-agent.md',
    '.claude/rules/demo-rule.md',
    '.claude/skills/demo/SKILL.md',
    '.claude/skills/ocgs-help/SKILL.md',
  ]);
});

test('syncClaudeMirror writes the mirror and manifest, then reports in sync', (t) => {
  const { root, read } = makeProject(t);

  const first = syncClaudeMirror(root);
  const second = syncClaudeMirror(root, { check: true });

  assert.equal(first.added.length, 4);
  assert.ok(second.inSync);
  assert.match(read('.claude/agents/demo-agent.md'), /^name: demo-agent$/m);
  assert.equal(JSON.parse(read(MANIFEST_PATH)).files['.claude/skills/ocgs-help/SKILL.md'], '.agents/skills/help/SKILL.md');
  assert.equal(mirrorSourceFor(root, '.claude/rules/demo-rule.md'), '.agents/rules/demo-rule.md');
  assert.equal(mirrorSourceFor(root, '.claude/settings.json'), null);
});

test('syncClaudeMirror check mode reports a changed source without writing', (t) => {
  const { root, write, read } = makeProject(t);
  syncClaudeMirror(root);
  write('.agents/rules/demo-rule.md', '---\npaths:\n  - "src/**"\n---\n\n# Rule v2\n');

  const report = syncClaudeMirror(root, { check: true });

  assert.equal(report.inSync, false);
  assert.deepEqual(report.updated, ['.claude/rules/demo-rule.md']);
  assert.match(read('.claude/rules/demo-rule.md'), /# Rule\n$/, 'check mode does not write');
});

test('syncClaudeMirror removes generated files whose source was deleted', (t) => {
  const { root } = makeProject(t);
  syncClaudeMirror(root);
  rmSync(join(root, '.agents/skills/demo'), { recursive: true });

  const report = syncClaudeMirror(root);

  assert.deepEqual(report.removed, ['.claude/skills/demo/SKILL.md']);
  assert.ok(!existsSync(join(root, '.claude/skills/demo')), 'empty skill directory is pruned');
  assert.ok(syncClaudeMirror(root, { check: true }).inSync);
});

test('syncClaudeMirror never overwrites or deletes hand-written files', (t) => {
  const { root, write, read } = makeProject(t);
  write('.claude/rules/demo-rule.md', '# My own rule\n');
  write('.claude/settings.json', '{}\n');

  const report = syncClaudeMirror(root);

  assert.deepEqual(report.conflicts, ['.claude/rules/demo-rule.md']);
  assert.equal(read('.claude/rules/demo-rule.md'), '# My own rule\n');
  assert.equal(read('.claude/settings.json'), '{}\n');
  assert.ok(!(JSON.parse(read(MANIFEST_PATH)).files['.claude/rules/demo-rule.md']), 'conflict is not claimed');

  const forced = syncClaudeMirror(root, { force: true });
  assert.deepEqual(forced.updated, ['.claude/rules/demo-rule.md']);
  assert.match(read('.claude/rules/demo-rule.md'), /# Rule\n$/);
});

test('syncClaudeMirror ignores CRLF-only differences', (t) => {
  const { root, write, read } = makeProject(t);
  syncClaudeMirror(root);
  write('.claude/rules/demo-rule.md', read('.claude/rules/demo-rule.md').replace(/\n/g, '\r\n'));

  assert.ok(syncClaudeMirror(root, { check: true }).inSync);
});

test('syncClaudeMirror needs no manifest for a project without .agents/', (t) => {
  const root = mkdtempSync(join(tmpdir(), 'ocgs-claude-empty-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));

  const report = syncClaudeMirror(root);

  assert.ok(report.inSync);
  assert.ok(!existsSync(join(root, MANIFEST_PATH)));
});

// ── Repository state ───────────────────────────────────────────────────────

test('committed .claude/ mirror matches .agents/ (run `npm run claude:sync` if this fails)', () => {
  const report = syncClaudeMirror(REPO, { check: true });

  assert.deepEqual(
    { added: report.added, updated: report.updated, removed: report.removed, conflicts: report.conflicts },
    { added: [], updated: [], removed: [], conflicts: [] },
  );
  assert.equal(report.manifestChanged, false);
});
