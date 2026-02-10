# Jenkins Pipeline Environment Variables Guide & Build Docker Image

## Overview
This document explains how SCM-specific variables like `GIT_COMMIT` work in Jenkins pipelines, particularly in multi-branch pipeline projects.

## Key Concepts

### 1. SCM Variable Availability
- **SCM-specific variables** (e.g., `GIT_COMMIT`, `GIT_BRANCH`) are **not automatically defined as global environment variables** in Jenkins
- These variables become accessible **through the return value of the checkout step**
- In **multi-branch pipeline projects**, the checkout happens **automatically/implicitly** at the beginning of the pipeline
- This makes SCM variables accessible to **all stages** in multi-branch pipelines

### 2. Accessing SCM Variables
Once available, you can access SCM variables using different syntaxes:

#### In Shell Script Blocks:
```bash
# Method 1: Direct variable expansion
echo ${GIT_COMMIT}

# Method 2: Using env prefix (in Groovy context)
echo ${env.GIT_COMMIT}

# Method 3: Direct shell variable
echo $GIT_COMMIT
```

#### In Groovy Script:
```groovy
println env.GIT_COMMIT
println GIT_COMMIT
```

### 3. Practical Example
Here's a pipeline stage demonstrating different ways to access the `GIT_COMMIT` variable:

```groovy
stage('Build Docker Image') {
    steps {
        script {
            sh '''
                echo "Printing default environment variables available" 
                printenv
                
                # Different ways to access GIT_COMMIT variable:
                
                # Method 1: Direct variable expansion
                docker build -t khannashiv/solar-system:${GIT_COMMIT} .
                
                # Method 2: Using env prefix in variable expansion
                docker build -t khannashiv/solar-system:${env.GIT_COMMIT} .
                
                # Method 3: Direct shell variable (may not work in all cases)
                docker build -t khannashiv/solar-system:$GIT_COMMIT .
                
                # Method 4: Explicit with env prefix (recommended)
                docker build -t khannashiv/solar-system:$env.GIT_COMMIT .
            '''
        }
    }
}
```

## Recommendations

### Best Practices:
1. **Use `${env.GIT_COMMIT}`** - Most reliable across different contexts
2. **Test variable availability** - Use `printenv` to see what's actually available
3. **Check pipeline syntax** - Use Jenkins' built-in documentation

### Checking Available Variables:
1. Navigate to your Jenkins pipeline
2. Click **Pipeline Syntax** 
3. Select **Global Variable Reference**
4. View all available global variables Jenkins provides by default

### Common Global Variables:
- `env.BUILD_NUMBER` - The current build number
- `env.JOB_NAME` - Name of the current job
- `env.BUILD_TAG` - Unique identifier for the build
- `env.WORKSPACE` - Absolute path of the workspace
- `env.GIT_COMMIT` - Git commit hash (when SCM checkout occurs)
- `env.GIT_BRANCH` - Git branch name (when SCM checkout occurs)

## Important Notes

### For Multi-branch Pipelines:
- ✅ SCM variables are available in all stages
- ✅ No explicit checkout step needed
- ✅ Variables populated automatically

### For Other Pipeline Types:
- You may need an explicit checkout step:
```groovy
steps {
    checkout scm
    // Now SCM variables are available
}
```

### Troubleshooting:
If `GIT_COMMIT` is not accessible:
1. Verify you're in a multi-branch pipeline project
2. Check that SCM checkout completed successfully
3. Use `printenv` to list all available environment variables
4. Consult the Jenkins Global Variable Reference for your specific version

## References
- [Jenkins Pipeline Syntax - Global Variables](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables)
- [Jenkins SCM Environment Variables](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#handling-credentials)