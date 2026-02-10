# Unit Testing with JUnit Reports and Secure Credentials Management

## Overview
This project demonstrates secure unit testing with Jenkins pipeline integration, featuring MongoDB integration and JUnit report generation while securely handling sensitive credentials.

## Key Features
- **Secure Credentials Management**: Uses Jenkins Credentials Binding plugin instead of plain environment variables
- **Automated Unit Testing**: Integrates `npm test` with JUnit report generation
- **Dockerized MongoDB**: Self-contained test environment setup
- **Flexible Configuration**: Supports both Docker Compose and standalone deployments

## Security Implementation

### Problem with Plain Environment Variables
```groovy
// ❌ UNSAFE - Exposes credentials in Jenkinsfile and logs
environment {
    MONGO_URI = "mongodb://testUser:testPass@127.0.0.1:27017/solarSystemDB?authSource=admin"
    MONGO_USERNAME = "testUser"
    MONGO_PASSWORD = "testPass"
}
```

### Secure Solution with Credentials Binding
```groovy
// ✅ SECURE - Uses Jenkins Credentials Store
withCredentials([usernamePassword(
    credentialsId: 'Mongo-DB-Credentials',
    passwordVariable: 'MONGO_PASSWORD',
    usernameVariable: 'MONGO_USERNAME'
)]) {
    // Credentials are securely injected here
}
```

## Jenkins Pipeline Stage

### Unit Testing Stage
```groovy
stage ("Unit Testing") {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'Mongo-DB-Credentials',
            passwordVariable: 'MONGO_PASSWORD',
            usernameVariable: 'MONGO_USERNAME'
        )]) {
            script {
                // Dynamic MONGO_URI construction
                env.MONGO_URI = "mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}?authSource=admin"
                
                // Docker MongoDB setup and testing
                sh '''
                    # Cleanup existing containers
                    docker stop test-mongo || true
                    docker rm test-mongo || true
                    
                    # Start MongoDB container
                    docker run -d --name test-mongo -p 27017:27017 \
                        -e MONGO_INITDB_ROOT_USERNAME=${MONGO_USERNAME} \
                        -e MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD} \
                        mongo:latest
                    sleep 15
                    
                    # Run tests
                    echo "DEBUG: Running tests with MONGO_URI=${MONGO_URI}"
                    npm test
                '''
            }
        }
        
        // JUnit Report Archiving
        junit allowEmptyResults: true, keepProperties: true, testResults: 'test-results.xml'
    }
}
```

## Database Connection Patterns

### Application Configuration
```javascript
// app.js - MongoDB Connection
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/solarSystemDB';
mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
});
```

### Connection URI Patterns

| Database       | Default Port | Connection Pattern                          |
|----------------|--------------|---------------------------------------------|
| **MongoDB**    | 27017        | `mongodb://user:pass@host:27017/db`        |
| PostgreSQL     | 5432         | `postgresql://user:pass@host:5432/db`      |
| MySQL          | 3306         | `mysql://user:pass@host:3306/db`           |
| Redis          | 6379         | `redis://host:6379`                        |
| Elasticsearch  | 9200         | `http://host:9200`                         |

## Environment Configuration

### Jenkins Pipeline Variables
```groovy
// Jenkinsfile - For host-based app accessing containerized DB
env.MONGO_URI = "mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@127.0.0.1:27017/solarSystemDB?authSource=admin"
```

### Docker Compose Variables
```yaml
# docker-compose.yml - For container-to-container communication
environment:
  MONGO_URI: "mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@mongodb:27017/solarSystemDB?authSource=admin"
```

## Key Differences in Configuration

### Context-Based URI Construction

| Context                          | Hostname     | Example                                                              |
|----------------------------------|--------------|----------------------------------------------------------------------|
| **Docker Compose**               | Service name | `mongodb://user:pass@mongodb:27017/db` (internal Docker network)     |
| **Jenkins (host to container)**  | localhost    | `mongodb://user:pass@127.0.0.1:27017/db` (host network)              |
| **Production/External**          | Server host  | `mongodb://user:pass@db-server:27017/db` (external network)          |

## Universal Rule
For any database/service in Docker environments:
- **Hostname** = Service name in `docker-compose.yml`
- **Port** = Internal container port (not necessarily the exposed port)

**Service Name in docker-compose.yml = Hostname in Docker network! 🚀**

## Quick Reference Commands

### Environment Variable Usage
| Usage                     | Meaning                   |
|---------------------------|---------------------------|
| `env.VAR = "value"`       | **Define / Set** variable |
| `env.VAR` or `${env.VAR}` | **Call / Read** variable  |

### Debug Commands
```bash
# View environment variables
echo "MONGO_URI: ${MONGO_URI}"

# Test MongoDB connection
mongosh "mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@localhost:27017"

# Check running containers
docker ps
```

## Documentation Links
- [Jenkins Environment Variables](https://www.jenkins.io/doc/pipeline/tour/environment/)
- [Jenkinsfile Best Practices](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables)
- [Docker Installation Guide](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

## Setup Instructions

1. **Store Credentials in Jenkins**
   - Go to Jenkins → Manage Jenkins → Credentials
   - Add new "Username with password" credentials
   - Use ID: `Mongo-DB-Credentials`

2. **Configure Pipeline**
   - Update `MONGO_HOST`, `MONGO_PORT`, `MONGO_DB` in Jenkinsfile
   - Ensure test-results.xml matches your test runner output

3. **Run Pipeline**
   - The pipeline will automatically:
     - Securely inject credentials
     - Start MongoDB container
     - Run unit tests
     - Archive JUnit reports
     - Clean up resources

## Best Practices
- ✅ Always use `withCredentials` for sensitive data
- ✅ Use container names for Docker-to-Docker communication
- ✅ Use localhost/127.0.0.1 for host-to-container access
- ✅ Archive test results for historical tracking
- ✅ Clean up containers after testing