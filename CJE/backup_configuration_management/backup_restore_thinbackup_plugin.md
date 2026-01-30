# Jenkins Backup and Restore with ThinBackup Plugin

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Performing Backups](#performing-backups)
- [Restoring from Backup](#restoring-from-backup)
- [Backup Validation Techniques](#backup-validation-techniques)
- [Important Notes](#important-notes)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Quick Reference](#quick-reference)
- [References](#references)

## Overview

This guide provides comprehensive instructions for backing up and restoring Jenkins using the ThinBackup plugin. It includes detailed procedures for validation, troubleshooting, and best practices to ensure reliable backup and recovery of your Jenkins instance.

## Prerequisites

- Jenkins instance with administrative access
- Internet access to install plugins (or offline plugin installation)
- Sufficient disk space for backups
- Appropriate permissions to stop/start Jenkins service

## Installation

### Install ThinBackup Plugin

**Method 1: Via Jenkins UI**
1. Navigate to **Manage Jenkins** → **Plugins** → **Available Plugins**
2. Search for "ThinBackup" 
3. Select and install the plugin
4. Restart Jenkins if required

**Method 2: Manual Installation**
1. Download the plugin from [Official Plugin Page](https://plugins.jenkins.io/thinBackup/)
2. Go to **Manage Jenkins** → **Plugins** → **Advanced**
3. Upload the `.hpi` file under "Deploy Plugin"
4. Restart Jenkins

## Configuration

### 1. Configure Backup Settings
1. Navigate to **Manage Jenkins** → **System** → **ThinBackup Configuration**
2. Set the following parameters:

| Parameter | Recommended Value | Description |
|-----------|------------------|-------------|
| Backup directory | `/var/lib/jenkins/fullbackup_thinbackup_plugin` | Directory where backups will be stored |
| Backup schedule | Daily/Weekly based on needs | Frequency of automatic backups |
| Backup build results | **Disable for space saving** | Includes build history (significantly increases size) |
| Max backup age | 30-90 days | How long to keep old backups |
| Files excluded from backup | Optional | Patterns to exclude specific files |

3. Click **Save & Apply**

### 2. Backup Build Results Option
⚠️ **Important Decision Point:**
- **Enabled**: All build history and artifacts are backed up (requires significant storage)
- **Disabled**: Only job configurations are backed up (build history will be lost on restore)

**Recommendation:** Enable only if you have sufficient storage and need to preserve build history. Otherwise, rely on job configurations only.

## Performing Backups

### Manual Backup

1. Navigate to **Manage Jenkins** → **Tools and Actions** → **ThinBackup**
2. Click **Backup Now**
3. Monitor progress in **Manage Jenkins** → **System Log** → **All Jenkins Logs**

### Automated Backups
Configure in **ThinBackup Configuration** section:
- Set backup schedule (daily/weekly)
- Choose full/differential backup options
- Set retention policy

### Sample Backup Logs

```
Jan 11, 2026 9:45:24 PM INFO org.jvnet.hudson.plugins.thinbackup.ThinBackupMgmtLink doBackupManual
Starting manual backup.
Jan 11, 2026 9:45:25 PM INFO org.jvnet.hudson.plugins.thinbackup.backup.HudsonBackup 
No previous full backup found, thus creating one.
Jan 11, 2026 9:45:25 PM INFO org.jvnet.hudson.plugins.thinbackup.backup.HudsonBackup backupJobsDirectory
Found 22 jobs in /var/lib/jenkins/jobs to back up.
...
Jan 11, 2026 9:46:22 PM INFO org.jvnet.hudson.plugins.thinbackup.ThinBackupPeriodicWork backupNow
Backup process finished successfully.
```

### Verify Backup Files

```bash
# Check backup directory structure
cd /var/lib/jenkins
ls -ldh fullbackup_thinbackup_plugin/
# Output: drwxr-xr-x 3 jenkins jenkins 4.0K Jan 11 21:45 fullbackup_thinbackup_plugin/

# View backup folders
cd fullbackup_thinbackup_plugin/
ls
# Output: FULL-2026-01-11_21-45

# Examine backup contents
cd FULL-2026-01-11_21-45/
ls -al
```

### Backup Directory Structure

A complete backup includes:
```
├── config.xml                    # Main Jenkins configuration
├── credentials.xml              # Encrypted credentials
├── installedPlugins.xml         # Plugin inventory
├── jobConfigHistory.xml         # Job configuration history
├── jobs/                        # All job configurations
│   ├── job1/
│   ├── job2/
│   └── ...
├── nodes/                       # Agent/node configurations
├── users/                       # User accounts and settings
├── audit-trail.xml             # Audit logs
└── *.xml                        # Various plugin configurations
```

## Restoring from Backup

### Example Test Scenario
Before testing restore functionality:
1. **Identify a test job** (e.g., "monitor-jenkins-grafana-prometheus")
2. **Note its content:**
   ```groovy
   node('ubuntu-docker-jdk17-node18') {
       stage('Hello from ubuntu agent..!!') {
           sh 'echo "Using jenkins slave node to run a job"'
       }
   }
   
   node {
       stage('Hello from controller agent..!!') {
           sh 'echo "Using controller to run a job"'
       }
   }
   ```
3. Take a backup
4. Delete the test job
5. Perform restore to verify recovery

### Restore Procedure

1. Navigate to **Manage Jenkins** → **Tools and Actions** → **ThinBackup**
2. Click **Restore**
3. Select the backup date/time from the dropdown
4. Click **Restore**
5. **Jenkins will restart automatically** - this is expected

### Sample Restore Logs

```
Jan 11, 2026 10:02:53 PM INFO org.jvnet.hudson.plugins.thinbackup.ThinBackupMgmtLink doRestore
Starting restore operation.
Jan 11, 2026 10:02:55 PM INFO org.jvnet.hudson.plugins.thinbackup.restore.HudsonRestore restore
Restore completed successfully.
Jan 11, 2026 10:02:55 PM INFO org.jvnet.hudson.plugins.thinbackup.ThinBackupMgmtLink doRestore
Restore finished.
```

### Post-Restore Verification

1. **Check restored items:**
   - Verify the deleted test job has been restored
   - Confirm all job configurations are intact
   - Check build history (if backup included build results)

2. **System verification:**
   - Login with existing credentials
   - Check plugin functionality
   - Verify agent connections

## Backup Validation Techniques

### Method 1: Change Jenkins Home Directory and Port (Comprehensive Test)

This method validates backup integrity by running Jenkins from a backup location on a different port.

#### Step-by-Step Procedure:

1. **Stop Jenkins Service:**
   ```bash
   sudo systemctl stop jenkins
   sudo systemctl disable jenkins
   ```

2. **Copy Jenkins Data:**
   ```bash
   # Copy with progress tracking
   rsync -avh --progress /var/lib/jenkins/ /tmp/jenkins/
   
   # Or using cp with verbose output
   cp -rv /var/lib/jenkins /tmp/
   
   # Fix ownership
   chown -R jenkins:jenkins /tmp/jenkins
   ```

3. **Run Jenkins Manually with New Settings:**
   ```bash
   # Set custom home directory
   export JENKINS_HOME=/tmp/jenkins
   
   # Run Jenkins on alternate port
   java -jar /usr/share/java/jenkins.war --httpPort=1234
   
   # Alternative with more options:
   # java -jar /usr/share/java/jenkins.war --httpPort=1234 --prefix=/jenkins
   ```

4. **Verification Steps:**
   - Access Jenkins at `http://localhost:1234`
   - Login with existing user credentials
   - Navigate to **Manage Jenkins** → **System Information**
   - Verify `JENKINS_HOME` shows `/tmp/jenkins`
   - Check all jobs, configurations, and plugins are present
   - Test a sample job execution

5. **Expected Log Output:**
   ```
   2026-01-11 15:06:19.623+0000 [id=1] INFO hudson.WebAppMain#contextInitialized: 
   Jenkins home directory: /tmp/jenkins found at: EnvVars.masterEnvVars.get("JENKINS_HOME")
   
   2026-01-11 15:06:19.797+0000 [id=1] INFO o.e.j.server.AbstractConnector#doStart: 
   Started ServerConnector@17d2ed1b{HTTP/1.1, (http/1.1)}{0.0.0.0:1234}
   ```

6. **Cleanup:**
   ```bash
   # Stop Jenkins (Ctrl+C in terminal)
   # Remove temporary directory
   rm -rf /tmp/jenkins
   
   # Re-enable original Jenkins
   sudo systemctl enable jenkins
   sudo systemctl start jenkins
   ```

### Method 2: Determine Current JENKINS_HOME

Use these methods to check where Jenkins is currently configured to store data:

#### a) Environment Variable Check
```bash
echo $JENKINS_HOME
# If empty, Jenkins is using default location
```

#### b) Systemd Service Configuration
```bash
systemctl show jenkins | grep -i environment
# Output: Environment=JENKINS_HOME=/var/lib/jenkins ...
```

#### c) Configuration File Check
```bash
cat /etc/default/jenkins | grep JENKINS_HOME
```

#### d) Jenkins Web UI
- Navigate to **Manage Jenkins** → **System Information**
- Search for `JENKINS_HOME` in the environment variables section

#### e) Process Inspection
```bash
ps -ef | grep jenkins
# Check the command line arguments for home directory
```

#### f) Find Jenkins WAR Location
```bash
# On Debian/Ubuntu systems:
dpkg -L jenkins | grep jenkins.war
# Output: /usr/share/java/jenkins.war

# Alternative:
find / -name "jenkins.war" 2>/dev/null
```

## Important Notes

### Critical Configuration Points

1. **Build Results Decision:**
   - **Enabled**: Backups include all build history, artifacts, logs
   - **Disabled**: Only configuration files are backed up
   - **Recommendation**: Schedule full backups (with builds) weekly and differential backups (config only) daily

2. **Port Change Considerations:**
   ⚠️ **When changing ports for validation:**
   - Ensure the port (e.g., 1234) is not in use
   - Update firewall rules if necessary
   - Consider security implications of running on non-standard ports
   - Remember that manual runs are temporary and stop when terminal closes

3. **Ownership and Permissions:**
   ```bash
   # Critical: Backup directory must be owned by jenkins user
   chown -R jenkins:jenkins /path/to/backup/directory
   
   # Verify permissions
   ls -ld /var/lib/jenkins/fullbackup_thinbackup_plugin/
   # Should show: drwxr-xr-x jenkins jenkins
   ```

4. **Systemd vs Manual Execution:**
   ```
   systemctl show jenkins        → Shows active runtime environment
   /etc/default/jenkins          → Defines startup configuration
   
   Manual run: java -jar /usr/share/java/jenkins.war --httpPort=1234
   Permanent: Edit /etc/default/jenkins and restart via systemctl
   ```

### Log Monitoring Locations

- **Backup/Restore Logs**: Manage Jenkins → System Log → All Jenkins Logs
- **Service Logs**: `journalctl -u jenkins.service`
- **Manual Run Logs**: Output directly in terminal
- **Access Logs**: `/var/log/jenkins/jenkins.log`

## Troubleshooting

### Common Issues and Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Permission Denied** | Backup fails, access errors | `chown -R jenkins:jenkins /backup/path` |
| **Insufficient Space** | Backup incomplete, errors | Free up disk space, check with `df -h` |
| **Silent Backup Failure** | No visible error, no backup | Check system logs, verify plugin is enabled |
| **Restore Doesn't Work** | Jenkins doesn't restart properly | Check service status: `systemctl status jenkins` |
| **Port Already in Use** | Manual run fails on port binding | Use different port: `--httpPort=1235` |
| **Wrong JENKINS_HOME** | Manual run uses wrong directory | Explicitly set: `export JENKINS_HOME=/correct/path` |

### Diagnostic Commands

```bash
# Check service status
sudo systemctl status jenkins

# View detailed service configuration
systemctl show jenkins

# Check disk space
df -h /var/lib/jenkins

# Verify file ownership
ls -la /var/lib/jenkins/fullbackup_thinbackup_plugin/

# Test port availability
netstat -tuln | grep :8080
netstat -tuln | grep :1234
```

### Log Analysis Tips

1. **Backup Logs**: Look for "Backup process finished successfully"
2. **Restore Logs**: Look for "Restore completed successfully"
3. **Error Patterns**: Search for "ERROR", "Exception", "Failed"
4. **Timing Issues**: Check for timeouts or interrupted operations

## Best Practices

### 1. Backup Strategy
- **Frequency**: Daily for configurations, weekly for full backups
- **Retention**: Keep 30 days of daily, 12 months of monthly backups
- **Verification**: Monthly restore tests in isolated environment
- **Documentation**: Maintain restore procedure documentation

### 2. Storage Considerations
- **Location**: Store backups on separate physical storage
- **Encryption**: Encrypt backups containing sensitive credentials
- **Monitoring**: Set up alerts for backup failures
- **Testing**: Regularly test backup integrity

### 3. Operational Guidelines
- **Change Management**: Always backup before major changes
- **Version Control**: Keep Jenkins configuration in version control (Job DSL, JCasC)
- **Documentation**: Document all custom configurations
- **Training**: Train multiple team members on restore procedures

### 4. Recovery Planning
- **RTO/RPO**: Define Recovery Time and Point Objectives
- **Procedure Documentation**: Step-by-step restore instructions
- **Contact Information**: Maintain vendor/team contact details
- **Alternative Methods**: Know manual recovery options

## Quick Reference

### Essential Commands

```bash
# Backup Operations
cd /var/lib/jenkins/fullbackup_thinbackup_plugin
ls -la                          # List available backups

# Service Management
sudo systemctl stop jenkins     # Stop Jenkins service
sudo systemctl start jenkins    # Start Jenkins service
sudo systemctl restart jenkins  # Restart Jenkins service
sudo systemctl status jenkins   # Check service status

# Manual Validation
export JENKINS_HOME=/tmp/jenkins
java -jar /usr/share/java/jenkins.war --httpPort=1234

# Permission Management
chown -R jenkins:jenkins /path/to/jenkins/data
chmod 755 /path/to/backup/directory

# Diagnostic Commands
ps -ef | grep jenkins           # Find Jenkins process
systemctl show jenkins         # Show service environment
df -h /var/lib/jenkins         # Check disk space
```

### Configuration File Locations
- **Jenkins Home**: `/var/lib/jenkins/` (default on Ubuntu/Debian)
- **Service Config**: `/etc/default/jenkins`
- **WAR File**: `/usr/share/java/jenkins.war`
- **Logs**: `/var/log/jenkins/`

### Critical Files to Monitor
- `config.xml` - Core configuration
- `credentials.xml` - Encrypted credentials
- `hudson.model.UpdateCenter.xml` - Update center configuration
- `jenkins.model.JenkinsLocationConfiguration.xml` - Jenkins URL settings

## References

### Official Documentation
- [ThinBackup Plugin Documentation](https://plugins.jenkins.io/thinBackup/)
- [Jenkins Backup Best Practices](https://www.jenkins.io/doc/book/system-administration/backing-up/)
- [System Administration Guide](https://www.jenkins.io/doc/book/system-administration/)

### Alternative Backup Plugins
1. **Periodic Backup**: Simple scheduled backups
2. **Backup Plugin**: More configuration options
3. **Configuration as Code (JCasC)**: Infrastructure as code approach

### Related Resources
- [Jenkins Hardening Guide](https://www.jenkins.io/doc/book/security/)
- [Disaster Recovery Planning](https://www.jenkins.io/doc/book/scaling/disaster-recovery/)
- [Performance Tuning](https://www.jenkins.io/doc/book/scaling/performance-tuning/)

---

## 📝 Final Checklist

### Before Production Implementation
- [ ] Test backup/restore in non-production environment
- [ ] Document restore procedure specific to your environment
- [ ] Set up monitoring for backup jobs
- [ ] Train team members on restore process
- [ ] Establish backup retention policy
- [ ] Configure appropriate permissions
- [ ] Test with actual data size
- [ ] Validate off-site backup strategy

### Regular Maintenance Tasks
- [ ] Monthly backup integrity tests
- [ ] Quarterly restore drills
- [ ] Biannual review of backup strategy
- [ ] Annual disaster recovery testing

---

*Last Updated: January 2026*  
*Tested with: Jenkins 2.516.2, ThinBackup Plugin 1.11*  
*Applicable to: Ubuntu/Debian systems, may vary for other distributions*

⚠️ **Disclaimer**: Always test backup and restore procedures in a non-production environment before implementing in production. Regular testing is crucial for ensuring recoverability.