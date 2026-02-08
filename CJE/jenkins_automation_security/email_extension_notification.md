# Jenkins Email Extension Notification - Freestyle & Pipeline Projects

## Overview
This guide demonstrates how to configure and use the Email Extension Plugin in Jenkins for sending email notifications based on build status for both freestyle and pipeline projects.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Global Configuration](#global-configuration)
- [Freestyle Project Setup](#freestyle-project-setup)
- [Pipeline Project Setup](#pipeline-project-setup)
- [Advanced Configuration](#advanced-configuration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Prerequisites
- Jenkins installed and running
- Email Extension Plugin (Extended E-mail Notification) installed

## Installation
1. Install the **Email Extension Plugin** or **Extended E-mail Notification** plugin via:
   - Manage Jenkins → Manage Plugins → Available plugins
   - Search for "Email Extension" and install

## Global Configuration

### Step 1: Configure System Email Settings
1. Navigate to **Manage Jenkins** → **System**
2. Find **Extended E-mail Notification** section
3. Configure the following:
   - **Default Recipients**: `devopspractice668@gmail.com`
   - **SMTP Server**: Your email server settings
   - **SMTP Port**: Typically 587 or 465
   - **Credentials**: Email account authentication
   - **Use SSL/TLS**: Enable if required

### Step 2: Configure Default Email Content
In the same **Extended E-mail Notification** section:
1. Set **Default Content Type**: HTML (text/html)
2. Configure **Default Content** with HTML template:

```html
<html>
  <body style="font-family: Arial, sans-serif; background-color: #f4f7fa; padding: 30px;">
    <div style="max-width: 700px; margin: auto; background: #ffffff; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); padding: 20px;">
      <h2 style="text-align: center; background-color: #007bff; color: white; padding: 15px; border-radius: 8px;">
        Jenkins Build Notification
      </h2>

      <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
        <tr style="background-color: #f0f4f8;">
          <td style="padding: 10px; width: 30%; font-weight: bold; border-bottom: 1px solid #ddd;">Project</td>
          <td style="padding: 10px; border-bottom: 1px solid #ddd;">${PROJECT_NAME}</td>
          <td style="padding: 10px; width: 30%; font-weight: bold; border-bottom: 1px solid #ddd;">Build Number</td>
          <td style="padding: 10px; border-bottom: 1px solid #ddd;">#${BUILD_NUMBER}</td>
        </tr>

        <tr style="background-color: #ffffff;">
          <td style="padding: 10px; font-weight: bold; border-bottom: 1px solid #ddd;">Status</td>
          <td style="padding: 10px; border-bottom: 1px solid #ddd;">${BUILD_STATUS}</td>
          <td style="padding: 10px; font-weight: bold; border-bottom: 1px solid #ddd;">Console Output</td>
          <td style="padding: 10px; border-bottom: 1px solid #ddd;">
            <a href="${BUILD_URL}" target="_blank" style="color: #007bff; text-decoration: none; font-weight: bold;">
              View Logs
            </a>
          </td>
        </tr>
      </table>

      <p style="text-align: center; color: #666; margin-top: 20px; font-size: 12px;">
        © Jenkins CI | This is an automated notification.
      </p>
    </div>
  </body>
</html>
```

### Step 3: Configure Default Triggers
In the same **Extended E-mail Notification** section:
1. Under **Triggers**, select:
   - **Failure - Any**
   - **Success**

---

## Freestyle Project Setup

### Step 1: Access Project Settings
1. Navigate to your freestyle project (e.g., `Chained_freestyle_project_demo_build_stage`)
2. Click **Configure**

### Step 2: Configure Post-build Actions
1. Scroll to **Post-build Actions**
2. Select **Editable Email Notification**
3. Configure the following:
   - **Project Recipient List**: Specify recipients or leave empty for defaults
   - **Triggers**: Configure as needed (Failure - Any, Success, etc.)
   - **Attach Build Log**: Check to include build logs as attachments

## Use Cases Demonstrated

### Case 1: No Project Recipient Specified
- **Configuration**: Project recipient list left empty
- **Behavior**: Uses default system recipients configured in global settings
- **Console Output**:
  ```
  Email was triggered for: Failure - Any
  Sending email for trigger: Failure - Any
  An attempt to send an e-mail to empty list of recipients, ignored.
  ```
- **Result**: **No email sent** when project recipient list is empty

### Case 2: With Project Recipient Specified
- **Configuration**: Recipient specified (`devopspractice668@gmail.com`)
- **Behavior**: Email sent to specified recipient
- **Console Output**:
  ```
  Email was triggered for: Failure - Any
  Sending email for trigger: Failure - Any
  Sending email to: devopspractice668@gmail.com
  ```
- **Result**: **Email successfully sent**

## Email Subject Examples

### For Failed Builds:
```
Chained_freestyle_project_demo_build_stage - Build # 39 - Still Failing!
```
**Body**: Check console output at http://localhost:8080/job/Chained_freestyle_project_demo_build_stage/39/ to view the results.

### For Successful Builds:
```
Chained_freestyle_project_demo_build_stage - Build # 40 - Fixed!
```
**Body**: Check console output at http://localhost:8080/job/Chained_freestyle_project_demo_build_stage/40/ to view the results.

---

## Pipeline Project Setup

### Reference Documentation
- Jenkins Pipeline Post Actions: https://www.jenkins.io/doc/pipeline/tour/post/

### Pipeline Email Configuration
Here's an example pipeline configuration with email notifications:

```groovy
pipeline {
    agent any
    
    stages {
        // Create a test file for attachment demonstration
        stage('Hello') {
            steps {
                script {
                    sh 'echo Testing-pipeline-email-notifications > testfile.txt'
                }
            }
        }
        
        // Additional stages can be added here
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Testing...'
            }
        }
    }
    
    post {
        always {
            emailext(
                attachLog: true,
                attachmentsPattern: 'testfile.*',
                body: '$DEFAULT_CONTENT',
                subject: '$DEFAULT_SUBJECT',
                to: '$DEFAULT_RECIPIENTS'
            )
        }
    }
}
```

### Pipeline Email Configuration Explained

#### 1. **File Attachment Creation**
```groovy
stage('Hello') {
    steps {
        script {
            sh 'echo Testing-pipeline-email-notifications > testfile.txt'
        }
    }
}
```
- Creates `testfile.txt` with sample content
- Used to demonstrate file attachment functionality

#### 2. **Email Notification in Post Section**
```groovy
post {
    always {
        emailext(
            attachLog: true,
            attachmentsPattern: 'testfile.*',
            body: '$DEFAULT_CONTENT',
            subject: '$DEFAULT_SUBJECT',
            to: '$DEFAULT_RECIPIENTS'
        )
    }
}
```

#### 3. **Email Parameters**

| Parameter | Description | Example |
|-----------|-------------|---------|
| `attachLog` | Attach build log to email | `true` |
| `attachmentsPattern` | Pattern for additional attachments | `'testfile.*'` |
| `body` | Email body content | `'$DEFAULT_CONTENT'` |
| `subject` | Email subject | `'$DEFAULT_SUBJECT'` |
| `to` | Recipient list | `'$DEFAULT_RECIPIENTS'` |

#### 4. **Post Conditions**
- `always`: Execute email regardless of build status
- Alternative conditions:
  - `success`: Only on successful builds
  - `failure`: Only on failed builds
  - `unstable`: Only on unstable builds
  - `changed`: Only when build status changes

### Generating Email Configuration
Use the **Snippet Generator**:
1. Navigate to your pipeline project
2. Click **Pipeline Syntax**
3. Select `emailext: Editable Email Notification`
4. Configure parameters and generate code

---

## Advanced Configuration

### 1. Custom Email Templates
Create custom email templates using Jenkins variables:
- `${PROJECT_NAME}` - Project name
- `${BUILD_NUMBER}` - Build number
- `${BUILD_STATUS}` - Build status (SUCCESS, FAILURE, etc.)
- `${BUILD_URL}` - URL to build console
- `${JENKINS_URL}` - Jenkins server URL

### 2. Conditional Email Triggers
```groovy
post {
    success {
        emailext(
            subject: "SUCCESS: ${PROJECT_NAME} - Build #${BUILD_NUMBER}",
            body: 'Build succeeded!',
            to: 'success-team@example.com'
        )
    }
    failure {
        emailext(
            subject: "FAILURE: ${PROJECT_NAME} - Build #${BUILD_NUMBER}",
            body: 'Build failed! Please check.',
            to: 'devops-alerts@example.com',
            attachLog: true
        )
    }
}
```

### 3. Multiple Attachments
```groovy
emailext(
    attachmentsPattern: '**/*.log, **/*.txt, **/test-results/*.xml',
    attachLog: true
)
```

### 4. Dynamic Recipient Lists
```groovy
post {
    always {
        script {
            def recipients = env.BRANCH_NAME == 'main' ? 
                'prod-team@example.com' : 
                'dev-team@example.com'
            
            emailext(
                to: recipients,
                subject: "${PROJECT_NAME} - ${env.BRANCH_NAME} Build Result",
                body: "Build completed for branch: ${env.BRANCH_NAME}"
            )
        }
    }
}
```

---

## Best Practices

### 1. Recipient Management
- **Always specify recipients** at project level to ensure emails are sent
- Use distribution lists instead of individual email addresses
- Implement role-based recipient assignment

### 2. Email Content
- **Enable build log attachments** for detailed failure analysis
- Use HTML templates for professional-looking emails
- Include essential build information in email body
- Add direct links to build console and artifacts

### 3. Trigger Configuration
- Configure appropriate triggers based on project requirements
- Avoid sending emails for every build (consider `changed` trigger)
- Separate success and failure notifications with different content

### 4. Performance Considerations
- Compress large attachments before sending
- Use file patterns instead of attaching entire workspaces
- Consider email throttling for high-frequency builds

### 5. Testing
- **Test email configuration** with a small recipient list first
- Verify email delivery in different scenarios (success/failure)
- Test attachment functionality with various file types
- Validate HTML rendering in different email clients

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "No emails were triggered"
**Symptoms:**
```
No emails were triggered.
```
**Solutions:**
- Check trigger configuration matches build status
- Verify email plugin is properly installed
- Ensure post-build actions are configured correctly

#### Issue 2: "Empty list of recipients, ignored"
**Symptoms:**
```
An attempt to send an e-mail to empty list of recipients, ignored.
```
**Solutions:**
- Ensure recipients are specified either in project or system settings
- Verify `$DEFAULT_RECIPIENTS` is configured in global settings
- Check if recipient variable expansion is working

#### Issue 3: Emails not received
**Symptoms:**
- Email appears sent in console but not received
**Solutions:**
- Check SMTP server configuration
- Verify authentication credentials
- Check spam/junk folders
- Test with simple email configuration first
- Verify network/firewall settings

#### Issue 4: Attachments not included
**Symptoms:**
- Email sent without attachments
**Solutions:**
- Verify file paths are correct
- Check file permissions
- Ensure files exist at the time of email sending
- Test with simple file patterns first

#### Issue 5: HTML rendering issues
**Symptoms:**
- HTML emails appear as plain text
**Solutions:**
- Verify content type is set to `HTML (text/html)`
- Check HTML syntax for errors
- Test with simple HTML first
- Verify email client compatibility

### Debugging Steps
1. **Check Jenkins System Log:**
   - Manage Jenkins → System Log
   - Look for email-related errors

2. **Enable Debug Logging:**
   ```groovy
   emailext(
       mimeType: 'text/html',
       debugMode: true,  // Enable debug
       to: 'test@example.com'
   )
   ```

3. **Test SMTP Configuration:**
   - Use simple test emails first
   - Verify SMTP server connectivity
   - Test authentication separately

4. **Verify File Paths:**
   - Use absolute paths in patterns
   - Check workspace location
   - Verify file creation timestamps

### Useful Commands for Debugging
```bash
# Check if files exist for attachment patterns
ls -la testfile.*

# Check Jenkins email plugin configuration
cat /var/lib/jenkins/hudson.plugins.emailext.ExtendedEmailPublisher.xml

# Test SMTP connectivity
telnet smtp.gmail.com 587
```

## Additional Resources
- [Jenkins Email Extension Plugin Documentation](https://plugins.jenkins.io/email-ext/)
- [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Jenkins Variables Reference](https://www.jenkins.io/doc/pipeline/tour/environment/)
- [HTML Email Templates Best Practices](https://templates.mailchimp.com/resources/email-client-css-support/)

## Support
For additional help:
1. Check Jenkins community forums
2. Review plugin documentation
3. Examine Jenkins system logs
4. Test with minimal configurations first

---

**Note**: Always test email configurations in a non-production environment before deploying to production. Consider implementing email rate limiting and monitoring to prevent email system abuse.