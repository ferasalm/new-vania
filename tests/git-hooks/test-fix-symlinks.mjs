/**
 * Tests for tools/fix-opencode-symlinks.mjs (generated .opencode mirrors).
 */

import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import { spawnSync } from "node:child_process"
import { fileURLToPath } from "node:url"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { strict as assert } from "node:assert"
import { describe, it } from "node:test"

import { LINKS, classifyLink, ensureLinks } from "../../tools/fix-opencode-symlinks.mjs"

function makeRoot({ canonical = true } = {}) {
	const root = mkdtempSync(join(tmpdir(), "ocgs-links-"))
	mkdirSync(join(root, ".opencode"), { recursive: true })
	if (canonical) {
		for (const name of LINKS) mkdirSync(join(root, ".agents", name), { recursive: true })
	}
	return root
}

describe("fix-opencode-symlinks: generation", () => {
	it("creates every missing link and reports ok", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))

		const result = ensureLinks(root)
		assert.equal(result.ok, true)
		assert.deepEqual(result.failures, [])
		for (const name of LINKS) {
			assert.equal(classifyLink(join(root, ".opencode", name)), "ok-symlink")
		}
	})

	it("is idempotent", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))

		ensureLinks(root)
		const second = ensureLinks(root)
		assert.equal(second.ok, true)
		assert.deepEqual(second.failures, [])
		assert.ok(second.actions.every((action) => action.includes(": ok")))
	})

	it("does not write in dry-run mode", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))

		const result = ensureLinks(root, { dryRun: true })
		assert.equal(result.ok, true)
		assert.ok(result.actions.some((action) => action.includes("would create")))
		for (const name of LINKS) {
			assert.equal(existsSync(join(root, ".opencode", name)), false)
		}
	})

	it("never deletes a materialised directory", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))
		mkdirSync(join(root, ".opencode", "agents"), { recursive: true })
		writeFileSync(join(root, ".opencode", "agents", "kept.md"), "content\n", "utf8")

		const result = ensureLinks(root)
		assert.equal(result.ok, true)
		assert.ok(existsSync(join(root, ".opencode", "agents", "kept.md")))
		assert.equal(classifyLink(join(root, ".opencode", "agents")), "ok-directory")
	})

	it("fails when the canonical source is absent", (t) => {
		const root = makeRoot({ canonical: false })
		t.after(() => rmSync(root, { recursive: true, force: true }))

		const result = ensureLinks(root)
		assert.equal(result.ok, false)
		assert.equal(result.failures.length, LINKS.length)
		assert.match(result.failures[0], /canonical source/)
	})
})

describe("fix-opencode-symlinks: safety", () => {
	it("keeps an unrecognised regular file and reports a failure", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))
		const file = join(root, ".opencode", "agents")
		writeFileSync(file, "my notes, not a link stub\n")

		const result = ensureLinks(root)
		assert.equal(result.ok, false)
		assert.equal(result.failures.length, 1)
		assert.match(result.failures[0], /agents: .*unrecognised file/)
		assert.equal(readFileSync(file, "utf8"), "my notes, not a link stub\n")
		assert.equal(classifyLink(join(root, ".opencode", "skills")), "ok-symlink")
	})

	it("replaces a recognised stub file", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))
		writeFileSync(join(root, ".opencode", "agents"), "../.agents/agents")

		const result = ensureLinks(root)
		assert.equal(result.ok, true)
		assert.equal(classifyLink(join(root, ".opencode", "agents")), "ok-symlink")
	})

	it("lists links that need repair as pending in a dry run", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))

		const dry = ensureLinks(root, { dryRun: true })
		assert.deepEqual(dry.pending, LINKS)
		ensureLinks(root)
		assert.deepEqual(ensureLinks(root, { dryRun: true }).pending, [])
	})
})

describe("fix-opencode-symlinks: --check CLI", () => {
	const script = fileURLToPath(new URL("../../tools/fix-opencode-symlinks.mjs", import.meta.url))

	function runCheck(root) {
		mkdirSync(join(root, "tools"), { recursive: true })
		const copy = join(root, "tools", "fix-opencode-symlinks.mjs")
		copyFileSync(script, copy)
		return spawnSync(process.execPath, [copy, "--check"], { encoding: "utf8", windowsHide: true })
	}

	it("exits 1 and writes nothing when links are missing", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))

		const run = runCheck(root)
		assert.equal(run.status, 1)
		assert.match(run.stdout, /missing or broken/)
		for (const name of LINKS) assert.equal(existsSync(join(root, ".opencode", name)), false)
	})

	it("exits 0 when every link is in place", (t) => {
		const root = makeRoot()
		t.after(() => rmSync(root, { recursive: true, force: true }))
		ensureLinks(root)

		const run = runCheck(root)
		assert.equal(run.status, 0)
		assert.match(run.stdout, /Links are healthy/)
	})
})
