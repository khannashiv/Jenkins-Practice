# Jenkins Pipeline Refactoring Demo

This project demonstrates the refactoring process of a Jenkins pipeline from an initial state to a more optimized and maintainable version. The pipeline is designed for a Node.js application with MongoDB integration, dependency scanning, unit testing, and code coverage.

## Table of Contents
- [Overview](#overview)
- [Initial Pipeline Analysis](#initial-pipeline-analysis)
- [Refactoring Changes](#refactoring-changes)
  - [Change 1: Centralized Environment Setup](#change-1-centralized-environment-setup)
  - [Change 2: Reusable Function for MongoDB Operations](#change-2-reusable-function-for-mongodb-operations)
  - [Change 3: Post-Build Actions](#change-3-post-build-actions)
- [Final Pipeline Structure](#final-pipeline-structure)
- [Key Learnings](#key-learnings)
- [Official Documentation References](#official-documentation-references)

## Overview

The Jenkins pipeline orchestrates the following workflow:
1. Environment setup and credential management
2. Node.js version verification
3. Dependency installation
4. Security scanning (parallel execution)
5. Docker permission setup
6. Unit testing with MongoDB
7. Code coverage analysis
8. Artifact collection and reporting

## Initial Pipeline Analysis

The initial pipeline had several areas for improvement:

**Issues Identified:**
1. **Credential Duplication**: MongoDB credentials were loaded multiple times in different stages
2. **Code Repetition**: MongoDB container management logic was duplicated in unit testing and code coverage stages
3. **Missing Post-Build Actions**: No centralized artifact collection or cleanup procedures

## Refactoring Changes

### Change 1: Centralized Environment Setup
**Problem**: MongoDB credentials were loaded separately in both unit testing and code coverage stages using `withCredentials` blocks.

**Solution**: Created a dedicated `Setup Environment` stage that loads credentials once and makes them available globally throughout the pipeline.

**Before:**
```groovy
stage ("Unit Testing"){
    steps {
        withCredentials([usernamePassword(credentialsId: 'Mongo-DB-Credentials', 
                         passwordVariable: 'MONGO_PASSWORD', 
                         usernameVariable: 'MONGO_USERNAME')]) {
            // MongoDB operations...
        }
    }
}
```

**After:**
```groovy
stage('Setup Environment') {
    steps {
        script {
            withCredentials([usernamePassword(credentialsId: 'Mongo-DB-Credentials', 
                             passwordVariable: 'MONGO_PASSWORD', 
                             usernameVariable: 'MONGO_USERNAME')]) {
                env.MONGO_URI = "mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${env.MONGO_HOST}:${env.MONGO_PORT}/${env.MONGO_DB}?authSource=admin"
                env.MONGO_USERNAME = MONGO_USERNAME
                env.MONGO_PASSWORD = MONGO_PASSWORD
            }
        }
    }
}
```

**Benefits**:
- Single source of truth for credentials
- Reduced pipeline complexity
- Improved security by minimizing credential exposure

### Change 2: Reusable Function for MongoDB Operations
**Problem**: The same MongoDB container lifecycle management code was duplicated in both unit testing and code coverage stages.

**Solution**: Extracted common functionality into a reusable Groovy function `runWithMongoDB()`.

**Before:**
```groovy
stage ("Unit Testing"){
    steps {
        script {
            // MongoDB startup, test execution, cleanup (20+ lines)
        }
    }
}

stage ("Code coverage"){
    steps {
        script {
            // MongoDB startup, coverage execution, cleanup (20+ lines - duplicated)
        }
    }
}
```

**After:**
```groovy
// Reusable function definition
def runWithMongoDB(command) {
    try {
        // Start MongoDB using Docker Compose
        sh """
            echo "Starting MongoDB container..."
            MONGO_USERNAME=${env.MONGO_USERNAME} \\
            MONGO_PASSWORD=${env.MONGO_PASSWORD} \\
            MONGO_DB=${env.MONGO_DB} \\
            MONGO_PORT=${env.MONGO_PORT} \\
            docker-compose -f docker-compose.yml up -d

            echo "Waiting for MongoDB to be ready..."
            sleep 15
        """

        // Run the provided command
        sh """
            echo "DEBUG: Running command with MONGO_URI=${env.MONGO_URI}"
            ${command}
        """
    } finally {
        // Cleanup
        sh '''
            echo "Cleaning up MongoDB container..."
            docker-compose -f docker-compose.yml down -v
        '''
    }
}

// Usage in stages
stage ("Unit Testing"){
    steps {
        script {
            runWithMongoDB("npm test")
        }
    }
}
```

**Benefits**:
- DRY (Don't Repeat Yourself) principle applied
- Easier maintenance and updates
- Consistent error handling with try-finally block

### Change 3: Post-Build Actions
**Problem**: No centralized mechanism for collecting artifacts, generating reports, or performing cleanup.

**Solution**: Added `post` block with conditional actions for different build outcomes.

**Implementation:**
```groovy
post {
    always {
        // Archive artifacts regardless of build result
        archiveArtifacts artifacts: '**/reports/*', allowEmptyArchive: true
        junit testResults: '**/test-results.xml', allowEmptyResults: true
    }
    success {
        // Actions for successful builds only
        echo 'Build succeeded!'
    }
    failure {
        // Actions for failed builds
        echo 'Build failed!'
        // Send notifications, etc.
    }
    cleanup {
        // Always run cleanup tasks
        echo 'Cleaning up workspace...'
        // Additional cleanup steps
    }
}
```

**Note**: In build #76, a "Declarative: Post Actions" stage appears in classic Jenkins UI but not in Blue Ocean. This is expected behavior as Blue Ocean handles post-build actions differently.

## Final Pipeline Structure

The refactored pipeline now includes:

1. **Environment Configuration**:
   - Global environment variables
   - Tool configuration (Node.js)
   - Pipeline options

2. **Stages**:
   - Setup Environment (credentials and URI)
   - Node.js Version Check
   - Dependency Installation
   - Dependency Scan (parallel execution)
   - Docker Permission Setup
   - Unit Testing
   - Code Coverage

3. **Shared Functionality**:
   - `runWithMongoDB()` function for consistent MongoDB operations

4. **Post-Build Actions**:
   - Artifact archiving
   - Report publishing
   - Cleanup operations

## Key Learnings

1. **Environment Variable Scope**: Variables set using `env.VARIABLE_NAME` in script blocks become globally accessible in subsequent stages.

2. **Credential Management**: Best practice is to load sensitive credentials once and store them in environment variables for pipeline-wide use.

3. **Code Reusability**: Shared Groovy functions outside the `pipeline {}` block can be called from any stage, promoting code reuse.

4. **Error Handling**: Using `try-finally` blocks ensures cleanup operations run even if the main command fails.

5. **Pipeline Organization**: Separating concerns (environment setup, testing, reporting) improves maintainability.

6. **Jenkins UI Differences**: Classic Jenkins UI and Blue Ocean may display pipeline stages differently, particularly for post-build actions.

## Official Documentation References

- [Groovy Language Semantics](https://groovy-lang.org/semantics.html)
- [Declarative vs Scripted Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/#declarative-versus-scripted-pipeline-syntax)
- [Pipeline CPS Steps](https://www.jenkins.io/doc/pipeline/steps/workflow-cps/)
- [Jenkinsfile Documentation](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/)
- [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/#post)
- [Speaker Blog: Jenkins World](https://www.jenkins.io/blog/2017/06/27/speaker-blog-SAS-jenkins-world/)