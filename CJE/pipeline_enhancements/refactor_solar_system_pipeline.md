# Jenkins Pipeline Refactoring with Kubernetes Agent

## Overview
This document demonstrates refactoring a Jenkins pipeline to use Kubernetes agents instead of standard agents, enabling dynamic pod provisioning with multi-container support. The refactoring provides significant efficiency gains through shared workspace volumes and network communication between containers in the same pod.

## Branch Creation
- Created new branch `feature/k8s-agent` from `feature/advanced-demo`
- All refactoring work performed on this branch

## Key Benefits Achieved

### ✅ **Workspace Sharing**
- Dependencies installed once are accessible across all containers
- Source code checkout happens once, available to all stages
- Build artifacts persist across container switches
- No redundant `npm install` operations needed

### ✅ **Network Communication**
- All containers share the same network namespace
- MongoDB accessible at `localhost:27017` from any container
- No complex service discovery or DNS configuration required

### ✅ **Resource Efficiency**
- Single pod with multiple specialized containers
- Better resource utilization than separate pods
- Faster pipeline execution with shared dependencies

## Kubernetes Agent Configuration Methods

### Method 1: Inline YAML Definition
```groovy
agent {
  kubernetes {
    cloud 'EKS-cluster'
    defaultContainer 'node-18'
    yaml '''apiVersion: v1
kind: Pod
spec:
  containers:
    - name: node-18
      image: node:18-alpine
      command:
        - cat
      tty: true
    - name: node-19
      image: node:19-alpine
      command:
        - cat
      tty: true'''
  }
}
```

### Method 2: External YAML File (Recommended)
```groovy
agent {
  kubernetes {
    cloud 'EKS-cluster'
    defaultContainer 'node-18'
    yamlFile 'k8s-agent.yaml'
  }
}
```

## Multi-Container Pod Configuration (`k8s-agent.yaml`)

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: node-18
      image: node:18-alpine
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "400m"
          memory: "1Gi"  # Allocated enough for npm install spikes
    - name: node-19
      image: node:19-alpine
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
    - name: mongodb
      image: mongo:latest
      ports:
        - containerPort: 27017
      env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: "testUser"
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: "testPass"
      resources:
        requests:
          cpu: "250m"
          memory: "512Mi" # MongoDB baseline
    # The jnlp agent is added automatically by Jenkins
```

## How It Works: Automatic Volume Mounting

Jenkins Kubernetes plugin automatically handles workspace sharing:

1. **Auto-injects `jnlp` container** for Jenkins agent communication
2. **Creates `workspace-volume`** (emptyDir volume) automatically
3. **Mounts volume to all containers** at `/home/jenkins/agent`
4. **All containers share the same workspace** without manual configuration

### Container Communication Flow:
```mermaid
graph LR
    A[Stage 1: Install Dependencies<br/>node-18 container] --> B[Shared Workspace<br/>/home/jenkins/agent]
    B --> C[Stage 2: Dependency Scan<br/>node-18 container]
    B --> D[Stage 3: Unit Testing<br/>node-19 container]
    B --> E[Stage 4: Code Coverage<br/>node-18 container]
    
    F[MongoDB Container] --> G[localhost:27017]
    C --> G
    D --> G
    E --> G
```

## Stage-Specific Agent Strategy

### Kubernetes Agent Stages (Using shared workspace):
- **Installing nodejs dependencies** → Uses `node-18` container, installs to shared volume
- **Dependency Scan** → Uses `node-18` container, accesses same `node_modules`
- **Unit Testing** → Uses `node-19` container, uses same dependencies via shared volume
- **Code coverage** → Uses `node-18` container, accesses test results from shared volume

### Standard Agent Stages (Using `agent any`):
- **Build Docker Image**
- **Trivy vulnerability Scanner**
- **Setup Docker Permissions**

## Complete Working Pipeline Example (Sample code)

```groovy
pipeline {
    agent {
        kubernetes {
            cloud 'EKS-cluster'
            defaultContainer 'node-18'
            yamlFile 'k8s-agent.yaml'
        }
    }
    
    stages {
        stage('Install Dependencies') {
            steps {
                checkout scm
                sh 'npm ci'  # Installs once to shared volume
                sh 'echo "Dependencies installed with Node: $(node --version)"'
            }
        }
        
        stage('Dependency Scan') {
            steps {
                sh '''
                    echo "Running dependency scan..."
                    # Uses already-installed node_modules from shared volume
                    npx audit-ci --critical
                '''
            }
        }
        
        stage('Unit Testing') {
            steps {
                container('node-19') {
                    sh '''
                        echo "Testing with Node 19: $(node --version)"
                        # Same workspace, same node_modules!
                        npm test
                    '''
                }
            }
        }
        
        stage('Code Coverage') {
            steps {
                sh '''
                    echo "Running code coverage..."
                    # Uses test results from shared workspace
                    npx nyc report --reporter=lcov
                '''
            }
        }
        
        stage('Test MongoDB Integration') {
            steps {
                sh '''
                    echo "Testing MongoDB connection..."
                    # Connect to mongodb container in same pod
                    npx mongosh "mongodb://testUser:testPass@localhost:27017/test" \
                        --eval "db.stats()"
                '''
            }
        }
    }
}
```
## NOTE : Above is a simplified example focusing on key stages. Full source code is available in the referenced Gitea repository as noted below.

## Security Consideration

**Note**: MongoDB credentials are currently defined directly in the manifest. Future improvements will implement secure credential management strategies:
- Kubernetes Secrets integration
- Jenkins Credentials Binding
- HashiCorp Vault integration
- Environment variable encryption

## Pipeline Syntax Tool
The agent configuration was generated using Jenkins' **Directive Generator** available in the pipeline syntax helper, ensuring proper YAML structure and syntax.

## Efficiency Gains Summary

| Aspect | Before Refactoring | After Refactoring |
|--------|-------------------|------------------|
| **Dependency Installation** | Multiple times (per container) | Once (shared volume) |
| **Network Configuration** | Complex service discovery | Simple `localhost` |
| **Resource Usage** | Multiple pods | Single pod with multiple containers |
| **Pipeline Speed** | Slower (redundant operations) | Faster (shared resources) |
| **Configuration** | Complex volume management | Automatic by Jenkins |

## References
- Official Jenkins Kubernetes Plugin Documentation: https://plugins.jenkins.io/kubernetes/
- Jenkins Pipeline Syntax: https://www.jenkins.io/doc/book/pipeline/syntax/
- Gitea repository holding source code [`Actual code`]: https://gitea.com/my-demo-active-org/solar-system-migrate/src/branch/feature/k8s-agent/
