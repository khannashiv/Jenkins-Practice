# Jenkins Pipeline Demo: Preserving Stashes in Declarative Pipeline

This documentation demonstrates how to use the `stash` and `unstash` commands in Jenkins Declarative Pipeline, along with the `preserveStashes` option to enable stage restarts.

## Overview

When using different agents across stages in Jenkins Pipeline, files created in one stage are not automatically available in subsequent stages. The `stash`/`unstash` mechanism allows you to save files from one stage and retrieve them in another. The `preserveStashes` option ensures these stashes remain available when restarting specific stages.

## Prerequisites

- Jenkins with Pipeline plugin installed
- An agent labeled `ubuntu-docker-jdk17-node18` (for demonstration purposes)
- Basic understanding of Jenkins Declarative Pipeline syntax

## Case Studies

### Case 1: Base Pipeline (Single Agent)

**Pipeline Script:**
```groovy
pipeline {
    agent any
    
    stages {
        stage('Generate motivational quotes..!!') {
            steps {
                script {
                    def quotes = '''
                        "The only way to do great work is to love what you do." - Steve Jobs
                        "Don't be afraid to give up the good to go for the great." - John D. Rockefeller
                        "Success is not final, failure is not fatal: it is the courage to continue that counts." - Winston Churchill
                    '''
                    
                    writeFile file: 'motivation.txt', text: quotes
                    
                    sh '''
                        cat motivation.txt
                    '''
                }
            }
        }
        
        stage('Display motivational quotes..!!') {
            steps {
                script {
                    sh '''
                        echo "#=#=#=#=#=#=#Today's motivation quotes are: #=#=#=#=#=#=#"
                        cat motivation.txt
                        rm motivation.txt
                        echo "******Removing file from current workspace*******"
                    '''
                }
            }
        }
    }
}
```

**Result:** ✅ Build passes successfully because both stages use the same agent (`agent any`), so the `motivation.txt` file is available in the same workspace.

---

### Case 2: Different Agents per Stage (Without Stash)

**Pipeline Script:**
```groovy
pipeline {
    agent any
    
    stages {
        stage('Generate motivational quotes..!!') {
            agent {
                label 'ubuntu-docker-jdk17-node18'
            }
            
            steps {
                script {
                    def quotes = '''
                        "The only way to do great work is to love what you do." - Steve Jobs
                        "Don't be afraid to give up the good to go for the great." - John D. Rockefeller
                        "Success is not final, failure is not fatal: it is the courage to continue that counts." - Winston Churchill
                    '''
                    
                    writeFile file: 'motivation.txt', text: quotes
                    
                    sh '''
                        cat motivation.txt
                    '''
                }
            }
        }
        
        stage('Display motivational quotes..!!') {
            steps {
                script {
                    sh '''
                        echo "#=#=#=#=#=#=#Today's motivation quotes are: #=#=#=#=#=#=#"
                        cat motivation.txt
                        rm motivation.txt
                        echo "******Removing file from current workspace*******"
                    '''
                }
            }
        }
    }
}
```

**Result:** ❌ Build fails because:
- Stage 1 runs on `ubuntu-docker-jdk17-node18` agent
- Stage 2 runs on `agent any` (likely the controller)
- The `motivation.txt` file exists only in the workspace of the `ubuntu-docker-jdk17-node18` agent
- Stage 2 cannot access the file as it's in a different workspace

---

### Case 3: Using Stash/Unstash

**Pipeline Script:**
```groovy
pipeline {
    agent any
    
    stages {
        stage('Generate motivational quotes..!!') {
            agent {
                label 'ubuntu-docker-jdk17-node18'
            }
            
            steps {
                script {
                    def quotes = '''
                        "The only way to do great work is to love what you do." - Steve Jobs
                        "Don't be afraid to give up the good to go for the great." - John D. Rockefeller
                        "Success is not final, failure is not fatal: it is the courage to continue that counts." - Winston Churchill
                    '''
                    
                    writeFile file: 'motivation.txt', text: quotes
                    stash 'motivation.txt'
                    
                    sh '''
                        cat motivation.txt
                    '''
                }
            }
        }
        
        stage('Display motivational quotes..!!') {
            steps {
                script {
                    unstash 'motivation.txt'
                    
                    sh '''
                        echo "#=#=#=#=#=#=#Today's motivation quotes are: #=#=#=#=#=#=#"
                        cat motivation.txt
                        rm motivation.txt
                        echo "******Removing file from current workspace*******"
                    '''
                }
            }
        }
    }
}
```

**Result:** ✅ Build passes successfully because:
- `stash 'motivation.txt'` saves the file from Stage 1
- `unstash 'motivation.txt'` retrieves the file in Stage 2
- Files are transferred between different agents

---

### Case 4: Stage Restart Issue

**Scenario:**
1. Complete pipeline runs successfully
2. Attempt to restart only Stage 2 ("Display motivational quotes..!!")

**Result:** ❌ Build fails because:
- When restarting from Stage 2, Stage 1 is skipped
- The stash created in Stage 1 is not available
- `unstash` command cannot find the stashed file

---

### Case 5: Preserving Stashes for Stage Restarts

**Pipeline Script:**
```groovy
pipeline {
    agent any
    
    options {
        preserveStashes buildCount: 5
    }
    
    stages {
        stage('Generate motivational quotes..!!') {
            agent {
                label 'ubuntu-docker-jdk17-node18'
            }
            
            steps {
                script {
                    def quotes = '''
                        "The only way to do great work is to love what you do." - Steve Jobs
                        "Don't be afraid to give up the good to go for the great." - John D. Rockefeller
                        "Success is not final, failure is not fatal: it is the courage to continue that counts." - Winston Churchill
                    '''
                    
                    writeFile file: 'motivation.txt', text: quotes
                    stash 'motivation.txt'
                    
                    sh '''
                        cat motivation.txt
                    '''
                }
            }
        }
        
        stage('Display motivational quotes..!!') {
            steps {
                script {
                    unstash 'motivation.txt'
                    
                    sh '''
                        echo "#=#=#=#=#=#=#Today's motivation quotes are: #=#=#=#=#=#=#"
                        cat motivation.txt
                        rm motivation.txt
                        echo "******Removing file from current workspace*******"
                    '''
                }
            }
        }
    }
}
```

**Key Addition:**
```groovy
options {
    preserveStashes buildCount: 5
}
```

**Result:** ✅ Build passes successfully, even when restarting only Stage 2 because:
- `preserveStashes` keeps stashes from the last 5 successful builds
- When restarting Stage 2, it can access the stash from the previous successful run
- Enables efficient debugging by allowing stage-specific restarts

## How to Configure `preserveStashes`

### Using Declarative Directive Generator:

1. Navigate to your Jenkins Pipeline job
2. Click **Pipeline Syntax** (available in the side menu)
3. Select **Declarative Directive Generator**
4. Under **Directive**, select **options**
5. Find **Preserve stashes from completed builds**
6. Set **Keep this many of the most recent builds' stashes** to your desired value (e.g., 5)
7. Click **Generate Declarative Directive**
8. Copy and paste the generated code into your pipeline

### Manual Configuration:

Add the following to your pipeline, within the `pipeline` block:

```groovy
options {
    preserveStashes buildCount: 5
}
```

## Best Practices

1. **Use descriptive stash names**: Use meaningful names for your stashes (e.g., `stash 'source-code'` instead of `stash 'files'`)

2. **Limit stash size**: Stash is designed for small files. For large artifacts, consider using the `archiveArtifacts` step or external storage.

3. **Clean up stashes**: The `preserveStashes` option automatically manages stash retention. Set an appropriate `buildCount` based on your needs.

4. **Consider when to use stash**:
   - When stages run on different agents
   - When you need to restart specific stages
   - When transferring small configuration or data files between stages

5. **Alternative approach**: For simple file sharing between stages on the same agent, you can use the `stash`/`unstash` pattern even without different agents.

## Troubleshooting

### Common Issues:

1. **"No such saved stash" error**: 
   - Ensure `stash` is executed before `unstash`
   - Check that the stash name matches exactly
   - Verify `preserveStashes` is configured if restarting stages

2. **Stash not available after restart**:
   - Increase the `buildCount` in `preserveStashes`
   - Ensure the previous build completed successfully

3. **Performance issues with large stashes**:
   - Consider compressing files before stashing
   - Evaluate if `archiveArtifacts` would be more appropriate
   - Check available disk space on Jenkins controller

## Conclusion

The `stash`/`unstash` mechanism is essential for sharing files between stages that run on different agents in Jenkins Pipeline. The `preserveStashes` option enhances this functionality by making stashes available for stage restarts, improving debugging efficiency and pipeline flexibility.

By implementing these patterns, you can create more robust and maintainable Jenkins Pipelines that work seamlessly across multiple agents and support efficient debugging workflows.