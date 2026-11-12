#!/usr/bin/env node
/**
 * Create or repair the `.opencode/{agents,commands,skills,rules}` mirrors.
 *
 * These paths are **generated, not tracked**. `.gitignore` excludes them and
 * `npm install` runs this script through the `prepare` script, so every clone
 * materialises them the same way:
 *
 *   - Windows: an NTFS junction (no Developer Mode or admin rights needed)
 *   - POSIX:   a directory symlink
 *
 * Why generated instead of committed: git can only represent these as
 * symlinks (mode 120000). A Windows checkout without Developer Mode cannot
 * create real symlinks, so it writes inert text stubs or junctions that git
 * reads as "symlink deleted". Committing that converts the mirrors into
 * independent copies on POSIX clones and the two trees drift silently.
 * Removing them from the index removes the conflict instead of guarding it.
 *
 * Usage: node tools/fix-opencode-symlinks.mjs [--dry-run] [--check]
 *   --check exits 1 when a link is missing or broken, without writing.
 */
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import { pathToFileURL } from "node:url"

export const LINKS = ["agents", "commands", "skills", "rules"]

const STUB_RE = /^\.\.[\\/]\.agents[\\/][a-z-]+\s*$/i

/** @returns {"missing"|"ok-symlink"|"broken-symlink"|"ok-directory"|"stub-file"|"unknown-file"|"unknown"} */
export function classifyLink(linkPath) {
	if (!fs.existsSync(linkPath)) return "missing"
	const stat = fs.lstatSync(linkPath)
	if (stat.isSymbolicLink()) {
		try {
			const real = fs.realpathSync(linkPath)
			return fs.existsSync(real) && fs.statSync(real).isDirectory() ? "ok-symlink" : "broken-symlink"
		} catch {
			return "broken-symlink"
		}
	}
	if (stat.isDirectory()) return "ok-directory"
	if (stat.isFile()) {
		const content = fs.readFileSync(linkPath, "utf8").trim()
		return STUB_RE.test(content) ? "stub-file" : "unknown-file"
	}
	return "unknown"
}

function createLink(root, name) {
	const linkPath = path.join(root, ".opencode", name)
	const targetRel = path.join("..", ".agents", name)
	const targetAbs = path.join(root, ".agents", name)

	fs.rmSync(linkPath, { force: true, recursive: false })
	try {
		fs.symlinkSync(targetRel, linkPath, process.platform === "win32" ? "junction" : "dir")
	} catch (err) {
		// Junctions require an absolute target on Windows.
		if (process.platform === "win32") fs.symlinkSync(targetAbs, linkPath, "junction")
		else throw err
	}
}

/**
 * Ensure every mirror exists and resolves.
 * @returns {{ ok: boolean, actions: string[], failures: string[] }}
 */
export function ensureLinks(root, { dryRun = false } = {}) {
	const actions = []
	const failures = []
	const opencode = path.join(root, ".opencode")

	if (!fs.existsSync(opencode)) {
		return { ok: false, actions, failures: [".opencode/ is missing"] }
	}

	for (const name of LINKS) {
		const linkPath = path.join(opencode, name)
		const targetAbs = path.join(root, ".agents", name)
		const state = classifyLink(linkPath)

		if (state === "ok-symlink") {
			actions.push(`${name}: ok`)
			continue
		}
		// A real directory is a materialised copy. Never delete it; report it.
		if (state === "ok-directory") {
			actions.push(`${name}: ok (materialised directory, not a link)`)
			continue
		}
		if (!fs.existsSync(targetAbs) || !fs.statSync(targetAbs).isDirectory()) {
			failures.push(`${name}: canonical source .agents/${name} does not exist`)
			continue
		}
		if (dryRun) {
			actions.push(`${name}: would create link -> .agents/${name} (was ${state})`)
			continue
		}
		try {
			createLink(root, name)
			actions.push(`${name}: created -> .agents/${name} (was ${state})`)
		} catch (error) {
			failures.push(`${name}: ${error.message}`)
		}
	}

	return { ok: failures.length === 0, actions, failures }
}

function main() {
	const dryRun = process.argv.includes("--dry-run")
	const check = process.argv.includes("--check")
	const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..")

	// Not an OpenCode checkout (e.g. a packaged tarball): nothing to link.
	if (!check && !fs.existsSync(path.join(root, ".opencode"))) {
		console.log("ℹ No .opencode/ directory here; skipping link generation.")
		process.exit(0)
	}

	console.log("Checking .opencode/{agents,commands,skills,rules}...\n")
	const { ok, actions, failures } = ensureLinks(root, { dryRun: dryRun || check })

	for (const action of actions) console.log(`  ${action.startsWith("ok") ? "✓" : "→"} ${action}`)
	for (const failure of failures) console.error(`  ✗ ${failure}`)

	if (check) {
		console.log(ok ? "\nLinks are healthy." : "\nLinks are missing or broken; run `npm run fix:symlinks`.")
		process.exit(ok ? 0 : 1)
	}
	console.log(
		dryRun
			? "\nDry run complete. Re-run without --dry-run to apply."
			: "\nLinks ready. This runs automatically on `npm install`.",
	)
	process.exit(ok ? 0 : 1)
}

const invokedDirectly =
	process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href

if (invokedDirectly) main()
