#!/usr/bin/env node
/**
 * Repair the working tree after a branch switch or merge.
 *
 * `.opencode/{agents,commands,skills,rules}` are junctions into `.agents/` on
 * Windows. When git moves between a commit that tracks those paths and one
 * that does not, it removes them through the junction and deletes tracked
 * files under `.agents/`. This hook puts them back:
 *
 *   1. restores tracked files under `.agents/` that are missing from disk
 *      (only missing ones; modified files are left as they are);
 *   2. regenerates the links, unless the branch still tracks them.
 *
 * Run by `.githooks/post-checkout` and `.githooks/post-merge`. Never fails the git command.
 */
import { execFileSync } from "node:child_process"
import { pathToFileURL } from "node:url"

import { ensureLinks } from "../fix-opencode-symlinks.mjs"
import { BASE_REF, trackedLinks, tryGit } from "./branch-guard.mjs"

/** Tracked files under `.agents/` that are missing from the working tree. */
export function missingAgentFiles(root) {
	const out = tryGit(root, ["ls-files", "-d", "-z", "--", ".agents"])
	return out ? out.split("\0").filter(Boolean) : []
}

/**
 * Restore missing `.agents/` files and regenerate the links.
 * @returns {{ restored: string[], created: string[], warnings: string[] }}
 */
export function repairAfterCheckout(root) {
	const warnings = []
	const created = []

	const restored = missingAgentFiles(root)
	if (restored.length > 0) {
		try {
			execFileSync("git", ["checkout", "--pathspec-from-file=-", "--pathspec-file-nul"], {
				cwd: root,
				input: restored.join("\0"),
				stdio: ["pipe", "ignore", "pipe"],
				windowsHide: true,
			})
		} catch (error) {
			warnings.push(`could not restore ${restored.length} file(s) under .agents/: ${error.message}`)
			return { restored: [], created, warnings }
		}
	}

	if (trackedLinks(root).length > 0) {
		warnings.push(
			`this branch predates the generated .opencode links; commits are blocked until you run: git merge ${BASE_REF}`,
		)
		return { restored, created, warnings }
	}

	const { actions, failures } = ensureLinks(root)
	for (const action of actions) if (action.includes("created")) created.push(action)
	for (const failure of failures) warnings.push(failure)
	return { restored, created, warnings }
}

function main() {
	const root = tryGit(process.cwd(), ["rev-parse", "--show-toplevel"])
	if (!root) return
	const { restored, created, warnings } = repairAfterCheckout(root)
	if (restored.length > 0) console.log(`✔ post-checkout: restored ${restored.length} file(s) under .agents/`)
	if (created.length > 0) console.log(`✔ post-checkout: regenerated ${created.length} .opencode link(s)`)
	for (const warning of warnings) console.warn(`⚠️  post-checkout: ${warning}`)
}

const invokedDirectly =
	process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href

if (invokedDirectly) {
	try {
		main()
	} catch (error) {
		console.warn(`⚠️  post-checkout: ${error.message}`)
	}
}
