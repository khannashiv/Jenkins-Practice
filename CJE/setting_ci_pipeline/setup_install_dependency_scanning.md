# Jenkins Pipeline: Node.js Dependency Security Scanning

## Overview
This Jenkins pipeline implements a comprehensive security scanning process for Node.js applications, combining multiple vulnerability detection methods to ensure code security. The pipeline installs dependencies without audit and performs parallel dependency scanning using npm audit and OWASP Dependency-Check.

## Pipeline Stages

### 1. Dependency Installation
Installs Node.js dependencies with audit disabled to speed up the build process.

```groovy
stage("Installing nodejs dependencies") {
    steps {
        script {
            sh 'npm install --no-audit'
        }
    }
}
```

### 2. Parallel Dependency Scanning
Runs npm audit and OWASP Dependency-Check in parallel to optimize build time.

```groovy
stage('DP Scanning') {
    parallel {
        stage('NPM Audit') {
            steps {
                script {
                    sh 'npm audit --audit-level=critical'
                    sh 'echo $?'  // Check exit code
                }
            }
        }
        stage('OWASP DP Check') {
            steps {
                dependencyCheck additionalArguments: '''--project "NodeJS_Vulnerability_Scan"
                    --scan '.'
                    --format ALL
                    --out .
                    --prettyPrint
                    --exclude node_modules''',
                    odcInstallation: 'DPC-1003'
                
                // Post-scan vulnerability threshold checking
                dependencyCheckPublisher(
                    failedTotalCritical: 1,
                    pattern: 'dependency-check-report.xml',
                    skipNoReportFiles: true,
                    stopBuild: true
                )
            }
        }
    }
}
```

## Tools Configuration

### OWASP Dependency-Check Setup
1. Install the OWASP Dependency-Check plugin from Jenkins Plugin Manager
2. Configure the tool under **Manage Jenkins** → **Tools**
3. Add Dependency Check with name and version (v10.0.3 recommended)
4. Tool will download vulnerability database (~20-25 minutes on first run)

### NPM Audit
- Built into npm (no additional installation required)
- Sends dependency list to npm registry for vulnerability checking
- Can be configured with different audit levels (critical, high, moderate, low)

## Scan Reports

### Generated Output
OWASP Dependency-Check generates multiple report formats:
- HTML (`dependency-check-report.html`)
- JSON (`dependency-check-report.json`)
- CSV (`dependency-check-report.csv`)
- XML (`dependency-check-report.xml`)

Reports are available in the Jenkins workspace and repository root directory.

## Vulnerability Threshold Configuration

### Understanding Thresholds
The `dependencyCheckPublisher` configuration controls build failure based on vulnerability counts:

| Configured Threshold | Build Behavior | Meaning |
|---------------------|----------------|---------|
| `failedTotalCritical: 0` | Fails if ≥ 0 critical | Fail if any critical exists |
| `failedTotalCritical: 1` | Fails if ≥ 1 critical | Fail if 1+ critical found |
| `failedTotalCritical: 5` | Fails if ≥ 5 critical | Allow up to 4 critical |

### Configuration Parameters
```groovy
dependencyCheckPublisher(
    failedTotalCritical: 1,           // Fail if ≥ 1 critical vulnerability
    pattern: 'dependency-check-report.xml',  // Report file location
    skipNoReportFiles: true,          // Continue if report missing
    stopBuild: true                   // Stop pipeline immediately on failure
)
```

## Performance Notes

### Execution Times
- **First OWASP scan**: ~30 minutes (includes database download)
- **Subsequent OWASP scans**: Faster (uses cached database)
- **NPM Audit**: ~10 minutes
- **Parallel execution**: Total scan time ≈ max(OWASP, NPM) = ~30 minutes

### Optimization Tips
1. Run scans in parallel to save time
2. Cache OWASP database between builds
3. Use `--no-audit` during installation to speed up npm install
4. Consider scheduled scans for non-critical branches

## References

### Official Documentation
- [OWASP Dependency-Check CLI Arguments](https://dependency-check.github.io/DependencyCheck/dependency-check-cli/arguments.html)
- [Jenkins Dependency-Check Plugin](https://www.jenkins.io/doc/pipeline/steps/dependency-check-jenkins-plugin/)
- [Plugin Releases](https://plugins.jenkins.io/dependency-check-jenkins-plugin/releases/)

### Additional Resources
- [Medium: Integrate OWASP Dependency Check in Jenkins Pipeline](https://sudheer-baraker.medium.com/integrate-owasp-dependency-check-in-jenkins-pipeline-748d8aefc2b7)

## Best Practices

1. **Threshold Setting**: Start with `failedTotalCritical: 0` for new projects, then adjust based on risk tolerance
2. **Report Retention**: Archive vulnerability reports for compliance and trend analysis
3. **Failure Handling**: Use `stopBuild: true` in CI/CD pipelines to prevent vulnerable code from progressing
4. **Regular Updates**: Keep OWASP database updated for latest vulnerability detection
5. **Multiple Formats**: Generate ALL report formats for different stakeholder needs

## Troubleshooting

### Common Issues
1. **Long first scan time**: Expected behavior - OWASP downloads vulnerability database
2. **Missing reports**: Ensure `skipNoReportFiles: true` if reports might be missing
3. **Build not failing**: Check threshold settings and ensure `stopBuild: true`
4. **Memory issues**: OWASP scans can be memory-intensive for large projects

### Exit Code Handling
- NPM Audit exit code captured with `echo $?`
- OWASP failures controlled by `dependencyCheckPublisher` configuration
- Zero exit code indicates successful scan (regardless of findings unless configured otherwise)