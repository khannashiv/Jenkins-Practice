# Jenkins Controller Migration to Another Node/Server

This guide provides step-by-step instructions for migrating a Jenkins controller (master) from one server to another.

## 📋 Prerequisites

### Source Server (Original Jenkins Controller)
- Jenkins installation with data to migrate
- Sufficient disk space for backup creation
- Administrative/root access

### Target Server (New Jenkins Controller)
- Fresh Jenkins installation matching the version from source
- Same JDK/Java version as source server
- Sufficient disk space (typically 2-3x the size of `/var/lib/jenkins` folder)
- Administrative/root access

## 🔧 Pre-Migration Steps

### 1. Version Verification
- **Source Jenkins Version**: Check using:
  ```bash
  # Method 1: If Jenkins CLI is installed
  jenkins --version
  
  # Method 2: If installed via WAR file
  java -jar /usr/share/java/jenkins.war --version
  ```

- **Java Version**: Ensure both servers have identical JDK versions
  ```bash
  java -version
  ```

### 2. Document Startup Arguments
- Locate and document Java startup arguments from source server
- Refer to [Official Documentation](https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/migrating-jenkins-to-a-new-machine) for file paths

## 📦 Migration Process

### Step 1: Prepare Source Server

1. **Stop Jenkins service**:
   ```bash
   sudo systemctl stop jenkins
   ```

2. **Disable Jenkins service** (optional, prevents accidental restart):
   ```bash
   sudo systemctl disable jenkins
   ```

3. **Verify Jenkins directory permissions**:
   ```bash
   ls -la /var/lib/ | grep jenkins
   # Expected output: drwxr-xr-x 26 jenkins jenkins 12288 Jan  9 16:25 jenkins
   ```

4. **Create backup of Jenkins directory**:
   ```bash
   cd /var/lib
   sudo tar -czvf jenkins-backup.tar.gz jenkins
   ```

5. **Check backup file size**:
   ```bash
   ls -lh jenkins-backup.tar.gz
   ```

### Step 2: Prepare Target Server

1. **Install matching Jenkins version**

2. **Configure Java globally** (if needed):
   ```bash
   # Create profile script
   sudo sh -c 'echo "export PATH=/opt/jdk-17.0.17/bin:\$PATH" > /etc/profile.d/jdk.sh'
   
   # Set permissions
   sudo chmod 644 /etc/profile.d/jdk.sh
   
   # Reload environment
   source /etc/profile.d/jdk.sh
   
   # Verify Java availability for all users
   java -version
   sudo -i java -version
   sudo -u jenkins -i java -version
   ```

3. **Stop and disable Jenkins service**:
   ```bash
   sudo systemctl stop jenkins
   sudo systemctl disable jenkins
   ```

### Step 3: Transfer Backup File

**Option A: Using SCP** (simpler but may be slower):
```bash
scp -i "/path/to/your-key.pem" /var/lib/jenkins-backup.tar.gz \
ubuntu@<EC2-Public-IP>:/home/ubuntu/
```

**Option B: Using RSYNC** (faster with progress and resume capability):
```bash
rsync -avP -e "ssh -i '/path/to/your-key.pem'" \
/var/lib/jenkins-backup.tar.gz \
ubuntu@<EC2-Public-IP>:/home/ubuntu/
```

**Note**: File transfer of large backups (23GB in this case) can take several hours.

### Step 4: Restore on Target Server

1. **Move backup to appropriate directory**:
   ```bash
   sudo mv /home/ubuntu/jenkins-backup.tar.gz /var/lib/
   ```

2. **Create backup of existing Jenkins directory** (safety measure):
   ```bash
   cd /var/lib
   sudo tar -czvf jenkins-new-server-backup.tar.gz jenkins
   ```

3. **Remove existing Jenkins directory**:
   ```bash
   sudo rm -rf jenkins
   ```

4. **Extract the migrated backup**:
   ```bash
   sudo tar -xzvf jenkins-backup.tar.gz
   ```

5. **Verify ownership and permissions**:
   ```bash
   sudo chown -R jenkins:jenkins jenkins
   ls -la | grep jenkins
   ```

### Step 5: Start Jenkins on Target Server

1. **Enable and start Jenkins service**:
   ```bash
   sudo systemctl enable jenkins
   sudo systemctl start jenkins
   ```

2. **Verify service status**:
   ```bash
   sudo systemctl status jenkins
   ```

3. **Access Jenkins UI**:
   - Navigate to: `http://<new-server-ip>:8080`
   - Verify all jobs, builds, and credentials migrated successfully

## ⚠️ Troubleshooting

### Common Issues and Solutions

1. **Insufficient Disk Space**
   - Symptom: Extraction fails or Jenkins won't start
   - Solution: Increase storage (EBS volume in AWS)
   - Note: Extracted data may be 2-3x larger than compressed backup

2. **Permission Issues**
   - Symptom: Jenkins fails to start or access files
   - Solution: Ensure correct ownership:
     ```bash
     sudo chown -R jenkins:jenkins /var/lib/jenkins
     ```

3. **Java Version Mismatch**
   - Symptom: Jenkins fails with Java compatibility errors
   - Solution: Install exact same Java version as source server

4. **Service Won't Start**
   - Check logs: `sudo journalctl -u jenkins -f`
   - Verify disk space: `df -h`
   - Confirm permissions: `ls -la /var/lib/jenkins`

## 📊 Post-Migration Verification

- [x] Jenkins UI loads successfully
- [x] All jobs and configurations present
- [x] Build history intact
- [x] Credentials migrated
- [x] Plugins functional
- [x] Agent connections working (if applicable)

## 🔒 Security Considerations

1. **Clean up sensitive data** from source server after successful migration
2. **Update firewall rules** if IP address changed
3. **Rotate credentials** if required by security policy
4. **Update DNS records** if using domain names

## 📝 Notes

- Migration time depends on backup size and network speed
- Consider downtime window for production migrations
- Test thoroughly before decommissioning source server
- Document any custom configurations not captured in `/var/lib/jenkins`

## 📚 References

- [Official CloudBees Migration Documentation](https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/migrating-jenkins-to-a-new-machine)
-  [Backing-up/Restoring Jenkins](https://www.jenkins.io/doc/book/system-administration/backing-up/)

---

**Migration Successful**: ✅ All jobs, builds, and credentials imported successfully to the new server from the old Jenkins Server.