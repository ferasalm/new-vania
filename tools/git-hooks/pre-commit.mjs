#!/usr/bin/env node

/**
 * Pre-commit checks for the OCGS repository.
 *
 * Blocking checks (fix before committing):
 *   - credentials/private keys added in the staged diff
 *   - unresolved merge-conflict markers
 *   - staged files larger than 20 MB
 *   - staged changes that convert a `.opencode/*` symlink into a directory
 *   - framework validation when `.agents/` is staged
 *   - plugin tests when `.opencode/plugins/` is staged
 *   - Claude Code mirror check when mirrored `.agents/` content or `.claude/` is staged
 *
 * Advisory checks (warnings only):
 *   - likely-hardcoded credentials
 *   - staged files larger than 5 MB
 *
 * Environment:
 *   OCGS_SKIP_HOOK_CHECKS=1  skip the framework/plugin/claude gates (secret scan still runs)
 *
 * Usage: node tools/git-hooks/pre-commit.mjs
 * Exit codes: 0 = accepted, 1 = rejected.
 */

import { execFileSync } from "node:child_process"
import { existsSync, lstatSync, readFileSync, realpathSync, statSync } from "node:fs"
import { dirname, join, resolve } from "node:path"
import { pathToFileURL } from "node:url"

export const MAX_FILE_BYTES = 20 * 1024 * 1024
export const WARN_FILE_BYTES = 5 * 1024 * 1024

/** High-confidence credential shapes. Matches here block the commit. */
export const SECRET_RULES = [
	{
		id: "private-key",
		label: "private key block",
		pattern: /-----BEGIN (?:RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----/,
	},
	{
		id: "aws-access-key",
		label: "AWS access key id",
		pattern: /\bAKIA[0-9A-Z]{16}\b/,
	},
	{
		id: "github-token",
		label: "GitHub token",
		pattern: /\b(?:gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,})\b/,
	},
	{
		id: "slack-token",
		label: "Slack token",
		pattern: /\bxox[baprs]-[A-Za-z0-9-]{10,}\b/,
	},
	{
		id: "api-key",
		label: "API key (sk-…)",
		pattern: /\bsk-(?:ant-)?[A-Za-z0-9_-]{20,}\b/,
	},
	{
		id: "google-api-key",
		label: "Google API key",
		pattern: /\bAIza[0-9A-Za-z_-]{35}\b/,
	},
]

const CREDENTIAL_ASSIGNMENT =
	/^\s*(?:(?:export|const|let|var|private|public|protected|static|readonly)\s+)*[\w.-]*(?:api[_-]?key|secret|passwd|password|credential|token)[\w.-]*\s*[:=]\s*["'][^"']{8,}["']/i

const CREDENTIAL_PLACEHOLDER =
	/(?:x{3,}|\*{3,}|<[^>]*>|\$\{|\$[A-Z_]+|process\.env|changeme|example|dummy|placeholder|redacted|your[_-]|\.\.\.)/i

const CONFLICT_MARKER = /^(?:<{7}|>{7})(?:\s|$)/

const ADVICE_ONLY = (file) =>
	/\.md$/i.test(file) ||
	file.startsWith("docs/") ||
	file.startsWith("tests/") ||
	/(?:^|\/)test-[^/]*$/i.test(file) ||
	/(?:^|\/)\.github\//.test(file)

const normalize = (file) => file.replace(/\\/g, "/")

/** Run a git command, returning stdout. Throws when git fails. */
export function git(root, args, options = {}) {
	return execFileSync("git", args, {
		cwd: root,
		encoding: "utf8",
		maxBuffer: 32 * 1024 * 1024,
		stdio: ["ignore", "pipe", "pipe"],
		...options,
	})
}

/** Staged paths that represent added or modified content. */
export function stagedFiles(root) {
	const output = git(root, [
		"diff",
		"--cached",
		"--name-only",
		"--no-renames",
		"--diff-filter=ACMR",
	])
	return output
		.split("\n")
		.map((line) => line.trim())
		.filter(Boolean)
		.map(normalize)
}

/** Staged diff with zero context, for added-line scanning. */
export function stagedDiff(root) {
	return git(root, [
		"diff",
		"--cached",
		"--unified=0",
		"--no-color",
		"--no-ext-diff",
		"--diff-filter=ACMR",
	])
}

/**
 * Extract added lines from a unified diff.
 * @returns {Array<{ file: string, text: string }>}
 */
export function parseAddedLines(diff) {
	const entries = []
	let current = null
	for (const line of String(diff).split("\n")) {
		if (line.startsWith("+++ ")) {
			const target = line.slice(4).trim()
			current = target === "/dev/null" ? null : normalize(target.replace(/^b\//, ""))
			continue
		}
		if (current === null) continue
		if (line.startsWith("+") && line !== "+") entries.push({ file: current, text: line.slice(1) })
	}
	return entries
}

/**
 * Scan added lines for credentials and conflict markers.
 * @returns {{ errors: string[], warnings: string[] }}
 */
export function scanAddedLines(entries) {
	const errors = []
	const warnings = []
	const reported = new Set()

	for (const { file, text } of entries) {
		for (const rule of SECRET_RULES) {
			if (!rule.pattern.test(text)) continue
			const key = `${rule.id}:${file}`
			if (reported.has(key)) continue
			reported.add(key)
			errors.push(`${file}: possible ${rule.label} in staged content — remove it before committing.`)
		}

		if (CONFLICT_MARKER.test(text)) {
			const key = `conflict:${file}`
			if (!reported.has(key)) {
				reported.add(key)
				errors.push(`${file}: unresolved merge conflict marker — resolve the conflict first.`)
			}
		}

		if (!ADVICE_ONLY(file) && CREDENTIAL_ASSIGNMENT.test(text) && !CREDENTIAL_PLACEHOLDER.test(text)) {
			const key = `credential:${file}`
			if (!reported.has(key)) {
				reported.add(key)
				warnings.push(`${file}: hardcoded credential-like assignment — confirm it is not a real secret.`)
			}
		}
	}

	return { errors, warnings }
}

/**
 * Flag staged files by size.
 * @returns {{ errors: string[], warnings: string[] }}
 */
export function checkFileSizes(root, files, thresholds = {}) {
	const maxBytes = thresholds.maxBytes ?? MAX_FILE_BYTES
	const warnBytes = thresholds.warnBytes ?? WARN_FILE_BYTES
	const errors = []
	const warnings = []

	for (const file of files) {
		const full = join(root, file)
		if (!existsSync(full)) continue
		let stat
		try {
			stat = statSync(full)
		} catch {
			continue
		}
		if (!stat.isFile()) continue
		if (stat.size > maxBytes) {
			errors.push(
				`${file}: ${(stat.size / 1024 / 1024).toFixed(1)} MB exceeds the ${(maxBytes / 1024 / 1024).toFixed(0)} MB commit limit.`,
			)
		} else if (stat.size > warnBytes) {
			warnings.push(
				`${file}: ${(stat.size / 1024 / 1024).toFixed(1)} MB is large for a repository commit.`,
			)
		}
	}

	return { errors, warnings }
}

/**
 * Check that each `.opencode/<name>` entry exists and resolves to a directory
 * (a junction or symlink), or is a redirect stub whose target exists. It does not
 * require the target to be the canonical `.agents/<name>` path.
 * @returns {{ errors: string[], warnings: string[] }}
 */
export function checkFrameworkLinks(root) {
	const links = [
		["agents", ".agents/agents"],
		["commands", ".agents/commands"],
		["rules", ".agents/rules"],
		["skills", ".agents/skills"],
	]
	const opencode = join(root, ".opencode")
	const errors = []
	const warnings = []

	if (!existsSync(opencode)) return { errors, warnings }

	for (const [name, fallbackTarget] of links) {
		const path = join(opencode, name)
		if (!existsSync(path)) {
			errors.push(`.opencode/${name} is missing; expected a link to ${fallbackTarget}.`)
			continue
		}

		let stat
		try {
			stat = lstatSync(path)
		} catch {
			continue
		}

		if (stat.isSymbolicLink()) {
			try {
				if (!statSync(realpathSync(path)).isDirectory()) {
					errors.push(`.opencode/${name} points at something that is not a directory.`)
				}
			} catch {
				errors.push(`.opencode/${name} is a broken symlink; repoint it at ${fallbackTarget}.`)
			}
			continue
		}

		if (stat.isFile()) {
			const target = readFileSync(path, "utf8").trim()
			if (target === "") {
				errors.push(`.opencode/${name} is an empty redirect stub; expect "${fallbackTarget}".`)
				continue
			}
			if (!existsSync(resolve(dirname(path), target))) {
				errors.push(`.opencode/${name} redirects to "${target}", which does not exist.`)
			}
			continue
		}

		if (!stat.isDirectory()) {
			errors.push(`.opencode/${name} is neither a link, redirect stub nor directory.`)
		}
	}

	return { errors, warnings }
}

/** Paths whose changes can put the generated `.claude/` mirror out of date. */
const CLAUDE_MIRROR_INPUT =
	/^(?:\.agents\/(?:agents|skills|rules)\/|\.claude\/|tools\/sync-claude\.mjs$|tools\/lib\/(?:claude-mirror|harness-targets)\.mjs$)/

/**
 * The four `.opencode` paths tracked as symlinks to `.agents/`.
 * On Windows without Developer Mode they exist as junctions, which git cannot
 * represent, so a full `git add -A` stages them as "symlink deleted + N files
 * added". Committing that turns the mirrors into independent copies on POSIX
 * clones and the trees drift silently.
 * @see docs/tooling/opencode-symlink-conflict.md
 */
export const FRAMEWORK_LINK_PATHS = [
	".opencode/agents",
	".opencode/commands",
	".opencode/rules",
	".opencode/skills",
]

const STAGE_STATUS = {
	A: "added",
	C: "copied",
	D: "deleted",
	M: "modified",
	R: "renamed",
	T: "type-changed",
	U: "unmerged",
}

/**
 * Refuse staged changes that would commit a framework link as a directory.
 * Reads the **index**; the filesystem check below cannot see this conflict
 * because a junction is a directory to lstat.
 * @returns {{ errors: string[] }}
 */
export function checkFrameworkLinkStaging(root) {
	const output = git(root, ["diff", "--cached", "--name-status", "--no-renames", "--no-color"])
	const errors = []
	const reported = new Set()

	for (const line of output.split("\n")) {
		if (!line.trim()) continue
		const [code, ...rest] = line.split("\t")
		const file = normalize(rest.join("\t").trim())
		if (!file) continue

		const link = FRAMEWORK_LINK_PATHS.find((path) => file === path || file.startsWith(`${path}/`))
		if (!link || reported.has(link)) continue
		reported.add(link)

		const action = STAGE_STATUS[code[0]] ?? code
		errors.push(
			`${file}: staged ${action}, but ${link} is tracked as a symlink to .agents/ — committing this converts the mirror into an independent copy. ` +
				`Run "git restore --staged ${FRAMEWORK_LINK_PATHS.join(" ")}" and stage the change under .agents/ instead ` +
				`(docs/tooling/opencode-symlink-conflict.md).`,
		)
	}

	return { errors }
}


/** Which repository gates the staged paths require. */
export function planGates(files) {
	const gates = []
	if (
		files.some(
			(file) =>
				file.startsWith(".agents/") ||
				file.startsWith("tests/agents/") ||
				file === "AGENTS.md",
		)
	) {
		gates.push("framework")
	}
	if (files.some((file) => file.startsWith(".opencode/plugins/"))) {
		gates.push("plugins")
	}
	if (files.some((file) => CLAUDE_MIRROR_INPUT.test(file))) {
		gates.push("claude")
	}
	return gates
}

/**
 * Variables git exports to hooks that pin git commands to this repository
 * (`git rev-parse --local-env-vars`). Inherited by a gate, they make test
 * suites that build throwaway repositories commit, tag and write config into
 * the repository being committed instead.
 */
export const GIT_LOCAL_ENV_VARS = [
	"GIT_ALTERNATE_OBJECT_DIRECTORIES", "GIT_CONFIG", "GIT_CONFIG_PARAMETERS", "GIT_CONFIG_COUNT",
	"GIT_OBJECT_DIRECTORY", "GIT_DIR", "GIT_WORK_TREE", "GIT_IMPLICIT_WORK_TREE", "GIT_GRAFT_FILE",
	"GIT_INDEX_FILE", "GIT_NO_REPLACE_OBJECTS", "GIT_REPLACE_REF_BASE", "GIT_PREFIX",
	"GIT_SHALLOW_FILE", "GIT_COMMON_DIR",
]

/** Copy of `env` without the repository-pinning git variables, for gate commands. */
export function gateEnv(env = process.env) {
	const clean = { ...env }
	for (const name of GIT_LOCAL_ENV_VARS) delete clean[name]
	return clean
}

function runCommand(root, command, args, options = {}) {
	try {
		const output = execFileSync(command, args, {
			cwd: root,
			encoding: "utf8",
			env: gateEnv(),
			maxBuffer: 32 * 1024 * 1024,
			stdio: ["ignore", "pipe", "pipe"],
			timeout: options.timeout ?? 180_000,
			shell: options.shell ?? false,
		})
		return { ok: true, output }
	} catch (error) {
		return {
			ok: false,
			output: `${error.stdout ?? ""}${error.stderr ?? ""}` || error.message,
		}
	}
}

function tail(text, lines = 30) {
	const all = String(text).trimEnd().split("\n")
	return all.slice(-lines).join("\n")
}

/**
 * Run the selected repository gates.
 * @returns {{ errors: string[], warnings: string[], notes: string[] }}
 */
export function runGates(root, gates, env = process.env) {
	const errors = []
	const warnings = []
	const notes = []

	if (gates.length === 0) return { errors, warnings, notes }

	if (env.OCGS_SKIP_HOOK_CHECKS === "1") {
		notes.push(`Skipped gates (${gates.join(", ")}) because OCGS_SKIP_HOOK_CHECKS=1.`)
		return { errors, warnings, notes }
	}

	if (gates.includes("framework")) {
		const checks = [
			["framework validation", [process.execPath, ["tests/agents/validate.mjs", "--no-report"]]],
			["workflow integrity", [process.execPath, ["tests/workflow/run-all.mjs"]]],
		]
		for (const [label, [command, args]] of checks) {
			const result = runCommand(root, command, args)
			if (result.ok) notes.push(`${label} passed`)
			else errors.push(`${label} failed:\n${tail(result.output)}`)
		}
	}

	if (gates.includes("plugins")) {
		if (!existsSync(join(root, "node_modules", "tsx"))) {
			warnings.push('plugin gate skipped: run "npm install" so the tsx loader is available.')
		} else {
			const result = runCommand(root, "npm", ["run", "-s", "test:plugins"], { shell: true })
			if (result.ok) notes.push("plugin tests passed")
			else errors.push(`plugin tests failed:\n${tail(result.output)}`)
		}
	}

	if (gates.includes("claude")) {
		const result = runCommand(root, process.execPath, ["tools/sync-claude.mjs", "--check"])
		if (result.ok) notes.push("claude mirror check passed")
		else errors.push(`.claude/ mirror is out of date: run "npm run claude:sync" and stage .claude/.\n${tail(result.output)}`)
	}

	return { errors, warnings, notes }
}

/**
 * Full pre-commit evaluation (no printing, no exit) — used by tests.
 */
export function evaluatePreCommit(root, env = process.env) {
	const files = stagedFiles(root)
	const { errors: secretErrors, warnings: secretWarnings } = scanAddedLines(
		parseAddedLines(stagedDiff(root)),
	)
	const { errors: sizeErrors, warnings: sizeWarnings } = checkFileSizes(root, files)
	const { errors: linkStageErrors } = checkFrameworkLinkStaging(root)
	const { errors: linkErrors } = checkFrameworkLinks(root)
	const gates = runGates(root, planGates(files), env)

	return {
		errors: [...secretErrors, ...linkStageErrors, ...linkErrors, ...sizeErrors, ...gates.errors],
		warnings: [...secretWarnings, ...sizeWarnings, ...gates.warnings],
		notes: gates.notes,
	}
}

function main() {
	let root
	try {
		root = execFileSync("git", ["rev-parse", "--show-toplevel"], {
			encoding: "utf8",
			stdio: ["ignore", "pipe", "ignore"],
		}).trim()
	} catch (error) {
		console.error(`pre-commit: not inside a git work tree (${error.message})`)
		process.exit(0)
	}

	const { errors, warnings, notes } = evaluatePreCommit(root)

	for (const note of notes) console.log(`✔ pre-commit: ${note}`)
	for (const warning of warnings) console.warn(`⚠️  pre-commit: ${warning}`)

	if (errors.length > 0) {
		console.error("\n✖ Commit blocked by pre-commit checks:")
		for (const error of errors) console.error(`   - ${error}`)
		console.error("\n   Fix the problems above, then stage and commit again.")
		console.error("   To bypass once: git commit --no-verify\n")
		process.exit(1)
	}

	console.log("✔ pre-commit checks passed.")
	process.exit(0)
}

const invokedDirectly =
	process.argv[1] !== undefined &&
	import.meta.url === pathToFileURL(process.argv[1]).href

if (invokedDirectly) main()
