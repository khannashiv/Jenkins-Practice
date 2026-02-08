# Jenkins Built-in Email Notification Configuration

## Overview
This guide demonstrates how to configure and use Jenkins' built-in email notification system to automatically send build status updates to team members.

## Default Email Notification Setup

### Basic Configuration at Job Level
1. Navigate to your Jenkins job: **Generate ASCII Artwork**
2. Click **Configure**
3. Scroll to **Post-build Actions** section
4. Select **Email Notification**
5. Configure the following:
   - **Recipients**: Add email addresses of team members (e.g., `devopspractice668@gmail.com`)
   - **Send separate emails to individuals who broke the build**: Check this box to notify specific developers
   - **Send email for every unstable build**: Enable this option

### Testing Email Notifications
To test email functionality:
1. Create a shell script in your build step:
```bash
exit 1  # Force build failure for testing
```
2. This will trigger email notifications to configured recipients when build **Generate ASCII Artwork** fails

## SMTP Server Configuration

### Initial Issue
By default, Jenkins attempts to use localhost:25 for SMTP, resulting in connection errors:
```
16:34:51 Sending e-mails to: devopspractice668@gmail.com
16:34:51 ERROR: Couldn't connect to host, port: localhost, 25; timeout 60000
16:34:51 org.eclipse.angus.mail.util.MailConnectException: Couldn't connect to host, port: localhost, 25; timeout 60000;
```

### Configuring Gmail SMTP
1. Go to **Manage Jenkins** → **System**
2. Find **Email Notification** section
3. Configure with Google SMTP settings:
   - **SMTP server**: `smtp.gmail.com`
   - **Use SSL**: ✓ (checked)
   - **SMTP Port**: `465`
   - **Use SMTP Authentication**: ✓ (checked)
   - **Username**: `devopspractice668@gmail.com`
   - **Password**: **App Password** - `lfti afzl vlln ipgh` (app name: Jenkins-SMTP)

### Creating Gmail App Password
1. Enable 2-Step Verification on your Google account
2. Generate an App Password:
   - Go to Google Account → Security → App passwords
   - Create new app password named "Jenkins-SMTP"
   - Use the generated 16-character password

**Reference**: [How to create Gmail App Passwords](https://help.prowly.com/how-to-create-use-gmail-app-passwords)

### Additional Configuration
- **System Admin Email Address**: `admin@jenkins.com`
- **Test Configuration**: Use the "Test Configuration" button to verify setup
- Successful tests generate emails with subjects like:
  - Test email #1
  - Test email #2
  - Test email #3
  - Test email #4

## Email Notification Examples

### Build Failure Email (Example: Build #18)
- **Subject**: `Build failed in Jenkins: Generate ASCII Artwork #18`
- **Content**: Includes build failure details and console logs
- **Direct Link**: `http://localhost:8080/job/Generate%20ASCII%20Artwork/18/display/redirect`
- **Console Logs**: Includes all build execution details
- **Recipient**: `devopspractice668@gmail.com`

### Build Success Email (Example: Build #19)
- **Subject**: `Jenkins build is back to normal : Generate ASCII Artwork #19`
- **Content**: Notification that the previously failing build is now successful
- **Direct Link**: `http://localhost:8080/job/Generate%20ASCII%20Artwork/19/display/redirect`
- **Recipient**: `devopspractice668@gmail.com`

## Verification Steps
1. Configure SMTP settings as described above
2. Send a test email using the "Test Configuration" button
3. Check `devopspractice668@gmail.com` inbox for test emails (e.g., "Test email #4")
4. View email details by clicking "Show original" in Gmail's three-dot menu
5. Trigger a build failure in **Generate ASCII Artwork** to verify notification
   - Expected email subject: `Build failed in Jenkins: Generate ASCII Artwork #[next build number]`
6. Fix the build (remove `exit 1` from script) to receive "back to normal" notification
   - Expected email subject: `Jenkins build is back to normal : Generate ASCII Artwork #[next build number]`

## Job Information
- **Job Name**: Generate ASCII Artwork
- **Test Build Numbers Used**:
  - Failure: Build #18
  - Success: Build #19
- **Recipient Email**: `devopspractice668@gmail.com`
- **SMTP Configuration**:
  - Server: `smtp.gmail.com:465`
  - Authentication: `devopspractice668@gmail.com` with app password

## Notes
- App passwords are required for Gmail accounts with 2FA enabled
- Ensure firewall allows outbound connections to `smtp.gmail.com:465`
- Email subjects follow the pattern: `[Status] in Jenkins: [Job Name] #[Build Number]`
- The URL format uses URL encoding for spaces: `Generate%20ASCII%20Artwork`
- Build numbers increment automatically with each build execution