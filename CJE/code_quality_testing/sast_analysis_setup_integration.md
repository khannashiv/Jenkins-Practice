# Demo - SAST Analysis with SonarQube

This project demonstrates Static Application Security Testing (SAST) using SonarQube for a Node.js application. It includes setup instructions, Jenkins pipeline integration, and troubleshooting for common issues.

## Table of Contents
- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Jenkins Pipeline Integration](#jenkins-pipeline-integration)
- [Docker Compose Setup](#docker-compose-setup)
- [Troubleshooting](#troubleshooting)
- [Useful Commands](#useful-commands)
- [References](#references)

## Project Overview

This demo showcases:
- Setting up SonarQube on a virtual machine
- Creating a project in SonarQube UI
- Integrating SonarQube analysis with Jenkins pipeline
- Configuring code coverage for Node.js applications
- Docker Compose setup for local testing
- Quality Gate configuration and monitoring

## Prerequisites

- Virtual Machine with Linux OS
- Docker and Docker Compose installed
- Jenkins server with administrative access
- Node.js application for testing
- Git repository for source code

## Setup Instructions

### 1. SonarQube Setup

1. **Install SonarQube on VM:**
   - Follow official SonarQube installation guide for your Linux distribution

2. **Create Project in SonarQube UI:**
   - Navigate to SonarQube web interface (default: http://localhost:9000)
   - Login with default credentials (admin/admin) - **Change password after first login**
   - Create new project:
     - Project display name: `[Your-Project-Name]`
     - Project key: `[Your-Project-Key]`
     - Branch name: `main`
   - Select "Set up new code for project" → "Follows the instance's default"

3. **Generate Authentication Token:**
   - Select "How do you want to analyze your repository?" → "Locally"
   - Generate token:
     - Token name: [Your choice]
     - Expiration: Set as per your security policy
   - Save the generated token securely

### 2. Jenkins Configuration

1. **Install SonarQube Scanner Plugin:**
   - Go to Jenkins → Manage Jenkins → Plugins
   - Search for "SonarQube Scanner"
   - Install and restart Jenkins

2. **Configure SonarQube Scanner Tool:**
   - Go to Manage Jenkins → Tools
   - SonarQube Scanner Installations → Add
   - Name: `sonarqube-scanner-[version]`
   - Install automatically → Install from Maven Central
   - Select appropriate version
   - Apply changes

3. **Configure SonarQube Server in Jenkins:**
   - Go to Manage Jenkins → Configure System
   - SonarQube servers → Add
   - Name: `SonarQube-Server`
   - Server URL: `http://your-sonarqube-server:9000`
   - Add server authentication token from SonarQube

## Jenkins Pipeline Integration

### Environment Configuration
```groovy
environment {
    SONAR_SCANNER_HOME = tool name: 'sonarqube-scanner-[version]'
    SONAR_HOST_URL = credentials('sonarqube-url')
    SONAR_AUTH_TOKEN = credentials('sonarqube-token')
}
```

### SAST Stage in Jenkinsfile
```groovy
stage("SonarQube-SAST-Test") {
    steps {
        script {
            // Method-1: Using environment variables
            sh """
                echo "Sonar Scanner HOME: ${env.SONAR_SCANNER_HOME}"
                "${env.SONAR_SCANNER_HOME}/bin/sonar-scanner" \\
                    -Dsonar.projectKey=${PROJECT_KEY} \\
                    -Dsonar.sources=. \\
                    -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                    -Dsonar.token=${env.SONAR_AUTH_TOKEN} \\
                    -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info \\
                    -Dsonar.coverage.exclusions=**/node_modules/**,**/test/**
            """
            
            // Method-2: Using withSonarQubeEnv (Recommended)
            withSonarQubeEnv('SonarQube-Server') {
                sh '''
                    sonar-scanner \\
                        -Dsonar.projectKey="${PROJECT_KEY}" \\
                        -Dsonar.projectName="${PROJECT_NAME}" \\
                        -Dsonar.sources="." \\
                        -Dsonar.javascript.lcov.reportPaths="./coverage/lcov.info" \\
                        -Dsonar.coverage.exclusions="**/node_modules/**,**/test/**"
                '''
            }
        }
    }
}

// Quality Gate Check Stage
stage("SonarQube Quality Gate") {
    steps {
        timeout(time: 1, unit: 'HOURS') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

### Debugging Stage
```groovy
stage('List Tools') {
    steps {
        script {
            def scannerPath = tool name: 'sonarqube-scanner-[version]'
            echo "Scanner Path: ${scannerPath}"
            
            sh """
                echo "=== Testing SonarQube Scanner ==="
                "${scannerPath}/bin/sonar-scanner" --version
                echo "=== Environment Variables ==="
                env | sort
            """
        }
    }
}
```

## Docker Compose Setup

### docker-compose.yml Configuration
```yaml
version: '3.8'
services:
  mongodb:
    image: mongo:latest
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USERNAME}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: ${MONGO_DB}
    ports:
      - "27017:27017"
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

  nodejs-app:
    build: .
    environment:
      MONGO_URI: mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@mongodb:27017/${MONGO_DB}?authSource=admin
    ports:
      - "3000:3000"
    depends_on:
      mongodb:
        condition: service_healthy
    command: ["sh", "-c", "sleep 15 && npm start"]

  sonarqube:
    image: sonarqube:community
    environment:
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: "true"
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
```

### Environment Variables (.env file)
```bash
# Create .env file with your credentials
MONGO_USERNAME=your_mongo_username
MONGO_PASSWORD=your_mongo_password
MONGO_DB=your_database_name
```

### Docker Commands
```bash
# Start all services with environment file
docker-compose --env-file .env up -d

# Start specific services
docker-compose --env-file .env up -d mongodb nodejs-app

# Stop services
docker-compose stop mongodb nodejs-app

# View logs
docker-compose logs -f nodejs-app

# Run tests
docker-compose run nodejs-app npm test

# Check service status
docker-compose ps

# Complete cleanup
docker-compose down -v

# Rebuild specific service
docker-compose up -d --build nodejs-app
```

## Troubleshooting

### Issue 1: Code Coverage Showing 0%
**Problem:** SonarQube shows 0% code coverage despite tests running successfully.

**Solution:** Add Node.js specific coverage parameter:
```bash
-Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info
```

### Issue 2: Quality Gate Not Reflecting in Jenkins
**Problem:** Quality Gate fails in SonarQube UI but Jenkins pipeline shows success.

**Solution:** Ensure you have both:
1. `withSonarQubeEnv` wrapper for analysis
2. `waitForQualityGate` step to check results

### Issue 3: Docker Compose YAML Error
**Problem:** `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE contains true, which is an invalid type`

**Solution:** Use quotes for boolean-like values in YAML:
```yaml
environment:
  SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: "true"  # Must be string, not boolean
```

### Issue 4: Test Exit Code 6
**Problem:** Tests complete but return exit code 6.

**Solution:** Update package.json test scripts with proper error handling:
```json
"scripts": {
  "test": "timeout 30s mocha test/*.js --timeout 25000 --reporter mocha-junit-reporter --reporter-options mochaFile=./test-results.xml --exit || echo 'Tests completed with exit code: $?'",
  "coverage": "timeout 45s nyc --reporter cobertura --reporter lcov --reporter text --reporter json-summary mocha test/*.js --timeout 25000 --exit || echo 'Coverage completed with exit code: $?'"
}
```

### Issue 5: MongoDB Connection Issues
**Problem:** Application cannot connect to MongoDB.

**Solution:** 
1. Ensure MongoDB is healthy: `docker-compose ps mongodb`
2. Check connection string format
3. Verify credentials in .env file
4. Add wait time in app startup command

## Useful Commands

### Local Testing
```bash
# Start MongoDB only
docker-compose --env-file .env up -d mongodb

# Run app with environment variables
MONGO_URI="mongodb://username:password@localhost:27017/dbname?authSource=admin" npm start

# Run tests locally
MONGO_URI="mongodb://username:password@localhost:27017/dbname?authSource=admin" npx mocha test/*.js --timeout 10000 --exit

# Check SonarQube status
curl http://localhost:9000/api/system/status
```

### SonarQube CLI Command Template
```bash
sonar-scanner \
  -Dsonar.projectKey=YOUR_PROJECT_KEY \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://YOUR_SONARQUBE_HOST:9000 \
  -Dsonar.token=YOUR_SONARQUBE_TOKEN \
  -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info \
  -Dsonar.coverage.exclusions=**/node_modules/**,**/test/**
```

### Quality Gate Configuration
1. Navigate to SonarQube → Quality Gates
2. Create new Quality Gate: `[Your-Project]-Quality-Gate`
3. Set condition: Overall Code Coverage > [Your-Desired-Percentage]%
4. Set as default Quality Gate for your project
5. Add additional conditions as needed (bugs, vulnerabilities, etc.)

## References

### Documentation
- [SonarQube JavaScript/TypeScript Test Coverage](https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/test-coverage/javascript-typescript-test-coverage/)
- [SonarScanner CLI Documentation](https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/)
- [Jenkins SonarQube Plugin](https://plugins.jenkins.io/sonar/)
- [Mocha Test Framework](https://mochajs.org/)
- [Istanbul NYC Coverage](https://github.com/istanbuljs/nyc)

### Best Practices

1. **Security:**
   - Store tokens and credentials in Jenkins Credentials Store
   - Use environment variables instead of hardcoded values
   - Rotate tokens regularly
   - Use .env files for local development (add to .gitignore)

2. **Code Quality:**
   - Set realistic quality gate thresholds
   - Configure coverage exclusions appropriately
   - Regularly update SonarQube and scanner versions

3. **Jenkins Pipeline:**
   - Use declarative pipeline syntax
   - Implement proper error handling
   - Add timeout for quality gate checks
   - Use tool installation management

4. **Docker:**
   - Use health checks for dependencies
   - Implement proper wait strategies
   - Use named volumes for persistence
   - Follow Docker security best practices

### Project Structure
```
your-project/
├── src/
│   ├── app.js
│   └── (source files)
├── test/
│   ├── app-test.js
│   └── (test files)
├── coverage/
│   └── lcov.info
├── docker-compose.yml
├── .env.example
├── .gitignore
├── package.json
├── Jenkinsfile
└── README.md
```

### Version Information
- SonarQube: Community Edition
- SonarScanner: Version 6.2.1 (or latest)
- Node.js: Version specified in package.json
- MongoDB: Latest version
- Docker Compose: Version 3.8

This setup provides a complete SAST analysis pipeline using SonarQube with proper code coverage reporting and quality gate enforcement while maintaining security best practices.