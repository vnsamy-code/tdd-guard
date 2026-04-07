import { spawnSync, execFileSync } from 'node:child_process'
import { join } from 'node:path'
import { existsSync } from 'node:fs'
import type { ReporterConfig, TestScenarios } from '../types'
import { copyTestArtifacts } from './helpers'

const swiftBinary = existsSync('/usr/bin/swift') ? '/usr/bin/swift' : 'swift'
const reporterDir = join(__dirname, '../../swift')
const binaryPath = join(reporterDir, '.build/release/tdd-guard-swift')
const testScenarios = {
  singlePassing: 'passing',
  singleFailing: 'failing',
  singleImportError: 'compilation-error',
}

function buildReporter(): void {
  const result = spawnSync(swiftBinary, ['build', '-c', 'release'], {
    cwd: reporterDir,
    stdio: 'pipe',
  })
  if (result.status !== 0) {
    throw new Error(
      `Failed to build tdd-guard-swift: ${result.stderr?.toString()}`
    )
  }
}

function runSwiftTest(args: string[], tempDir: string): string {
  const result = spawnSync(swiftBinary, ['test', ...args], {
    cwd: tempDir,
    stdio: 'pipe',
    encoding: 'utf8',
  })
  return (result.stdout ?? '') + (result.stderr ?? '')
}

function runReporter(output: string, tempDir: string): void {
  try {
    execFileSync(binaryPath, ['--project-root', tempDir], {
      cwd: tempDir,
      input: output,
      stdio: 'pipe',
      encoding: 'utf8',
    })
  } catch {
    // Reporter exits non-zero when tests fail — that is expected behaviour
  }
}

export function createSwiftXCTestReporter(): ReporterConfig {
  buildReporter()

  return {
    name: 'SwiftXCTestReporter',
    testScenarios,
    run: (tempDir, scenario: keyof TestScenarios) => {
      copyTestArtifacts('swift/xctest', testScenarios, scenario, tempDir)
      const output = runSwiftTest([], tempDir)
      runReporter(output, tempDir)
    },
  }
}

export function createSwiftTestingReporter(): ReporterConfig {
  buildReporter()

  return {
    name: 'SwiftTestingReporter',
    testScenarios,
    run: (tempDir, scenario: keyof TestScenarios) => {
      copyTestArtifacts('swift/swift-testing', testScenarios, scenario, tempDir)
      const output = runSwiftTest(['--event-stream-output-path', '-'], tempDir)
      runReporter(output, tempDir)
    },
  }
}
