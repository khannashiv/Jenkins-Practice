# Jenkins Organization Folder Project with Gitea Integration

## 📋 Overview

This project demonstrates how to configure Jenkins Organization Folder to automatically discover and build repositories from a Gitea organization. The setup includes migrating repositories from GitHub to Gitea, configuring Jenkins with Gitea integration, and setting up webhook triggers for automated builds.

## 🎯 Prerequisites

- Jenkins instance with administrative access
- Gitea account (cloud or self-hosted)
- Source repository to migrate (e.g., from GitHub)
- SSH keys configured for Git operations
- Webhook tunneling tool (e.g., Ngrok) for local Jenkins testing

## 🚀 Setup Steps

### 1. Repository Migration to Gitea

1. Navigate to Gitea UI
2. Click the `+` button (top right) → "New Migration"
3. Select source platform (GitHub, GitLab, etc.)
4. Fill migration details:
   - **Migrate/Clone From URL**: Source repository URL
   - **Owner**: Select your target organization
   - **Repository Name**: Target repository name
5. Click "Migrate Repository"

### 2. Jenkins Gitea Plugin Installation

1. In Jenkins, go to **Manage Jenkins** → **Plugins**
2. Search for "Gitea" plugin and install it
3. Restart Jenkins if required

### 3. Gitea Server Configuration in Jenkins

1. Go to **Manage Jenkins** → **Configure System**
2. Find "Gitea Servers" section
3. Add new Gitea server:
   - **Name**: Any descriptive name
   - **Server URL**: Your Gitea instance URL
   - **Credentials**: Gitea Personal Access Token
   - **Manage Hooks**: Enabled (checked)

### 4. Configure Gitea Credentials

1. Create a Personal Access Token (PAT) in Gitea:
   - Go to Gitea → Settings → Applications → Generate New Token
   - Required scopes: `read:user`, `write:admin`, `write:organization`
   - Save the token securely

2. Add credentials in Jenkins:
   - Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
   - Add new credentials:
     - **Kind**: Secret text
     - **Secret**: Your Gitea PAT
     - **ID**: Descriptive ID (e.g., `gitea-access-token`)

### 5. Create Organization Folder Project

1. Click "New Item" in Jenkins
2. Select "Organization Folder"
3. Configure the project:

   **Basic Settings:**
   - **Display Name**: Descriptive project name
   - **Description**: Optional description

   **Gitea Configuration:**
   - **Server**: Your Gitea server URL
   - **Credentials**: Your configured Gitea credentials
   - **Owner**: Your Gitea organization name

   **Project Recognizers:**
   - Add "Pipeline Jenkinsfile" recognizer
   - Set path to Jenkinsfile (default: `Jenkinsfile` at root)

   **Scan Triggers:**
   - **Periodically if not otherwise run**: Set desired interval (e.g., 1 day)

4. Save configuration

### 6. SSH Key Configuration for Git Operations

```bash
# Generate SSH key
ssh-keygen -t ecdsa -b 256 -C "your-email@example.com"

# Copy public key
cat ~/.ssh/id_ecdsa.pub

# Add to Gitea
# Settings → SSH/GPG Keys → Add Key → Paste public key

# Configure Git remote URL
cd /path/to/local/repo
git remote set-url origin git@your-gitea-domain.com:organization/repository.git

# Test SSH connection
ssh -T git@your-gitea-domain.com
```

### 7. Webhook Configuration

For automated builds on push/pull request events:

1. **Using Gitea API**:
```bash
curl -u username:personal-access-token \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "type": "gitea",
    "config": {
      "url": "https://your-jenkins-url/gitea-webhook/post",
      "content_type": "json",
      "http_method": "post",
      "secret": ""
    },
    "events": ["push", "pull_request"],
    "active": true
  }' \
  https://your-gitea-domain.com/api/v1/repos/organization/repository/hooks
```

2. **Using Gitea UI**:
   - Navigate to repository → Settings → Webhooks → Add Webhook
   - Choose "Gitea" type (compatible with Jenkins)
   - Configure:
     - **Target URL**: `https://your-jenkins-url/gitea-webhook/post`
     - **HTTP Method**: `POST`
     - **Content Type**: `application/json`
     - **Events**: Push + Pull Request

### 8. Tunneling Setup for Local Testing (Optional)

For local Jenkins instances, use a tunneling service:

```bash
# Example with ngrok
ngrok http 8080

# Update Gitea webhook URL with the generated ngrok URL
# Example: https://xxxxx.ngrok-free.dev/gitea-webhook/post
```

## 🔧 Troubleshooting

### Common Issues and Solutions

1. **HTTP 404 Error during organization scan**:
   - Verify organization name is correct
   - Ensure PAT has proper scopes (`write:admin`, `write:organization`)
   - Check if organization was created directly (not by admin/system)

2. **Webhook not triggering builds**:
   - Verify Jenkins URL is accessible from Gitea
   - Check Gitea webhook delivery logs
   - Ensure Jenkins has Gitea plugin installed and configured
   - Verify webhook URL format: `https://jenkins-url/gitea-webhook/post`

3. **SSH connection issues**:
   - Verify SSH key is added to Gitea account
   - Check SSH configuration
   - Ensure correct remote URL format

4. **Permission issues**:
   - Ensure the Gitea user has proper access to the organization
   - Verify PAT has required scopes
   - Check organization ownership

## 📊 API Testing Commands

```bash
# 1. Get user info
curl -u username:personal-access-token https://your-gitea-domain.com/api/v1/user | jq

# 2. Get organization details
curl -u username:personal-access-token https://your-gitea-domain.com/api/v1/orgs/organization-name | jq

# 3. Get repositories under organization
curl -u username:personal-access-token https://your-gitea-domain.com/api/v1/orgs/organization-name/repos | jq

# 4. Verify repository exists
curl -u username:personal-access-token https://your-gitea-domain.com/api/v1/repos/organization-name/repository-name | jq
```

## 📝 Best Practices

1. **Repository Structure**:
   - Keep `Jenkinsfile` at repository root
   - Use consistent branch naming conventions
   - Maintain separate Jenkinsfiles for different environments if needed

2. **Security**:
   - Use dedicated service accounts for Jenkins
   - Store credentials securely in Jenkins Credential Store
   - Regularly rotate Personal Access Tokens
   - Use least privilege principle for token scopes

3. **Organization Management**:
   - Create organizations with proper ownership
   - Use consistent naming conventions across platforms
   - Document organization structure and access patterns

4. **Webhook Management**:
   - Use webhook secrets for additional security
   - Monitor webhook delivery failures
   - Set up proper error notifications

## 📚 References

- [Jenkins Best Practices Documentation](https://www.jenkins.io/doc/book/using/best-practices/)
- [Gitea Documentation](https://docs.gitea.com/)
- [Jenkins Gitea Plugin Documentation](https://plugins.jenkins.io/gitea/)

## 🏗️ Project Structure

```
Organization-folder-project/
├── organization-name/
│   └── repository-name/
│       ├── Jenkinsfile
│       ├── src/
│       └── ... other source files
└── (Other repositories auto-discovered)
```

## 🔄 Workflow

1. Code changes pushed to Gitea repository
2. Gitea sends webhook notification to Jenkins
3. Jenkins Organization Folder scans for changes
4. Jenkinsfile is detected and pipeline executes
5. Build results and status reported to Gitea (if configured)

## ⚠️ Important Notes

- Tunneling URLs (like Ngrok) are temporary and change frequently
- Gitea cloud instances may have limitations on webhook configurations
- Ensure Jenkins instance is accessible for webhooks to work properly
- Test all configurations in a development environment first
- Keep backup of Jenkins and Gitea configurations
- Document all custom configurations and setups

## 🔒 Security Considerations

- Never commit credentials or sensitive tokens to version control
- Use environment variables or credential stores for sensitive data
- Regularly audit access permissions and token usage
- Implement proper network security for Jenkins and Gitea communication
- Use HTTPS for all webhook communications
- Consider using webhook signatures for additional security

## 📈 Monitoring and Maintenance

- Monitor Jenkins build queues and performance
- Set up alerts for failed builds or webhook failures
- Regularly update Jenkins plugins and Gitea integration
- Review and clean up old builds and artifacts
- Document any changes to the setup for future reference