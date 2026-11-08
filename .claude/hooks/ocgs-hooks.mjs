#!/usr/bin/env node
/**
 * Claude Code adapter for the OCGS hooks.
 *
 * The hook logic lives in `.opencode/plugins/ccgs-hooks.ts` and is shared with
 * the OpenCode plugin; this script only maps Claude Code hook events onto it.
 * `.claude/settings.json` runs it as `node ocgs-hooks.mjs <event>` with the
 * hook input as JSON on stdin:
 *
 *   session-start  SessionStart  project context and gaps; recovery note after compaction;
 *                                warns when the .claude/ mirror is out of date
 *   pre-compact    PreCompact    session state → instructions for the compaction summary
 *   session-end    SessionEnd    archive active.md and a session summary to production/session-logs/
 *   pre-tool-use   PreToolUse    Bash `git commit`: block on validation errors, surface warnings;
 *                                Bash `git push`: protected-branch reminder; Agent: audit log
 *   post-tool-use  PostToolUse   Write/Edit: asset naming and JSON checks, skill-change reminder,
 *                                warning when a generated .claude/ file is edited; Agent: audit log
 *
 * Exit codes follow Claude Code: 0 continues, 2 blocks (pre-tool-use only),
 * anything else is a non-blocking error. The TypeScript module is loaded
 * through tsx only when an event needs it, so most Bash calls return
 * without loading it. Without `npm install` the hooks stay inactive and
 * say so at session start.
 *
 * The commit check fails open: if it crashes, Claude Code reports a
 * non-blocking error and the command runs. The git pre-commit hook in
 * `.githooks/` stays the enforced gate. The check reads what is staged when
 * the command starts, so `git add x && git commit` does not cover `x`.
 *
 * OCGS_PROJECT_ROOT overrides the project root (used by tests).
 */

import { readFileSync } from 'node:fs';
import { dirname, isAbsolute, relative, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { mirrorSourceFor, syncClaudeMirror } from '../../tools/lib/claude-mirror.mjs';

const CODE_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const ROOT = process.env.OCGS_PROJECT_ROOT ? resolve(process.env.OCGS_PROJECT_ROOT) : CODE_ROOT;
const HOOKS_MODULE = resolve(CODE_ROOT, '.opencode', 'plugins', 'ccgs-hooks.ts');

/** PreCompact stdout is capped at 10,000 characters; leave room for the truncation note. */
const COMPACT_LIMIT = 9500;

/** `git`, optional global options (`-C dir`, `-c key=value`, `--no-pager`, …), then `name`. */
function gitSubcommand(name) {
  return new RegExp(String.raw`(?:^|[\s;&|(])git(?:\s+(?:-[Cc]\s+\S+|--?[A-Za-z][\w-]*(?:=\S+)?))*\s+${name}\b`);
}

const GIT_COMMIT_RE = gitSubcommand('commit');
const GIT_PUSH_RE = gitSubcommand('push');
const ASSET_RE = /(?:^|\/)assets\//;
const SKILL_SOURCE_RE = /^\.(?:agents|opencode)\/(?:skills|commands)\//;
const MIRROR_SOURCE_RE = /^\.agents\/(?:agents|skills|rules)\//;

class MissingTsx extends Error {}

let hooksModule;

/** Load the shared TypeScript hook module through tsx (once per process). */
function loadHooks() {
  hooksModule ??= (async () => {
    let api;
    try {
      api = await import('tsx/esm/api');
    } catch {
      throw new MissingTsx('OCGS hooks are inactive: run `npm install` in the project root to install the tsx loader.');
    }
    return api.tsImport(pathToFileURL(HOOKS_MODULE).href, import.meta.url);
  })();
  return hooksModule;
}

function readInput() {
  try {
    const raw = readFileSync(0, 'utf-8');
    return raw.trim() ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function git(...args) {
  const result = spawnSync('git', args, {
    cwd: ROOT, encoding: 'utf-8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 15000,
  });
  return result.status === 0 ? result.stdout.trim() : '';
}

/** Project-relative path with forward slashes, or null for files outside the project. */
function toProjectPath(filePath) {
  const rel = relative(ROOT, isAbsolute(filePath) ? filePath : resolve(ROOT, filePath));
  if (!rel || rel.startsWith('..') || isAbsolute(rel)) return null;
  return rel.split(sep).join('/');
}

function writeJson(payload) {
  process.stdout.write(`${JSON.stringify(payload)}\n`);
}

function writeContext(hookEventName, notes) {
  if (notes.length === 0) return;
  writeJson({ hookSpecificOutput: { hookEventName, additionalContext: notes.join('\n') } });
}

function mirrorStatus() {
  try {
    const report = syncClaudeMirror(ROOT, { check: true });
    if (report.inSync) return '';
    const counts = [
      [report.added, 'missing'], [report.updated, 'changed'],
      [report.removed, 'stale'], [report.conflicts, 'blocked'],
    ].filter(([list]) => list.length > 0).map(([list, label]) => `${list.length} ${label}`);
    return `.claude/ is out of date with .agents/ (${counts.join(', ') || 'manifest changed'}). `
      + 'Run `npm run claude:sync`, then restart Claude Code so agents and skills reload.';
  } catch (error) {
    return `Could not check the .claude/ mirror: ${error.message}`;
  }
}

const HANDLERS = {
  async 'session-start'(input) {
    const lines = [];
    try {
      const hooks = await loadHooks();
      if (input.source === 'compact') {
        lines.push(hooks.handlePostCompact(ROOT));
      } else {
        lines.push('OCGS session context:', hooks.handleSessionCreated(ROOT));
        const gaps = hooks.handleDetectGaps(ROOT);
        if (gaps.length > 0) lines.push('', 'Project gaps:', ...gaps.map((gap) => `- ${gap}`));
      }
    } catch (error) {
      if (!(error instanceof MissingTsx)) throw error;
      lines.push(error.message);
    }
    const mirror = mirrorStatus();
    if (mirror) lines.push('', mirror);
    const text = lines.join('\n').trim();
    if (text) process.stdout.write(`${text}\n`);
  },

  async 'pre-compact'() {
    const hooks = await loadHooks();
    const state = hooks.buildCompactionContext(ROOT);
    hooks.logCompactionEvent(ROOT);
    const text = 'Keep the OCGS session state below in the summary so work can resume from '
      + `production/session-state/active.md.\n\n${state}`;
    process.stdout.write(text.length > COMPACT_LIMIT ? `${text.slice(0, COMPACT_LIMIT)}\n… (truncated)\n` : `${text}\n`);
  },

  async 'session-end'() {
    const hooks = await loadHooks();
    hooks.handleSessionIdle(ROOT);
  },

  async 'pre-tool-use'(input) {
    const tool = input.tool_name;
    const toolInput = input.tool_input ?? {};

    if (tool === 'Agent' || tool === 'Task') {
      (await loadHooks()).handleLogAgent(ROOT, String(toolInput.subagent_type ?? ''));
      return 0;
    }
    if (tool !== 'Bash') return 0;

    const command = String(toolInput.command ?? '');
    const isCommit = GIT_COMMIT_RE.test(command);
    const isPush = GIT_PUSH_RE.test(command);
    if (!isCommit && !isPush) return 0;

    const hooks = await loadHooks();
    const notes = [];

    if (isPush) {
      const branch = hooks.detectPushToProtected(command, git('rev-parse', '--abbrev-ref', 'HEAD'));
      if (branch) {
        hooks.logAudit(ROOT, `Push to protected branch '${branch}' detected.`);
        notes.push(`Pushing to protected branch '${branch}': confirm the build passes, unit tests pass, and no S1/S2 bugs are open.`);
      }
    }

    if (isCommit) {
      const staged = git('diff', '--cached', '--name-only').split('\n').filter(Boolean);
      const { errors, warnings } = hooks.validateCommitFiles(ROOT, staged);
      if (errors.length > 0) {
        errors.forEach((error) => hooks.logAudit(ROOT, error));
        process.stderr.write(`OCGS commit check blocked this commit:\n${errors.join('\n')}\n`);
        return 2;
      }
      warnings.forEach((warning) => hooks.logAudit(ROOT, warning));
      notes.push(...warnings);
    }

    writeContext('PreToolUse', notes);
    return 0;
  },

  async 'post-tool-use'(input) {
    const tool = input.tool_name;
    const toolInput = input.tool_input ?? {};

    if (tool === 'Agent' || tool === 'Task') {
      (await loadHooks()).handleLogAgentStop(ROOT, String(toolInput.subagent_type ?? ''));
      return;
    }

    const rawPath = toolInput.file_path ?? toolInput.notebook_path;
    if (typeof rawPath !== 'string' || !rawPath) return;
    const file = toProjectPath(rawPath);
    if (!file) return;

    const notes = [];
    const errors = [];

    const source = mirrorSourceFor(ROOT, file);
    if (source) {
      notes.push(`${file} is generated from ${source}. Make this change in ${source} and run `
        + '`npm run claude:sync`; direct edits are overwritten and fail `npm run claude:check`.');
    }
    if (MIRROR_SOURCE_RE.test(file)) {
      notes.push(`${file} is mirrored into .claude/: run \`npm run claude:sync\` before committing.`);
    }

    if (ASSET_RE.test(file) || SKILL_SOURCE_RE.test(file)) {
      const hooks = await loadHooks();
      const asset = hooks.validateAssetPath(ROOT, file);
      asset.warnings.forEach((warning) => hooks.logAudit(ROOT, warning));
      asset.errors.forEach((error) => hooks.logAudit(ROOT, error));
      notes.push(...asset.warnings);
      errors.push(...asset.errors);

      const skill = hooks.detectSkillChange(file);
      if (skill) {
        hooks.logAudit(ROOT, `=== Skill Modified: ${skill} ===`);
        notes.push(`Skill changed: ${skill}. Run /skill-test static ${skill} to check its structure.`);
      }
    }

    if (errors.length > 0) {
      writeJson({
        decision: 'block',
        reason: `Asset validation failed:\n${errors.join('\n')}`,
        ...(notes.length > 0 && {
          hookSpecificOutput: { hookEventName: 'PostToolUse', additionalContext: notes.join('\n') },
        }),
      });
      return;
    }
    writeContext('PostToolUse', notes);
  },
};

async function main(event) {
  const handler = HANDLERS[event];
  if (!handler) {
    process.stderr.write(`Unknown OCGS hook event '${event}'. Expected one of: ${Object.keys(HANDLERS).join(', ')}\n`);
    return 1;
  }
  return (await handler(readInput())) ?? 0;
}

main(process.argv[2]).then(
  (code) => { process.exitCode = code; },
  (error) => {
    process.stderr.write(error instanceof MissingTsx
      ? `${error.message}\n`
      : `OCGS hook '${process.argv[2]}' failed: ${error?.stack ?? error}\n`);
    process.exitCode = error instanceof MissingTsx ? 0 : 1;
  },
);
