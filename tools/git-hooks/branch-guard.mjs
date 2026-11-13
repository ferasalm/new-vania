/**
 * Branch rule: every task starts as a new branch from `origin/Main`.
 *
 * Used by the pre-commit hook (block) and the post-checkout hook (repair).
 * Nothing here writes to the repository.
 */
import { execFileSync } from "node:child_process"

/** Branches that never take direct commits. */
export const PROTECTED_BRANCHES = ["Main"]

/** The ref every task branch starts from. */
export const BASE_REF = "origin/Main"

/** Generated link paths. A branch that still tracks them predates the generated-links change. */
export const LINK_PATHS = [".opencode/agents", ".opencode/commands", ".opencode/skills", ".opencode/rules"]

/** Run git and return trimmed stdout, or null when git fails. */
export function tryGit(root, args) {
	try {
		return execFileSync("git", args, {
			cwd: root,
			encoding: "utf8",
			stdio: ["ignore", "pipe", "ignore"],
			windowsHide: true,
		}).trim()
	} catch {
		return null
	}
}

/** Current branch name, or null on a detached HEAD. */
export function currentBranch(root) {
	return tryGit(root, ["symbolic-ref", "--short", "-q", "HEAD"]) || null
}

/**
 * Link paths that the index still tracks: either the path itself (a symlink
 * entry, the pre-generated layout) or any file below it (a committed copy).
 */
export function trackedLinks(root) {
	const out = tryGit(root, ["ls-files", "-z", "--", ...LINK_PATHS])
	if (!out) return []
	const listed = out.split("\0").filter(Boolean)
	return LINK_PATHS.filter((path) => listed.some((file) => file === path || file.startsWith(`${path}/`)))
}

/**
 * Check the branch a commit is about to land on.
 * @returns {{ errors: string[], warnings: string[] }}
 */
export function checkBranchBase(root) {
	const errors = []
	const warnings = []
	const branch = currentBranch(root)
	if (branch === null) return { errors, warnings }

	if (PROTECTED_BRANCHES.includes(branch)) {
		errors.push(
			`commits on ${branch} are blocked. Start a task branch from ${BASE_REF}: npm run task:new -- <type>/<topic>`,
		)
		return { errors, warnings }
	}

	const stale = trackedLinks(root)
	if (stale.length > 0) {
		errors.push(
			`branch ${branch} predates the generated .opencode links (it still tracks ${stale.join(", ")}). ` +
				`Bring it up to date first: git merge ${BASE_REF}`,
		)
	}

	const behind = Number(tryGit(root, ["rev-list", "--count", `HEAD..${BASE_REF}`]))
	if (Number.isInteger(behind) && behind > 0) {
		warnings.push(`branch ${branch} is ${behind} commit(s) behind ${BASE_REF}; merge it in before opening a PR.`)
	}

	return { errors, warnings }
}
