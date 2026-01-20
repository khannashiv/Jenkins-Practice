# Jenkins Pipeline: Refactoring Unit Test Stage with Parallel Execution

## Overview
This document demonstrates refactoring a Jenkins pipeline unit testing stage to run tests across multiple Node.js versions simultaneously using parallel execution strategies. The investigation reveals unexpected workspace persistence behavior when switching between agent types.

## Current Implementation
The original unit testing stage uses a single Node.js 18 container running inside a Kubernetes pod:

```groovy
stage ("Unit Testing") {
    steps {
        script {
            runWithMongoDB("npm test")
            sh 'node -v'
        }
    }
}
```

## Refactored Implementation
The refactored approach introduces parallel execution across three different Node.js environments:

```groovy
stage ("Refactor Unit Testing") {
    parallel {
        stage ('NodeJS 18') {
            // Uses default container defined globally under agent section
            steps {
                script {
                    sh 'node -v'
                    runWithMongoDB("npm test")
                }
            }
        }

        stage ('NodeJS 19') {
            // Uses another container defined in k8s-agent.yaml pod specification
            steps {
                container('node-19') {
                    script {
                        sh 'sleep 10s'  // Avoid port conflict
                        sh 'node -v'
                        runWithMongoDB("npm test")
                    }
                }
            }   
        }

        stage ('NodeJS 20') {
            // Uses Docker as agent (external to Kubernetes pod)
            agent {
                docker {
                    image 'node:20-alpine'
                }
            }
            stages {
                stage("Install-dependency-Sequential") {
                    steps {
                        sh 'node -v'
                        sh 'npm install --no-audit'          
                    }
                }
                stage("Unit-Testing-Sequential") {
                    steps {
                        sh 'node -v'
                        runWithMongoDB("npm test")                      
                    }
                }
            }
        }
    }
}
```

## Key Architecture Components

### 1. **Agent Configuration**

- **Global Agent**: Kubernetes pod with multiple containers (node-18, node-19, mongodb)
- **Stage-Level Agent Override**: `NodeJS 20` uses `agent { docker }` which overrides global agent
- **Agent Switching**: When using `agent { docker }`, Jenkins switches execution from K8s pod to Jenkins controller

### 2. **Workspace Management**

- **K8s Pod Workspace**: `/home/jenkins/agent/workspace/...` (in Kubernetes pod)
- **Jenkins Controller Workspace**: `/var/lib/jenkins/workspace/...` (on Jenkins master)
- **Docker Mount**: Jenkins controller workspace mounted to Docker container

## Critical Investigation: The Dependency Sharing Mystery

### **The Puzzling Question**
**Q:** Why does the `NodeJS 20` stage pass even though it uses a Docker container separate from the Kubernetes pod where dependencies were installed, **without using stash/unstash or cache mechanisms**?

### **The Evidence from Logs**

1. **Stage 1 Execution Location**:
   ```
   Running on n-folder-demo-solar-system-migrate-feature-2fk8s-agent-22-szb8p
   in /home/jenkins/agent/workspace/system-migrate_feature_k8s-agent
   ```
   - Runs in **Kubernetes pod**
   - Installs dependencies in pod workspace

2. **Stage 3 Execution Location**:
   ```
   [Pipeline] node
   Running on Jenkins in /var/lib/jenkins/workspace/system-migrate_feature_k8s-agent
   ```
   - Runs on **Jenkins controller**
   - Different workspace path

3. **Critical npm Output**:
   ```
   + npm install --no-audit
   up to date in 918ms  # ← This is the mystery!
   ```
   - npm reports dependencies are "up to date"
   - But this is a fresh Docker container on Jenkins controller

### **The Investigation**

#### **What We Know:**

1. **No Stash/Unstash**: No `stash` or `unstash` commands in logs
2. **No Cache Usage**: No cache operations in logs (`added 359 packages in 7s` indicates fresh install)
3. **Different Workspaces**: K8s pod vs Jenkins controller
4. **Fresh Docker Container**: `node:20-alpine` container starts clean

#### **What Doesn't Make Sense:**
- Docker container on Jenkins controller shouldn't have `node_modules/`
- `npm install` should take ~7 seconds (like Stage 1), not 918ms
- Workspaces are physically separate

### **The Most Likely Explanation: Jenkins Workspace Synchronization**

When Jenkins switches from Kubernetes agent to Docker agent, it **automatically synchronizes the workspace contents**. This is a built-in Jenkins behavior that happens transparently.

#### **How It Works:**
1. **Stage 1**: `npm install` in K8s pod creates `node_modules/`
2. **Stage 3**: Jenkins switches to Docker agent on controller
3. **Automatic Sync**: Jenkins copies workspace files from K8s pod to Jenkins controller
4. **Docker Mount**: Docker container mounts synced workspace
5. **npm install**: Finds existing `node_modules/`, reports "up to date"

#### **Evidence Supporting This:**
1. **Checkout in Stage 3**: The logs show `[Pipeline] checkout` in NodeJS 20 stage
2. **Workspace Paths**: Different but Jenkins manages synchronization
3. **No Manual File Transfer**: No stash/unstash/cache commands

### **Alternative Explanations Considered and Rejected:**

#### **❌ Docker-in-Docker (DinD)**
- **Why not**: Logs show `Running on Jenkins` not `Running in container`
- **Evidence**: `Jenkins does not seem to be running inside a container`

#### **❌ Shared Network Storage**
- **Why not**: Different paths (`/home/jenkins/agent/` vs `/var/lib/jenkins/workspace/`)
- **Evidence**: Explicit different mount points

#### **❌ Pipeline Caching**
- **Why not**: No cache operations in logs
- **Evidence**: Cache block exists but `npm install` shows fresh install

#### **❌ Stash/Unstash**
- **Why not**: No stash/unstash commands in logs
- **Evidence**: Code has stash but not executed in this run

### **Proving the Theory**

#### **Test 1: Add Debug Information**
```groovy
stage ('NodeJS 20 - Debug') {
    agent {
        docker { image 'node:20-alpine' }
    }
    steps {
        script {
            sh '''
                echo "=== Location Check ==="
                hostname
                pwd
                echo "Workspace: $WORKSPACE"
                
                echo "=== File Check Before npm ==="
                ls -la node_modules 2>/dev/null | head -3 || echo "No node_modules initially"
                
                echo "=== npm install output ==="
                npm install --no-audit --verbose 2>&1 | tail -20
            '''
        }
    }
}
```

#### **Test 2: Check File Timestamps**
```groovy
stage ('Check File Sync') {
    steps {
        script {
            sh '''
                echo "=== In K8s Pod ==="
                pwd
                stat node_modules/package.json 2>/dev/null || echo "No package.json"
            '''
        }
    }
}

stage ('NodeJS 20 - Check Sync') {
    agent {
        docker { image 'node:20-alpine' }
    }
    steps {
        script {
            sh '''
                echo "=== In Docker on Jenkins ==="
                pwd
                stat node_modules/package.json 2>/dev/null || echo "No package.json"
                # Compare timestamps if file exists
            '''
        }
    }
}
```

#### **Test 3: Force Isolation**
```groovy
stage ('NodeJS 20 - Clean Test') {
    agent {
        docker {
            image 'node:20-alpine'
            args '--rm -v $(pwd):/workspace:rw'
        }
    }
    steps {
        script {
            // Clean workspace to test true isolation
            sh '''
                echo "=== Clean Workspace ==="
                rm -rf node_modules package-lock.json
                ls -la node_modules 2>/dev/null || echo "Confirmed clean"
                
                echo "=== Fresh npm install ==="
                time npm install --no-audit
            '''
            runWithMongoDB("npm test")
        }
    }
}
```

## Key Learnings

### **1. Jenkins' Automatic Workspace Management**
- Jenkins automatically synchronizes workspaces between different agent types
- This happens transparently without explicit commands
- Can create unexpected behavior when assuming isolation

### **2. Agent Switching Has Hidden Costs**
- Switching from K8s to Docker agent triggers workspace sync
- File transfer happens behind the scenes
- Performance impact for large workspaces

### **3. Debugging Agent Behavior**
- Always check `Running on...` lines in logs
- Monitor workspace paths
- Add explicit file checks when debugging

### **4. Ensuring True Isolation**
If you need complete isolation between agents:

```groovy
stage ('NodeJS 20 - Isolated') {
    agent {
        docker {
            image 'node:20-alpine'
            args '--rm'  // Clean container
        }
    }
    steps {
        script {
            // Explicit cleanup
            sh 'rm -rf node_modules package-lock.json'
            sh 'npm install --no-audit'  // Fresh install
            runWithMongoDB("npm test")
        }
    }
}
```

## Best Practices for Multi-Agent Pipelines

### **1. Explicit File Management**
```groovy
// Option A: Use stash/unstash for clarity
stage ('Install') {
    steps {
        sh 'npm install --no-audit'
        stash includes: 'node_modules/', name: 'deps'
    }
}

stage ('Test on Docker') {
    agent { docker { image 'node:20-alpine' } }
    steps {
        unstash 'deps'  // Explicit file transfer
        runWithMongoDB("npm test")
    }
}
```

### **2. Per-Agent Installation**
```groovy
stage ('Parallel Tests') {
    parallel {
        stage ('K8s Node 18') {
            steps {
                sh 'npm install --no-audit'
                runWithMongoDB("npm test")
            }
        }
        stage ('Docker Node 20') {
            agent { docker { image 'node:20-alpine' } }
            steps {
                sh 'npm install --no-audit'  // Fresh install per agent
                runWithMongoDB("npm test")
            }
        }
    }
}
```

### **3. Agent-Aware Workspace Management**
```groovy
// Add at pipeline start
environment {
    IS_DOCKER_AGENT = false
}

stage ('NodeJS 20') {
    agent { 
        docker { 
            image 'node:20-alpine'
        }
    }
    environment {
        IS_DOCKER_AGENT = true
    }
    steps {
        script {
            if (env.IS_DOCKER_AGENT == 'true') {
                sh 'npm install --no-audit'  // Always fresh for Docker
            }
            runWithMongoDB("npm test")
        }
    }
}
```

## Troubleshooting Guide

### **Common Multi-Agent Issues**

#### **1. Missing Dependencies in Docker Agent**
**Symptoms**: `Error: Cannot find module 'mocha'`
**Solution**:
```groovy
steps {
    sh 'rm -rf node_modules'  // Clean first
    sh 'npm install --no-audit'  // Fresh install
}
```

#### **2. Workspace Path Confusion**
**Symptoms**: Files exist in one agent but not another
**Debug**:
```groovy
sh '''
    echo "Agent: $NODE_NAME"
    echo "Workspace: $WORKSPACE"
    pwd
    ls -la
'''
```

#### **3. Port Conflicts in Parallel Stages**
**Symptoms**: `EADDRINUSE: address already in use :::3000`
**Solutions**:
- Add delays between stages
- Use dynamic port allocation
- Run services on different ports

## References
- [Kubernetes Plugin Documentation](https://plugins.jenkins.io/kubernetes/)
- [Parallel Stages with Declarative Pipeline 1.2](https://www.jenkins.io/blog/2017/09/25/declarative-1/)
- [Using Docker with Pipeline](https://www.jenkins.io/doc/book/pipeline/docker/)
- [Jenkins Workspace Management](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#workspaces)
- [Gitea Repository - Source Code](https://gitea.com/my-demo-active-org/solar-system-migrate/src/branch/feature/k8s-agent/)
- [Jenkins Build #22 Logs](http://localhost:8080/job/Organization-folder-demo/job/solar-system-migrate/job/feature%2Fk8s-agent/22/console)

## Conclusion
The investigation reveals that Jenkins **automatically synchronizes workspace contents** when switching between different agent types (Kubernetes to Docker in this case). This built-in behavior explains why the `NodeJS 20` Docker container can access dependencies installed in the Kubernetes pod, even without explicit stash/unstash or cache mechanisms.

While this automatic synchronization provides convenience, it's important to be aware of it for:
1. **Performance**: Large workspaces incur sync overhead
2. **Isolation**: May not provide complete isolation between agents
3. **Debugging**: Can mask missing dependency issues

For production pipelines requiring strict isolation, implement explicit file management strategies or ensure fresh dependency installation in each agent context.