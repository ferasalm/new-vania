/**
 * Claude Code mirror of the canonical `.agents/` content.
 *
 * Claude Code loads subagents, skills, and rules only from `.claude/`. This
 * module plans a generated copy of `.agents/{agents,skills,rules}` with the
 * changes Claude Code needs, then writes or checks it:
 *
 *   - agents gain the `name:` frontmatter Claude Code requires;
 *   - skill `allowed-tools` use Claude Code tool names (`question` →
 *     `AskUserQuestion`, `Task` → `Agent`, `webfetch` → `WebFetch`);
 *   - the non-standard skill `context:` preload block becomes a short
 *     instruction in the skill body (Claude Code only accepts `context: fork`);
 *   - `/help` and `/code-review` become `/ocgs-help` and `/ocgs-code-review`,
 *     because a built-in command or personal skill with the same name would
 *     replace the project skill.
 *
 * `.agents/commands/` is not mirrored: every Claude Code skill is already a
 * slash command, and the OCGS command files only route to the same-named skill.
 *
 * Every generated path is recorded in `.claude/ocgs-sync.json`. A sync only
 * rewrites or deletes paths listed there, so hand-written files under
 * `.claude/` (settings, hooks, extra rules) are never touched.
 */

import {
  existsSync, mkdirSync, readFileSync, readdirSync, rmdirSync, statSync, unlinkSync, writeFileSync,
} from 'fs';
import { dirname, join, relative, sep } from 'path';
import { claudeAgentMarkdown } from './harness-targets.mjs';

/** Manifest of generated files, relative to the project root. */
export const MANIFEST_PATH = '.claude/ocgs-sync.json';

/** Skills renamed because a Claude Code built-in or personal skill would shadow them. */
export const SKILL_RENAMES = Object.freeze({
  help: 'ocgs-help',
  'code-review': 'ocgs-code-review',
});

/** OCGS tool names used in skill `allowed-tools` → Claude Code tool names. */
export const TOOL_RENAMES = Object.freeze({
  question: 'AskUserQuestion',
  Task: 'Agent',
  webfetch: 'WebFetch',
});

// `/help` as a command, not as part of a path (`skills/help/`) or URL.
const SLASH_RENAME_RE = new RegExp(
  `(^|[^A-Za-z0-9_./-])/(${Object.keys(SKILL_RENAMES).map(escapeRegex).join('|')})(?![A-Za-z0-9_-])`,
  'gm',
);

// Rule cross-references written as "Skill: `code-review`".
const SKILL_REF_RENAME_RE = new RegExp(
  `(\\bSkill:\\s*\`)(${Object.keys(SKILL_RENAMES).map(escapeRegex).join('|')})(\`)`,
  'g',
);

// ── Content transforms ─────────────────────────────────────────────────────

/** Convert CRLF/CR line endings to LF. */
export function normalizeEol(text) {
  return text.replace(/\r\n?/g, '\n');
}

/**
 * Rewrite references to the renamed skills: `/help` and `/code-review` commands,
 * and "Skill: `code-review`" cross-references, become their Claude Code names.
 */
export function renameSlashCommands(text) {
  return text
    .replace(SLASH_RENAME_RE, (_, lead, name) => `${lead}/${SKILL_RENAMES[name]}`)
    .replace(SKILL_REF_RENAME_RE, (_, open, name, close) => `${open}${SKILL_RENAMES[name]}${close}`);
}

/** Map a comma-separated `allowed-tools` value to Claude Code tool names, dropping duplicates. */
export function mapAllowedTools(value) {
  const tools = value
    .split(/,(?![^(]*\))/)
    .map((tool) => tool.trim())
    .filter(Boolean)
    .map((tool) => TOOL_RENAMES[tool] ?? tool);
  return [...new Set(tools)].join(', ');
}

/** Claude Code version of an `.agents/agents/*.md` file. */
export function claudeAgentFile(content, filename) {
  return renameSlashCommands(claudeAgentMarkdown(normalizeEol(content), filename));
}

/** Claude Code version of an `.agents/skills/<name>/SKILL.md` file. */
export function claudeSkillMarkdown(content) {
  const text = normalizeEol(content);
  const parts = splitFrontmatter(text);
  if (!parts) return renameSlashCommands(text);

  const lines = parts.frontmatter.split('\n');
  const kept = [];
  let preload = null;
  let inToolList = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (inToolList) {
      const item = line.match(/^(\s+-\s+)(.*)$/);
      if (item) {
        kept.push(`${item[1]}${TOOL_RENAMES[item[2].trim()] ?? item[2]}`);
        continue;
      }
      inToolList = false;
    }

    const name = line.match(/^name:\s*(['"]?)(.*?)\1\s*$/);
    if (name) {
      kept.push(SKILL_RENAMES[name[2]] ? `name: ${SKILL_RENAMES[name[2]]}` : line);
      continue;
    }

    const tools = line.match(/^allowed-tools:\s*(.*)$/);
    if (tools) {
      if (tools[1].trim()) {
        kept.push(`allowed-tools: ${mapAllowedTools(tools[1])}`);
      } else {
        kept.push(line);
        inToolList = true;
      }
      continue;
    }

    const context = line.match(/^context:\s*(.*)$/);
    if (context && context[1].trim() !== 'fork') {
      const value = context[1].trim();
      preload = [];
      if (/^[|>][-+]?$/.test(value)) {
        while (i + 1 < lines.length && (lines[i + 1].trim() === '' || /^\s/.test(lines[i + 1]))) {
          preload.push(lines[++i].trim());
        }
      } else if (value) {
        preload.push(value.replace(/^(['"])(.*)\1$/, '$2'));
      }
      continue;
    }

    kept.push(line);
  }

  const body = preload ? insertAfterTitle(parts.body, renderPreload(preload.filter(Boolean))) : parts.body;
  return renameSlashCommands(`---\n${kept.join('\n')}\n---\n${body}`);
}

function splitFrontmatter(text) {
  if (!text.startsWith('---\n')) return null;
  const close = text.indexOf('\n---', 3);
  if (close === -1) return null;
  const bodyStart = text.indexOf('\n', close + 4);
  return {
    frontmatter: text.slice(4, close),
    body: bodyStart === -1 ? '' : text.slice(bodyStart + 1),
  };
}

function renderPreload(lines) {
  const commands = lines.filter((line) => line.startsWith('!')).map((line) => line.slice(1).trim()).filter(Boolean);
  const notes = lines.filter((line) => !line.startsWith('!'));
  const out = notes.map((note) => `> ${note}`);
  if (commands.length > 0) {
    if (out.length > 0) out.push('');
    out.push('**Context preload:** run these first and use the output as context (empty output is fine).', '');
    out.push(...commands.map((command) => `- \`${command}\``));
  }
  return out;
}

function insertAfterTitle(body, block) {
  if (block.length === 0) return body;
  const lines = body.split('\n');
  let i = 0;
  while (i < lines.length && lines[i].trim() === '') i++;
  if (i < lines.length && /^#\s/.test(lines[i])) {
    lines.splice(i + 1, 0, '', ...block);
  } else {
    lines.splice(i, 0, ...block, '');
  }
  return lines.join('\n');
}

// ── Planning ───────────────────────────────────────────────────────────────

/**
 * Compute the mirror: a Map of `.claude/...` target path → `{ source, content }`.
 * Text content is a string with LF line endings; other files are Buffers.
 */
export function planClaudeMirror(root) {
  const plan = new Map();
  const add = (source, target, content) => {
    if (plan.has(target)) {
      throw new Error(`${source} and ${plan.get(target).source} both map to ${target}`);
    }
    plan.set(target, { source, content });
  };

  const agentsDir = join(root, '.agents', 'agents');
  for (const file of listDir(agentsDir)) {
    if (!file.endsWith('.md') || !isFile(join(agentsDir, file))) continue;
    add(`.agents/agents/${file}`, `.claude/agents/${file}`, claudeAgentFile(readText(join(agentsDir, file)), file));
  }

  const skillsDir = join(root, '.agents', 'skills');
  for (const dir of listDir(skillsDir)) {
    const sourceDir = join(skillsDir, dir);
    if (!isDir(sourceDir)) continue;
    const targetDir = SKILL_RENAMES[dir] ?? dir;
    for (const rel of walkFiles(sourceDir)) {
      const abs = join(sourceDir, rel);
      let content;
      if (rel === 'SKILL.md') content = claudeSkillMarkdown(readText(abs));
      else if (rel.endsWith('.md')) content = renameSlashCommands(normalizeEol(readText(abs)));
      else content = readFileSync(abs);
      add(`.agents/skills/${dir}/${rel}`, `.claude/skills/${targetDir}/${rel}`, content);
    }
  }

  const rulesDir = join(root, '.agents', 'rules');
  for (const file of listDir(rulesDir)) {
    if (!file.endsWith('.md') || !isFile(join(rulesDir, file))) continue;
    add(`.agents/rules/${file}`, `.claude/rules/${file}`, renameSlashCommands(normalizeEol(readText(join(rulesDir, file)))));
  }

  return plan;
}

// ── Sync / check ───────────────────────────────────────────────────────────

/**
 * Bring `.claude/` in line with the plan, or with `check: true` only report
 * what would change. A path that exists on disk but was not created by a sync
 * is reported as a conflict and left alone unless `force` is set.
 *
 * @returns {{ added: string[], updated: string[], removed: string[], conflicts: string[],
 *             unchanged: number, total: number, manifestChanged: boolean, inSync: boolean }}
 */
export function syncClaudeMirror(root, { check = false, force = false } = {}) {
  const plan = planClaudeMirror(root);
  const manifestFile = join(root, MANIFEST_PATH);
  const previous = readManifest(manifestFile);
  const report = { added: [], updated: [], removed: [], conflicts: [], unchanged: 0, total: plan.size };

  for (const [target, { content }] of plan) {
    const abs = join(root, target);
    if (!existsSync(abs)) {
      report.added.push(target);
      if (!check) writeOut(abs, content);
    } else if (sameContent(abs, content)) {
      report.unchanged++;
    } else if (!previous.has(target) && !force) {
      report.conflicts.push(target);
    } else {
      report.updated.push(target);
      if (!check) writeOut(abs, content);
    }
  }

  for (const target of previous.keys()) {
    if (plan.has(target)) continue;
    const abs = join(root, target);
    if (!existsSync(abs)) continue;
    report.removed.push(target);
    if (!check) {
      unlinkSync(abs);
      pruneEmptyDirs(root, dirname(abs));
    }
  }

  const managed = [...plan.keys()].filter((target) => !report.conflicts.includes(target)).sort();
  const nextManifest = renderManifest(managed, plan);
  const currentManifest = existsSync(manifestFile) ? normalizeEol(readFileSync(manifestFile, 'utf-8')) : null;
  // Nothing to mirror and nothing mirrored before: no manifest needed.
  report.manifestChanged = !(managed.length === 0 && currentManifest === null) && currentManifest !== nextManifest;
  if (!check && report.manifestChanged) writeOut(manifestFile, nextManifest);

  report.inSync = report.added.length === 0
    && report.updated.length === 0
    && report.removed.length === 0
    && report.conflicts.length === 0
    && !report.manifestChanged;
  return report;
}

/** Source path (`.agents/...`) of a generated `.claude/...` file, or null if it is not generated. */
export function mirrorSourceFor(root, target) {
  if (!target.startsWith('.claude/')) return null;
  try {
    return readManifest(join(root, MANIFEST_PATH)).get(target) ?? null;
  } catch {
    return null;
  }
}

function readManifest(file) {
  if (!existsSync(file)) return new Map();
  let data;
  try {
    data = JSON.parse(readFileSync(file, 'utf-8'));
  } catch (error) {
    throw new Error(`Cannot parse ${MANIFEST_PATH}: ${error.message}`);
  }
  return new Map(Object.entries(data?.files ?? {}));
}

function renderManifest(targets, plan) {
  const files = {};
  for (const target of targets) files[target] = plan.get(target).source;
  return `${JSON.stringify({
    $comment: 'Generated by tools/sync-claude.mjs from .agents/. Edit the source files, then run `npm run claude:sync`.',
    files,
  }, null, 2)}\n`;
}

// ── File helpers ───────────────────────────────────────────────────────────

function sameContent(abs, content) {
  if (typeof content === 'string') return normalizeEol(readFileSync(abs, 'utf-8')) === content;
  return Buffer.compare(readFileSync(abs), content) === 0;
}

function writeOut(abs, content) {
  mkdirSync(dirname(abs), { recursive: true });
  writeFileSync(abs, content);
}

function pruneEmptyDirs(root, dir) {
  const stop = join(root, '.claude');
  while (dir.startsWith(stop + sep) && readdirSync(dir).length === 0) {
    rmdirSync(dir);
    dir = dirname(dir);
  }
}

function readText(abs) {
  return readFileSync(abs, 'utf-8');
}

function listDir(dir) {
  return existsSync(dir) ? readdirSync(dir).sort() : [];
}

function isFile(path) {
  try { return statSync(path).isFile(); } catch { return false; }
}

function isDir(path) {
  try { return statSync(path).isDirectory(); } catch { return false; }
}

function walkFiles(dir, base = dir) {
  const files = [];
  for (const entry of listDir(dir)) {
    const abs = join(dir, entry);
    if (isDir(abs)) files.push(...walkFiles(abs, base));
    else if (isFile(abs)) files.push(relative(base, abs).split(sep).join('/'));
  }
  return files;
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
