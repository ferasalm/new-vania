#!/usr/bin/env node
/**
 * Local mirror of the GitHub Actions CI workflows.
 *
 * Maps:
 *   .github/workflows/test.yml            -> --job test
 *   .github/workflows/agent-validation.yml -> --job agents
 *
 * Default (`--job all`) runs both workflows, skipping the duplicate plugin
 * suite because `npm test` already covers it.
 *
 * Usage:
 *   node tools/ci/run-local.mjs
 *   node tools/ci/run-local.mjs --job test
 *   node tools/ci/run-local.mjs --job agents --skip-install
 *   node tools/ci/run-local.mjs --list
 */

import { spawnSync } from 'node:child_process';
import { existsSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const IS_WINDOWS = process.platform === 'win32';
const NPM = IS_WINDOWS ? 'npm.cmd' : 'npm';
const NODE = process.execPath;

const JOBS = {
  test: {
    workflow: '.github/workflows/test.yml',
    description: 'Run the same suite as the test workflow.',
    steps: [
      {
        id: 'npm-test',
        label: 'npm test (plugin + git-hook suites)',
        command: NPM,
        args: ['test'],
      },
    ],
  },
  agents: {
    workflow: '.github/workflows/agent-validation.yml',
    description: 'Run the same jobs as the agent-validation workflow.',
    steps: [
      {
        id: 'agent-validation',
        label: 'Agent framework validation',
        command: NODE,
        args: ['tests/agents/validate.mjs'],
      },
      {
        id: 'workflow-integrity',
        label: 'Workflow integrity',
        command: NODE,
        args: ['tests/workflow/run-all.mjs'],
      },
      {
        id: 'module-structure',
        label: 'Module structure',
        command: NODE,
        args: ['tests/modules/validate-modules.mjs'],
      },
      {
        id: 'module-harness',
        label: 'Module installer harness',
        command: NPM,
        args: ['run', 'test:modules'],
      },
      {
        id: 'plugin-tests',
        label: 'Plugin tests',
        command: NPM,
        args: ['run', 'test:plugins'],
      },
    ],
  },
};

// `npm test` already runs the plugin suite, so `all` avoids running it twice.
const ALL_STEPS = [
  ...JOBS.test.steps,
  ...JOBS.agents.steps.filter((step) => step.id !== 'plugin-tests'),
];

const useColor = process.stdout.isTTY && !process.env.NO_COLOR;
const color = {
  bold: (value) => (useColor ? `\x1b[1m${value}\x1b[0m` : value),
  dim: (value) => (useColor ? `\x1b[2m${value}\x1b[0m` : value),
  green: (value) => (useColor ? `\x1b[32m${value}\x1b[0m` : value),
  red: (value) => (useColor ? `\x1b[31m${value}\x1b[0m` : value),
  yellow: (value) => (useColor ? `\x1b[33m${value}\x1b[0m` : value),
};

/**
 * Prints the command-line help text.
 */
function printHelp() {
  console.log(`Local CI runner — mirrors the GitHub Actions workflows.

Usage:
  node tools/ci/run-local.mjs [options]

Options:
  -j, --job <name>   Job to run: test, agents, all (default: all).
                     Repeat the flag to run more than one job.
      --skip-install Skip dependency installation.
      --install      Force dependency installation even if node_modules exists.
      --keep-going   Continue after a failing step.
  -l, --list         List jobs and steps without running them.
  -h, --help         Show this help.

Examples:
  npm run ci
  npm run ci -- --job test
  npm run ci -- --job agents --skip-install
`);
}

/**
 * Parses the CLI arguments into an options object.
 * @param {string[]} argv Arguments after `node` and the script path.
 * @returns {{jobs: string[], skipInstall: boolean, forceInstall: boolean, keepGoing: boolean, list: boolean, help: boolean}}
 */
function parseArgs(argv) {
  const options = {
    jobs: [],
    skipInstall: false,
    forceInstall: false,
    keepGoing: false,
    list: false,
    help: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '-j' || arg === '--job') {
      const value = argv[index + 1];
      if (!value || value.startsWith('-')) {
        throw new Error(`${arg} requires a job name`);
      }
      options.jobs.push(value);
      index += 1;
    } else if (arg === '--skip-install') {
      options.skipInstall = true;
    } else if (arg === '--install') {
      options.forceInstall = true;
    } else if (arg === '--keep-going') {
      options.keepGoing = true;
    } else if (arg === '-l' || arg === '--list') {
      options.list = true;
    } else if (arg === '-h' || arg === '--help') {
      options.help = true;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return options;
}

/**
 * Resolves job names into a deduplicated list of steps.
 * @param {string[]} jobNames Job names from the CLI.
 * @returns {{label: string, steps: Array<{id: string, label: string, command: string, args: string[]}>}}
 */
function resolveSteps(jobNames) {
  if (jobNames.length === 0 || jobNames.includes('all')) {
    return { label: 'all workflows', steps: ALL_STEPS };
  }

  const steps = [];
  const seen = new Set();
  for (const name of jobNames) {
    const job = JOBS[name];
    if (!job) {
      throw new Error(`Unknown job "${name}". Valid jobs: ${Object.keys(JOBS).join(', ')}, all`);
    }
    for (const step of job.steps) {
      if (!seen.has(step.id)) {
        seen.add(step.id);
        steps.push(step);
      }
    }
  }

  return { label: jobNames.join(', '), steps };
}

/**
 * Prints the available jobs and their steps.
 */
function listJobs() {
  console.log('Local CI jobs:\n');
  for (const [name, job] of Object.entries(JOBS)) {
    console.log(`  ${color.bold(name)} — ${job.description}`);
    console.log(`  ${color.dim(`mirrors ${job.workflow}`)}`);
    for (const step of job.steps) {
      console.log(`    - ${step.label}`);
    }
    console.log('');
  }
  console.log(`  ${color.bold('all')} — both workflows (plugin suite runs once via npm test)`);
}

/**
 * Returns true when package.json or package-lock.json is newer than the
 * installed dependency tree.
 * @returns {boolean}
 */
function lockfileIsNewerThanInstall() {
  const installed = join(ROOT, 'node_modules', '.package-lock.json');
  if (!existsSync(installed)) return true;

  const sources = ['package.json', 'package-lock.json']
    .map((name) => join(ROOT, name))
    .filter((path) => existsSync(path));

  if (sources.length === 0) return false;

  const newestSource = Math.max(...sources.map((path) => statSync(path).mtimeMs));
  return newestSource > statSync(installed).mtimeMs;
}

/**
 * Decides whether dependencies must be installed before running the steps.
 * @param {{skipInstall: boolean, forceInstall: boolean}} options CLI options.
 * @returns {boolean}
 */
function shouldInstall(options) {
  if (options.skipInstall) return false;
  if (options.forceInstall) return true;
  if (!existsSync(join(ROOT, 'node_modules'))) return true;
  return lockfileIsNewerThanInstall();
}

/**
 * Runs one step and reports its result.
 * @param {{id: string, label: string, command: string, args: string[]}} step Step to run.
 * @returns {{step: object, ok: boolean, seconds: string}}
 */
function runStep(step) {
  const started = Date.now();
  console.log(`\n${color.bold('▶')} ${step.label}`);
  console.log(color.dim(`  $ ${[step.command, ...step.args].join(' ')}`));

  const result = spawnSync(step.command, step.args, {
    cwd: ROOT,
    stdio: 'inherit',
    env: process.env,
    shell: IS_WINDOWS && step.command === NPM,
  });

  const seconds = ((Date.now() - started) / 1000).toFixed(1);

  if (result.error) {
    console.log(`${color.red('✖')} ${step.label} — ${result.error.message} (${seconds}s)`);
    return { step, ok: false, seconds };
  }

  if (result.status !== 0) {
    console.log(`${color.red('✖')} ${step.label} — exit ${result.status} (${seconds}s)`);
    return { step, ok: false, seconds };
  }

  console.log(`${color.green('✔')} ${step.label} (${seconds}s)`);
  return { step, ok: true, seconds };
}

/**
 * Entry point: parses options, runs the selected steps, and exits non-zero on
 * failure.
 */
function main() {
  let options;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(`${color.red('Error:')} ${error.message}`);
    console.error('Run with --help for usage.');
    process.exit(2);
  }

  if (options.help) {
    printHelp();
    return;
  }

  if (options.list) {
    listJobs();
    return;
  }

  let selection;
  try {
    selection = resolveSteps(options.jobs);
  } catch (error) {
    console.error(`${color.red('Error:')} ${error.message}`);
    process.exit(2);
  }

  const nodeMajor = Number(process.versions.node.split('.')[0]);
  if (nodeMajor < 20) {
    console.error(`${color.red('Error:')} Node 20 or newer is required (found ${process.versions.node}).`);
    process.exit(2);
  }
  if (nodeMajor !== 20) {
    console.log(color.yellow(`Note: CI runs Node 20; local Node is ${process.versions.node}.`));
  }

  console.log(color.bold('\nLocal CI runner'));
  console.log(color.dim(`Repository: ${ROOT}`));
  console.log(color.dim(`Jobs: ${selection.label}`));
  console.log(color.dim(`Steps: ${selection.steps.length}${shouldInstall(options) ? ' + dependency install' : ''}`));

  const results = [];

  if (shouldInstall(options)) {
    const installStep = {
      id: 'install',
      label: 'Install dependencies',
      command: NPM,
      args: existsSync(join(ROOT, 'package-lock.json'))
        ? ['ci', '--no-audit', '--no-fund']
        : ['install', '--no-audit', '--no-fund'],
    };
    const result = runStep(installStep);
    results.push(result);
    if (!result.ok && !options.keepGoing) {
      printSummary(results);
      process.exit(1);
    }
  }

  for (const step of selection.steps) {
    const result = runStep(step);
    results.push(result);
    if (!result.ok && !options.keepGoing) {
      break;
    }
  }

  printSummary(results);
  process.exit(results.every((result) => result.ok) ? 0 : 1);
}

/**
 * Prints the pass/fail table for the completed steps.
 * @param {Array<{step: object, ok: boolean, seconds: string}>} results Step results.
 */
function printSummary(results) {
  const passed = results.filter((result) => result.ok).length;
  const failed = results.length - passed;

  console.log(`\n${color.bold('Local CI summary')}`);
  console.log('─'.repeat(60));
  for (const result of results) {
    const status = result.ok ? color.green('PASS') : color.red('FAIL');
    console.log(`  ${status}  ${result.step.label} (${result.seconds}s)`);
  }
  console.log('─'.repeat(60));

  if (failed === 0) {
    console.log(color.green(`Result: ${passed}/${results.length} steps passed.`));
  } else {
    console.log(color.red(`Result: ${failed} step(s) failed, ${passed} passed.`));
  }
}

main();
