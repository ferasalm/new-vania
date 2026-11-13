/**
 * Tests for the branch rule: tools/git-hooks/branch-guard.mjs,
 * tools/git-hooks/post-checkout.mjs and tools/new-task.mjs.
 */
import { execFileSync } from "node:child_process"
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { strict as assert } from "node:assert"
import { describe, it } from "node:test"

import { LINKS, classifyLink } from "../../tools/fix-opencode-symlinks.mjs"
import { checkBranchBase, currentBranch, trackedLinks } from "../../tools/git-hooks/branch-guard.mjs"
import { missingAgentFiles, repairAfterCheckout } from "../../tools/git-hooks/post-checkout.mjs"
import { BRANCH_RE, createTask, planTask } from "../../tools/new-task.mjs"

function git(root, args, input) {
	return execFileSync("git", args, {
		cwd: root,
		encoding: "utf8",
		input,
		stdio: ["pipe", "pipe", "pipe"],
		windowsHide: true,
	}).trim()
}

/** A repository on branch `Main` with one commit that holds `.agents/` and `.opencode/`. */
function makeRepo(t) {
	const parent = mkdtempSync(join(tmpdir(), "ocgs-branch-"))
	t.after(() => rmSync(parent, { recursive: true, force: true }))
	const root = join(parent, "repo")
	mkdirSync(root)
	git(root, ["init", "-q"])
	git(root, ["config", "user.email", "test@example.com"])
	git(root, ["config", "user.name", "Test"])
	git(root, ["config", "core.hooksPath", "no-hooks"])
	git(root, ["checkout", "-q", "-b", "Main"])
	for (const name of LINKS) {
		mkdirSync(join(root, ".agents", name), { recursive: true })
		writeFileSync(join(root, ".agents", name, "item.md"), `${name}\n`)
	}
	mkdirSync(join(root, ".opencode", "plugins"), { recursive: true })
	writeFileSync(join(root, ".opencode", "plugins", "keep.txt"), "keep\n")
	writeFileSync(join(root, ".gitignore"), LINKS.map((name) => `/.opencode/${name}`).join("\n") + "\n")
	git(root, ["add", "-A"])
	git(root, ["commit", "-q", "-m", "init"])
	git(root, ["update-ref", "refs/remotes/origin/Main", "HEAD"])
	return root
}

function trackLink(root, name) {
	const hash = git(root, ["hash-object", "-w", "--stdin"], `../.agents/${name}`)
	git(root, ["update-index", "--add", "--cacheinfo", `120000,${hash},.opencode/${name}`])
}

describe("branch-guard: checkBranchBase", () => {
	it("blocks commits on Main", (t) => {
		const root = makeRepo(t)
		const { errors } = checkBranchBase(root)
		assert.equal(errors.length, 1)
		assert.match(errors[0], /commits on Main are blocked/)
		assert.match(errors[0], /task:new/)
	})

	it("allows a task branch from origin/Main", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "-b", "fix/demo"])
		assert.equal(currentBranch(root), "fix/demo")
		assert.deepEqual(checkBranchBase(root), { errors: [], warnings: [] })
	})

	it("blocks a branch that still tracks the .opencode links", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "-b", "chore/old"])
		trackLink(root, "agents")
		assert.deepEqual(trackedLinks(root), [".opencode/agents"])
		const { errors } = checkBranchBase(root)
		assert.equal(errors.length, 1)
		assert.match(errors[0], /predates the generated \.opencode links/)
		assert.match(errors[0], /git merge origin\/Main/)
	})

	it("warns when the branch is behind origin/Main", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "-b", "fix/demo"])
		git(root, ["checkout", "-q", "Main"])
		git(root, ["commit", "-q", "--allow-empty", "-m", "newer"])
		git(root, ["update-ref", "refs/remotes/origin/Main", "HEAD"])
		git(root, ["checkout", "-q", "fix/demo"])
		const { errors, warnings } = checkBranchBase(root)
		assert.deepEqual(errors, [])
		assert.match(warnings[0], /1 commit\(s\) behind origin\/Main/)
	})

	it("does not block a detached HEAD", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "--detach"])
		assert.equal(currentBranch(root), null)
		assert.deepEqual(checkBranchBase(root).errors, [])
	})
})

describe("post-checkout: repairAfterCheckout", () => {
	it("restores missing .agents files and regenerates the links", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "-b", "fix/demo"])
		rmSync(join(root, ".agents", "agents", "item.md"))
		assert.deepEqual(missingAgentFiles(root), [".agents/agents/item.md"])

		const result = repairAfterCheckout(root)
		assert.deepEqual(result.restored, [".agents/agents/item.md"])
		assert.equal(result.created.length, LINKS.length)
		assert.deepEqual(result.warnings, [])
		assert.equal(existsSync(join(root, ".agents", "agents", "item.md")), true)
		for (const name of LINKS) assert.equal(classifyLink(join(root, ".opencode", name)), "ok-symlink")
		assert.equal(git(root, ["status", "--porcelain"]), "")
	})

	it("leaves modified files as they are", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "-b", "fix/demo"])
		writeFileSync(join(root, ".agents", "skills", "item.md"), "my edit\n")
		rmSync(join(root, ".agents", "rules", "item.md"))

		const result = repairAfterCheckout(root)
		assert.deepEqual(result.restored, [".agents/rules/item.md"])
		assert.equal(readFileSync(join(root, ".agents", "skills", "item.md"), "utf8"), "my edit\n")
	})

	it("does nothing when the tree is healthy", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "-b", "fix/demo"])
		repairAfterCheckout(root)
		assert.deepEqual(repairAfterCheckout(root), { restored: [], created: [], warnings: [] })
	})

	it("does not regenerate links on a branch that tracks them", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "-b", "chore/old"])
		trackLink(root, "agents")
		const result = repairAfterCheckout(root)
		assert.deepEqual(result.created, [])
		assert.match(result.warnings[0], /predates the generated \.opencode links/)
		assert.equal(existsSync(join(root, ".opencode", "skills")), false)
	})
})

describe("new-task", () => {
	it("accepts <type>/<topic> names only", () => {
		for (const good of ["fix/clash-stagger", "feat/sys-29", "docs/adr_0002", "chore/a.b"]) assert.match(good, BRANCH_RE)
		for (const bad of ["Main", "fix", "fix/", "Fix/x", "fix/Upper", "wip/x", "fix/a b", "fix/a/b", "fix/-x"]) {
			assert.doesNotMatch(bad, BRANCH_RE)
		}
	})

	it("plans a sibling worktree named after the topic", (t) => {
		const root = makeRepo(t)
		const { branch, dir } = planTask(root, "fix/demo")
		assert.equal(branch, "fix/demo")
		assert.equal(dir, join(root, "..", "repo-demo"))
		assert.throws(() => planTask(root, "demo"), /not a valid task name/)
	})

	it("creates the branch from origin/Main in a new worktree, with links", (t) => {
		const root = makeRepo(t)
		const { branch, dir } = createTask(root, "fix/demo", { fetch: false })

		assert.equal(currentBranch(dir), branch)
		assert.equal(git(dir, ["rev-parse", "HEAD"]), git(root, ["rev-parse", "origin/Main"]))
		for (const name of LINKS) assert.equal(classifyLink(join(dir, ".opencode", name)), "ok-symlink")
		assert.equal(currentBranch(root), "Main")
		assert.throws(() => createTask(root, "fix/demo", { fetch: false }), /already exists/)
	})
})

describe("branch-guard: tracked copies below a link path", () => {
	it("blocks a branch that tracks a regular file below a link path", (t) => {
		const root = makeRepo(t)
		git(root, ["checkout", "-q", "-b", "chore/copied"])
		mkdirSync(join(root, ".opencode", "agents"), { recursive: true })
		writeFileSync(join(root, ".opencode", "agents", "item.md"), "copy\n")
		git(root, ["add", "-f", ".opencode/agents/item.md"])

		assert.deepEqual(trackedLinks(root), [".opencode/agents"])
		assert.match(checkBranchBase(root).errors[0], /predates the generated \.opencode links/)
		assert.deepEqual(repairAfterCheckout(root).created, [])
	})

	it("reports link failures from createTask without throwing", (t) => {
		const root = makeRepo(t)
		rmSync(join(root, ".agents", "rules"), { recursive: true })
		git(root, ["add", "-A"])
		git(root, ["commit", "-q", "--no-verify", "-m", "drop rules"])
		git(root, ["update-ref", "refs/remotes/origin/Main", "HEAD"])

		const { dir, linkFailures } = createTask(root, "fix/nolinks", { fetch: false })
		assert.equal(existsSync(dir), true)
		assert.equal(linkFailures.length, 1)
		assert.match(linkFailures[0], /rules: canonical source/)
	})
})
