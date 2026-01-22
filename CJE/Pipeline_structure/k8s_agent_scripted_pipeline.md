# Jenkins Scripted Pipeline with Kubernetes Agent: Complete Guide

## 📋 **Overview**
This guide demonstrates how to create a Jenkins Scripted Pipeline that leverages Kubernetes (K8S) agents for dynamic resource allocation, specifically for Node.js applications with MongoDB integration.

## 🔗 **Official Documentation**
- **Kubernetes Plugin**: https://plugins.jenkins.io/kubernetes/
- **Repository URL**: [https://gitea.com/my-demo-active-org/solar-system-migrate.git]
    - Branch: */pipeline/scripted
    - Script Path: Jenkinsfile

## 🎯 **Key Concepts**

### **Ephemeral Pod Templates**
- `podTemplate` defines temporary pod templates that exist only within the pipeline execution block
- Not shared across builds or projects
- Created when entering the `podTemplate` block, deleted immediately after

### **Two Approaches for Pod Templates**
1. **Inline Definition** (used here): Hardcoded directly in the pipeline script
2. **Cloud-level Definition**: Defined at Jenkins cloud configuration level

## 🚀 **Implementation Steps**

### **Step 1: Generate Initial Template**
1. Navigate to **Pipeline Syntax** → **Snippet Generator**
2. Search for **podTemplate**
3. Configure:
   - Cloud: `EKS-cluster`
   - Label: `nodejs-pod`
   - Container Template:
     - Name: `node-18`
     - Docker Image: `node:18-alpine`
     - TTY: Enabled
     - Usage: *Build job with label expression*

### **Step 2: Optimize Generated Code**
**Initial Generated YAML:**
```groovy
podTemplate(cloud: 'EKS-cluster', containers: [containerTemplate(args: '9999999', command: 'sleep', image: 'node:18-alpine', livenessProbe: containerLivenessProbe(execArgs: '', failureThreshold: 0, initialDelaySeconds: 0, periodSeconds: 0, successThreshold: 0, timeoutSeconds: 0), name: 'node-18', privileged: true, resourceLimitCpu: '', resourceLimitEphemeralStorage: '', resourceLimitMemory: '', resourceRequestCpu: '', resourceRequestEphemeralStorage: '', resourceRequestMemory: '', ttyEnabled: true, workingDir: '/home/jenkins/agent')], label: 'nodejs-pod') {
    // some block
}
```

**Optimized Version:**
```groovy
podTemplate(
    cloud: 'EKS-cluster', 
    label: 'nodejs-pod',
    containers: [
        containerTemplate(
            args: '9999999',
            command: 'sleep',
            image: 'node:18-alpine',
            name: 'node-18',
            ttyEnabled: true,
            privileged: true,
            workingDir: '/home/jenkins/agent'
        )
    ]
) {
    // Pipeline stages here
}
```

## ⚠️ **Common Challenges & Solutions**

### **Challenge 1: Cross-Agent Resource Access**

**Problem**: Code checkout and dependencies are not automatically available in K8S pods

**Solution**:
- Explicit `checkout scm` in each agent context
- Use `stash`/`unstash` for sharing dependencies
- Scripted pipelines require manual checkout (unlike declarative)

### **Challenge 2: Fargate Compatibility**

**Problem**: AWS Fargate doesn't support privileged containers

**Error**:
```
[POD_UNSUPPORTED_ON_FARGATE] Pod not supported on Fargate: 
invalid SecurityContext fields: Privileged,Privileged
```

**Solution**: Remove `privileged: true` for Fargate compatibility

### **Challenge 3: Disk Space Management**

**Problem**: `/tmp` directory running out of space

**Solution**:
```bash
# Clean Docker resources
docker system prune -a --volumes -f

# Clean Jenkins workspace
cd /home/workspace
rm -rf *
```

## 🛠️ **Final Working Pipeline**

```groovy
// Global Static Configuration
env.MONGO_DB   = "solarSystemDB"
env.MONGO_PORT = "27017"

// Wrap everything in credentials for template visibility
withCredentials([usernamePassword(
    credentialsId: 'Mongo-DB-Credentials', 
    passwordVariable: 'MONGO_PASSWORD', 
    usernameVariable: 'MONGO_USERNAME'
)]) { 
    podTemplate(
        cloud: 'EKS-cluster', 
        label: 'nodejs-pod',
        containers: [
            // Node.js 18 Container
            containerTemplate(
                args: '9999999',
                command: 'sleep',
                image: 'node:18-alpine',
                name: 'node-18',
                ttyEnabled: true
            ),
            // Node.js 19 Container
            containerTemplate(
                args: '9999999',
                command: 'sleep',
                image: 'node:19-alpine',
                name: 'node-19',
                ttyEnabled: true
            ),
            // MongoDB Sidecar Container
            containerTemplate(
                args: '9999999',
                command: 'sleep',
                image: 'mongo:latest',
                name: 'mongodb',
                ttyEnabled: true,
                envVars: [
                    envVar(key: 'MONGO_INITDB_ROOT_USERNAME', value: "${MONGO_USERNAME}"),
                    envVar(key: 'MONGO_INITDB_ROOT_PASSWORD', value: "${MONGO_PASSWORD}")
                ]
            )
        ]
    ) {   
        // --- PRIMARY AGENT: EC2 Instance ---
        node('ubuntu-docker-jdk17-node18') {
            // Node.js Tool Configuration
            env.NODEJS_HOME = "${tool 'NodeJS-23.11.1'}"
            env.PATH = "${env.NODEJS_HOME}/bin:${env.PATH}"
            
            sh 'npm --version'
            
            // Pipeline Properties
            properties([
                disableConcurrentBuilds(abortPrevious: true), 
                [$class: 'JobRestrictionProperty']
            ])

            // Stage 1: Checkout SCM
            stage ("Checkout-SCM") {
                checkout scm
            }

            // Stage 2: Install Dependencies (with caching)
            timestamps {
                stage ("Installing nodejs dependencies") {
                    cache(caches: [
                        arbitraryFileCache(
                            cacheName: 'npm-dependency-cache',
                            cacheValidityDecidingFile: 'package-lock.json',
                            excludes: '',
                            includes: '**/*',
                            path: 'node_modules/'
                        )
                    ], maxCacheSize: 550) {
                        script {
                            sh 'node -v'
                            sh 'npm install --no-audit'
                            stash includes: 'node_modules/', name: 'solar-system-node-modules'
                        }
                    }
                }
            }

            // Stage 3: Unit Testing (in K8S Pod)
            stage ("Unit Testing") { 
                // --- SECONDARY AGENT: EKS Pod ---
                node('nodejs-pod') {
                    container('node-18') {
                        // Explicit checkout for scripted pipeline
                        checkout scm
                        
                        // Restore dependencies from stash
                        unstash 'solar-system-node-modules'
                        
                        // Construct MongoDB connection URI
                        def mongoUri = "mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@localhost:${env.MONGO_PORT}/${env.MONGO_DB}?authSource=admin"
                        
                        // Execute tests with MongoDB sidecar
                        withEnv(["MONGO_URI=${mongoUri}"]) {
                            echo "Executing tests against the Kubernetes Sidecar..."
                            sh 'sleep 10s && npm test'
                        }
                    }
                }
            }
        }
    }
}
```

## 📝 **Key Takeaways**

### **1. Multi-Agent Architecture**
- **EC2 Agent**: Primary agent for SCM checkout and dependency installation
- **K8S Pod**: Ephemeral agent for unit testing with MongoDB sidecar

### **2. Resource Sharing Strategy**
- `stash`/`unstash` for sharing `node_modules` between agents
- Manual `checkout scm` required in each agent context for scripted pipelines

### **3. Security Best Practices**
- Credentials wrapped at pipeline level for template visibility
- Environment variables for sensitive configuration
- MongoDB credentials injected via `envVars`

### **4. Performance Optimizations**
- Caching for npm dependencies
- Ephemeral K8S pods for resource efficiency
- Timestamps for build stage tracking

## 🔍 **Debugging Tips**

1. **Check Pod Status**: Monitor pod creation in Jenkins console
2. **Disk Space**: Regularly clean workspaces and Docker resources
3. **Fargate Limitations**: Avoid privileged mode for Fargate clusters
4. **Network Connectivity**: Ensure MongoDB sidecar is accessible from test container

This pipeline demonstrates a robust pattern for leveraging Kubernetes agents in Jenkins scripted pipelines while addressing common challenges in multi-environment builds.