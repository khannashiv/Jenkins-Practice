# Jenkins Pipeline: Deploy Application to AWS EC2

This repository contains a Jenkins pipeline configuration for deploying applications to an AWS EC2 instance using SSH.

## Overview

The pipeline automates the deployment process to an AWS EC2 instance through SSH connections. It includes a dedicated stage for deployment that handles SSH authentication and command execution on the target server.

## Features

- **SSH-based deployment**: Secure deployment to EC2 instances using SSH
- **SSH Agent integration**: Uses Jenkins SSH Agent for credential management
- **Declarative Pipeline**: Jenkins declarative pipeline syntax
- **StrictHostKeyChecking configuration**: Configurable SSH security settings

## Pipeline Structure

The pipeline includes a `Deploy-AWS-EC2` stage that:
1. Uses SSH Agent for authentication
2. Establishes SSH connection to the target EC2 instance
3. Executes deployment commands on the remote server

## Key Concepts

### SSH StrictHostKeyChecking

The pipeline configures `StrictHostKeyChecking` to handle SSH security:

- **`StrictHostKeyChecking=no`**: Used in automation to prevent SSH prompts
  - Automatically accepts new host keys
  - Shows warnings for changed keys but still connects
  - Recommended for CI/CD pipelines where manual intervention is not possible

### Scripted vs Declarative Pipeline

- **Declarative Pipeline**: Primary syntax used for this pipeline
- **Scripted Pipeline Elements**: Incorporated using the `script {}` block for complex logic
- **Limitations**: Loops (if, for, while) are not natively supported in declarative syntax and must be wrapped in `script {}` blocks

## Prerequisites

1. **Jenkins Configuration**:
   - Jenkins with Pipeline plugin
   - SSH Agent plugin installed
   - SSH credentials configured in Jenkins Credential Store

2. **Target EC2 Instance**:
   - Running EC2 instance with SSH access
   - Required dependencies installed on the target server
   - Network connectivity from Jenkins server to EC2 instance

3. **AWS Setup**:
   - EC2 instance with proper security groups allowing SSH access
   - Key pair for SSH authentication

## Usage

### Pipeline Snippet Generation

To generate SSH pipeline snippets:
1. Navigate to **Pipeline Syntax** in Jenkins
2. Use **Snippet Generator**
3. Select **sshagent: SSH Agent** step
4. Configure your SSH credentials
5. Generate the pipeline script

### Example Structure

```groovy
pipeline {
    agent any
    stages {
        stage('Deploy-AWS-EC2') {
            steps {
                script {
                    sshagent(['your-ssh-credentials-id']) {
                        sh '''
                            # Set SSH options
                            ssh -o StrictHostKeyChecking=no user@ec2-instance-ip '
                                # Deployment commands here
                                cd /path/to/application
                                ./deploy-script.sh
                            '
                        '''
                    }
                }
            }
        }
    }
}
```

## Security Considerations

1. **SSH Keys**: Store SSH private keys securely in Jenkins Credential Store
2. **Network Security**: Ensure proper security groups and network ACLs
3. **Instance Security**: Follow AWS security best practices for EC2 instances
4. **Credentials Rotation**: Regularly rotate SSH keys and access credentials

## Troubleshooting

### Common Issues

1. **SSH Connection Failures**:
   - Verify network connectivity
   - Check security group rules
   - Validate SSH key permissions

2. **Pipeline Syntax Errors**:
   - Ensure proper use of `script {}` blocks for complex logic
   - Validate Groovy syntax in scripted sections

3. **Permission Issues**:
   - Verify Jenkins user permissions
   - Check file permissions on target EC2 instance

## Documentation References

- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [GitLab Runner SSH Executor](https://docs.gitlab.com/runner/executors/ssh/)
- [SSH StrictHostKeyChecking](https://unix.stackexchange.com/questions/229124/how-do-i-run-the-ssh-command-to-set-stricthostkeychecking-no)

## Notes

- This pipeline uses `StrictHostKeyChecking=no` for automation purposes only
- For production environments, consider implementing proper host key verification strategies
- Always review and adjust security settings based on your organization's policies

## Support

For issues or questions related to this pipeline configuration, please refer to the Jenkins documentation or consult your DevOps team.