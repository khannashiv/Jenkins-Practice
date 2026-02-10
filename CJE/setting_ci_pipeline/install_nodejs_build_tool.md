# Jenkins Node.js Integration Guide

This document explains how to set up Node.js as a build tool within Jenkins and addresses common version discrepancies between Jenkins jobs and the system.

## Overview

When working with Node.js in Jenkins, you may encounter version inconsistencies between what's available on your system and what Jenkins uses during builds. This guide covers both setup and troubleshooting.

## Prerequisites

- Jenkins installed and running
- Basic knowledge of Jenkins configuration
- Access to Jenkins administration panel

## Installation Steps

### Step 1: Install Node.js Plugin
1. Navigate to **Manage Jenkins** → **Plugins**
2. Go to **Available plugins** tab
3. Search for "NodeJS" plugin
4. Install the plugin and restart Jenkins if required

### Step 2: Configure Node.js Tool
1. Navigate to **Manage Jenkins** → **Tools**
2. Scroll to **NodeJS installations** section
3. Click **Add NodeJS**
4. Configure the installation:
   - **Name**: Give a descriptive name (e.g., "NodeJS-18")
   - **Version**: Select desired version from the dropdown
   - **Global npm packages**: Optional - add packages to install globally
   - **Install automatically**: Keep checked
5. Click **Save**

### Step 3: Use Node.js in Jenkins Job
1. Create or edit a Jenkins job
2. In **Build Environment** section
3. Check **Provide Node & npm bin/ folder to PATH**
4. Select the Node.js installation name configured in Step 2
5. Configure your build steps to use Node.js/npm

## Common Issue: Version Mismatch

### Problem Description
Your system shows Node.js v24.7.0, but Jenkins jobs use v18.19.1.

### Root Cause
The discrepancy occurs because:
- **Your user session** uses Node.js installed via NVM (Node Version Manager)
- **Jenkins service** runs under a different user (typically root or jenkins user) that doesn't load NVM configurations
- Jenkins uses system-wide Node.js installation instead of NVM-managed versions

### Verification Commands
```bash
# Check your user's Node.js version
node -v  # Shows v24.7.0 (NVM installation)
npm -v   # Shows 11.5.1

# Check system/root user Node.js version
sudo node -v  # Shows v18.19.1 (system installation)
sudo npm -v   # Shows 9.2.0
```

### Why This Happens
| Context | Node Path | Version | Explanation |
|---------|-----------|---------|-------------|
| Your user (`ubuntu`) | `/home/ubuntu/.nvm/versions/node/v24.7.0/bin/node` | v24.7.0 | Uses NVM which modifies PATH only for your user shell |
| Root/Jenkins service user | `/usr/bin/node` | v18.19.1 | Uses system-wide Node.js available globally |

### Solutions

#### Solution 1: Use Jenkins Node.js Plugin (Recommended)
Configure Node.js through the Jenkins plugin as described in the installation steps above. This ensures:
- Consistent Node.js versions across all builds
- Version management through Jenkins UI
- Isolation from system Node.js installations

#### Solution 2: Install Node.js System-Wide
If you want Jenkins to use v24.7.0:
```bash
# Remove existing system Node.js (if needed)
sudo apt remove nodejs npm

# Install Node.js v24.x using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
sudo node -v  # Should show v24.x.x
```

#### Solution 3: Configure Jenkins to Use NVM (Advanced)
1. Modify Jenkins service to run as your user:
   ```bash
   sudo systemctl edit jenkins
   ```
   Add:
   ```
   [Service]
   User=ubuntu
   Group=ubuntu
   ```
2. Restart Jenkins:
   ```bash
   sudo systemctl restart jenkins
   ```
3. Configure NVM in Jenkins global environment variables

## Best Practices

1. **Use Jenkins Node.js Plugin**: For consistent build environments
2. **Version Pinning**: Specify exact Node.js versions in your project's `package.json`
3. **`.nvmrc` File**: Create an `.nvmrc` file in your repository with the required Node.js version
4. **Node Version in Jenkinsfile**: Explicitly declare Node.js version in pipeline scripts
5. **Regular Updates**: Keep Jenkins Node.js plugin and installed versions updated

## Troubleshooting

### Jenkins Doesn't Show Node.js Option
- Ensure Node.js plugin is installed and Jenkins is restarted
- Check plugin compatibility with your Jenkins version

### Build Still Uses Wrong Version
- Verify Jenkins job configuration has correct Node.js version selected
- Check "Global Properties" for any overriding configurations
- Review Jenkins environment variables

### Permission Issues
- Ensure Jenkins user has execute permissions for Node.js binaries
- Check workspace permissions

## Conclusion

Using the Jenkins Node.js plugin provides the most reliable and maintainable approach for managing Node.js versions in your CI/CD pipeline. It isolates your builds from system dependencies and allows for easy version switching between projects.

For production environments, consider using containerized builds (Docker) for even better isolation and reproducibility.