# Jenkins CLI SSH Authentication Demo

## Overview
This document demonstrates how to authenticate to Jenkins CLI using SSH key pair authentication instead of the traditional HTTP basic authentication method.

## Documentation Reference
- Official Jenkins Documentation: [Managing Jenkins CLI](https://www.jenkins.io/doc/book/managing/cli/)

## Prerequisites
- Jenkins instance running (default: `localhost:8080`)
- SSH client installed on your local machine
- Jenkins user account with appropriate permissions
- Java runtime environment (for `jenkins-cli.jar`)

## Step-by-Step Guide

### 1. Verify Current SSH Status
By default, SSH is disabled in Jenkins installations. Verify this by checking the HTTP headers:

```bash
curl -Lv http://localhost:8080/login
```

You won't see any SSH-related information since SSH is disabled by default.

### 2. Enable SSH in Jenkins
1. Log into Jenkins web interface
2. Navigate to **Manage Jenkins** → **Security** → **SSH Server**
3. Select a random port number from the available options
4. Click **Apply** and **Save**

### 3. Verify SSH Configuration
After enabling SSH, verify the configuration:

```bash
curl -Lv http://localhost:8080/login
```

You should now see SSH endpoint information in the response headers:
```
X-SSH-Endpoint: localhost:34253
```

To filter specifically for the SSH endpoint:

```bash
curl -Lv http://localhost:8080/login 2>&1 | grep -i 'x-ssh-endpoint'
```

### 4. Test Initial SSH Connection
Test the SSH connection to Jenkins using the assigned port:

```bash
ssh -l user2 -p 34253 localhost help
```

### 5. Set Up SSH Key Authentication

#### Generate SSH Key Pair
```bash
ssh-keygen -t rsa
```
- Press Enter to accept default location (`~/.ssh/id_rsa`)
- Optionally set a passphrase (or leave empty)

#### View Public Key
```bash
cat ~/.ssh/id_rsa.pub
```

#### Add Public Key to Jenkins
1. In Jenkins web interface, log in as `user2`
2. Click on your username/profile picture in the top-right corner
3. Select **Configure** or **Security** (depending on your Jenkins version)
4. Find the **SSH Public Keys** section
5. Paste the content of your public key (`~/.ssh/id_rsa.pub`)
6. Click **Save**

### 6. Test SSH Authentication

#### Test Help Command
```bash
ssh -l user2 -p 34253 localhost help
```

#### Execute Various Commands
```bash
# List all jobs
ssh -l user2 -p 34253 localhost list-jobs

# Check current user
ssh -l user2 -p 34253 localhost who-am-i

# Get Jenkins version
ssh -l user2 -p 34253 localhost version
```

## Jenkins CLI Connection Modes

### 1. WebSocket Connection Mode (Default)
- Enabled by default (can explicitly use `-webSocket` option)
- Advantages: Works better with reverse proxies, no special proxy configuration needed
- Example:
  ```bash
  java -jar jenkins-cli.jar -s http://localhost:8080 -webSocket help
  ```

### 2. HTTP Connection Mode
- Must explicitly pass `-http` option (Jenkins 2.391+)
- Authentication: `-auth username:apitoken`
- Example:
  ```bash
  java -jar jenkins-cli.jar -s http://localhost:8080 -http -auth user2:abc1234ffe4a list-jobs
  ```

### 3. SSH Connection Mode
- Authentication via SSH keypair
- Must specify Jenkins user ID with `-user` parameter
- Client acts like native SSH command
- Examples:

  ```bash
  # Get help
  java -jar jenkins-cli.jar -s http://localhost:8080 -ssh -user user2 help
  
  # Check current user
  java -jar jenkins-cli.jar -s http://localhost:8080 -ssh -user user2 who-am-i
  
  # Get Jenkins version
  java -jar jenkins-cli.jar -s http://localhost:8080 -ssh -user user2 version
  
  # List all jobs
  java -jar jenkins-cli.jar -s http://localhost:8080 -ssh -user user2 list-jobs
  ```

**Note:** All these commands authenticate via SSH key pair, not username/password.

---

## Advanced Demo: Editing a Freestyle Job Using Jenkins CLI

### List Available Jobs
```bash
# Using jenkins-cli.jar with SSH mode
java -jar jenkins-cli.jar -s http://localhost:8080 -ssh -user user2 list-jobs

# Using native SSH
ssh -l user2 -p 34253 localhost list-jobs
```

**Example Job:** `Generate ASCII Artwork` (Freestyle project)

### Export Job Configuration
```bash
# Using jenkins-cli.jar with SSH mode
java -jar jenkins-cli.jar -s http://localhost:8080 -ssh -user user2 get-job 'Generate ASCII Artwork'

# Using native SSH (note: quotes are essential for job names with spaces)
ssh -l user2 -p 34253 localhost "get-job 'Generate ASCII Artwork'"
```

### Save Job Configuration to File
```bash
ssh -l user2 -p 34253 localhost "get-job 'Generate ASCII Artwork'" > generate_ascii_artwork.xml
```

### Edit Job Configuration
1. Open the exported XML file:
   ```bash
   nano generate_ascii_artwork.xml
   # or
   vim generate_ascii_artwork.xml
   ```

2. Locate the shell script section (look for `<command>` tags within the build section)

3. Modify the shell script as needed. For example, add echo statements:
   ```xml
   <command>echo "Starting ASCII art generation..."
   # Your existing shell commands here
   echo "Process completed successfully!"</command>
   ```

4. Save the file

### Update Job in Jenkins

#### Using jenkins-cli.jar
```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -ssh -user user2 update-job 'Generate ASCII Artwork' < generate_ascii_artwork.xml
```

#### Using Native SSH
```bash
ssh -l user2 -p 34253 localhost "update-job 'Generate ASCII Artwork'" < generate_ascii_artwork.xml
```

**Important Notes:**
- The `<` operator pipes the XML file content to the command via standard input
- Quotes around the job name (`'Generate ASCII Artwork'`) are essential when the name contains spaces
- The job XML must be valid and well-formed

### Verify the Update
1. Check the job configuration in Jenkins web interface
2. Trigger a build to verify successful execution
3. Check the console output to confirm your changes are active

## Troubleshooting

### Common Issues

#### 1. SSH Connection Refused
```bash
# Verify SSH is enabled in Jenkins
curl -Lv http://localhost:8080/login 2>&1 | grep -i 'x-ssh-endpoint'

# Check if the port is accessible
telnet localhost 34253
```

#### 2. Permission Denied
```bash
# Verify SSH key is properly added to Jenkins user profile
# Check file permissions
ls -la ~/.ssh/
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

#### 3. Job Update Fails
- Ensure the XML is well-formed
- Check user permissions for the job
- Verify job name is correct (case-sensitive)

## Best Practices

1. **Use SSH Keys**: Always use SSH key authentication over password-based authentication
2. **Secure Your Keys**: Protect your private key with a passphrase
3. **Regular Backups**: Regularly backup job configurations
4. **Version Control**: Store job configurations in version control
5. **Test Changes**: Test job changes in a non-production environment first

## Summary

This guide demonstrated:
- ✅ Enabling SSH authentication in Jenkins
- ✅ Generating and configuring SSH keys
- ✅ Using Jenkins CLI with SSH authentication
- ✅ Exporting and updating job configurations via CLI
- ✅ Understanding different Jenkins CLI connection modes

By following this guide, you can securely manage your Jenkins instance using SSH-based CLI authentication, providing a more secure and convenient way to automate Jenkins operations.