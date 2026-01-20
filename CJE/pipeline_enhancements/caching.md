# Jenkins Pipeline: Dependency Caching with Job Cacher Plugin

## Overview
This project demonstrates how to use the Jenkins **Job Cacher Plugin** to efficiently cache dependencies and build artifacts, significantly reducing build times in CI/CD pipelines. This is particularly valuable in environments that run in clean states (like containers) where dependencies would otherwise need to be downloaded repeatedly.

## Official Documentation
- **Job Cacher Plugin**: [https://plugins.jenkins.io/jobcacher/](https://plugins.jenkins.io/jobcacher/)

## Why Caching is Crucial

- **Reduces Build Time**: By storing and reusing previously created artifacts and dependencies.
- **Optimizes Build Processes**: Eliminates redundant downloads and installations.
- **Essential for Ephemeral Environments**: Particularly beneficial for containerized builds that start from a clean state each time.

## Use Case: Node.js/NPM Dependency Caching
Caching is most effective in the dependency installation stage, especially for applications with **1000+ dependencies** where installation can take a significant amount of time.

## Implementation Steps

### 1. Install the Plugin
First, install the **Job Cacher Plugin** through the Jenkins plugin manager.

### 2. Generate Pipeline Syntax

1. Navigate to **Pipeline Syntax → Snippet Generator**
2. Select **cache: Cache** from the list
3. Configure the following fields:
   - **Path**: `node_modules/` (directory to cache)
   - **Name**: `npm-dependency-cache` (unique cache identifier)
   - **Cache Validity Deciding File**: `package-lock.json` (file that changes when dependencies are added/removed)
   - **Compression Mode**: `TARGZ`
   - **Max Cache Size**: `550 MB` (under Advanced settings)
4. Click **Generate Pipeline Script**

### 3. Pipeline Configuration

```groovy
stage('Installing nodejs dependencies') {
    agent any  // Runs on Jenkins controller for caching
    
    steps {
        // Cache dependencies using the Job Cacher plugin
        cache(caches: [
            arbitraryFileCache(
                cacheName: 'npm-dependency-cache',
                cacheValidityDecidingFile: 'package-lock.json',
                excludes: '',
                includes: '**/*',
                path: 'node_modules/'
            )
        ], defaultBranch: '', maxCacheSize: 550) {
            // Dependency installation block
            sh 'npm ci'
        }
        
        // Stash the node_modules for use in subsequent stages
        stash(name: 'solar-system-node-modules', includes: 'node_modules/**/*')
    }
}
```

### 4. Using Cached Dependencies in Subsequent Stages
For stages running on different agents (like Kubernetes pods), use `unstash` to retrieve the dependencies:

```groovy
stage('Unit Testing') {
    agent { 
        kubernetes {
            // Your Kubernetes agent configuration
        }
    }
    
    steps {
        // Retrieve the stashed dependencies
        unstash 'solar-system-node-modules'
        
        // Run tests with cached dependencies
        sh 'npm test'
    }
}
```

## Cache Behavior
- **First Build**: Creates the cache by storing `node_modules/` with a unique hash
- **Subsequent Builds**: Restores from cache if `package-lock.json` hasn't changed
- **Cache Invalidation**: Automatically invalidated when `package-lock.json` changes (new dependencies added/removed)

## Technical Details

### Stash vs. Unstash
- **Stash**: Saves files from the current workspace to Jenkins Controller (temporary storage)
- **Unstash**: Retrieves stashed files from Controller to current agent's workspace
- **Note**: Stashed files are automatically deleted after pipeline completion

### Multi-Agent Pipeline Example
```groovy
pipeline {
    agent {
        kubernetes {
            // Default K8s pod configuration
        }
    }
    
    stages {
        stage('Install Dependencies') {
            agent any  // Runs on controller for caching
            steps {
                // Cache and stash dependencies
            }
        }
        
        stage('Parallel Testing') {
            parallel {
                stage('NodeJS 18') {
                    // Uses global K8s pod agent
                    steps {
                        unstash 'solar-system-node-modules'
                        // Run Node 18 tests
                    }
                }
                stage('NodeJS 19') {
                    // Uses specific container in K8s pod
                    steps {
                        unstash 'solar-system-node-modules'
                        // Run Node 19 tests
                    }
                }
                stage('NodeJS 20') {
                    agent {
                        docker {
                            image 'node:20-alpine'
                            // Overrides global K8s agent
                        }
                    }
                    stages {
                        stage('Install-dependency-Sequential') {
                            steps {
                                unstash 'solar-system-node-modules'
                                // Install additional deps if needed
                            }
                        }
                        stage('Unit-Testing-Sequential') {
                            steps {
                                // Run Node 20 tests
                            }
                        }
                    }
                }
            }
        }
    }
}
```

### Agent Distribution
| Parallel Stage | Agent Used | Runtime Environment | Stash Location |
|----------------|------------|---------------------|----------------|
| NodeJS 18 | Global K8s Pod | Default container in K8s pod | Transferred from Controller to K8s Worker |
| NodeJS 19 | Global K8s Pod | Specific node-19 container in K8s pod | Transferred from Controller to K8s Worker |
| NodeJS 20 | Local Docker | Docker container on Jenkins Controller | Moved locally within Controller |

## Review Build Logs
Refer to build #26 and #27 of the Jenkins project to examine cached logs:
- **Full Project Name**: `Organization-folder-demo/solar-system-migrate/feature%2Fk8s-agent`

## Key Considerations
1. Cache size management is crucial to avoid storage issues
2. Choose cache validity files carefully (e.g., `package-lock.json`, `yarn.lock`, `requirements.txt`)
3. Consider cache strategy for multi-branch pipelines
4. Monitor cache hit rates to measure optimization effectiveness

## Best Practices
- Use descriptive cache names for different dependency types
- Set appropriate max cache sizes based on dependency volume
- Regularly monitor and clean up old cache entries
- Consider cache strategies for multi-platform builds