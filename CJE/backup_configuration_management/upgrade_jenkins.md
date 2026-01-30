# Demo: Upgrading Jenkins

This repository documents a hands-on demonstration of upgrading a Jenkins instance. It includes step-by-step instructions, references to official documentation, and practical commands used during the upgrade process.

## 📋 Overview
This demo covers the process of upgrading Jenkins from version `2.516.2` to `2.528.3` on a Linux system. The upgrade involves:
- Checking for new versions
- Preparing Jenkins for shutdown
- Replacing the Jenkins WAR file
- Restarting the service

## 🔗 Official Documentation References
- [Jenkins Download Page](https://www.jenkins.io/download/)
- [Jenkins Changelog (Stable)](https://www.jenkins.io/changelog-stable/)
- [Jenkins WAR Stable Releases](https://get.jenkins.io/war-stable/)

## 📁 File Sources for New Version
- https://get.jenkins.io/war-stable/2.528.3/
- https://mirrors.huaweicloud.com/jenkins/war-stable/2.528.3/
- https://mvnrepository.com/search?q=jenkins
- https://mvnrepository.com/artifact/org.jenkins-ci.main/jenkins-war/2.528.3
- https://repo.jenkins-ci.org/releases/org/jenkins-ci/main/jenkins-war/2.528.3/

## 🚀 Upgrade Procedure

### 1. Check Current Version & Notifications
- Navigate to **Manage Jenkins** → Look for notifications
- Example notification: `New version of Jenkins (2.528.3) is available for download (changelog)`
- Note current version (e.g., `2.516.2`)
- Review changelog for security updates, bug fixes, and enhancements

### 2. Identify Running Jenkins Process
```bash
ps -ef | grep jenkins
# OR
ps aux | grep jenkins
```
Example output:
```
jenkins    302       1 13 06:29 ?        00:03:16 /usr/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.war --webroot=/var/cache/jenkins/war --httpPort=8080
```

### 3. Prepare for Shutdown
- Go to **Manage Jenkins** → **Prepare for Shutdown**
- Enter reason: "Planning for an upgrade"
- This prevents new builds from starting while allowing current jobs to complete
- Any new builds will queue with message: "Jenkins is about to shutdown"

### 4. Stop Jenkins Service
```bash
systemctl stop jenkins
```

### 5. Backup and Replace WAR File
```bash
cd /usr/share/java/
ls  # Verify current WAR file
rm -rf jenkins.war  # Remove old WAR file
wget https://get.jenkins.io/war-stable/2.528.3/jenkins.war
```

### 6. Start Jenkins Service
```bash
systemctl start jenkins
```

### 7. Verify Upgrade
- Access Jenkins web interface
- Confirm version is now `2.528.3`
- "Prepare for shutdown" banner should be gone
- Queue should be processing normally

## 📝 Key Considerations
1. **Timing**: Schedule upgrades during maintenance windows
2. **Backup**: Consider backing up Jenkins configuration (`JENKINS_HOME`) before upgrade
3. **Plugins**: Some upgrades may require plugin updates
4. **Testing**: Test critical jobs after upgrade completion

## 🛠️ Commands Summary
```bash
# Check current process
ps -ef | grep jenkins

# Stop service
systemctl stop jenkins

# Navigate to WAR location and replace
cd /usr/share/java/
rm -rf jenkins.war
wget https://get.jenkins.io/war-stable/2.528.3/jenkins.war

# Start service
systemctl start jenkins
```

## ✅ Verification
- **Before upgrade**: Version 2.516.2
- **After upgrade**: Version 2.528.3
- All existing jobs completed before shutdown
- New jobs can be triggered normally after restart

## 📚 Additional Resources
- [Jenkins Upgrade Guide](https://www.jenkins.io/doc/upgrade-guide/)
- [Jenkins Backup and Restore](https://www.jenkins.io/doc/book/system-administration/backing-up/)
- [Jenkins Installation](https://www.jenkins.io/doc/book/installing/)

---
*Note: Always test upgrades in a staging environment before applying to production.*