# Scripted Pipeline Conversion Demo

## Overview
This documentation outlines the process of converting a Declarative Jenkins pipeline to a Scripted Pipeline format. The conversion demonstrates key differences between Declarative and Scripted pipeline syntax while maintaining the same functionality.

## Branch Information
- **Source Branch**: `feature/k8s-agent`
- **Target Branch**: `pipeline/scripted`
- **Initial File**: `Jenkinsfile.declarative`
- **Converted File**: `Jenkinsfile`

## Key Conversion Steps

### 1. Pipeline Structure
- **Declarative**: Starts with `pipeline {}`
- **Scripted**: Starts with `node {}`

### 2. Agent Declaration
- **Declarative**: Uses `agent any` to run on master node
- **Scripted**: No agent block needed for master/controller node execution

### 3. Tool Configuration
Using NodeJS plugin as per official documentation:

**Scripted Pipeline Syntax:**
```groovy
node {
    env.NODEJS_HOME = "${tool 'NodeJS-23.11.1'}"
    env.PATH="${env.NODEJS_HOME}/bin:${env.PATH}"
    sh 'npm --version'
}
```

**Corresponding Declarative Syntax:**
```groovy
tools {
    nodejs 'NodeJS-23.11.1'
}
```

### 4. Options Directive Conversion
**Declarative:**
```groovy
options {
    disableConcurrentBuilds abortPrevious: true
    disableResume()
}
```

**Scripted:**
```groovy
properties([disableConcurrentBuilds(abortPrevious: true), [$class: 'JobRestrictionProperty']])
```

### 5. Stage Structure
- **Declarative**: Requires `steps {}` block within each stage
- **Scripted**: Directly contains executable steps within stage blocks
- No `stages {}` wrapper required in Scripted pipelines

### 6. Timestamps Integration
Using Timestamper plugin for build step timing:

**Scripted Implementation:**
```groovy
timestamps {
    stage ("Installing nodejs dependencies") {
        // Stage content
    }
}
```

### 7. Cache Configuration
Maintained the same cache configuration during conversion:
- Cache name: `npm-dependency-cache`
- Cache validity file: `package-lock.json`
- Cache path: `node_modules/`
- Max cache size: 550 MB

## Final Scripted Pipeline
```groovy
node {
    env.NODEJS_HOME = "${tool 'NodeJS-23.11.1'}"
    env.PATH="${env.NODEJS_HOME}/bin:${env.PATH}"
    sh 'npm --version'
    
    properties([disableConcurrentBuilds(abortPrevious: true), [$class: 'JobRestrictionProperty']])
    
    stage ("Checkout-SCM") {
        checkout scm
    }
    
    timestamps {
        stage ("Installing nodejs dependencies") {
            cache(caches: [arbitraryFileCache(cacheName: 'npm-dependency-cache', 
                     cacheValidityDecidingFile: 'package-lock.json', 
                     excludes: '', 
                     includes: '**/*', 
                     path: 'node_modules/')], maxCacheSize: 550) {
                script {
                    sh 'node -v'
                    sh 'npm install --no-audit'
                    stash includes: 'node_modules/', name: 'solar-system-node-modules'
                }
            }
        }
    }
}
```

## Official Documentation References
- [NodeJS Plugin](https://plugins.jenkins.io/nodejs/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/#declarative-directives)
- [Timestamper Plugin](https://plugins.jenkins.io/timestamper/)

## Build Information
- **Project**: Organization-folder-demo/solar-system-migrate
- **Successful Build**: #4 (Build #3 was superseded)
- **Branch Path**: pipeline%2Fscripted

## Key Takeaways
1. Scripted pipelines offer more flexibility with Groovy scripting
2. Directive conversions require different syntax approaches
3. Plugin usage varies between Declarative and Scripted formats
4. Stage structure is simpler in Scripted pipelines
5. Common functionality (caching, stashing, tools) remains similar with syntax adjustments