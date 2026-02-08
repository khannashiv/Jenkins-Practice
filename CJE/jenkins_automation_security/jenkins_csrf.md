# Jenkins CSRF Protection Demo

## Overview
This demo demonstrates how to handle Jenkins Cross-Site Request Forgery (CSRF) protection using crumb tokens for API authentication and secure request handling.

## CSRF Protection in Jenkins

### What is CSRF?
Cross-Site Request Forgery (CSRF or XSRF) is a security vulnerability in web applications where unauthorized commands are transmitted from a user that the web application trusts.

### Jenkins CSRF Configuration
- **Location**: `Manage Jenkins` → `Security` → `CSRF Protection`
- **Default**: Enabled by default
- **Mechanism**: Uses a token called "crumb" for form submissions and modifications

### Crumb Issuer Information
The Default Crumb Issuer encodes the following information in the hash:
- Username that the crumb was generated for
- Web session ID that the crumb was generated in
- IP address of the user that the crumb was generated for
- Salt unique to the Jenkins instance

## API Commands

### 1. Get Crumb Information
```bash
curl -s -u Admin:Your-Password http://localhost:8080/crumbIssuer/api/json | jq
```

### 2. Get Crumb with Detailed Headers
```bash
curl -s -u Admin:Your-Password http://localhost:8080/crumbIssuer/api/json -v | jq
```

### 3. Store Cookie and Get Crumb
```bash
curl -s -u Admin:Your-Password http://localhost:8080/crumbIssuer/api/json -v --cookie-jar /tmp/cookies | jq
```

Verify stored cookies:
```bash
cat /tmp/cookies
```

### 4. Trigger Jenkins Job with CSRF Protection
```bash
curl -s -u Admin:Your-Password -X POST http://localhost:8080/job/parameterized-pipeline-job/buildWithParameters \
  --data BRANCH_NAME=test \
  --data APP_PORT=8081 \
  --cookie /tmp/cookies \
  -H "Jenkins-Crumb:257fdedca0615eeb1fdc480959f38501d83ea1d6658f039f39ddf6acee50ebd6" \
  -v
```

## Workflow Summary

1. **Authentication**: Use basic auth with username and password
2. **Cookie Management**: Store session cookies for maintaining context
3. **Crumb Token**: Retrieve and include CSRF token in requests
4. **Secure API Calls**: Combine cookies and crumb tokens for authenticated requests

## Reference Documentation
- [Jenkins CSRF Protection Official Documentation](https://www.jenkins.io/doc/book/security/csrf-protection/)

## Security Notes
- Never commit passwords or sensitive tokens to version control
- Use environment variables or secure vaults for credentials
- Ensure proper access controls on Jenkins instance
- Regularly update Jenkins and plugins to latest security patches