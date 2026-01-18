# Jenkins Administration Activities

This document covers advanced Jenkins administration topics, including security settings, access controls, plugins for restrictions and monitoring, and scaling considerations.

## Demo: Global Security Settings

### Overview

Jenkins comes pre-configured with strong security measures to minimize potential vulnerabilities, effectively securing your Jenkins instance and reducing attack vectors. However, you may need to adjust these settings for specific jobs. Always loosen security cautiously and only when absolutely necessary.

Key security options include:

- **Markup Formatting**: Allows users to format descriptions in jobs, views, and system messages for better readability. Without proper controls, users could inject malicious code, leading to vulnerabilities like cross-site scripting (XSS) attacks.
- **CSRF Protection**: Prevents cross-site request forgery attacks, where attackers trick logged-in users into performing unintended actions (e.g., triggering builds or modifying configurations).

### Markup Formatters

Jenkins offers several markup format options:

1. **Plain Text** (default): The most secure option, as it escapes all input to prevent code interpretation.
2. **Safe HTML**: Allows basic HTML formatting while removing risky elements to mitigate XSS.
3. **Custom Markup Formatters**: Provided by plugins for advanced formatting, requiring careful configuration.

### CSRF Protection

CSRF is a web vulnerability allowing attackers to exploit active sessions. Jenkins includes built-in CSRF protection (also called Crumb protection), adding hidden tokens to forms and requests. It is highly recommended to keep this enabled.

**Prevention Tips**:
- Enable CSRF settings in Jenkins.
- Train users to avoid suspicious links while logged in.

### Demo: Configuring Markup Formatter

**Official Documentation**: [Jenkins Markup Formatter](https://www.jenkins.io/doc/book/security/markup-formatter/)

**Steps**:
1. Navigate to **Manage Jenkins** > **System** > **System Message** and update it with HTML content (e.g., `<b>Bold Text</b>`).
2. Initially, it renders as plain text due to the default "Plain Text" formatter.
3. Go to **Manage Jenkins** > **Security** > **Markup Formatter** and change to "Safe HTML".
4. The HTML now renders properly on the Jenkins homepage.

## Demo: Access Control for Builds

### Overview

Similar to access control for users, builds in Jenkins run with an associated user authorization.
By default, builds run as the internal SYSTEM user with full permissions. To restrict this, use the Authorize Project Plugin for global or per-project authorization.

**Official Documentation**:
- [Build Authorization](https://www.jenkins.io/doc/book/security/build-authorization/)
- [Authorize Project Plugin](https://plugins.jenkins.io/authorize-project/)

### Installation and Setup

1. Install the Authorize Project Plugin.
2. Run a test job (e.g., `NodeJS-NPM-version-test`) to see it runs as SYSTEM.

### Configuration Options

- **Project Default Build Authorization**: Global setting.
- **Per-Project Configurable Build Authorization**: Individual job settings.

#### Case 1: Project Default - Run as Anonymous

- Set strategy to "Run as Anonymous".
- Builds fail with permission errors (e.g., "'anonymous' lacks permission to run on 'Jenkins'").
- Tested on jobs like `String-Interpolation-Demo`, `Demo-pipeline-script-project`, and `NodeJS-NPM-version-test`.
- Revert to SYSTEM to allow builds.

#### Case 2: Per-Project Configurable Authorization

- Enable per-project settings; a padlock icon appears on jobs.
- For `String-Interpolation-Demo`: Set to "Run as User who Triggered the Build"  Success.
- For `NodeJS-NPM-version-test`: Initially "Run as Anonymous"  Fails; change to "Run as User who Triggered the Build"  Success as user2.

This allows fine-grained control, assigning different users per job.

## Demo: Job Restrictions Plugin

### Overview

The Job Restrictions Plugin restricts job execution on nodes to enhance security or behavior.

**Official Documentation**: [Job Restrictions Plugin](https://plugins.jenkins.io/job-restrictions/)

**Features**:
- **Node-Level Restrictions**: Limit jobs by name pattern (e.g., only "QA_.*" jobs) or prevent user jobs on the controller.
- **Trigger Restrictions**: Prohibit manual builds or allow only specific owners.
- Extensible via plugins.

### Demo Steps

1. Install the plugin.
2. Go to **Manage Jenkins** > **Nodes** > **Built-in Node** > **Configure**.
3. Enable "Restrict job execution at node level".
4. Add restriction: Regular Expression for job name (e.g., `NodeJS-.*` will run jobs starting with "NodeJS" while no other jobs will run).
5. Test: `NodeJS-NPM-version-test` runs; others (e.g., `String-Interpolation-Demo`) pend.
6. Add OR condition: `NodeJS.*` OR started by user4.
7. Now, jobs starting with "NodeJS" or triggered by user4 run.

This ensures controlled execution, useful for multi-user environments.

## Demo: Job Configuration History Plugin

### Overview

This plugin saves copies of job and system configuration files for every change, allowing diffs and restores.

**Official Documentation**: [Job Configuration History Plugin](https://plugins.jenkins.io/jobConfigHistory/)

**Capabilities**:
- Side-by-side diffs.
- Restore old configurations (jobs only).
- Tracks system changes.

### Demo Steps

1. Install the plugin and restart.
2. Create a job (e.g., `My_ORG_JHCP`) with a shell step: `echo "This is a demo for Job Configuration History plugin."`
3. Build, then add another step: `sleep 5s`.
4. View history at job level or via `http://localhost:8080/jobConfigHistory`.
5. Compare configs, restore if needed.
6. Delete the job and restore from history.
7. Configure storage path in **Manage Jenkins** > **System** (default: `/var/lib/jenkins/config-history`).

Example config output (XML snippet):

```xml
<?xml version='1.1' encoding='UTF-8'?>
<project>
  <description>My_ORG_JCHP</description>
  <keepDependencies>false</keepDependencies>
  <!-- ... -->
</project>
```

This is essential for auditing and rollback in production.

## Demo: Build Monitor View Plugin

### Overview

Provides a dashboard view for monitoring build statuses.

**Official Documentation**: [Build Monitor Plugin](https://plugins.jenkins.io/build-monitor-plugin/)

### Demo Steps

1. Install the plugin.
2. Create a new view: **Jenkins Home** > **New View** > "Demo-Build-Monitor-View".
3. Select jobs and customize settings (e.g., badges, display options).
4. Add a test job and monitor its status in the view.

Useful for teams needing quick build overviews.

## Jenkins Scaling Capacity Planning

### Theory

- **Horizontal Scaling**: Add more nodes/agents to distribute load.
- **Vertical Scaling**: Increase resources (CPU, memory) on the controller.

Plan based on usage metrics from monitoring tools.

## Demo: Monitoring Jenkins using Java Melody

### Overview

Java Melody monitors Java applications, providing statistics on Jenkins usage.

**Official Documentation**: [Monitoring Plugin](https://plugins.jenkins.io/monitoring/)

### Demo Steps

1. Install the Monitoring Plugin and restart.
2. Go to **Manage Jenkins** > **Monitoring** (Jenkins instance or agents).
3. View stats on memory, CPU, API usage, etc.

This helps optimize performance and resource allocation.
