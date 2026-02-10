# Trivy Vulnerability Scanner Jenkins Integration

## Overview

This document explains how to integrate Trivy vulnerability scanning into a Jenkins CI/CD pipeline to scan Docker images for security vulnerabilities and generate multiple report formats.

## Prerequisites

### 1. Install Trivy
Trivy must be installed on your Jenkins agent/Ubuntu system. Follow the official installation guide:
- [Trivy Installation Documentation](https://trivy.dev/docs/latest/getting-started/installation/)
- [Trivy GitHub Repository](https://github.com/aquasecurity/trivy)

### 2. Verify Installation
After installation, verify Trivy is working correctly:
```bash
trivy -v
```

## Jenkins Pipeline Integration

### Stage: Trivy Vulnerability Scanner
The following Jenkins pipeline stage performs vulnerability scanning with Trivy:

```groovy
stage('Trivy vulnerability Scanner') {
    steps {
        script {
            sh '''
                # Scan for LOW and MEDIUM severity vulnerabilities
                trivy image --severity LOW,MEDIUM \
                    --exit-code 0 \
                    --quiet \
                    --format json \
                    --output trivy-image-low-medium-results.json \
                    khannashiv/solar-system:$GIT_COMMIT

                # Scan for HIGH and CRITICAL severity vulnerabilities
                trivy image --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    --quiet \
                    --format json \
                    --output trivy-image-high-critical-results.json \
                    khannashiv/solar-system:$GIT_COMMIT
            '''
        }
    }

    post {
        always {
            echo "Converting Trivy JSON reports to HTML and JUnit XML..."
            
            sh '''
                # Convert HIGH/CRITICAL JSON to HTML
                trivy convert --format template \
                    --template "@/usr/local/share/trivy/templates/html.tpl" \
                    --output trivy-image-high-critical-results.html \
                    trivy-image-high-critical-results.json

                # Convert LOW/MEDIUM JSON to HTML
                trivy convert --format template \
                    --template "@/usr/local/share/trivy/templates/html.tpl" \
                    --output trivy-image-low-medium-results.html \
                    trivy-image-low-medium-results.json

                # Convert HIGH/CRITICAL JSON to JUnit XML
                trivy convert --format template \
                    --template "@/usr/local/share/trivy/templates/junit.tpl" \
                    --output trivy-image-high-critical-results.xml \
                    trivy-image-high-critical-results.json

                # Convert LOW/MEDIUM JSON to JUnit XML
                trivy convert --format template \
                    --template "@/usr/local/share/trivy/templates/junit.tpl" \
                    --output trivy-image-low-medium-results.xml \
                    trivy-image-low-medium-results.json
            '''
        }
    }
}
```

### Trivy Command Options

| Option | Description |
|--------|-------------|
| `--severity` | Specifies vulnerability severity levels to scan (LOW, MEDIUM, HIGH, CRITICAL) |
| `--exit-code` | Exit code to return based on scan results (0 for success, 1 for vulnerabilities found) |
| `--quiet` | Suppress progress output |
| `--format json` | Output results in JSON format |
| `--output` | Save output to specified file |

## Report Generation

### Supported Formats
Trivy supports multiple output formats:
- **Table** (default)
- **JSON**
- **SARIF**
- **Template**
- **SBOM**
- **GitHub dependency snapshot**

### Template-Based Conversion
Trivy provides built-in templates for report conversion:
- HTML templates: `/usr/local/share/trivy/templates/html.tpl`
- JUnit templates: `/usr/local/share/trivy/templates/junit.tpl`

### Generated Artifacts
After scanning and conversion, the following files are generated:
- `trivy-image-high-critical-results.json` - Raw JSON results for HIGH/CRITICAL vulnerabilities
- `trivy-image-low-medium-results.json` - Raw JSON results for LOW/MEDIUM vulnerabilities
- `trivy-image-high-critical-results.html` - HTML report for HIGH/CRITICAL vulnerabilities
- `trivy-image-low-medium-results.html` - HTML report for LOW/MEDIUM vulnerabilities
- `trivy-image-high-critical-results.xml` - JUnit XML report for HIGH/CRITICAL vulnerabilities
- `trivy-image-low-medium-results.xml` - JUnit XML report for LOW/MEDIUM vulnerabilities

## Jenkins Post-Processing

### Viewing Results
1. **Blue Ocean Interface**: 
   - View HTML reports under "Artifacts"
   - View test results under "Tests" tab

2. **Classic Jenkins UI**:
   - Check workspace for generated files
   - Verify file sizes are not zero/very small
   - Use "HTML Publisher" plugin to view HTML reports
   - Use "JUnit" plugin to view test results

### Improving HTML Report Visibility
To enable CSS styling for better HTML report readability:
1. Navigate to **Manage Jenkins** → **Nodes**
2. Go to **Script Console**
3. Run the following script:
   ```groovy
   System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "")
   ```
4. Re-trigger the Jenkins build

## Exit Code Strategy

- **Exit code 0**: Used for LOW/MEDIUM severity scans (allows pipeline to continue)
- **Exit code 1**: Used for HIGH/CRITICAL severity scans (fails pipeline if vulnerabilities found)

**Note**: Adjust severity levels based on your security requirements. In the example, HIGH severity was moved to LOW/MEDIUM scan to allow pipeline to pass.

## Additional Capabilities

Trivy can also be used for:
- Scanning Kubernetes manifest files
- License compliance checking
- CIS benchmarking
- Infrastructure as Code scanning

## Docker Image Push Stage

To push scanned images to Docker registry:

```groovy
stage('Push Docker Image') {
    steps {
        withDockerRegistry(credentialsId: 'Docker-hub-login-creds', url: 'https://hub.docker.com/') {
            // Docker push commands
        }
    }
}
```

**Required Plugin**: Docker Pipeline plugin

## References

- [Trivy Official Documentation](https://trivy.dev/docs/latest/guide/)
- [Trivy Configuration Guide](https://trivy.dev/docs/latest/guide/configuration/reporting/)
- [Trivy CLI Reference](https://trivy.dev/docs/latest/references/configuration/cli/trivy/)
- [Jenkins HTML Content Security Policy](https://stackoverflow.com/questions/76219682/generate-a-html-report-from-trivy)

## Troubleshooting

1. **Empty reports**: Ensure the image exists and is accessible
2. **Template errors**: Verify Trivy templates exist at `/usr/local/share/trivy/templates/`
3. **Permission issues**: Jenkins agent must have execute permissions for Trivy
4. **Network issues**: Ensure Jenkins agent can access Docker registry and external resources