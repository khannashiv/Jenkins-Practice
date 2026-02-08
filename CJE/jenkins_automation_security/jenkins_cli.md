# Jenkins CLI - Demo 1: Building a Job

This demo demonstrates how to use the Jenkins Command Line Interface (CLI) to build a Jenkins job remotely.

## 📋 Prerequisites

- Jenkins server running and accessible
- Java installed on the machine where CLI will be executed
- Valid Jenkins credentials (username and API token or password)

## 🚀 Setup & Configuration

### 1. Download Jenkins CLI JAR
```bash
# Download the Jenkins CLI jar from your Jenkins server
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
```

### 2. Verify CLI Installation
```bash
# Test the CLI by displaying help
java -jar jenkins-cli.jar -s http://localhost:8080/ help
```

### 3. Authentication Check
```bash
# Check current authentication (anonymous access)
java -jar jenkins-cli.jar -s http://localhost:8080 who-am-i

# Authenticate and check user
java -jar jenkins-cli.jar -s http://localhost:8080 -auth Admin:Your-password who-am-i
```

## 📊 Available Commands

### List All Jobs
```bash
# List all jobs in Jenkins
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:Your-password list-jobs
```

**Example Output:**
```
Chained_freestyle_project_demo_build_stage
Chained_freestyle_project_demo_deploy_stage
Chained_freestyle_project_demo_test_stage
Demo-pipeline-script-project
Demo-pipeline-script-SCM-project
Generate ASCII Artwork
parameterized-pipeline-job
simple-java-springboot-app
```

### Build a Job

#### Basic Syntax
```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ build JOB [OPTIONS]
```

#### Options Available:
- `-c` : Check for SCM changes before building
- `-f` : Follow the build output (stream console output)
- `-p` : Specify build parameters (key=value pairs)
- `-r N` : Retry the build N times if it fails
- `-s` : Wait until the build is completed
- `-v` : Verbose output
- `-w` : Wait until the build is completed

## 🎯 Demo: Building a Parameterized Pipeline Job

### Example 1: Build with Specific Parameters
```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:Your-password \
  build parameterized-pipeline-job \
  -f \
  -p BRANCH_NAME=main \
  -p APP_PORT=8081 \
  -v
```

### Example 2: Build with Different Parameters
```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:Your-password \
  build parameterized-pipeline-job \
  -f \
  -p BRANCH_NAME=test \
  -p APP_PORT=8081 \
  -p SLEEP_TIME=10s \
  -v
```

## 🔧 Command Breakdown

- `-s http://localhost:8080/` : Jenkins server URL
- `-auth admin:Your-password` : Authentication (username:password or username:api_token)
- `build parameterized-pipeline-job` : Action and target job name
- `-f` : Follow the build output in real-time
- `-p PARAM=VALUE` : Pass parameters to the job
- `-v` : Show verbose output

## 📝 Notes

1. **CLI Location**: The Jenkins CLI can run on any machine that can reach the Jenkins server, not necessarily on the Jenkins master itself.

2. **Authentication Methods**:
   - Username/Password
   - Username/API Token (recommended)
   - SSH keys

3. **Security**: For production use, consider using API tokens instead of passwords and secure the credentials properly.

4. **Portability**: The same CLI commands work across different operating systems as long as Java is available.

## 📚 Documentation

For more information, refer to the official Jenkins CLI documentation:
https://www.jenkins.io/doc/book/managing/cli/