#!/usr/bin/env node
/**
 * Start a task the one supported way: a new branch from `origin/Main`, in its own worktree.
 *
 * Usage: npm run task:new -- <type>/<topic> [--no-fetch]
 *   e.g. npm run task:new -- fix/clash-stagger
 *
 * Creates `../<repo>-<topic>` on branch `<type>/<topic>` from a freshly fetched
 * `origin/Main`, generates the `.opencode` links there, and prints the next steps.
 * It never touches the current checkout and never deletes anything.
 */
import { execFileSync } from "node:child_process"
import fs from "node:fs"
import path from "node:path"
import { pathToFileURL } from "node:url"

import { ensureLinks } from "./fix-opencode-symlinks.mjs"
import { BASE_REF, tryGit } from "./git-hooks/branch-guard.mjs"

/** `<type>/<topic>`: a Conventional Commits type, then a lower-case topic. */
export const BRANCH_RE = /^(feat|fix|docs|chore|refactor|test|perf|ci|build|style|revert)\/([a-z0-9][a-z0-9._-]*)$/

function git(root, args) {
	return execFileSync("git", args, {
		cwd: root,
		encoding: "utf8",
		stdio: ["ignore", "pipe", "pipe"],
		windowsHide: true,
	}).trim()
}

/** The main worktree (first entry of `git worktree list`). */
export function mainWorktree(root) {
	const first = git(root, ["worktree", "list", "--porcelain"]).split("\n")[0]
	return path.resolve(first.replace(/^worktree /, ""))
}

/**
 * Work out the branch and folder for a task without creating anything.
 * @returns {{ branch: string, dir: string }}
 */
export function planTask(root, name) {
	const match = BRANCH_RE.exec(name ?? "")
	if (!match) {
		throw new Error(`"${name ?? ""}" is not a valid task name. Use <type>/<topic>, for example fix/clash-stagger.`)
	}
	const main = mainWorktree(root)
	return { branch: name, dir: path.join(path.dirname(main), `${path.basename(main)}-${match[2]}`) }
}

/**
 * Create the worktree and branch from `origin/Main`.
 * @returns {{ branch: string, dir: string, base: string }}
 */
export function createTask(root, name, { fetch = true } = {}) {
	const { branch, dir } = planTask(root, name)
	if (tryGit(root, ["rev-parse", "-q", "--verify", `refs/heads/${branch}`])) {
		throw new Error(`branch ${branch} already exists. Pick another topic.`)
	}
	if (fs.existsSync(dir)) throw new Error(`${dir} already exists. Pick another topic.`)

	if (fetch) git(root, ["fetch", "--quiet", "origin", "Main"])
	const base = tryGit(root, ["rev-parse", "--short", BASE_REF])
	if (!base) throw new Error(`${BASE_REF} is not available. Run: git fetch origin`)

	git(root, ["worktree", "add", "--quiet", dir, "-b", branch, BASE_REF])
	ensureLinks(dir)
	return { branch, dir, base }
}

function main() {
	const args = process.argv.slice(2)
	const name = args.find((arg) => !arg.startsWith("--"))
	const root = tryGit(process.cwd(), ["rev-parse", "--show-toplevel"])
	if (!root) {
		console.error("✖ task:new: not inside a git work tree.")
		process.exit(1)
	}
	try {
		const { branch, dir, base } = createTask(root, name, { fetch: !args.includes("--no-fetch") })
		console.log(`✔ Created ${branch} from ${BASE_REF} (${base})`)
		console.log(`  Worktree: ${dir}`)
		console.log(`  Next: cd "${dir}", then run "npm install" there if you need the tests or hooks that use tsx.`)
	} catch (error) {
		console.error(`✖ task:new: ${error.message}`)
		process.exit(1)
	}
}

const invokedDirectly =
	process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href

if (invokedDirectly) main()
