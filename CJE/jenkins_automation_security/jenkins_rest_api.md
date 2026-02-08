# Jenkins REST API - Demo 2

This demo demonstrates how to interact with Jenkins using its REST API for various operations including job management and plugin installation.

## 📚 Documentation References

- [Jenkins Remote Access API Documentation](https://www.jenkins.io/doc/book/using/remote-access-api/)
- [Jenkins API Browser](http://localhost:8080/api/)
- [KodeKloud Jenkins REST API Notes](https://notes.kodekloud.com/docs/Jenkins-For-Beginners/Automation-and-Security/Jenkins-REST-API-Install-a-Plugin)
- [Emotional Jenkins Plugin Releases](https://plugins.jenkins.io/emotional-jenkins-plugin/releases/)
- [Emotional Jenkins Plugin](https://plugins.jenkins.io/emotional-jenkins-plugin/)

## 📋 Prerequisites

- Jenkins server running and accessible
- `curl` command-line tool installed
- `jq` (JSON processor) for pretty output (optional but recommended)
- Valid Jenkins credentials (username and API token)

## 🔑 Key Concepts

- **Item = Project = Job**: In Jenkins terminology, these terms are often used interchangeably
- **Crumb**: A security token to prevent CSRF (Cross-Site Request Forgery) attacks
- **API Token**: Preferred authentication method for REST API calls

## 🚀 Basic API Operations

### 1. List Jobs (Simple Format)
```bash
# Direct browser access
http://localhost:8080/api/json?tree=jobs[name]

# Using curl with basic authentication
curl -u admin:Your-Password http://localhost:8080/api/json?tree=jobs[name]
```

### 2. Get All Jenkins Information (Pretty with jq)
```bash
# Get all information about Jenkins
curl -u admin:Your-Password http://localhost:8080/api/json | jq

# Get only jobs information
curl -u admin:Your-Password http://localhost:8080/api/json?tree=jobs | jq
```

### 3. Get Specific Job Information
```bash
# Get details about a specific job
curl -u admin:Your-Password http://localhost:8080/job/parameterized-pipeline-job/api/json | jq
```

## 🔧 Building Jobs via REST API

### Initial Attempt (Will Fail - CSRF Protection)
```bash
# This will fail due to missing crumb
curl -u admin:Your-Password http://localhost:8080/job/parameterized-pipeline-job/buildWithParameters \
  --data BRANCH_NAME=test \
  --data APP_PORT=8081 \
  --data verbosity=high

# Even with POST method
curl -u admin:Your-Password -X POST http://localhost:8080/job/parameterized-pipeline-job/buildWithParameters \
  --data BRANCH_NAME=test \
  --data APP_PORT=8081 \
  --data verbosity=high
```

**Error Output:**
```
HTTP ERROR 403 No valid crumb was included in the request
```

### Solution: Use API Token Authentication

1. **Create API Token from Jenkins UI:**
   - Go to Jenkins → People → Admin → Configure → API Token → Add new token
   - Generated token: `Token-value`

2. **Successfully Trigger Build with API Token:**
```bash
curl -u admin:Token-value \
  -X POST \
  http://localhost:8080/job/parameterized-pipeline-job/buildWithParameters \
  --data BRANCH_NAME=test \
  --data APP_PORT=8081 \
  --data verbosity=high
```

## 🛠️ Plugin Management via REST API

### Install a Plugin
```bash
curl -u admin:Token-value \
  -X POST \
  http://localhost:8080/pluginManager/installNecessaryPlugins \
  -H 'Content-Type: text/xml' \
  -d '<jenkins><install plugin="emotional-jenkins-plugin@1.2" /></jenkins>'
```

**Format:** `name-of-the-plugin@version-of-plugin`

## 📝 Common API Endpoints

| Endpoint | Method | Purpose | Authentication |
|----------|--------|---------|----------------|
| `/api/json` | GET | Get Jenkins information | Basic Auth / API Token |
| `/job/{job-name}/api/json` | GET | Get job details | Basic Auth / API Token |
| `/job/{job-name}/build` | POST | Trigger build without parameters | API Token + Crumb |
| `/job/{job-name}/buildWithParameters` | POST | Trigger build with parameters | API Token |
| `/pluginManager/installNecessaryPlugins` | POST | Install plugins | API Token |

## 🔒 Security Considerations

### 1. **Crumb vs API Token**
- **Crumb**: Dynamic, session-based token for browser requests (CSRF protection)
- **API Token**: Static token for API authentication (preferred for automation)

### 2. **Best Practices**
- Always use API tokens instead of passwords
- Store tokens securely (environment variables, secret managers)
- Use HTTPS in production environments
- Regularly rotate API tokens

## 📊 Response Format Examples

### Sample Job List Response
```json
{
  "jobs": [
    {
      "name": "Chained_freestyle_project_demo_build_stage"
    },
    {
      "name": "Chained_freestyle_project_demo_deploy_stage"
    },
    {
      "name": "Demo-pipeline-script-project"
    }
  ]
}
```

### Sample Job Details Response
```json
{
  "name": "parameterized-pipeline-job",
  "url": "http://localhost:8080/job/parameterized-pipeline-job/",
  "buildable": true,
  "builds": [...],
  "color": "blue",
  "healthReport": [...]
}
```

## ⚠️ Important Notes

1. **Parameter Syntax**: Different from CLI - use `--data` parameters for each build parameter
2. **Content-Type**: Plugin installation requires `text/xml` content type
3. **Silent Mode**: `-s` in `curl` means silent mode, not server address
4. **Jenkins CLI vs REST API**: 
   - CLI: `-s` = server address
   - curl: `-s` = silent mode

## 🎯 Troubleshooting

### Common Issues & Solutions

1. **403 Forbidden Error**
   - Use API token instead of password
   - Ensure proper permissions for the user

2. **Plugin Installation Fails**
   - Verify plugin name and version exist
   - Check Jenkins compatibility with plugin version
   - Ensure proper XML format

3. **Connection Issues**
   - Verify Jenkins server is running
   - Check firewall/network connectivity
   - Ensure correct port and URL

## 📈 Next Steps

- Explore more API endpoints from `/api/` browser
- Implement error handling in scripts
- Create wrapper scripts for common operations
- Set up webhook integrations
- Monitor API usage and rate limiting

---

**Note**: Always test API calls in a non-production environment first and review Jenkins security settings before implementing in production.