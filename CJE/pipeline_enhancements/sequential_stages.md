# Jenkins Pipeline: Sequential Stages Demo

## Overview
This document demonstrates the implementation of sequential stages within a Jenkins Declarative Pipeline stage. The example shows how to structure a pipeline to perform sequential operations (dependency installation and unit testing) within a single containerized stage.

## Key Concept
In Jenkins Declarative Pipeline version 1.3.x and later, you can use **nested stages** within a parent stage to create sequential execution flow. This allows for better organization and visualization of related steps within a single context (like a specific agent or container).

## Example Implementation

### Working Configuration
```groovy
stage ('NodeJS 20') {
    agent {
        docker {
            image 'node:20-alpine'
        }
    }
    
    // Sequential stages within the NodeJS 20 container
    stages {
        stage("Install-dependency-Sequential") {
            steps {
                sh 'npm install --no-audit'
                sh 'node -v'                            
            }
        }
        stage("Unit-Testing-Sequential") {
            steps {
                runWithMongoDB("npm test")
                sh 'node -v'                            
            }
        }
    }
}
```

## Important Constraint
**Only one of `matrix`, `parallel`, `stages`, or `steps` is allowed within a single stage.** You cannot combine these directives.

### ❌ Invalid Configuration (Will Fail)
```groovy
stage ('NodeJS 20') {
    agent { /* ... */ }
    
    steps {
        // Regular steps block
    }
    
    stages {
        // Sequential stages block - NOT ALLOWED!
    }
}
```

### ✅ Valid Alternatives

**Option 1: Using nested stages (as shown above)**
```groovy
stage ('NodeJS 20') {
    agent { /* ... */ }
    stages {
        // Sequential sub-stages
    }
}
```

**Option 2: Using regular steps**
```groovy
stage ('NodeJS 20') {
    agent { /* ... */ }
    steps {
        // All steps executed sequentially
        sh 'npm install --no-audit'
        sh 'node -v'
        runWithMongoDB("npm test")
    }
}
```

## Debugging Information
The example includes commented-out debugging steps that were used to troubleshoot issues:
- Checking current working directory
- Verifying existence of `node_modules`
- Examining folder creation timestamps

## References
1. [Jenkins Blog: What's new in Declarative Pipeline 1.3.x - Sequential Stages](https://www.jenkins.io/blog/2018/07/02/whats-new-declarative-piepline-13x-sequential-stages)
2. [Stack Overflow: Sequential stages within parallel pipeline in Jenkins](https://stackoverflow.com/questions/59688963/sequential-stages-within-parallel-pipeline-in-jenkins)

## Usage Notes
- Sequential stages provide better visualization in Blue Ocean and other pipeline visualization tools
- Each nested stage can have its own post-conditions (post actions)
- The entire parent stage (`NodeJS 20`) shares the same agent/container environment
- Use `runWithMongoDB()` for tests requiring MongoDB (custom function implementation not shown)

## Error Resolution
If you encounter the error:
```
WorkflowScript: 185: Only one of "matrix", "parallel", "stages", or "steps" allowed for stage "NodeJS 20"
```
Remove either the `steps {}` block or the `stages {}` block from the stage, keeping only one.