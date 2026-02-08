# Jenkins Introduction & Administration Guide

## Overview
This repository contains a collection of Jenkins scripts, installation guides, and administration tips for managing Jenkins instances.

## Official Jenkins Resources
- **Official Jenkins Scripts Repository**: https://github.com/jenkinsci/jenkins-scripts
- **Scriptler Scripts**: https://github.com/jenkinsci/jenkins-scripts/blob/main/scriptler/countExecutors.groovy
- **Console Scripts Collection**: https://github.com/samrocketman/jenkins-script-console-scripts

## Installation & Configuration

### Prerequisites
```bash
# Check if port 8080 is in use
sudo ss -tulpn | grep :8080
```

### Installation on Debian/Ubuntu
Follow the official installation guide: https://www.jenkins.io/doc/book/installing/linux/#debianubuntu

### Java Support Policy
Ensure Java compatibility: https://www.jenkins.io/doc/book/platform-information/support-policy-java/

### Changing Jenkins Port
1. Create systemd override directory:
   ```bash
   sudo mkdir -p /etc/systemd/system/jenkins.service.d
   ```

2. Create override configuration:
   ```bash
   sudo nano /etc/systemd/system/jenkins.service.d/override.conf
   ```
   
   Add the following content:
   ```
   [Service]
   Environment="JENKINS_PORT=8085"
   ```

3. Apply changes:
   ```bash
   # Verify configuration
   sudo cat /etc/systemd/system/jenkins.service.d/override.conf
   
   # Reload systemd and restart Jenkins
   sudo systemctl daemon-reload
   sudo systemctl restart jenkins
   
   # Verify Jenkins is running on port 8085
   sudo systemctl status jenkins
   sudo ss -tulpn | grep 8085
   ```

## JVM Tuning & Optimization

### Reference Documentation
- **Systemd Services**: https://www.jenkins.io/doc/book/system-administration/systemd-services/
- **JVM Memory Best Practices**: https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/best-practices/jvm-memory-settings-best-practice
- **JVM Troubleshooting**: https://docs.cloudbees.com/docs/cloudbees-ci/latest/jvm-troubleshooting/#_heap_size

### Common Commands
```bash
# Edit Jenkins service configuration
systemctl edit jenkins

# Restart Jenkins
systemctl restart jenkins

# View Jenkins logs
journalctl -u jenkins

# Check Jenkins process
ps aux | grep -i jenkins
```

## Manual WAR File Installation
```bash
# Download Jenkins WAR file
wget <endpoint-of-war-file>

# Run Jenkins with custom port and prefix
java -jar jenkins.war --httpPort=1234 --prefix=/demo

# Check the process
ps aux | grep -i jenkins
```

**Note**: Manual installation generates a default admin password.

## Useful Jenkins Plugins

### 1. Build Timeout Plugin
- **Purpose**: Automatically terminate builds that exceed time limits
- **Pipeline Alternative**: Use `timeout` step in Pipeline scripts
- **References**:
  - Plugin: https://plugins.jenkins.io/build-timeout/
  - GitHub: https://github.com/jenkinsci/build-timeout-plugin

### 2. Timestamper Plugin
- **Purpose**: Add timestamps to build console output
- **References**:
  - Plugin: https://plugins.jenkins.io/timestamper/
  - Date Format: https://docs.oracle.com/javase/8/docs/api/java/text/SimpleDateFormat.html

### 3. Copy Artifact Plugin
- **Purpose**: Copy artifacts between jobs
- **Plugin**: https://plugins.jenkins.io/copyartifact/

### 4. Yet Another Build Visualizer
- **Purpose**: Enhanced build visualization
- **References**:
  - Plugin: https://plugins.jenkins.io/yet-another-build-visualizer/
  - Releases: https://plugins.jenkins.io/yet-another-build-visualizer/releases/

## WSL Installation Fix

If Jenkins fails on WSL due to Java version issues:

1. Install OpenJDK 17:
   ```bash
   sudo apt update
   sudo apt install openjdk-17-jdk -y
   ```

2. Find Java installation path:
   ```bash
   update-alternatives --config java
   # Example path: /usr/lib/jvm/java-17-openjdk-amd64/bin/java
   ```

3. Configure Jenkins to use the correct Java:
   ```bash
   sudo nano /etc/default/jenkins
   # Add: JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
   ```

4. Apply changes:
   ```bash
   sudo systemctl daemon-reexec
   sudo systemctl restart jenkins
   sudo systemctl status jenkins
   ```

5. Verify installation: `http://localhost:8080`

## Example Freestyle Project Script

```bash
#!/bin/bash

# Build Stage

# Fix PATH for Jenkins (includes /usr/games for cowsay)
export PATH=$PATH:/usr/games:/usr/local/games

# Fetch advice from API
curl -s https://api.adviceslip.com/advice > advice.json

# Extract advice text
jq -r .slip.advice advice.json > advice.message

# Test Stage - Check word count
word_count=$(wc -w < advice.message)

if [ $word_count -gt 5 ]; then
  echo "Advice has more than 5 words"
else
  echo "Advice $(cat advice.message) has 5 words or less"
fi

# Deploy Stage - Display with cowsay
# Ensure cowsay is installed
if ! command -v cowsay &> /dev/null; then
  echo "Error: cowsay is not installed. Please run: sudo apt-get install cowsay -y"
  exit 1
fi

# Display advice with random cow
echo $PATH
cat advice.message | cowsay -f $(ls /usr/share/cowsay/cows | shuf -n 1)
```

## Additional Resources
- **Stable WAR Downloads**: https://get.jenkins.io/war-stable/
- **Initial Settings**: https://www.jenkins.io/doc/book/installing/initial-settings/

## Best Practices
1. Always use supported Java versions with Jenkins
2. Configure JVM memory settings appropriately for your workload
3. Use plugins to extend functionality when needed
4. Implement build timeouts to prevent resource exhaustion
5. Chain projects using the Copy Artifact plugin for complex workflows

---

*Note: This documentation is based on official Jenkins resources and community best practices. Always refer to official documentation for production deployments.*