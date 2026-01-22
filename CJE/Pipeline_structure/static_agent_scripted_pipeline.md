# Demo: Scripted Pipeline with Static Agent

## Overview
This project demonstrates a Jenkins Scripted Pipeline that runs on a static agent with MongoDB integration for unit testing. The pipeline showcases how to migrate from a default master/controller node execution to a designated slave node, implement environment variable management, handle credentials securely, and orchestrate Docker containers for testing.

## Features
- **Static Agent Usage**: Pipeline runs on `ubuntu-docker-jdk17-node18` agent (Ubuntu-based Jenkins slave)
- **MongoDB Integration**: Automated MongoDB container orchestration for unit tests
- **Environment Management**: Multiple methods for handling environment variables (secret and non-secret)
- **Dependency Caching**: Optimized npm dependency caching to reduce build times
- **Secure Credentials**: Safe handling of MongoDB credentials using Jenkins Credentials Store
- **Clean Resource Management**: Proper Docker container cleanup after tests

## Prerequisites
1. Jenkins with the following plugins:
   - Pipeline
   - Credentials Binding
   - Timestamper
   - Build Timeout
   - Workspace Cleanup (optional)

2. Static Agent Configuration:
   - Agent name: `ubuntu-docker-jdk17-node18`
   - OS: Ubuntu with Docker and Docker Compose installed
   - Tools: JDK 17, Node.js 18+

3. Jenkins Credentials:
   - Credential ID: `Mongo-DB-Credentials` (username/password type)

4. Environment Variables:
   - `MONGO_USERNAME` (from credentials)
   - `MONGO_PASSWORD` (from credentials)
   - `MONGO_DB`: `solarSystemDB`
   - `MONGO_PORT`: `27017`

## Complete Pipeline Code

### Full Scripted Pipeline

```groovy
node('ubuntu-docker-jdk17-node18') {
    // 1. Static Environment Configuration
    env.MONGO_PORT = "27017"
    env.MONGO_DB = "solarSystemDB"
    env.NODEJS_HOME = "${tool 'NodeJS-23.11.1'}"
    
    // Configure PATH for Linux/Mac
    env.PATH = "${env.NODEJS_HOME}/bin:${env.PATH}"
    
    // Verify Node.js installation
    sh 'npm --version'
    
    // 2. Pipeline Properties
    properties([
        disableConcurrentBuilds(abortPrevious: true), 
        [$class: 'JobRestrictionProperty']
    ])
    
    // 3. Checkout Source Code
    stage("Checkout-SCM") {
        checkout scm
    }
    
    // 4. Timestamp Wrapper for All Stages
    timestamps {
        // 5. Dependency Installation with Caching
        stage("Installing nodejs dependencies") {
            cache(
                caches: [
                    arbitraryFileCache(
                        cacheName: 'npm-dependency-cache',
                        cacheValidityDecidingFile: 'package-lock.json',
                        excludes: '',
                        includes: '**/*',
                        path: 'node_modules/'
                    )
                ],
                maxCacheSize: 550
            ) {
                script {
                    sh 'node -v'
                    sh 'npm install --no-audit'
                    stash includes: 'node_modules/', name: 'solar-system-node-modules'
                }
            }
        }
        
        // 6. Unit Testing with MongoDB
        stage("Unit Testing") {
            // Secure credential binding for MongoDB
            withCredentials([
                usernamePassword(
                    credentialsId: 'Mongo-DB-Credentials',
                    passwordVariable: 'MONGO_PASSWORD',
                    usernameVariable: 'MONGO_USERNAME'
                )
            ]) {
                runWithMongoDB("npm test")
                sh 'node -v'
            }
        }
    }
}

// 7. Helper Function for MongoDB Integration
def runWithMongoDB(command) {
    try {
        // Start MongoDB using Docker Compose
        sh """
            echo "Starting MongoDB container..."
            docker-compose -f docker-compose-jenkins.yml up -d
            echo "Waiting for MongoDB to be ready..."
            sleep 15s
        """
        
        // Construct MongoDB URI for host-to-container communication
        def mongoUri = "mongodb://${env.MONGO_USERNAME}:${env.MONGO_PASSWORD}@localhost:${env.MONGO_PORT}/${env.MONGO_DB}?authSource=admin"
        
        // Execute command with MONGO_URI environment variable
        withEnv(["MONGO_URI=${mongoUri}"]) {
            echo "Executing Test Command..."
            sh "${command}"
        }
    } finally {
        // Cleanup Docker containers and networks
        sh '''
            echo "Cleanup: Wipe everything including networks"
            docker-compose -f docker-compose-jenkins.yml down
        '''
    }
}
```

### Alternative Environment Variable Methods

#### Method 1: Using `withEnv` for Non-Secret Variables
```groovy
// Example usage within a stage
stage("Example withEnv") {
    withEnv(["MONGO_DB=solar-system", "MONGO_PORT=27017"]) {
        runWithMongoDB("npm test")
    }
}
```

#### Method 2: Direct Environment Assignment
```groovy
// Example in node block
node('ubuntu-docker-jdk17-node18') {
    env.MONGO_PORT = "27017"
    env.MONGO_DB = "solarSystemDB"
    // ... rest of pipeline
}
```

#### Method 3: Credentials Binding (Recommended for Secrets)
```groovy
// Secure credential usage pattern
stage("Secure Stage") {
    withCredentials([
        usernamePassword(
            credentialsId: 'Mongo-DB-Credentials',
            passwordVariable: 'MONGO_PASSWORD',
            usernameVariable: 'MONGO_USERNAME'
        )
    ]) {
        // Access variables as env.MONGO_USERNAME and env.MONGO_PASSWORD
        echo "User: ${env.MONGO_USERNAME}"
        runWithMongoDB("npm test")
    }
}
```

### Docker Compose File Reference
Create a `docker-compose-jenkins.yml` file in your repository:

```yaml
version: '3.8'
services:
  mongodb:
    image: mongo:latest
    container_name: jenkins-test-mongo
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USERNAME}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ismaster')"]
      interval: 5s
      timeout: 30s
      retries: 3
      start_period: 40s

  solar-system-nodejs-app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: jenkins-solar-system-app
    environment:
      MONGO_URI: "mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@mongodb:27017/${MONGO_DB}?authSource=admin"
    # command: ["sh", "-c", "sleep 15s && npm test"]  # TEST MODE for Jenkins
    # No ports mapping - tests run internally within the container.
    command: ["sh", "-c", "sleep infinity"]
    depends_on:
      mongodb:
        condition: service_healthy
```

## Migration Examples

### From Declarative Pipeline
```groovy
// Declarative Pipeline (Original)
stage ("Unit Testing") {
    steps {
        script {
            runWithMongoDB("npm test")
            sh 'node -v'
        }
    }
}

// Scripted Pipeline (Migrated)
stage ("Unit Testing") {
    sh 'node -v'
    runWithMongoDB("npm test")
}
```

### Agent Configuration Migration
```groovy
// Before: Running on master/controller (implicit)
node {
    // Pipeline code here
}
// After: Running on specific static agent in Scripted Pipeline
node('ubuntu-docker-jdk17-node18') {
    // Pipeline code here
}
```

## Pipeline Breakdown by Section

### 1. Agent Specification
```groovy
node('ubuntu-docker-jdk17-node18') {
    // Executes on EC2 t2.micro with Ubuntu, Docker, JDK17, Node18
}
```

### 2. Environment Configuration
- Sets MongoDB connection parameters
- Configures Node.js tool location
- Updates system PATH for command execution

### 3. Pipeline Properties
- Disables concurrent builds (aborts previous)
- Adds job restrictions as needed

### 4. Source Code Management
- Uses `checkout scm` for repository cloning
- Supports Git, SVN, and other SCM systems

### 5. Dependency Management with Caching
- Caches `node_modules` based on `package-lock.json`
- Uses Jenkins arbitrary file cache plugin
- Stashes dependencies for potential cross-stage usage

### 6. Testing with MongoDB
- Securely binds MongoDB credentials
- Orchestrates Docker containers for isolated testing
- Implements proper cleanup in finally block

### 7. Helper Function
- Manages MongoDB container lifecycle
- Handles environment variable propagation
- Ensures resource cleanup regardless of test outcome

### 8. Q&A

- Q: How are environment variables passed to Docker containers?
- A:
    - withCredentials sets environment variables in the Jenkins execution context
    - These are inherited by the sh step inside runWithMongoDB
    - Docker Compose reads them from the shell environment
    - No explicit parameter passing needed - it's all through environment inheritance

- Q: what is the meaning of following block in the helper function?
```groovy  
        // Construct MongoDB URI for host-to-container communication
        def mongoUri = "mongodb://${env.MONGO_USERNAME}:${env.MONGO_PASSWORD}@localhost:${env.MONGO_PORT}/${env.MONGO_DB}?authSource=admin"
        
        // Execute command with MONGO_URI environment variable
        withEnv(["MONGO_URI=${mongoUri}"]) {
            echo "Executing Test Command..."
            sh "${command}"
        }
```
- A: Two-Step Process:

    Construction (def mongoUri = ...):

        Dynamically builds a MongoDB connection string using credentials from Jenkins secrets
        Format: mongodb://username:password@localhost:port/database?authSource=admin
        Example: mongodb://admin:secret123@localhost:27017/solarSystemDB?authSource=admin

    Injection (withEnv(["MONGO_URI=${mongoUri}"]) { ... }):

        Bridges the Groovy/Jenkins context to the shell execution context
        Makes MONGO_URI available as an environment variable for npm test
        Enables Node.js to access it via process.env.MONGO_URI
    
    Key Insights:

        Without withEnv: The connection string exists only as a Groovy variable; npm test cannot access it
        With withEnv: The string becomes a shell environment variable that Node.js can read
        Security: Jenkins automatically masks credentials in logs when using withEnv

    Why This is Critical:

        Your Node.js application expects process.env.MONGO_URI to connect to MongoDB.
        This block delivers the properly authenticated connection string from Jenkins secrets to your application.
        It's the essential link between pipeline credentials and application runtime configuration.

## Usage Instructions

### 1. Create Jenkins Pipeline Job
1. Navigate to Jenkins → New Item
2. Select "Pipeline" type
3. Name: `solar-system-scripted-pipeline`

### 2. Configure Pipeline
```groovy
// In Pipeline script section, paste the complete pipeline code
// OR point to Jenkinsfile in repository
Definition: Pipeline script from SCM
Repository URL: [https://gitea.com/my-demo-active-org/solar-system-migrate.git]
Branch: */pipeline/scripted
Script Path: Jenkinsfile
```

### 3. Setup Credentials
1. Go to Jenkins → Credentials → System → Global credentials
2. Add new credentials:
   - Kind: Username with password
   - ID: `Mongo-DB-Credentials`
   - Username: [Your MongoDB username]
   - Password: [Your MongoDB password]

### 4. Configure Node.js Tool
1. Go to Jenkins → Manage Jenkins → Tools
2. Add NodeJS installation:
   - Name: `NodeJS-23.11.1`
   - Install automatically (select version)

### 5. Verify Agent Availability
- Ensure `ubuntu-docker-jdk17-node18` agent is online
- Verify Docker and Docker Compose are installed on agent
- Confirm network connectivity between agent and Jenkins master

## Troubleshooting Guide

### Build Failures
1. **Agent Offline**: Check agent connectivity in Jenkins → Manage Nodes
2. **Docker Permission Denied**: 
   ```bash
   # On agent machine
   sudo usermod -aG docker jenkins
   sudo systemctl restart docker
   ```
3. **Credential Not Found**: Verify credential ID matches exactly

### Testing Issues
1. **MongoDB Connection Failed**:
   - Check if port 27017 is available
   - Verify credential binding in logs
   - Inspect Docker container logs

2. **npm test Failures**:
   - Check Node.js version compatibility
   - Verify test script in package.json
   - Ensure all dependencies are installed

### Performance Optimization
1. **Cache Not Working**:
   - Verify cache configuration matches actual paths
   - Check cache size limits
   - Monitor cache hit/miss ratios

2. **Slow Docker Startup**:
   - Consider using pre-warmed images
   - Optimize Docker Compose file
   - Adjust sleep timing based on actual startup time

## Monitoring and Logs

### Access Build Logs
- **Console Output**: Pipeline build #5 shows detailed execution
- **Project Path**: Organization-folder-demo/solar-system-migrate/pipeline/scripted
- **Timestamps**: All stages include execution timing

### Key Log Indicators
```bash
# Successful indicators
[Pipeline] node
Running on ubuntu-docker-jdk17-node18
Starting MongoDB container...
Waiting for MongoDB to be ready...
Executing Test Command...
Cleanup: Wipe everything including networks
Finished: SUCCESS
```

## Best Practices Implemented

1. **Security**: Never expose secrets in logs or code
2. **Reliability**: Try-finally ensures cleanup
3. **Performance**: Dependency caching reduces build times
4. **Maintainability**: Helper function for complex logic
5. **Portability**: Environment abstraction for different agents
6. **Resource Management**: Proper Docker cleanup prevents orphaned containers

## Reference
- **Full Implementation**: See build #5 for complete console output
- **Agent Details**: EC2 t2.micro Ubuntu with Docker, JDK17, Node18
- **Repository**: Contains Jenkinsfile and docker-compose-jenkins.yml
- **Credentials**: Securely stored in Jenkins Credentials Store

## Support
For issues with this pipeline:
1. Check Jenkins console output for specific errors
2. Verify agent configuration and connectivity
3. Ensure all prerequisites are met
4. Review the Docker Compose file for environment variable consistency

