Here's the markdown file for your content:

```markdown
# Demo: Declarative vs Scripted Pipeline

## Official Documentation
- [Jenkins Pipeline Examples](https://github.com/jenkinsci/pipeline-examples)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)

## Setup Instructions

### Project Creation
1. Created a new Jenkins project/item/job named **`d-v-s-pipeline`**
2. Configured the project with the following settings:
   - **Pipeline definition**: Pipeline from SCM
   - **SCM**: Git
   - **Repository URL**: `https://gitea.com/Shiv/declarative-vs-scripted-pipeline.git`
   - **Branch**: `demo1`
   - **Script Path**: 
     - First test with: `Jenkinsfile.scripted`
     - Later test with: `Jenkinsfile.declarative`

### Repository
- **Gitea Repository**: https://gitea.com/Shiv/declarative-vs-scripted-pipeline.git

## Build Outcomes Comparison

### Build Results
- **Build #11**: Outcomes of Declarative Pipeline
- **Build #10**: Outcomes of Scripted Pipeline

### Key Differences Observed

1. **Checkout Stage**: 
   - Scripted Pipeline has no checkout stage by default
   - Checkout must be explicitly mentioned in the Jenkinsfile
   - Declarative Pipeline includes checkout stage automatically

2. **Missing Features in Scripted Pipeline**:
   - Git build data not shown (if we don't mention checkout explicitly in the pipeline)
   - Restart from stage options

## Pipeline Examples

### Sample Scripted Pipeline

```groovy
node {
    try {
        stage ("Scripted Pipeline!") {
            checkout scm
            sh 'echo "This is simple example of Scripted pipeline."'
            sh 'ls -ltr'
        }
    }
    catch (error) {
        echo "Failed: ${error}"
    }
    finally {
        sh 'echo "This will always run."'
        // Cleaning up jenkins workspace.
        sh 'rm -rf *'
    }
}
```

### Sample Declarative Pipeline

```groovy
pipeline {
    agent any

    stages {
        stage ("Declarative Pipeline!") {
            steps {
                sh 'echo "Hello from declarative pipeline"'
                sh 'ls -ltr'
            }
        }
    }

    post {
        always {
            sh 'echo "This will run always irrespective of fact pipeline pass or fails!!"'
            // Cleaning up workspace...
            sh 'rm -rf *'
        }
    }
}
```

## Structure Comparison

| Aspect | Scripted Pipeline | Declarative Pipeline |
|--------|-------------------|----------------------|
| **Syntax** | Groovy-based DSL | Structured, predefined syntax |
| **Checkout** | Manual (explicit `checkout scm`) | Automatic |
| **Error Handling** | Try-catch blocks | Built-in post sections |
| **Cleanup** | Finally block | Post-always section |
| **Stage Restart** | Not available | Available |
| **Git Data** | Not shown | Displayed in build |

## Notes
- Scripted pipelines offer more flexibility but require more boilerplate code
- Declarative pipelines provide better structure and built-in features
- The choice depends on specific project requirements and team preferences
```