# Jenkins Pipeline: Vulnerability Fixing & Report Publishing

## Overview
This document describes the process for identifying, fixing, and reporting security vulnerabilities in a Node.js project using Jenkins pipeline.

## Workflow Steps

### 1. **Vulnerability Identification**
```bash
# Run npm audit to identify vulnerabilities
npm audit
```

### 2. **Vulnerability Fixing**
```bash
# Fix specific critical vulnerabilities
npm install mongoose@8.19.3
npm install underscore.string@latest

# Run audit for critical vulnerabilities only
npm audit --audit-level=critical

# Fix all vulnerabilities automatically
npm audit fix

# Force fix vulnerabilities (use with caution)
npm audit fix --force
```

### 3. **Report Generation**
After fixing vulnerabilities, the pipeline generates multiple reports:
- HTML reports (Dependency Check)
- JUnit reports (XML format)
- JSON reports

### 4. **Report Publishing in Jenkins**

#### **Publish HTML Reports**
```groovy
publishHTML([
    allowMissing: true, 
    alwaysLinkToLastBuild: true, 
    icon: '', 
    keepAll: true, 
    reportDir: 'dp-scanning-report/', 
    reportFiles: 'dependency-check-jenkins.html', 
    reportName: 'Dependency-Check-HTML-Report', 
    reportTitles: '', 
    useWrapperFileDirectly: true
])
```

#### **Publish JUnit Test Results**
```groovy
junit(
    allowEmptyResults: true, 
    keepProperties: true, 
    testResults: 'dp-scanning-report/dependency-check-junit.xml'
)
```

### 5. **Enabling CSS in HTML Reports**
By default, Jenkins blocks CSS for security. To enable proper formatting:

1. Navigate to **Manage Jenkins → Script Console**
2. Run the following command:
```java
System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "")
```
3. Restart Jenkins or rerun the build to see formatted reports

**Note:** This relaxation of Content Security Policy should be done cautiously in production environments.

## Pipeline Configuration

### OWASP Dependency Check Stage
The pipeline includes a dedicated stage for OWASP Dependency Check with:
- Critical vulnerability threshold set to 1 (fails if critical vulnerabilities found)
- Automatic HTML and JUnit report generation
- Artifact archiving for developer access

### Artifacts Access
Developers can access reports through:
- **Blue Ocean Interface**: Navigate to build artifacts
- **Classic UI**: Find reports under "Artifacts" section
- **Test Results**: Available in both Blue Ocean and Classic UI under "Test Result" section

## Success Criteria
- ✅ No critical vulnerabilities (threshold: 1)
- ✅ All audit checks passing
- ✅ HTML reports published with CSS formatting
- ✅ JUnit test results available
- ✅ Reports accessible via Jenkins interface

## Important Notes
1. **Security Consideration**: The CSP relaxation (`System.setProperty`) should be implemented judiciously
2. **Report Retention**: HTML reports are kept for all builds (`keepAll: true`)
3. **Build References**: Reports always link to the last build for easy comparison
4. **Threshold Configuration**: Pipeline fails if critical vulnerabilities exceed the set threshold

## Troubleshooting
- **Missing CSS in reports**: Ensure CSP property is set correctly
- **Missing reports**: Check workspace permissions and report directory paths
- **Audit failures**: Review `npm audit` output for specific vulnerability details

## References
- [Jenkins Content Security Policy Documentation](https://www.jenkins.io/doc/book/security/configuring-content-security-policy/)
- OWASP Dependency Check Plugin
- Jenkins Pipeline Syntax Generator