# Jenkins Kubernetes Cloud Integration Guide

## Overview
This comprehensive guide demonstrates how to configure Jenkins to dynamically provision build agents on a Kubernetes cloud, specifically Amazon EKS. The setup follows security best practices while ensuring operational efficiency.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Core Concepts](#core-concepts)
3. [Phase 1: EKS Cluster Setup](#phase-1-eks-cluster-setup)
4. [Phase 2: Plugin Installation](#phase-2-plugin-installation)
5. [Phase 3: Authentication Methods](#phase-3-authentication-methods)
6. [Phase 4: Advanced Configuration](#phase-4-advanced-configuration)
7. [Phase 5: Troubleshooting Guide](#phase-5-troubleshooting-guide)
8. [Security Best Practices](#security-best-practices)
9. [Configuration Checklist](#configuration-checklist)

## Prerequisites

### Tools Required
- **Jenkins**: Instance with administrative access
- **AWS CLI**: Configured with appropriate IAM permissions
- **Kubernetes Tools**: 
  - `eksctl` for cluster management
  - `kubectl` for Kubernetes operations
- **Access**: AWS EKS cluster creation permissions

### Plugin Information
- **Plugin Name**: Kubernetes
- **Version**: 4392.v19cea_fdb_5913 (n-1 version recommended)
- **Download URL**: https://updates.jenkins.io/download/plugins/kubernetes/4392.v19cea_fdb_5913/kubernetes.hpi
- **Documentation**: 
  - [Kubernetes Plugin Releases](https://plugins.jenkins.io/kubernetes/releases/)
  - [kubectl Quick Reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

## Core Concepts

### Security Principles
- **Least Privilege**: Grant minimum necessary permissions
- **Namespace Isolation**: Restrict access to specific namespaces
- **Service Account Authentication**: Use Kubernetes-native identities

### Kubernetes RBAC Components
| Component | Scope | Purpose |
|-----------|-------|---------|
| **Service Account** | Namespace | Identity for applications |
| **Role** | Namespace | Permissions within a namespace |
| **ClusterRole** | Cluster-wide | Permissions across cluster |
| **RoleBinding** | Namespace | Links Role to Service Account |
| **ClusterRoleBinding** | Cluster-wide | Links ClusterRole to subjects |

### Role vs ClusterRole Comparison
| Feature | Role | ClusterRole |
|---------|------|------------|
| **Scope** | Single namespace only | Cluster-wide |
| **Can manage nodes/PVs?** | ❌ No | ✔ Yes |
| **Used for namespaced objects?** | ✔ Yes | ✔ Yes (cluster-wide or per-namespace) |
| **Binding Method** | RoleBinding | RoleBinding or ClusterRoleBinding |

## Phase 1: EKS Cluster Setup

### Create EKS Cluster with Fargate
```bash
eksctl create cluster \
  --name my-eks-lab \
  --region us-east-1 \
  --fargate
```

### Verify Cluster Creation
```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name my-eks-lab

# Verify cluster nodes
kubectl get nodes
```

### Cluster Management
⚠️ **Important Note**: EKS clusters cannot be stopped; they must be deleted when not in use:
```bash
eksctl delete cluster --name my-eks-lab --region us-east-1
```

## Phase 2: Plugin Installation

### Installation Methods
1. **Direct HPI Installation**: Upload downloaded `.hpi` file
2. **Advanced URL Installation**:
   - Navigate to **Manage Jenkins → Plugins → Advanced**
   - Paste plugin URL in the "Deploy Plugin" section
   - Click **Deploy** followed by Jenkins restart

### Cloud Configuration Setup
1. Navigate to **Manage Jenkins → Clouds**
2. Click **New Cloud**
3. Select **Kubernetes** as cloud type
4. Provide cloud name (e.g., "kubernetes-cloud")

## Phase 3: Authentication Methods

### Method 1: Kubeconfig File (Not Recommended for Production)
**Security Concern**: Provides admin access to entire cluster

```bash
# Retrieve kubeconfig
kubectl config view --raw
```

**Jenkins Configuration Steps**:
1. Create credentials of type **Secret File**
2. Upload kubeconfig YAML file
3. Provide ID (e.g., `kube-config-us-east`)
4. Select credentials in cloud configuration
5. Test connection

**⚠️ Security Warning**: This method violates least privilege principles by granting cluster-wide admin access.

### Method 2: Service Account with Limited Privileges (Recommended)

#### Step 1: Create Jenkins Namespace
```bash
kubectl create namespace jenkins
```

#### Step 2: Create Service Account
```bash
kubectl -n jenkins create serviceaccount jenkins-service-account
```

#### Step 3: Generate Service Account Token
```bash
# Token valid for 100 days
kubectl -n jenkins create token jenkins-service-account --duration=100d
```

#### Step 4: Configure RBAC Permissions
```bash
# Create RoleBinding with admin privileges within namespace
kubectl -n jenkins create rolebinding jenkins-admin-binding \
  --clusterrole=admin \
  --serviceaccount=jenkins:jenkins-service-account
```

#### Step 5: Jenkins Token Configuration
1. Copy generated JWT token
2. Add as **Secret Text** credential in Jenkins
3. Provide ID (e.g., `k8s-jenkins-sa-token`)
4. Configure Kubernetes cloud with:
   - **Kubernetes URL**: Cluster API endpoint
   - **Namespace**: `jenkins`
   - **Credentials**: Select service account token
   - **Disable https certificate check** (if needed)
5. Test connection

### Token Generation Methods Comparison
| Feature | Secret-based Token (Legacy) | Token Request API (Modern) |
|---------|----------------------------|---------------------------|
| **Storage** | Persists in etcd as Secret | Generated dynamically |
| **Visibility** | Accessible via `kubectl get secret` | Visible only at creation |
| **Security Risk** | Higher (persistent in DB) | Lower (ephemeral) |
| **EKS Compatibility** | Often lacks `aud` claim | Includes proper audience claim |
| **Recommended** | ❌ No | ✔ Yes |

## Phase 4: Advanced Configuration

### Agent Connection Methods
- **JNLP (TCP)**: Default method using TCP ports
- **WebSocket**: Alternative for environments with TCP port restrictions

### Pod Labels Configuration
Define custom labels for better pod management:
```yaml
labels:
  environment: production
  team: devops
  project: jenkins-agents
```

**Usage Example**: Key: `My-org`, Value: `Learning-Jenkins`

### Pod Retention Policies
| Policy | Behavior | Use Case |
|--------|----------|----------|
| **Never** | Pods deleted immediately after execution | Clean resource management |
| **Always** | Pods retained after execution | Debugging/analysis |
| **On Failure** | Pods retained only on failed builds | Failure investigation |

**Recommendation**: Use **Never** for production, **On Failure** for debugging.

### Certificate Configuration
To resolve SSL certificate issues:
1. Extract CA certificate from kubeconfig:
```bash
kubectl config view --raw --minify -o yaml | grep certificate-authority-data
```
2. Decode and add to **Kubernetes server certificate key** field
3. Alternative: Check "Disable https certificate check" for lab environments

## Phase 5: Troubleshooting Guide

### Error 1: 401 Unauthorized
**Symptoms**: `Status(apiVersion=v1, code=401, message=Unauthorized)`

**Root Causes**:
1. Invalid or expired credentials
2. Missing RBAC permissions
3. Incorrect namespace configuration

**Solutions**:
```bash
# Refresh AWS credentials
aws eks update-kubeconfig --region us-east-1 --name my-eks-lab

# Verify RBAC configuration
kubectl get rolebinding -n jenkins
kubectl auth can-i --list --as=system:serviceaccount:jenkins:jenkins-service-account

# Check AWS IAM mapping
kubectl get configmap aws-auth -n kube-system -o yaml
```

### Error 2: PKIX Certificate Validation Failed
**Symptoms**: `PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException`

**Solutions**:
1. Add CA certificate to Jenkins configuration
2. Disable certificate validation (lab only)
3. Verify cluster endpoint accessibility:
   - `https://[CLUSTER-ENDPOINT]/livez`
   - `https://[CLUSTER-ENDPOINT]/readyz`
   - `https://[CLUSTER-ENDPOINT]/healthz`

### Error 3: 403 Forbidden Despite Token
**Symptoms**: `Status(apiVersion=v1, code=403, message=Forbidden)`

**Solutions**:
1. Verify RoleBinding exists:
```bash
kubectl get rolebinding jenkins-admin-binding -n jenkins -o yaml
```
2. Check Service Account association
3. Ensure namespace matches in Jenkins configuration

### Error 4: AWS EKS Console Access Issues
**Symptoms**: "Your current IAM principal doesn't have access to Kubernetes objects"

**Solutions**:
1. Update `aws-auth` ConfigMap:
```yaml
apiVersion: v1
data:
  mapUsers: |
    - userarn: arn:aws:iam::ACCOUNT_ID:user/USERNAME
      username: USERNAME
      groups:
        - system:masters
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
```

## Security Best Practices

### Credential Management
1. **Never embed AWS keys** in kubeconfig files
2. **Rotate service account tokens** regularly in production
3. **Use IAM Roles for Service Accounts** (IRSA) for production workloads
4. **Store tokens** in Jenkins credential manager (not plain text)

### Network Security
1. Use private EKS endpoints for production
2. Configure security groups to restrict access
3. Implement network policies within Kubernetes
4. Enable audit logging for cluster activities

### Resource Management
1. Set resource limits on Jenkins agent pods
2. Implement pod quotas in Jenkins namespace
3. Use Horizontal Pod Autoscaler for agent scaling
4. Monitor pod resource utilization

## Configuration Checklist

### Pre-Configuration
- [ ] AWS CLI configured with appropriate permissions
- [ ] `eksctl` and `kubectl` installed
- [ ] Jenkins instance accessible
- [ ] EKS cluster created and verified

### Plugin Installation
- [ ] Kubernetes plugin downloaded/installed
- [ ] Jenkins restarted after plugin installation
- [ ] Cloud section accessible in Manage Jenkins

### Kubernetes Setup
- [ ] Dedicated `jenkins` namespace created
- [ ] Service account created in namespace
- [ ] Role/RoleBinding configured
- [ ] Service account token generated
- [ ] Token stored as Jenkins credential

### Jenkins Configuration
- [ ] New cloud configured with Kubernetes type
- [ ] Kubernetes URL and namespace set
- [ ] Service account token selected as credentials
- [ ] SSL certificate configured or validation disabled
- [ ] Pod retention policy selected
- [ ] Pod labels configured (optional)
- [ ] Connection test successful

### Validation
- [ ] Test pipeline using Kubernetes agent
- [ ] Verify pod creation/deletion
- [ ] Confirm resource cleanup
- [ ] Validate security restrictions

## Additional Resources

### Sample Pipeline Using Kubernetes Agent
```groovy
pipeline {
    agent {
        kubernetes {
            label 'jenkins-agent'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
"""
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'echo "Building on Kubernetes agent"'
            }
        }
    }
}
```

### Monitoring Commands
```bash
# Monitor Jenkins agent pods
kubectl get pods -n jenkins -w

# Check pod resource usage
kubectl top pods -n jenkins

# View pod logs
kubectl logs -f <pod-name> -n jenkins

# Check events
kubectl get events -n jenkins --sort-by='.lastTimestamp'
```

## Conclusion

This guide provides a comprehensive approach to integrating Jenkins with Kubernetes using secure, production-ready practices. By following these steps, you can:

1. **Minimize security risks** through least privilege access
2. **Improve resource utilization** with dynamic agent provisioning
3. **Enhance scalability** with Kubernetes-native scheduling
4. **Maintain operational control** through proper configuration

Remember that while the initial setup may require troubleshooting, the long-term benefits of automated, scalable CI/CD infrastructure are substantial. Regularly review and update your configuration to align with evolving security requirements and operational needs.