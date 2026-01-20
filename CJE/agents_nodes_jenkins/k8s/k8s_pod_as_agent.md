# Demo: Utilizing Kubernetes Pods as Jenkins Agents on AWS EKS

## Overview
This demonstration showcases how to configure Jenkins to use Kubernetes pods as ephemeral build agents on an AWS EKS cluster, including Fargate-based deployments. The solution enables dynamic, scalable Jenkins agents that run in isolated containers within Kubernetes.

## Prerequisites
- Jenkins instance with Kubernetes plugin installed
- AWS EKS cluster with Fargate profiles configured
- Kubernetes CLI (`kubectl`) configured to access the EKS cluster
- AWS CLI configured with appropriate permissions

## Configuration Steps

### 1. Jenkins Pipeline Setup
Create a new pipeline job in Jenkins with the following configuration:

- **Job Type**: Pipeline
- **Name**: `EKS-Cloud-Agent-Demo`
- **Pipeline Definition**: Pipeline script
- **Script Type**: Declarative (Kubernetes)

### 2. Initial Pipeline Script
```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: shell
    image: ubuntu
    command:
    - sleep
    args:
    - infinity
    securityContext:
      runAsUser: 1000
'''
            defaultContainer 'shell'
            retries 2
        }
    }
    stages {
        stage('Main') {
            steps {
                sh 'hostname'
            }
        }
    }
}
```

### 3. Enhanced Pipeline Script
```groovy
pipeline {
    agent {
        kubernetes {
            cloud 'EKS-cluster'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: nodejs-container
    image: node:krypton-bookworm
    command:
    - sleep
    args:
    - infinity
  - name: ubuntu-container
    image: ubuntu
    command:
    - sleep
    args:
    - infinity
'''
            defaultContainer 'ubuntu-container'
            retries 2
        }
    }
    stages {
        stage('Print NodeJS Version') {
            steps {
                container('nodejs-container') {
                    sh 'node -v'
                    sh 'npm -v'
                }
            }
        }
        stage('Print Hostname') {
            steps {
                sh 'hostname'
                sh 'sleep 30s'
            }
        }
    }
}
```

## Challenges and Solutions

### Challenge 1: Fargate Pod Scheduling Failure
**Problem**: Jenkins pods failed to schedule with error:
```
Pod [Pending][Unschedulable] 0/2 nodes are available: 2 node(s) had untolerated taint {eks.amazonaws.com/compute-type: fargate}
```

**Root Cause**: 
- Fargate profiles are namespace-specific mappings to infrastructure
- The default Fargate profile (`fp-default`) only handled pods in `default` and `kube-system` namespaces
- Jenkins was creating pods in the `jenkins` namespace, which had no associated Fargate profile

**Solution**: Create a Fargate profile specifically for the Jenkins namespace:
```bash
# Get the role ARN from your existing fp-default profile
aws eks describe-fargate-profile \
    --cluster-name my-eks-lab \
    --fargate-profile-name fp-default \
    --query 'fargateProfile.podExecutionRoleArn' \
    --output text

# Create a new Fargate profile for the jenkins namespace
aws eks create-fargate-profile \
    --cluster-name my-eks-lab \
    --fargate-profile-name fp-jenkins \
    --pod-execution-role-arn <your-pod-execution-role-arn> \
    --selectors namespace=jenkins
```

**Verification**:
```bash
aws eks describe-fargate-profile --cluster-name my-eks-lab --fargate-profile-name fp-jenkins --query 'fargateProfile.status'
kubectl get pods -n jenkins -w
```

### Challenge 2: Jenkins Agent Connectivity Issues
**Problem**: Agent pods remained offline with status "ContainerCreating" and JNLP agent unable to connect.

**Root Cause**:
- Jenkins URL was configured as `http://localhost:8080/`
- Inside the Kubernetes pod, `localhost` refers to the pod itself, not the Jenkins server
- The JNLP agent couldn't find the Jenkins controller to register itself

**Solution**:
1. **Update Jenkins URL in Global Configuration**:
   - Navigate to `Manage Jenkins` → `System`
   - Change Jenkins URL from `http://localhost:8080/` to your actual Jenkins address
   - In this case: `https://kneadable-saniyah-semierectly.ngrok-free.dev`

2. **Update Kubernetes Cloud Configuration**:
   - Navigate to `Manage Jenkins` → `Clouds` → `Kubernetes`
   - Ensure Jenkins URL field matches your external address
   - Enable WebSocket mode (especially important for ngrok tunnels)

3. **Verify Configuration**:
   - Check agent pod logs: `kubectl logs <pod-name> -n jenkins -c jnlp`
   - Ensure JNLP agent can establish connection

## Key Learnings

### 1. Fargate Profile Management
- Fargate profiles act as namespace-to-infrastructure mappers
- Each namespace requiring Fargate execution needs its own profile
- Profile creation is asynchronous; verify status before use

### 2. Jenkins-Kubernetes Integration
- Specify the cloud name explicitly in pipeline: `cloud 'EKS-cluster'`
- Multiple containers can be defined in a single pod spec
- Use `container()` directive to execute steps in specific containers
- WebSocket mode enables agent connectivity through HTTP tunnels

### 3. Container Configuration
- Always include a `jnlp` container (automatically added by Jenkins)
- Define custom containers for specific build environments
- Use `sleep infinity` pattern to keep containers alive during pipeline execution
- Consider security contexts for production environments

## Monitoring and Troubleshooting

### Useful Commands
```bash
# Check pod status
kubectl get pods -n jenkins

# View detailed pod information
kubectl describe pod <pod-name> -n jenkins

# Check container logs
kubectl logs <pod-name> -n jenkins -c <container-name>

# List Fargate profiles
aws eks list-fargate-profiles --cluster-name my-eks-lab

# Monitor build progress in Jenkins
tail -f /var/log/jenkins/jenkins.log
```

### Common Issues and Resolutions
1. **Pod scheduling delays**: Check Fargate profile status and namespace selectors
2. **Agent offline**: Verify Jenkins URL configuration and network connectivity
3. **Resource constraints**: Adjust CPU/memory requests in pod spec
4. **Image pull failures**: Ensure image names are correct and accessible

## Best Practices

### Security
- Use non-root users in containers when possible
- Implement appropriate resource limits
- Use IAM roles for service accounts (IRSA) for AWS permissions
- Regularly update base images for security patches

### Performance
- Right-size container resources based on workload
- Use appropriate node selectors and tolerations
- Implement pod affinity/anti-affinity rules for critical workloads
- Monitor Fargate pod startup times and adjust retry policies

### Maintainability
- Externalize pod YAML definitions to separate files
- Use Jenkins shared libraries for reusable pipeline components
- Implement proper tagging and versioning for custom images
- Document all configuration changes and their rationales

## Conclusion
This demonstration successfully implemented Jenkins agents running as Kubernetes pods on AWS EKS with Fargate. The solution provides:
- Dynamic, ephemeral build environments
- Isolation between different build jobs
- Scalability through Kubernetes scheduling
- Cost efficiency with Fargate serverless compute

By addressing the challenges of Fargate namespace mapping and Jenkins agent connectivity, we established a robust foundation for CI/CD pipelines in Kubernetes environments.