Here's a clean `README.md` file based on your content:

```markdown
# Jenkins Audit Trail Plugin Demo

## Overview
This document provides a guide for installing and configuring the Jenkins Audit Trail plugin to track user activities within Jenkins.

## Official Documentation
- **Plugin Page**: https://plugins.jenkins.io/audit-trail/
- **Java FileHandler API**: https://docs.oracle.com/javase/7/docs/api/java/util/logging/FileHandler.html

## Plugin Description
The Audit Trail plugin maintains a comprehensive log of user-performed operations in Jenkins, including job configuration changes and other administrative actions.

## Supported Logger Types
- **File Logger**: Outputs audit logs to rolling files
- **Syslog Logger**: Sends audit logs to a Syslog server
- **Console Logger**: Outputs audit logs to stdout/stderr (primarily for debugging)
- **Elastic Search Logger**: Sends audit logs to an Elastic Search server

## Installation & Configuration

### Step 1: Install the Plugin
Install the Audit Trail plugin through the Jenkins plugin manager.

### Step 2: Configure the Plugin
1. Navigate to **Manage Jenkins** → **System**
2. Locate and click on **Audit Trail**
3. Click **Add Logger**
4. Select **Log file daily rotation** with the following settings:
   - **Log count**: 10
   - **Log location**: `/var/log/jenkins/audit-%g.log`
5. Under **Advanced Settings**, check **Display Username instead of UserID**
6. Click **Save & Apply**

## Demonstration

### Test Pipeline Configuration
For testing purposes, we'll modify the `monitor-jenkins-grafana-prometheus` job pipeline to a simple Hello World script:

```groovy
pipeline {
    agent any

    stages {
        stage('Hello') {
            steps {
                echo 'Hello World'
            }
        }
    }
}

//  node('ubuntu-docker-jdk17-node18') {
//      stage('Hello from ubntu agent..!!') {
//          sh 'echo "Using jenkins slave node to run a job"'
//      }
//  }

// node {
//     stage('Hello from controller agent..!!') {
//          sh 'echo "Using controller to run a job"'
//     }
// }
```

### Verify Audit Logs
After making the configuration changes and running the job:

1. Navigate to the log directory: `/var/log/jenkins`
2. You should see audit log files (e.g., `audit-0.log-2026-01-08` and `audit-0.log-2026-01-08.lck`)
3. Examine the log contents:

```bash
$ cat audit-0.log-2026-01-08
```

### Sample Audit Log Output
The audit log captures detailed information about user actions:

```
Jan 8, 2026 12:28:02,611 AM/job/monitor-jenkins-grafana-prometheus/configSubmit by user2 from [0:0:0:0:0:0:0:1]
Jan 8, 2026 12:28:02,664 AM/job/monitor-jenkins-grafana-prometheus/configSubmit by user2 from [0:0:0:0:0:0:0:1]
Jan 8, 2026 12:28:04,789 AMjob/monitor-jenkins-grafana-prometheus/ #49 Started by user user2, Parameters:[]
Jan 8, 2026 12:30:45,795 AMmonitor-jenkins-grafana-prometheus #49 Started by user user2, Parameters:[] on Built-In Node;Slave-Agent-Node-1 started at 2026-01-07T18:58:04Z completed in 160980ms completed: SUCCESS
```

## Key Information Captured
- User who performed the action
- Type of action (configSubmit, job start, etc.)
- Timestamp of the action
- Source IP address
- Job/build details
- Success/failure status

## Benefits
- **Security**: Track who made changes to Jenkins configurations
- **Compliance**: Maintain audit records for regulatory requirements
- **Troubleshooting**: Identify when and by whom changes were made
- **Accountability**: Establish clear user responsibility for actions

---
*Note: Ensure proper log rotation and security measures are in place for audit logs, as they may contain sensitive information.*
```