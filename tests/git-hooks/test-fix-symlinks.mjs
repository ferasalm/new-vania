/**
 * Tests for tools/fix-opencode-symlinks.mjs (generated .opencode mirrors).
 */

import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs"
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
