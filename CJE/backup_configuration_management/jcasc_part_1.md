# Jenkins Configuration as Code (JCasC) - Theory and Demo

## 📚 Introduction to JCasC

Jenkins Configuration as Code (JCasC) is a plugin that allows you to define Jenkins configuration in human-readable YAML format. This approach enables version control, easy replication, and consistent configuration management across Jenkins instances.

### Key Benefits
- **Version Control**: Store configuration in Git for history tracking
- **Reproducibility**: Recreate identical Jenkins environments
- **Consistency**: Maintain uniform configurations across instances
- **Automation**: Integrate with CI/CD pipelines
- **Documentation**: Configuration becomes self-documenting

## 🔗 Official Documentation
- [Configuration as Code Plugin](https://plugins.jenkins.io/configuration-as-code/)
- [JCasC Documentation](https://github.com/jenkinsci/configuration-as-code-plugin)

## 🚀 Demo: Configure and Explore JCasC

### Step 1: Install JCasC Plugin
1. Navigate to **Manage Jenkins** → **Plugins** → **Available plugins**
2. Search for "Configuration as Code"
3. Install the plugin
4. **Restart Jenkins** after installation

### Step 2: Access JCasC Interface
After restart:
1. Go to **Manage Jenkins** → **System Configuration**
2. Find new option: **Configuration as Code**
3. Click on **Configuration as Code**

### Step 3: Export Current Configuration
1. Click on **View Configuration** or **Export Configuration**
2. Click **Download** to save the complete YAML configuration locally
3. The YAML file contains 7 main configuration objects:

```yaml
credentials:          # Credentials configuration
jenkins:             # Core Jenkins settings
globalCredentialsConfiguration: # Global credentials settings
security:            # Security settings
tools:               # Tool installations (JDK, Maven, etc.)
appearance:          # UI/Appearance settings
unclassified:        # Plugin-specific configurations
```

### Step 4: Create JCasC Configuration File
Navigate to the backup directory:
```bash
cd /var/lib/jenkins/fullbackup_thinbackup_plugin
ls
# Output: FULL-2026-01-11_21-45
```

Create a new JCasC YAML file:
```bash
touch jenkins-casc.yaml
```

Paste the exported YAML content into the file and edit the system message:
```yaml
jenkins:
  systemMessage: "Working and learning about CasC plugin"
  # ... other configurations
```

Verify the file structure:
```bash
ls
# Output:
# FULL-2026-01-11_21-45  jenkins-casc.yaml
```

### Step 5: Apply JCasC Configuration
1. Go back to **Configuration as Code** in Jenkins UI
2. Update **Configuration Source** with the path:
   ```
   /var/lib/jenkins/fullbackup_thinbackup_plugin/jenkins-casc.yaml
   ```
3. The plugin validates the YAML syntax
4. Click **Apply New Configuration**

### Step 6: Verify Configuration
After successful application:
```
Configuration as Code

Configuration loaded from:
    /var/lib/jenkins/fullbackup_thinbackup_plugin/jenkins-casc.yaml

Last time applied: Jan 14, 2026, 9:03:55 AM IST
```

**Verification Points:**
1. ✅ System message updated on Jenkins homepage: "Working and learning Jenkins-CasC plugin"
2. ✅ Configuration loaded from specified YAML file
3. ✅ Timestamp shows last successful application

## 🛠️ Available Actions in JCasC Interface
- **View Configuration**: Display current YAML configuration
- **Reload**: Reapply configuration from source
- **Download**: Export current configuration as YAML file
- **Documentation**: Access plugin documentation
- **JSON Schema**: View configuration schema for validation

## 📝 YAML Configuration Structure Details

### 1. **jenkins** (Core Settings)
```yaml
jenkins:
  systemMessage: "Custom welcome message"
  numExecutors: 2
  mode: NORMAL
  scmCheckoutRetryCount: 0
```

### 2. **credentials** (Credentials Management)
```yaml
credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              scope: GLOBAL
              id: "docker-hub"
              username: "admin"
              password: "secret"
```

### 3. **security** (Security Configuration)
```yaml
security:
  queueItemAuthenticator:
    authenticators:
      - global:
          strategy: "triggeringUsersAuthorization"
```

### 4. **tools** (Tool Installations)
```yaml
tools:
  jdk:
    installations:
      - name: "jdk11"
        home: "/usr/lib/jvm/java-11-openjdk-amd64"
```

### 5. **unclassified** (Plugin Configurations)
```yaml
unclassified:
  location:
    url: "http://jenkins.example.com/"
    adminAddress: "admin@example.com"
```

## 🔄 Common JCasC Operations

### Export Configuration
```bash
# Via Jenkins UI: Manage Jenkins → Configuration as Code → Download
# OR via CLI (if installed):
java -jar jenkins-cli.jar -s http://localhost:8080/ configuration-as-code export
```

### Apply Configuration
```bash
# Apply from YAML file
java -jar jenkins-cli.jar -s http://localhost:8080/ configuration-as-code apply -f /path/to/config.yaml
```

### Validate Configuration
```bash
# Check YAML syntax
yamllint jenkins-casc.yaml

# Validate against schema
java -jar jenkins-cli.jar -s http://localhost:8080/ configuration-as-code check -f /path/to/config.yaml
```

## 🎯 Best Practices

1. **Version Control**: Store JCasC YAML files in Git
2. **Backup**: Keep backups before applying changes
3. **Testing**: Test in staging before production
4. **Incremental Changes**: Make small, incremental changes
5. **Documentation**: Comment complex configurations
6. **Validation**: Always validate YAML before applying

## 📊 Configuration Management Workflow

```
Current Jenkins State
        ↓
Export Configuration (YAML)
        ↓
Store in Version Control (Git)
        ↓
Modify as Needed
        ↓
Validate & Test
        ↓
Apply to Jenkins
        ↓
Verify Changes
```

## ⚠️ Important Notes

1. **Plugin Dependencies**: Some configurations require specific plugins
2. **Sensitive Data**: Use Jenkins credentials store for secrets
3. **Order Matters**: Configuration is applied in specific order
4. **Backup**: Always backup `JENKINS_HOME` before major changes
5. **Compatibility**: Ensure plugin versions are compatible

## 🔗 Additional Resources
- [JCasC Examples Repository](https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos)
- [YAML Syntax Guide](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html)
- [Jenkins JCasC Reference](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md)

---

*Tip: Use JCasC for managing Jenkins configurations across development, staging, and production environments to maintain consistency and reduce configuration drift.*