# Module: Code Quality & Testing - Demo 1: Code Coverage & Error Handling

## Overview
This module demonstrates implementing code coverage analysis in a Jenkins pipeline with proper error handling. The setup ensures that even when code coverage thresholds are not met, the pipeline continues to execute subsequent stages instead of failing completely.

## Demo Objectives
- Add a code coverage stage to an existing Jenkins pipeline
- Handle code coverage threshold failures gracefully
- Publish HTML coverage reports
- Ensure pipeline continues execution despite coverage failures

## Key Components

### 1. Code Coverage Stage
The stage executes `npm run coverage` to analyze test coverage and generates a detailed report showing:
- Statement coverage percentage
- Branch coverage percentage
- Function coverage percentage
- Line coverage percentage
- Uncovered line numbers

### 2. Error Handling with `catchError`
To prevent pipeline failure when coverage thresholds aren't met:
```groovy
catchError(
    buildResult: 'SUCCESS',
    message: 'Oops!... We will fix coverage in upcoming release.',
    stageResult: 'UNSTABLE'
) {
    // Code coverage execution logic
}
```

**Parameters:**
- `buildResult`: Sets overall build result to SUCCESS
- `message`: Custom message displayed in console output
- `stageResult`: Marks the specific stage as UNSTABLE

### 3. MongoDB Integration
The coverage tests require a MongoDB instance, which is managed via Docker Compose:
- MongoDB credentials are securely loaded using Jenkins credentials
- Container is started before tests and cleaned up afterward
- Environment variables are properly configured for the application

### 4. HTML Report Publishing
Coverage reports are published as HTML for easy visualization:
```groovy
publishHTML([
    allowMissing: true,
    alwaysLinkToLastBuild: true,
    keepAll: true,
    reportDir: 'coverage/lcov-report',
    reportFiles: 'index.html',
    reportName: 'Code-Coverage-HTML-Report'
])
```

## Implementation Details

### Pipeline Stage Structure
```groovy
stage("Code coverage") {
    steps {
        // 1. Load MongoDB credentials securely
        // 2. Execute coverage tests with error handling
        // 3. Publish HTML reports
    }
}
```

### Coverage Threshold Error
Initial execution showed:
```
ERROR: Coverage for lines (59.45%) does not meet global threshold (90%)
```
This would normally fail the pipeline, but with `catchError`, it's handled gracefully.

### Build Outcome
- **Classic UI**: Shows custom error message and UNSTABLE status
- **Blue Ocean UI**: Shows UNSTABLE status (no custom message)
- **Both UIs**: Include link to Code-Coverage-HTML-Report

## Example Output
```
File      | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s
----------|---------|----------|---------|---------|------------------
All files |   58.66 |    42.85 |      50 |   59.45 |
app.js    |   58.66 |    42.85 |      50 |   59.45 | ...141,145,150-151...
```

## Reference Build
For complete implementation and output, refer to:
**Build #72** - Organization-folder-demo/solar-system-migrate/72

## Best Practices Demonstrated
1. **Graceful Error Handling**: Pipeline continues despite coverage failures
2. **Secure Credential Management**: MongoDB credentials are handled securely
3. **Resource Cleanup**: Docker containers are properly cleaned up
4. **Artifact Preservation**: HTML reports are archived for future reference
5. **Informative Messaging**: Clear communication about coverage issues

## Next Steps
- Improve test coverage to meet the 90% threshold
- Add quality gates for other metrics (complexity, duplication)
- Implement trend analysis for coverage over time
- Add notifications for coverage regressions