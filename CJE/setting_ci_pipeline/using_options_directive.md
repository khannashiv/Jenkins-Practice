```markdown
# Jenkins Pipeline Options Directive Demo

## Overview
This repository demonstrates the usage of the `options` directive in Jenkins Declarative Pipeline. The `options` directive allows you to configure pipeline-specific options like retry behavior, timestamps, concurrent build control, and more.

## Official Documentation
- [Jenkins Pipeline Syntax: Options](https://www.jenkins.io/doc/book/pipeline/syntax/#options)

## How to Define Options Directive

### Method 1: Directive Generator
1. Navigate to **Pipeline Syntax** in your Jenkins instance
2. Select **Declarative Directive Generator**
3. Choose **options** from the dropdown
4. Configure your desired options and click **Generate Declarative Directive**

### Method 2: Direct Configuration
Options can be defined at two levels:
- **Global level**: Applied to the entire pipeline
- **Stage level**: Applied to specific stages (where supported)

## Demo Examples

### 1. Stage-Level Options: Retry
**Location**: `stage("Check NodeJS version locally")`  
**Configuration**:
```groovy
options {
    retry(3)
}
```
**Purpose**: Retries the stage up to 3 times if it fails  
**Verification**: See Build #67 (Organization-folder-demo/solar-system-migrate/67) where the build was intentionally failed to demonstrate retry behavior

### 2. Stage-Level Options: Timestamps
**Location**: `stage("Installing nodejs dependencies")`  
**Configuration**:
```groovy
options {
    timestamps()
}
```
**Purpose**: Adds timestamps to all console output  
**Verification**: See Build #70 (Organization-folder-demo/solar-system-migrate/70) for timestamped output:
```
npm install --no-audit— Shell Script<1s
[2025-11-15T11:19:22.611Z] + npm install --no-audit
[2025-11-15T11:19:23.162Z] 
[2025-11-15T11:19:23.163Z] up to date in 596ms
```

### 3. Global-Level Options: Concurrent Build Control
**Location**: Pipeline root level  
**Configuration**:
```groovy
options {
    disableConcurrentBuilds abortPrevious: true
    disableResume()
}
```
**Purpose**:
- `disableConcurrentBuilds abortPrevious: true`: Prevents concurrent builds and aborts previous running builds when a new one starts
- `disableResume()`: Prevents the pipeline from resuming if Jenkins restarts

**Testing Methodology**:
1. Added `sh 'sleep 120s'` to stage steps to create a delay
2. Triggered a new build while the previous one was running
3. Observed that the previous build (#68) was aborted when new builds (#69, #70) started

## Key Features Demonstrated

### Retry Mechanism
- Automatically retries failed stages
- Configurable retry count
- Useful for handling flaky tests or network issues

### Timestamps
- Adds ISO timestamps to all console output
- Helps with debugging and log analysis
- Provides precise timing information

### Concurrent Build Control
- Prevents resource contention by disabling concurrent builds
- `abortPrevious: true` ensures only the latest build runs
- Useful for deployment pipelines or resource-intensive jobs

### Pipeline Resilience
- `disableResume()` prevents unexpected behavior after Jenkins restarts
- Ensures clean state for each build execution

## Project Structure
```
solar-system-migrate/
├── Jenkinsfile         # Main pipeline definition
├── build_67/           # Example with retry option
├── build_68/           # Example build aborted by concurrent control
├── build_69/           # Subsequent build
└── build_70/           # Example with timestamps option
```

## Usage Notes
1. **Stage-specific options**: Some options (like `retry` and `timestamps`) can be applied at stage level
2. **Global options**: Options like `disableConcurrentBuilds` must be defined at pipeline level
3. **Combination**: You can combine multiple options in a single `options` block
4. **Order**: Options are processed in the order they're defined

## Testing the Examples
1. Trigger a build with intentional failure to test `retry(3)`
2. Check console output for timestamp formatting with `timestamps()`
3. Trigger multiple builds in quick succession to test `disableConcurrentBuilds`

## Related Resources
- [Jenkins Declarative Pipeline Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Pipeline Examples Repository](https://github.com/jenkinsci/pipeline-examples)
- [Jenkins Handbook](https://www.jenkins.io/doc/book/)

---
*Note: Build numbers and project paths mentioned are examples from the demonstration environment.*
```