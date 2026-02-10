# Jenkins Pipeline with SonarQube Quality Gate Integration

## Overview
This documentation describes the integration of SonarQube quality gates into a Jenkins pipeline to automatically interrupt the pipeline when quality standards are not met. The setup includes configuring webhooks and refactoring pipeline stages for better security and efficiency.

## Architecture
The integration follows this flow:
1. Jenkins pipeline triggers SonarQube analysis
2. SonarQube processes the analysis and determines quality gate status
3. SonarQube sends results back to Jenkins via webhook
4. Jenkins pipeline pauses and waits for quality gate results
5. Pipeline continues or aborts based on quality gate status

## Prerequisites
- Jenkins with SonarQube Scanner and SonarQube Scanner for Jenkins plugins installed
- SonarQube server running (separate container in this setup)
- Jenkins configured with SonarQube server details

## Configuration Steps

### 1. SonarQube Webhook Configuration
- Access SonarQube UI → Administration → Configuration → Webhooks
- Create a new webhook:
  - **Name**: `Jenkins-Sonar-Webhook-1`
  - **URL**: `[Jenkins Webhook URL]`
  - **Secret**: (Optional, not required in this setup)
- Click "Create" to save the webhook

### 2. Jenkins SonarQube Server Configuration
- Navigate to Jenkins → Manage Jenkins → System
- In the SonarQube servers section:
  - **Name**: `Sonar-server-configuration`
  - **Server URL**: `http://localhost:9000`
  - **Server authentication token**: Use credentials manager

### 3. Credential Setup in Jenkins
- Go to Jenkins → Manage Jenkins → Credentials
- Add new credentials:
  - **Kind**: Secret text
  - **Secret**: [SonarQube Token]
  - **ID**: Provide unique identifier
  - **Description**: SonarQube authentication token

### 4. SonarQube Container Setup
The SonarQube server runs as a separate Docker container:

```bash
# Stop and remove existing container
docker stop [container_name]
docker rm [container_name]

# Start new container with proper configuration
docker run -d \
  --name sonarqube-prod \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -e SONAR_WEB_JAVAOPTS="-Xmx3g -Xms1g -XX:MaxRAM=4g" \
  --memory=4g \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -v sonarqube_logs:/opt/sonarqube/logs \
  sonarqube:community

# Wait for initialization
sleep 180
```

### 5. Pipeline Stage Configuration

#### Before Refactoring:
The initial pipeline stage contained hardcoded tokens and debugging statements.

#### After Refactoring:
```groovy
stage ("SonarQube-SAST-Test") {
    steps {
        script {
            timeout(time: 5, unit: 'MINUTES') {
                withSonarQubeEnv(installationName: 'Sonar-server-configuration') {
                    sh """
                        echo "Sonar Scanner HOME: ${env.SONAR_SCANNER_HOME}"
                        "${env.SONAR_SCANNER_HOME}/bin/sonar-scanner" \
                            -Dsonar.projectKey=Solar-system-Nodejs-Project \
                            -Dsonar.sources=app.js \
                            -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info
                    """
                }
                sleep 10
                waitForQualityGate abortPipeline: true
            }
        }
    }
}
```

## Key Improvements

### Security Enhancements
- Removed hardcoded SonarQube tokens from pipeline script
- Using Jenkins credentials manager for token storage
- Eliminated exposed sensitive information in pipeline code

### Code Quality
- Removed redundant debugging statements
- Simplified shell command structure
- Used Jenkins-native SonarQube integration methods

### Pipeline Reliability
- Added timeout wrapper to prevent hanging processes
- Implemented proper quality gate waiting mechanism
- Configured automatic pipeline abortion on quality gate failure

## Troubleshooting

### SonarQube Container Issues
```bash
# Check container logs
docker logs sonarqube-prod
docker logs sonarqube-prod | tail -20

# Monitor container resources
docker stats sonarqube-prod

# Check container status
docker ps | grep sonarqube

# Test SonarQube API
curl http://localhost:9000/api/system/status
curl http://localhost:9000/api/ce/activity
```

### Common Issues and Solutions
1. **Quality Gate Failure**: Adjust code coverage thresholds in SonarQube
2. **Webhook Delivery Issues**: Verify webhook URL accessibility from SonarQube
3. **Analysis Upload Failures**: Check network connectivity between Jenkins and SonarQube
4. **Timeout Errors**: Increase timeout duration in pipeline configuration

## References
- [SonarQube Jenkins Integration Documentation](https://docs.sonarsource.com/sonarqube-cloud/advanced-setup/ci-based-analysis/jenkins/key-features#pipeline-interruption)
- [Jenkins Pipeline Pause Documentation](https://docs.sonarsource.com/sonarqube-cloud/advanced-setup/ci-based-analysis/jenkins/pipeline-pause)

## Notes
- The quality gate threshold was adjusted from 90% to 60% coverage to align with project capabilities
- All sensitive tokens and URLs have been removed from this documentation
- The Jenkins webhook URL should be replaced with the actual Jenkins instance URL
- Regular monitoring of SonarQube container resources is recommended for production use