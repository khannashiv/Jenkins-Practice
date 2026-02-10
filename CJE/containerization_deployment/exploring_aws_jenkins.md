# Demo: Exploring AWS with Jenkins and Docker

## Overview
This demo demonstrates how to integrate AWS EC2 instances with Jenkins for automated Docker deployments. The workflow includes setting up an EC2 instance, installing Docker, configuring Jenkins with AWS plugins, and establishing secure connections between Jenkins and EC2.

## Prerequisites
- AWS Account with appropriate IAM permissions
- Jenkins instance (can be local or cloud-based)
- Basic understanding of AWS services, Jenkins, and Docker

## Demo Steps

### 1. AWS EC2 Instance Setup
- **Create an EC2 instance** in your preferred AWS region
- Choose appropriate instance type (t2.micro for testing)
- Configure security groups to allow:
  - SSH (port 22) - for Jenkins connections
  - HTTP (port 80) - for application access
  - Custom TCP (port 8080) - for Jenkins UI if applicable
- **Install Docker** on the EC2 instance:
  ```bash
  # Update system packages
  sudo yum update -y
  
  # Install Docker
  sudo yum install docker -y
  
  # Start Docker service
  sudo service docker start
  
  # Add current user to docker group
  sudo usermod -a -G docker ec2-user
  ```

### 2. Jenkins Configuration

#### Install Required Plugins
1. Access Jenkins UI at `http://<your-jenkins-server>:8080`
2. Navigate to **Manage Jenkins** → **Manage Plugins**
3. Install the following plugins:
   - **AWS Steps** - For AWS integration
   - **SSH Agent** - For SSH connections to EC2

#### Configure AWS Credentials
1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **Add Credentials**
3. Configure AWS credentials:
   - **Kind**: AWS Credentials
   - **Scope**: Global
   - **Access Key ID**: Your AWS Access Key
   - **Secret Access Key**: Your AWS Secret Key
   - **ID**: aws-credentials (or meaningful identifier)

#### Configure SSH Credentials for EC2
1. Navigate to **Manage Jenkins** → **Manage Credentials**
2. Click **Add Credentials**
3. Configure SSH credentials:
   - **Kind**: SSH Username with private key
   - **Username**: ec2-user (or your EC2 username)
   - **Private Key**: Paste the private key corresponding to your EC2 instance
   - **ID**: ec2-ssh-key (or meaningful identifier)

### 3. Jenkins Pipeline Setup

#### Create a New Pipeline Job
1. Click **New Item** in Jenkins
2. Enter a job name and select **Pipeline**
3. In the pipeline configuration, select **Pipeline script** or **Pipeline script from SCM** based on your preference

#### Sample Pipeline Script
```groovy
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        EC2_INSTANCE_ID = 'your-instance-id'
        DOCKER_IMAGE = 'your-docker-image:latest'
    }
    
    stages {
        stage('Connect to EC2') {
            steps {
                script {
                    // Use SSH Agent plugin to connect to EC2
                    sshagent(['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${EC2_INSTANCE_IP} '
                                # Pull Docker image
                                docker pull ${DOCKER_IMAGE}
                                
                                # Stop existing container if running
                                docker stop app-container || true
                                docker rm app-container || true
                                
                                # Run new container
                                docker run -d --name app-container -p 80:8080 ${DOCKER_IMAGE}
                            '
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    sshagent(['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${EC2_INSTANCE_IP} '
                                docker ps | grep app-container
                                curl -f http://localhost:80 || exit 1
                            '
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Docker deployment successful!'
        }
        failure {
            echo 'Docker deployment failed!'
        }
    }
}
```

### 4. Security Considerations
- **IAM Roles**: Consider using IAM roles instead of access keys for EC2 instances
- **Security Groups**: Restrict SSH access to Jenkins server IP only
- **Key Management**: Store private keys securely and rotate them regularly
- **Network Security**: Use VPC and subnet configurations appropriately

### 5. Troubleshooting Common Issues

#### Connection Issues
- Verify security group rules allow SSH from Jenkins IP
- Check EC2 instance is running
- Validate SSH key permissions

#### Docker Permission Issues
```bash
# On EC2 instance, if Docker commands require sudo:
sudo usermod -aG docker $USER
newgrp docker
```

#### Jenkins Plugin Issues
- Restart Jenkins after plugin installation
- Check plugin compatibility with Jenkins version
- Review Jenkins logs for errors

## Best Practices
1. Use parameterized builds for flexible deployments
2. Implement proper error handling in pipeline scripts
3. Store sensitive data in Jenkins credentials only
4. Monitor EC2 instance costs and auto-scale as needed
5. Implement proper logging and notification mechanisms

## Cleanup
Remember to:
- Terminate EC2 instances when not in use
- Remove unused credentials from Jenkins
- Delete unnecessary Docker images from EC2

## Next Steps
- Implement blue-green deployments
- Add automated testing stages
- Integrate with Docker registry (ECR)
- Set up monitoring and alerting

## Resources
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Documentation](https://docs.docker.com/)
- [AWS Steps Plugin](https://plugins.jenkins.io/aws-steps/)

---
**Note**: Replace placeholder values (instance IDs, IPs, image names) with your actual configuration values before running the pipeline.