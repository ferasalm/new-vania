#!/usr/bin/env node
/**
 * Render and verify the orchestration prompts.
 *
 * Usage:
 *   node tools/orchestration/render-prompts.mjs            # render the active lanes + NEXT + hashes
 *   node tools/orchestration/render-prompts.mjs --all      # render every lane block in the master
 *   node tools/orchestration/render-prompts.mjs --lane SYS-03
 *   node tools/orchestration/render-prompts.mjs --next     # render NEXT.md only
 *   node tools/orchestration/render-prompts.mjs --check    # verify every hash/header; no writes
 *
 * The master (`production/orchestration/lane-kickoff-master.md`) is the source
 * for lane bodies. The manifest (`production/orchestration/manifest.yaml`) is
 * the source of truth for versions and hashes. Generated files must not be
 * hand-edited.
 */
import { createHash } from "node:crypto"
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..")
const MASTER = path.join(ROOT, "production/orchestration/lane-kickoff-master.md")
const MANIFEST = path.join(ROOT, "production/orchestration/manifest.yaml")
const ORCHESTRATOR = path.join(ROOT, "production/orchestration/prompts/orchestrator-loop.md")
const NEXT = path.join(ROOT, "production/orchestration/prompts/NEXT.md")

/** Lanes rendered by default. `--all` renders every block in the master. */
const DEFAULT_LANES = ["ART-BIBLE", "SYS-03", "SYS-04"]

const args = process.argv.slice(2)
const check = args.includes("--check")
const all = args.includes("--all")
const nextOnly = args.includes("--next")
const laneArgIndex = args.indexOf("--lane")
const laneArg = laneArgIndex >= 0 ? args[laneArgIndex + 1] : null

const normalize = (s) => s.replace(/\r\n/g, "\n").replace(/\s+$/u, "") + "\n"
const hash = (s) => createHash("sha256").update(normalize(s), "utf8").digest("hex").slice(0, 12)
const read = (p) => fs.readFileSync(p, "utf8")
const write = (p, s) => {
	fs.mkdirSync(path.dirname(p), { recursive: true })
	fs.writeFileSync(p, s, "utf8")
}

function fail(message) {
	console.error(`\u2716 ${message}`)
	process.exit(1)
}

function parseBlocks(text, marker) {
	const re = new RegExp(`<!-- ${marker}:([A-Z0-9-]+) -->\\n([\\s\\S]*?)\\n<!-- \\/${marker}:\\1 -->`, "g")
	const blocks = new Map()
	let match
	while ((match = re.exec(text)) !== null) blocks.set(match[1], normalize(match[2]))
	return blocks
}

function parseManifest(text) {
	const laneRe = /^  - id: ([A-Z0-9-]+)$/gm
	const laneStarts = [...text.matchAll(laneRe)]
	const lanes = new Map()
	for (let i = 0; i < laneStarts.length; i++) {
		const start = laneStarts[i].index
		const end = i + 1 < laneStarts.length ? laneStarts[i + 1].index : text.length
		const block = text.slice(start, end)
		const field = (name) => {
			const m = block.match(new RegExp(`^    ${name}: (.*)$`, "m"))
			return m ? m[1].replace(/^"|"$/g, "") : null
		}
		lanes.set(laneStarts[i][1], {
			id: laneStarts[i][1],
			branch: field("branch"),
			worktree: field("worktree"),
			prompt_path: field("prompt_path"),
			prompt_version: field("prompt_version"),
			prompt_hash: field("prompt_hash"),
			model: field("model"),
			status: field("status"),
		})
	}
	const supportRe = /^  - id: ([a-z0-9-]+)$/gm
	const supportStarts = [...text.matchAll(supportRe)]
	const support = new Map()
	for (let i = 0; i < supportStarts.length; i++) {
		const start = supportStarts[i].index
		const end = i + 1 < supportStarts.length ? supportStarts[i + 1].index : text.indexOf("\nlanes:", start)
		const block = text.slice(start, end < 0 ? text.length : end)
		const field = (name) => {
			const m = block.match(new RegExp(`^    ${name}: (.*)$`, "m"))
			return m ? m[1].replace(/^"|"$/g, "") : null
		}
		support.set(supportStarts[i][1], {
			id: supportStarts[i][1],
			path: field("path"),
			version: field("version"),
			hash: field("hash"),
		})
	}
	const nextBlock = text.slice(text.indexOf("\nnext:") + 1, text.indexOf("\nsupport_prompts:"))
	const nextField = (name) => {
		const m = nextBlock.match(new RegExp(`^  ${name}: (.*)$`, "m"))
		return m ? m[1].replace(/^"|"$/g, "") : null
	}
	const generated = (text.match(/^generated: "(.*)"$/m) ?? [])[1] ?? "unknown"
	return {
		lanes,
		support,
		next: {
			kind: nextField("kind"),
			path: nextField("path"),
			version: nextField("version"),
			hash: nextField("hash"),
		},
		generated,
	}
}

function setBlockField(text, startMarker, endMarker, field, value) {
	const start = text.indexOf(startMarker)
	if (start < 0) fail(`manifest block not found: ${startMarker}`)
	const end = endMarker ? text.indexOf(endMarker, start + startMarker.length) : text.length
	const slice = text.slice(start, end < 0 ? text.length : end)
	const fieldRe = new RegExp(`^(    |  )${field}: ".*"$`, "m")
	if (!fieldRe.test(slice)) fail(`field ${field} not found in ${startMarker}`)
	const updated = slice.replace(fieldRe, (line) => line.replace(/".*"$/, `"${value}"`))
	return text.slice(0, start) + updated + text.slice(end < 0 ? text.length : end)
}

function renderLane(id, lane, shared, block, generated) {
	const body = normalize(`${shared}\n\n${block}`)
	const h = hash(body)
	const header = `<!--
Lane: ${id}
Branch: ${lane.branch}
Worktree: ${lane.worktree}
Version: ${lane.prompt_version}
Model: ${lane.model}
Hash: ${h}
Source: production/orchestration/lane-kickoff-master.md
Generated: ${generated}
-->

`
	const outPath = path.join(ROOT, lane.prompt_path)
	write(outPath, header + body)
	return h
}

function renderNext(manifest) {
	const body = normalize(read(ORCHESTRATOR))
	const h = hash(body)
	const header = `<!--
Kind: ${manifest.next.kind}
Path: ${manifest.next.path}
Version: ${manifest.next.version}
Hash: ${h}
Source: ${manifest.next.path}
Generated: ${manifest.generated}
-->

`
	write(NEXT, header + body)
	return h
}

function verifyLane(id, lane, shared, blocks) {
	if (!lane.prompt_path) fail(`lane ${id} has no prompt_path`)
	if (lane.prompt_hash === "pending") return null
	const block = blocks.get(id)
	if (!block) fail(`lane ${id} has a hash but no master block`)
	const expected = hash(normalize(`${shared}\n\n${block}`))
	const file = read(path.join(ROOT, lane.prompt_path))
	const headerHash = (file.match(/^Hash: ([0-9a-f]{12})$/m) ?? [])[1]
	if (headerHash !== expected) fail(`lane ${id}: header hash ${headerHash} != master hash ${expected}`)
	const fields = { Lane: id, Branch: lane.branch, Worktree: lane.worktree, Version: lane.prompt_version, Model: lane.model }
	for (const [key, value] of Object.entries(fields)) {
		const actual = (file.match(new RegExp(`^${key}: (.*)$`, "m")) ?? [])[1]
		if (actual !== String(value)) fail(`lane ${id}: header ${key} ${actual} != manifest ${value}`)
	}
	if (lane.prompt_hash !== expected) fail(`lane ${id}: manifest hash ${lane.prompt_hash} != master hash ${expected}`)
	const body = file.slice(file.indexOf("-->\n\n") + 5)
	if (hash(body) !== expected) fail(`lane ${id}: body hash != master hash ${expected}`)
	return expected
}

function verifySupport(manifest) {
	for (const [id, entry] of manifest.support) {
		if (!entry.path || entry.hash === "pending") continue
		const actual = hash(read(path.join(ROOT, entry.path)))
		if (actual !== entry.hash) fail(`support ${id}: manifest hash ${entry.hash} != file hash ${actual}`)
	}
}

function verifyNext(manifest) {
	if (manifest.next.hash === "pending") return
	const actual = hash(read(ORCHESTRATOR))
	if (actual !== manifest.next.hash) fail(`next: manifest hash ${manifest.next.hash} != orchestrator hash ${actual}`)
	const file = read(NEXT)
	const headerHash = (file.match(/^Hash: ([0-9a-f]{12})$/m) ?? [])[1]
	if (headerHash !== actual) fail(`NEXT.md header hash ${headerHash} != orchestrator hash ${actual}`)
	const body = file.slice(file.indexOf("-->\n\n") + 5)
	if (hash(body) !== actual) fail(`NEXT.md body hash != orchestrator hash ${actual}`)
}

function main() {
	if (!fs.existsSync(MASTER)) fail(`master not found: ${MASTER}`)
	if (!fs.existsSync(MANIFEST)) fail(`manifest not found: ${MANIFEST}`)
	const master = read(MASTER)
	const shared = (master.match(/<!-- SHARED -->\n([\s\S]*?)\n<!-- \/SHARED -->/) ?? [])[1]
	if (!shared) fail("shared block not found in the master")
	const blocks = parseBlocks(master, "LANE")
	let manifestText = read(MANIFEST)
	let manifest = parseManifest(manifestText)

	if (check) {
		verifySupport(manifest)
		verifyNext(manifest)
		for (const [id, lane] of manifest.lanes) verifyLane(id, lane, shared, blocks)
		console.log("\u2714 orchestration prompts verified: headers and manifest hashes match")
		return
	}

	// Support prompt hashes.
	for (const [id, entry] of manifest.support) {
		if (!entry.path) fail(`support ${id} has no path`)
		const h = hash(read(path.join(ROOT, entry.path)))
		manifestText = setBlockField(manifestText, `  - id: ${id}\n`, "\n  - id: ", "hash", h)
	}
	manifest = parseManifest(manifestText)

	// Next hash + NEXT.md.
	const nextHash = renderNext(manifest)
	manifestText = setBlockField(manifestText, "\nnext:\n", "\nsupport_prompts:", "hash", nextHash)
	manifest = parseManifest(manifestText)

	// Lane prompts.
	const targets = nextOnly ? [] : laneArg ? [laneArg] : all ? [...blocks.keys()] : DEFAULT_LANES
	for (const id of targets) {
		const lane = manifest.lanes.get(id)
		if (!lane) fail(`lane ${id} is not in the manifest`)
		const block = blocks.get(id)
		if (!block) fail(`lane ${id} has no master block`)
		const h = renderLane(id, lane, shared, block, manifest.generated)
		manifestText = setBlockField(manifestText, `  - id: ${id}\n`, "\n  - id: ", "prompt_hash", h)
	}
	write(MANIFEST, manifestText)
	console.log(`\u2714 rendered: ${targets.join(", ")} + NEXT.md; manifest hashes updated`)
}

main()
