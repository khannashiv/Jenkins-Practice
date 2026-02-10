# Jenkins Pipeline: Integration Testing on AWS EC2

This repository contains a Jenkins pipeline for integration testing and deployment of a solar system application on AWS EC2 instances.

## Pipeline Overview

The pipeline includes the following key stages:

1. **Conditional Execution**: Only triggers on `release/*` branches
2. **AWS Integration**: Uses AWS CLI and Jenkins AWS plugin for EC2 operations
3. **EC2 Instance Management**: Retrieves EC2 instance details and extracts connection information
4. **Application Deployment**: Deploys a solar system application with MongoDB backend on EC2

## Prerequisites

### Jenkins Setup
- Jenkins with Pipeline plugin
- AWS Credentials plugin
- SSH Agent plugin

### AWS Configuration
1. AWS IAM credentials with EC2 access
2. EC2 instance(s) running with proper security groups
3. SSH key pair for EC2 access

### Required Jenkins Credentials
- `AWS-Secret`: AWS Access Key and Secret Key
- `SSH-KVP`: SSH private key for EC2 access

## Pipeline Components

### 1. Conditional Execution
```groovy
when {
  branch 'release/*'
}
```
The pipeline only executes for branches matching the `release/*` pattern.

### 2. AWS Integration
```groovy
withAWS(credentials: 'AWS-Secret', region: 'us-east-1') {
    // AWS operations
}
```
Uses Jenkins AWS plugin to handle AWS authentication and operations.

### 3. EC2 Instance Discovery
The pipeline can extract EC2 instance information using AWS CLI commands:
```bash
aws ec2 describe-instances --instance-ids i-1234567890abcdef0
```
Key fields from the response:
- `PublicDnsName`: Public DNS hostname (e.g., `ec2-34-253-223-13.us-east-2.compute.amazonaws.com`)
- `PublicIpAddress`: Public IP address (e.g., `34.253.223.13`)
- `State.Name`: Instance state (e.g., `running`)

### 4. Deployment Script
The deployment stage performs the following operations:

#### Docker Cleanup
- Stops and removes all existing containers
- Prunes unused images and volumes
- Creates or reuses an application network

#### MongoDB Deployment
- Deploys MongoDB container with authentication
- Waits for MongoDB readiness
- Configures root user credentials from environment variables

#### Application Deployment
- Deploys the solar system application container
- Uses Git commit hash as image tag (falls back to "latest")
- Configures MongoDB connection string
- Waits for application readiness
- Exposes application on port 3000

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGO_USERNAME` | MongoDB root username | `testUser` |
| `MONGO_PASSWORD` | MongoDB root password | `testPass` |
| `MONGO_DB` | MongoDB database name | `solar-system` |
| `GIT_COMMIT` | Git commit hash for image tag | `abc123def456` |

## EC2 JSON Response Structure

The AWS CLI returns EC2 instance information in the following structure:
```json
{
    "Reservations": [
        {
            "Instances": [
                {
                    "PublicDnsName": "ec2-34-253-223-13.us-east-2.compute.amazonaws.com",
                    "PublicIpAddress": "34.253.223.13",
                    "State": {
                        "Name": "running"
                    },
                    // ... other fields
                }
            ]
        }
    ]
}
```

## Useful AWS CLI Commands

1. **Describe all instances**:
   ```bash
   aws ec2 describe-instances
   ```

2. **Describe specific instance**:
   ```bash
   aws ec2 describe-instances --instance-ids i-1234567890abcdef0
   ```

3. **Filter by state**:
   ```bash
   aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
   ```

4. **Extract Public IP**:
   ```bash
   aws ec2 describe-instances --instance-ids i-1234567890abcdef0 \
     --query 'Reservations[0].Instances[0].PublicIpAddress' \
     --output text
   ```

## Health Checks

### MongoDB Health Check
```bash
docker exec mongo-prod mongosh \
  --username "${MONGO_USERNAME}" \
  --password "${MONGO_PASSWORD}" \
  --authenticationDatabase admin \
  --eval "db.adminCommand({ ping: 1 })"
```

### Application Health Check
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/live
# Expected response: 200
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   - Verify SSH key is correctly configured in Jenkins
   - Check EC2 security group allows SSH (port 22)
   - Ensure instance is in running state

2. **Docker Image Not Found**:
   - Verify image exists in Docker Hub
   - Check if Git commit hash is valid
   - Ensure Jenkins has `GIT_COMMIT` environment variable

3. **MongoDB Connection Failed**:
   - Verify MongoDB credentials
   - Check if MongoDB container is running
   - Ensure network connectivity between containers

### Debugging Commands
```bash
# Check container status
sudo docker ps -a

# Check container logs
sudo docker logs mongo-prod
sudo docker logs solar-system-app

# Check network connectivity
sudo docker network inspect app-network

# Check application health
curl http://localhost:3000/live
```

## Security Notes

1. **Credentials Management**:
   - Never hardcode credentials in pipeline scripts
   - Use Jenkins Credentials store for all secrets
   - Rotate credentials regularly

2. **EC2 Security**:
   - Use security groups to restrict access
   - Regularly update EC2 instances
   - Monitor AWS CloudTrail logs

3. **Database Security**:
   - Use strong passwords for MongoDB
   - Enable authentication
   - Consider using AWS Secrets Manager for credential management

## References

- [Jenkins Pipeline When Directive](https://www.jenkins.io/doc/book/pipeline/syntax/#when)
- [AWS CLI EC2 Reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/)
- [AWS Describe Instances Examples](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html#examples)