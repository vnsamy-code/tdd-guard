import { spawnSync } from 'node:child_process'
import { join } from 'node:path'
import { existsSync, cpSync } from 'node:fs'
import type { ReporterConfig, TestScenarios } from '../types'
import { copyTestArtifacts } from './helpers'

export function createSwiftReporter(): ReporterConfig {
  // Use hardcoded absolute path for security when available, fall back to PATH for CI environments
  const swiftBinary = existsSync('/usr/bin/swift') ? '/usr/bin/swift' : 'swift'
  const artifactDir = 'swift'
  const testScenarios = {
    singlePassing: 'passing',
    singleFailing: 'failing',
    singleImportError: 'import',
  }

  return {
    name: 'SwiftReporter',
    testScenarios,
    run: (tempDir, scenario: keyof TestScenarios) => {
      // Copy the Swift reporter package to temp directory
      const swiftReporterPath = join(__dirname, '../../swift')
      const swiftDestPath = join(tempDir, 'swift')
      cpSync(swiftReporterPath, swiftDestPath, { recursive: true })

      // Copy the test artifacts to temp
      copyTestArtifacts(artifactDir, testScenarios, scenario, tempDir)

      // Run swift test
      return spawnSync(swiftBinary, ['test'], {
        cwd: tempDir,
        env: { ...process.env, PWD: tempDir, CLAUDE_PROJECT_DIR: tempDir },
        stdio: 'pipe',
        encoding: 'utf8',
      })
    },
  }
}
