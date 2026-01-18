# Slack Notifications Setup in Jenkins

## Overview

Official Documentation: [Jenkins Slack Plugin](https://plugins.jenkins.io/slack)

The Slack Notifications plugin integrates Jenkins with Slack, enabling the publication of build statuses and messages to Slack channels.

## Prerequisites

- A Slack workspace named `jenkins-workspace`.
- Sign up for Slack at [slack.com](https://slack.com/).
- Create a public channel named `demo-notifications-1`.

## Creating a Slack App

1. Visit [api.slack.com/apps](https://api.slack.com/apps) to create a new app.
2. Obtain the Bot User OAuth Token, e.g., `YOUR_BOT_TOKEN_HERE`.
   - **Security Note:** Never commit actual tokens to version control. Store them securely using Jenkins credentials or environment variables.
3. Store this token securely in Jenkins.

## Configuring Jenkins

1. Navigate to **Manage Jenkins** > **System**.
2. Search for "Slack" and configure the workspace and credentials.
   - Workspace: `jenkins-workspace`

## App Manifest

Use the following app manifest with the required permissions:

```json
{
    "display_information": {
        "name": "Shiv"
    },
    "features": {
        "bot_user": {
            "display_name": "Shiv",
            "always_online": true
        }
    },
    "oauth_config": {
        "scopes": {
            "bot": [
                "channels:read",
                "channels:write.invites",  // Allows bot invitations
                "chat:write",
                "chat:write.customize",
                "chat:write.public",       // Allows posting to public channels
                "files:write",
                "reactions:write",
                "users:read",
                "users:read.email",
                "groups:read",
                "groups:write.invites"     // For private channels
            ]
        }
    },
    "settings": {
        "org_deploy_enabled": false,
        "socket_mode_enabled": false,
        "token_rotation_enabled": false
    }
}
```

## Testing the Token

### Test 1: Verify Token Validity

```bash
curl -s -H "Authorization: Bearer YOUR_BOT_TOKEN_HERE" \
    "https://slack.com/api/auth.test" | jq '{ok: .ok, error: .error, url: .url}'
```

### Test 2: List Channels

```bash
curl -s -H "Authorization: Bearer YOUR_BOT_TOKEN_HERE" \
  "https://slack.com/api/conversations.list?limit=200&exclude_archived=true" \
  | jq '.channels[] | select(.is_member == true) | "#\(.name) - member: \(.is_member)"'
```

### Test 3: Post a Message

```bash
curl -X POST -H "Authorization: Bearer YOUR_BOT_TOKEN_HERE" \
  -H "Content-type: application/json" \
  --data '{"channel":"#demo-notifications","text":"Direct API test"}' \
  https://slack.com/api/chat.postMessage | jq '{ok: .ok, error: .error}'
```

## Common Issues

### Issue 1: Test Connection Failure

Ensure the "Custom slack app bot user" option is ticked in **Manage Jenkins** > **System** > Slack configuration.

### Issue 2: "not_in_channel" Error

Add the app to the channel with all permissions from the manifest, including "channels:write.invites". Reinstall the app and test the connection.

## Final App Manifest

```json
{
    "display_information": {
        "name": "App-1",
        "description": "This app is created via UI.",
        "background_color": "#30302f",
        "long_description": "##################################################\r\nThis app is created via UI. \r\nUsing the URL i.e. https://api.slack.com/apps\r\n*********************************************************************"
    },
    "features": {
        "bot_user": {
            "display_name": "App-1",
            "always_online": true
        }
    },
    "oauth_config": {
        "scopes": {
            "bot": [
                "channels:read",
                "channels:write.invites",
                "chat:write",
                "chat:write.customize",
                "files:write",
                "reactions:write",
                "users:read",
                "users:read.email",
                "groups:read"
            ]
        }
    },
    "settings": {
        "org_deploy_enabled": false,
        "socket_mode_enabled": false,
        "token_rotation_enabled": false
    }
}
```

Once the test connection passes, we should see a confirmation message in the Slack channel: "Slack/Jenkins plugin: we're all set on http://localhost:8080/"

## Using Slack Notifications in Jenkins Pipelines

### Setup

Create a new branch, e.g., `feature/slack-notification` from `main`.

Use the Pipeline Syntax Generator to generate the `slackSend` step.

### Adding Notifications

Add `slackSend` steps in the `post` block for different build statuses (success, failure, etc.).

Define a method to handle notifications based on build status.

Example Pipeline:

```groovy
def slack_notification() { 
		
    def buildResult = currentBuild.currentResult
    def buildUrl = env.BUILD_URL ?: 'URL not available'  // Groovy Elvis operator: shorthand for if BUILD_URL is not null, use it; otherwise, use 'URL not available'
    
    if (buildResult == 'UNSTABLE') {
        slackSend channel: 'demo-notificaions-1', 
                    color: '#ff8c00ff', 
                    message: "Build Started: ${env.JOB_NAME} ${env.BUILD_NUMBER}\n${buildUrl}",  // \n is a newline character to separate the build info from the URL
                    teamDomain: 'jenkins-workspace', 
                    tokenCredentialId: 'Slack-Jenkins-OAUTH-Token'
        println("Color of the build is: Orange")
    } 

    else if (buildResult == 'ABORTED') {
        slackSend channel: 'demo-notificaions-1', 
                    color: '#809fff', 
                    message: "Build Started: ${env.JOB_NAME} ${env.BUILD_NUMBER}\n${buildUrl}",
                    teamDomain: 'jenkins-workspace', 
                    tokenCredentialId: 'Slack-Jenkins-OAUTH-Token'
        println("Color of the build is: Blue")
    } 

    else if (buildResult == 'SUCCESS') {
        slackSend channel: 'demo-notificaions-1', 
                    color: '#99ff66', 
                    message: "Build Started: ${env.JOB_NAME} ${env.BUILD_NUMBER}\n${buildUrl}",
                    teamDomain: 'jenkins-workspace', 
                    tokenCredentialId: 'Slack-Jenkins-OAUTH-Token'
        println("Color of the build is: Green")
    } 

    else if (buildResult == 'FAILURE') {
        slackSend channel: 'demo-notificaions-1', 
                    color: '#ff0000', 
                    message: "Build Started: ${env.JOB_NAME} ${env.BUILD_NUMBER}\n${buildUrl}",
                    teamDomain: 'jenkins-workspace', 
                    tokenCredentialId: 'Slack-Jenkins-OAUTH-Token'
        println("Color of the build is: Red")
    }

    else {
        slackSend channel: 'demo-notificaions-1', 
                    color: '#808080', 
                    message: "Build Started: ${env.JOB_NAME} ${env.BUILD_NUMBER}\n${buildUrl}",
                    teamDomain: 'jenkins-workspace', 
                    tokenCredentialId: 'Slack-Jenkins-OAUTH-Token'
        println("Color of the build is: Gray (for other statuses)")
    }
}
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
    
    post {
        always {
            slack_notification()
        }
    }
}
```

## Learning Groovy for Jenkins

### Introduction

Groovy is used in Jenkins for scripting.

### Key Patterns

1. Access Jenkins: `Jenkins.instance.<method>`
2. Find Configuration: `Jenkins.instance.getDescriptorByType(Class.forName("..."))`
3. Save Changes: `thing.save(); Jenkins.instance.save()`
4. Explore Objects: `println obj.class.methods.collect { it.name }`

### Resources

1. [Jenkins JavaDoc](https://javadoc.jenkins.io/)
2. [Script Console Wiki](https://wiki.jenkins.io/display/JENKINS/Jenkins+Script+Console)
3. [Plugin Developer Guide](https://www.jenkins.io/doc/developer/)
4. [Groovy Documentation](http://groovy-lang.org/documentation.html)
5. [Extend Jenkins](https://www.jenkins.io/doc/developer/)
6. [Apache Groovy Docs](https://groovy-lang.org/documentation.html)
7. [Jenkins Core](https://javadoc.jenkins.io/index-core.html)
8. [Plugins Index](https://plugins.jenkins.io/)
9. [Script Console](https://www.jenkins.io/doc/book/managing/script-console/)

### Simple Breakdown: What to Memorize vs Practice

#### Memorize (8 Things)

1. **The Root Object (1 thing)**  
   `Jenkins.instance`  // This is everything

2. **Discovery Patterns (3 things)**  
   - See what you can do with anything: `obj.class.methods.each { println it.name }`  
   - Find configuration for anything: `Jenkins.instance.getDescriptorByType(Class.forName("..."))`  
   - Save changes: `thing.save(); Jenkins.instance.save()`

3. **Useful Shortcuts (4 things)**  
   - Define variable: `def name = "value"`  
   - Loop through list: `["list", "items"].each { }`  
   - If statement: `if(condition) { }`  
   - String with variable: `"string ${variable}"`

#### Quick Reference Card

Always remember:  
1. `Jenkins.instance` → starting point  
2. `.class.methods` → shows what you can do  
3. `getDescriptorByType()` → gets config  
4. `.save()` → saves changes


### Elvis Operator

The "Elvis operator" is a shorthand ternary operator. It provides a default value if an expression is false-ish.

Example:  
`displayName = user.name ?: 'Anonymous'`

This is equivalent to:  
`displayName = user.name ? user.name : 'Anonymous'`

Reference: [Groovy Operators](https://groovy-lang.org/operators.html#_elvis_operator)
