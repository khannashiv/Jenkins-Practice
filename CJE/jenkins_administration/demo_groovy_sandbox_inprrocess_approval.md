# Jenkins Groovy Sandbox & In-process Script Approval Demo

## Overview
This documentation covers a three-part demonstration of Jenkins Groovy Sandbox functionality and the In-process Script Approval system. The demo explores how Jenkins secures pipeline execution by restricting certain Groovy methods and how administrators can approve scripts for execution.

## Prerequisites
- Jenkins instance with Pipeline plugin installed
- Script Security plugin (usually comes bundled with Jenkins)
- Basic understanding of Jenkins pipeline syntax

## Part 1: Basic Sandbox Configuration

### Step 1: Create Pipeline Project
1. Create a new pipeline project named "Groovy-Sandbox"
2. Use the following sample pipeline code:
```groovy
pipeline {
    agent any
    stages {
        stage ('Topic') {
            steps {
                echo "Exploring Groovy Sandbox."   
            }
        }
    }
}
```

3. **Important**: Uncheck the "Use Groovy Sandbox" option in the pipeline configuration

### Step 2: Initial Error Encounter
When running the pipeline without sandbox, you'll encounter:
```
org.jenkinsci.plugins.scriptsecurity.scripts.UnapprovedUsageException: script not yet approved for use
at PluginClassLoader for script-security//
org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval.using(ScriptApproval.java:695)
```

### Step 3: Script Approval
1. Navigate to: **Manage Jenkins** → **Security** → **In-process Script Approval**
2. Click **Approve** for the pending script
3. Re-run the pipeline - it should now succeed

**Note**: Any modifications to the pipeline will require re-approval

## Part 2: Sandbox Configuration Management

### Disabling Sandbox UI Option
1. Navigate to: **Manage Jenkins** → **Security** → **Pipeline sandbox**
2. Check "Enable script security for Pipeline"
3. The "Use Groovy Sandbox" checkbox will no longer appear in job configurations

### Global Sandbox Enforcement
To enforce sandbox usage globally:
1. Navigate to: **Manage Jenkins** → **Security** → **Pipeline sandbox**
2. Enable "Force the use of the sandbox globally in the system"

## Part 3: Whitelist vs Blacklist Methods

### Understanding Method Restrictions
The Script Security Plugin maintains:
- **Whitelists**: Allowed methods/signatures
  - `jenkins-whitelist`: Jenkins-specific allowed APIs
  - `generic-whitelist`: General Groovy/Java allowed APIs
- **Blacklist**: Blocked methods requiring explicit approval

### Testing Blacklisted Methods

#### Example 1: Get Hudson Instance
Add this stage to your pipeline:
```groovy
stage ('Get Hudson Instance') {
    steps {
        script {
            def myInstance = hudson.model.Hudson.getInstance()
            println "Hudson Instance: ${myInstance}"
        }   
    }
}
```

**Error encountered** (even with "Use Groovy Sandbox" enabled):
```
Scripts not permitted to use staticMethod hudson.model.Hudson getInstance. 
Script signature is not in the default whitelist.
```

**Resolution**: Approve via **Manage Jenkins** → **Script Approval**

#### Example 2: System Properties
Add another blacklisted method:
```groovy
stage ('System Properties') {
    steps {
        script {
            def sysProps = java.lang.System.getProperties()
            println "System properties: ${sysProps}"
        }   
    }
}
```

**Error**:
```
Scripts not permitted to use staticMethod java.lang.System getProperties. 
Script signature is not in the default whitelist.
```

**Resolution**: Approve via **Manage Jenkins** → **Script Approval**

## Complete Pipeline Example
```groovy
pipeline {
    agent any
    stages {
        stage ('Topic') {
            steps {
                echo "Exploring Groovy Sandbox.!!!"   
            }
        }
        stage ('Get Hudson Instance') {
            steps {
                script {
                    def myInstance = hudson.model.Hudson.getInstance()
                    println "Hudson Instance: ${myInstance}"
                }   
            }
        }
        stage ('System Properties') {
            steps {
                script {
                    def sysProps = java.lang.System.getProperties()
                    println "System properties: ${sysProps}"
                }   
            }
        }
    }
}
```

## Important Notes

1. **Sandbox Behavior**: Even with "Use Groovy Sandbox" enabled, blacklisted methods still require approval
2. **Approval Persistence**: Approved scripts persist across Jenkins restarts
3. **Security Implications**: Be cautious when approving scripts - understand what each method does
4. **Performance**: Script approval adds a layer of security but may impact pipeline startup time

## Official Documentation
- [Jenkins Script Security Documentation](https://www.jenkins.io/doc/book/managing/script-approval/)
- [Script Security Plugin GitHub Repository](https://github.com/jenkinsci/script-security-plugin/tree/master)

## Troubleshooting
- If scripts fail after approval, check Jenkins logs for detailed errors
- Ensure all required methods are approved for complex pipelines
- Review the blacklist file in the plugin repository for restricted methods

## Best Practices
1. Always use the Groovy Sandbox when possible
2. Review and understand what each blacklisted method does before approving
3. Regularly audit approved scripts
4. Consider implementing additional security measures like Pipeline Shared Libraries for reusable code

---

*This demo demonstrates the balance between security and flexibility in Jenkins pipeline execution, showing how administrators can control what scripts are allowed to run while maintaining system security.*