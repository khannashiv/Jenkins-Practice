# Demo: Kubernetes Deploy - Update Image Tag

This Jenkins pipeline demonstrates a complete CI/CD workflow for updating Kubernetes deployment images, with comprehensive documentation on heredoc usage, troubleshooting WSL issues, and pipeline commands.

## 📋 Table of Contents
- [Pipeline Overview](#pipeline-overview)
- [Prerequisites](#prerequisites)
- [Jenkins Pipeline Structure](#jenkins-pipeline-structure)
- [Key Concepts & Documentation](#key-concepts--documentation)
- [Heredoc (EOF) Reference Guide](#heredoc-eof-reference-guide)
- [Troubleshooting](#troubleshooting)
- [Common Errors & Solutions](#common-errors--solutions)

## 🔄 Pipeline Overview

This demo showcases a Jenkins pipeline that:
- Checks out source code from a repository
- Updates container image tags in Kubernetes deployment files
- Applies changes to Kubernetes clusters
- Demonstrates proper heredoc usage for remote SSH commands

## 📋 Prerequisites

- Jenkins server (2.x or later)
- Kubernetes cluster access
- Git
- SSH access configured for remote servers
- WSL (if running on Windows)

## 🏗 Jenkins Pipeline Structure

### Pipeline Nodes and Processes

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                dir('kubernetes-deployment') {
                    // Change to specific directory
                    checkout scm
                }
            }
        }
        
        stage('Update Image Tag') {
            steps {
                // Update Kubernetes deployment image
                sh '''
                    sed -i "s|image:.*|image: myapp:${BUILD_NUMBER}|" k8s/deployment.yaml
                '''
            }
        }
        
    }
}
```

## 📚 Key Concepts & Documentation

### Jenkins Pipeline Steps Documentation

| Step | Description | Documentation Link |
|------|-------------|-------------------|
| **dir** | Change current directory in workspace | [Jenkins Pipeline Steps: workflow-durable-task-step](https://www.jenkins.io/doc/pipeline/steps/workflow-durable-task-step/) |
| **fileExists** | Verify if file exists in workspace | [Jenkins Pipeline Steps: workflow-basic-steps](https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/#fileexists-verify-if-file-exists-in-workspace) |

### Usage Examples

**dir() Example:**
```groovy
dir('kubernetes-configs') {
    // All commands here execute from 'kubernetes-configs' directory
    sh 'ls -la'
}
```

**fileExists() Example:**
```groovy
if (fileExists('k8s/deployment.yaml')) {
    echo "Deployment file exists, proceeding..."
} else {
    error "Deployment file not found!"
}
```

## 📝 Heredoc (EOF) Reference Guide

Understanding heredoc syntax is crucial for remote command execution in Jenkins pipelines.

### 🔑 Key Differences: 'EOF' vs EOF vs <<-EOF

| Syntax | Variable Expansion | Indentation | Use Case |
|--------|-------------------|------------|----------|
| **'EOF'** | ❌ No expansion (literal) | Not allowed | When you want exact literal text, no variable substitution |
| **EOF** | ✅ Variables expand | Must start at column 1 | When you need variable expansion and can align to column 1 |
| **<<-EOF** | ✅ Variables expand | Allows tabs (not spaces) | When you need clean indentation in pipeline code |

### 📌 Heredoc Examples

**1. 'EOF' - No Variable Expansion (Literal)**
```groovy
sh '''
    ssh user@host 'bash -s' <<'EOF'
        echo "The variable \$HOME will not expand"
        echo "Literal: \$MONGO_USERNAME stays as text"
    EOF
'''
```

**2. EOF - Variable Expansion**
```groovy
sh '''
    ssh user@host 'bash -s' <<EOF
        echo "Home directory: $HOME"  # Expands locally before sending
        echo "Username: $MONGO_USERNAME"  # Will expand
    EOF
'''
```

**3. <<-EOF - Variable Expansion with Tabs**
```groovy
sh '''
    ssh user@host 'bash -s' <<-EOF
    ↠↠echo "This line starts with tabs"  # ↠ represents tab character
    ↠↠kubectl apply -f deployment.yaml
    ↠↠EOF  # EOF can be indented with tabs
'''
```

### ⚠️ Important Notes

1. **<<-EOF** only strips **tabs**, not spaces
2. Using spaces before EOF will cause: `bash: line 47: EOF: command not found`
3. **'EOF'** (quoted) prevents all variable expansion
4. **EOF** (unquoted) expands variables **at submission time**, not on remote server

## 🔧 Troubleshooting

### WSL (Windows Subsystem for Linux) Issues

#### ❌ Error 1: Jenkins pipeline fails at checkout stage

**Error Message:**
```
error=0, Failed to exec spawn helper
pid: 29254, exit value: 1
```

**Root Cause:**
This occurs when the Jenkins service in WSL becomes unresponsive or the WSL kernel has issues with process spawning.

**✅ Solution 1:**
```bash
# Step 1: Shutdown WSL
wsl --shutdown

# Step 2: Restart Jenkins service
sudo systemctl restart jenkins
```

**Alternative Solutions:**
```bash
# Force terminate all WSL instances
wsl --terminate <distro-name>

# Or restart WSL service completely
net stop LxssManager
net start LxssManager
```

## ❗ Common Errors & Solutions

### Error: "EOF: command not found"

**Problem:** Spaces used before EOF terminator
```groovy
sh '''
    ssh user@host <<EOF  # Correct: no spaces before EOF
        echo "Hello"
    EOF                  # Correct: EOF at column 1
'''
```

**Incorrect:**
```groovy
sh '''
    ssh user@host <<EOF
        echo "Hello"
    EOF                 # ❌ Spaces before EOF
'''
```

### Error: Variables not expanding

**Problem:** Using single quotes or 'EOF' when expansion needed
```groovy
// ❌ No expansion
sh '''
    ssh user@host <<'EOF'
        echo $BUILD_NUMBER  # Won't expand
    EOF
'''

// ✅ Variables will expand
sh '''
    ssh user@host <<EOF
        echo $BUILD_NUMBER  # Will expand
    EOF
'''
```

## 💡 Best Practices

1. **Use <<-EOF** for cleaner pipeline code with indentation
2. **Always use tabs** for heredoc indentation, never spaces
3. **Quote the delimiter** ('EOF') when you need literal strings
4. **Combine with bash -s** for complex remote commands:
   ```groovy
   ssh user@host 'bash -s' <<-EOF
       kubectl get pods
       kubectl rollout status deployment/$APP_NAME
   EOF
   ```
5. **Always verify file existence** before operations:
   ```groovy
   if (fileExists('deployment.yaml')) {
       // Safe to proceed
   }
   ```

## 📚 Additional Resources

- [Jenkins Pipeline Syntax Documentation](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Kubernetes Deployment Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Bash Heredoc Documentation](https://www.gnu.org/software/bash/manual/html_node/Redirections.html#Here-Documents)

---

**Note:** This demo focuses on the image tag update pattern commonly used in CI/CD pipelines for Kubernetes deployments. Adjust the paths and commands according to your specific infrastructure setup.