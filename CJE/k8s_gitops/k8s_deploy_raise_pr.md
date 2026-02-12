# README.md

# Gitea Pull Request Automation with Kubernetes Deployment Demo

## 🚀 Overview

This demo showcases the complete CI/CD pipeline automation for creating Pull Requests (PRs) in Gitea as part of a Kubernetes deployment workflow. It demonstrates how to programmatically create PRs using Gitea's Swagger API, integrate with Jenkins pipelines, and deploy applications on Kubernetes with MongoDB.

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Gitea API Integration](#gitea-api-integration)
- [Jenkins Pipeline Configuration](#jenkins-pipeline-configuration)
- [Kubernetes Deployment](#kubernetes-deployment)
- [MongoDB Integration](#mongodb-integration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## ✨ Features

- **Automated PR Creation**: Programmatically create pull requests in Gitea using REST API
- **Jenkins Integration**: Stage-based pipeline with conditional triggers
- **Kubernetes Deployment**: Full application deployment on K8s with MongoDB
- **Auto-seeding Database**: Application automatically initializes MongoDB with sample data
- **Idempotent Operations**: Safe to run multiple times without data duplication
- **Branch Protection**: Enforced branch protection rules for main branches

## 🏗 Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│   Jenkins   │────▶│  Gitea API   │────▶│    PR       │────▶│   GitHub    │
│   Pipeline  │     │  /pulls      │     │  Creation   │     │   Mirror    │
└─────────────┘     └──────────────┘     └─────────────┘     └─────────────┘
                                                           
                                                            ┌─────────────┐
                                                    ArgoCD  │   K8s       │
                                                    Sync    │  Cluster    │
                                                            └─────────────┘
                                                                   │
                                                    ┌──────────────┴──────────────┐
                                                    │                             │
                                            ┌───────▼──────┐             ┌────────▼──────┐
                                            │   App Pod    │             │  MongoDB Pod  │
                                            │   (Node.js)  │◄────────────│   (Stateful)  │
                                            └──────────────┘             └───────────────┘
```

## 📦 Prerequisites

- Gitea account with repository access
- Jenkins server
- Kubernetes cluster
- Docker Hub account
- Gitea Personal Access Token with appropriate permissions

## 🔧 Gitea API Integration

### Official API Documentation

- **Swagger UI**: [https://gitea.com/api/swagger](https://gitea.com/api/swagger)
- **Create PR Endpoint**: [https://gitea.com/api/swagger#/repository/repoCreatePullRequest](https://gitea.com/api/swagger#/repository/repoCreatePullRequest)

### Sample API Call from Swagger

```bash
curl -X 'POST' \
  'https://gitea.com/api/v1/repos/YOUR_ORG/YOUR_REPO/pulls' \
  -H 'accept: application/json' \
  -H 'Authorization: token YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "assignee": "string",
    "assignees": ["string"],
    "base": "string",
    "body": "string",
    "due_date": "2025-12-06T09:10:55.101Z",
    "head": "string",
    "labels": [0],
    "milestone": 0,
    "reviewers": ["string"],
    "team_reviewers": ["string"],
    "title": "string"
  }'
```

### Production API Call

```bash
curl -X 'POST' \
  'https://gitea.com/api/v1/repos/YOUR_ORG/YOUR_REPO/pulls' \
  -H 'accept: application/json' \
  -H 'Authorization: token $GITEA_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "assignee": "YOUR_USERNAME",
    "assignees": ["YOUR_USERNAME"],
    "base": "main",
    "body": "Updated docker image in deployment manifest",
    "head": "feature-$BUILD_ID",
    "title": "Updated docker image"
  }'
```

## 🔑 Gitea Token Configuration

### Token Permissions Required

```
✓ write:activitypub
✓ write:misc
✓ write:notification  
✓ write:organization
✓ write:package
✓ write:issue
✓ write:repository
✓ write:user
```

**Repository Access**: All (public, private, and limited)

### Token Verification

```bash
# Test token authentication
export GITEA_TOKEN="your-personal-access-token"

# Test 1 - User endpoint
curl -s -H "Authorization: token $GITEA_TOKEN" "https://gitea.com/api/v1/user" | jq '.login'

# Test 2 - Organizations endpoint
curl -s -H "Authorization: token $GITEA_TOKEN" "https://gitea.com/api/v1/user/orgs"

# Test 3 - Bearer token format
curl -s -H "Authorization: Bearer $GITEA_TOKEN" "https://gitea.com/api/v1/user/orgs"
```

## 🔄 Jenkins Pipeline Configuration

### Stage: Kubernetes - Raise PR

```groovy
stage('k8s - raise PR') {
    when {
        expression { env.BRANCH_NAME.startsWith('PR') }
    }
    steps {
        withCredentials([string(variable: 'GITEA_TOKEN', 
                                credentialsId: 'gitea-token')]) {
            sh '''
                BUILD_ID=${BUILD_NUMBER}
                curl -X 'POST' \
                  'https://gitea.com/api/v1/repos/YOUR_ORG/YOUR_REPO/pulls' \
                  -H 'accept: application/json' \
                  -H "Authorization: token ${GITEA_TOKEN}" \
                  -H 'Content-Type: application/json' \
                  -d '{
                    "assignee": "YOUR_USERNAME",
                    "assignees": ["YOUR_USERNAME"],
                    "base": "main",
                    "body": "Automated PR: Updated docker image in deployment manifest",
                    "head": "feature-${BUILD_ID}",
                    "title": "build: updated docker image - build #${BUILD_ID}"
                  }'
            '''
        }
    }
}
```

## ☸ Kubernetes Deployment Manifests

### Directory Structure

```
your-gitops-repo/
├── kubernetes/
│   ├── deployment.yaml         # Application deployment
│   ├── service.yaml            # Application service
│   ├── mongodb-deployment.yaml # MongoDB deployment
│   ├── mongodb-service.yaml    # MongoDB service
│   ├── mongodb-pvc.yaml        # Persistent volume claim
│   └── mongo-db-creds.yaml     # MongoDB credentials secret
```

### MongoDB Deployment

```yaml
# mongodb-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: your-namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:6.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongo-db-creds
              key: username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongo-db-creds
              key: password
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
      volumes:
      - name: mongodb-data
        persistentVolumeClaim:
          claimName: mongodb-pvc
```

### MongoDB Service

```yaml
# mongodb-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  namespace: your-namespace
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
  type: ClusterIP
```

### MongoDB Persistent Volume Claim

```yaml
# mongodb-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
  namespace: your-namespace
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### Application Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-app-name
  namespace: your-namespace
spec:
  replicas: 2
  selector:
    matchLabels:
      app: your-app-name
  template:
    metadata:
      labels:
        app: your-app-name
    spec:
      containers:
      - name: your-app-name
        image: your-dockerhub-username/your-app-image:latest
        ports:
        - containerPort: 3000
        env:
        - name: MONGO_URI
          value: mongodb://$(MONGO_USER):$(MONGO_PASS)@mongodb:27017/your-database?authSource=admin
        - name: MONGO_USER
          valueFrom:
            secretKeyRef:
              name: mongo-db-creds
              key: username
        - name: MONGO_PASS
          valueFrom:
            secretKeyRef:
              name: mongo-db-creds
              key: password
```

### MongoDB Credentials Secret

```yaml
# mongo-db-creds.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongo-db-creds
  namespace: your-namespace
type: Opaque
data:
  username: <base64-encoded-username>
  password: <base64-encoded-password>
```

**Note**: Generate base64 encoded values:
```bash
echo -n "your-username" | base64
echo -n "your-password" | base64
```

### Application Service

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: your-app-name
  namespace: your-namespace
spec:
  selector:
    app: your-app-name
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30000
  type: NodePort
```

## 🗄 MongoDB & Application Data Flow

### Auto-Initialization Logic in app.js

```javascript
// app.js - Auto-seeding functionality
const initializeSampleData = async () => {
    try {
        const count = await planetModel.countDocuments();
        
        // Only seed if database is empty
        if (count === 0) {
            console.log('🌱 Seeding database with sample data...');
            
            const sampleData = [
                // Your sample data here
            ];
            
            await yourModel.insertMany(sampleData);
            console.log('✅ Database seeded successfully');
        } else {
            console.log(`📊 Database already contains ${count} records. Skipping seed.`);
        }
    } catch (error) {
        console.error('❌ Error seeding database:', error);
    }
};
```

### Why No Additional Changes Are Needed

Your application is **production-ready** for Kubernetes because:

✅ **Auto-seeds on first run** - When MongoDB is empty, it inserts initial data  
✅ **Idempotent operation** - Checks if data exists before inserting  
✅ **Self-healing** - If MongoDB loses data, app will re-seed it  
✅ **Zero configuration** - No extra manifests or init containers required  
✅ **Persistent data** - With PVC, data survives pod restarts  

## 🚦 Kubernetes Deployment Status

```bash
$ kubectl get all -n your-namespace

NAME                                READY   STATUS    RESTARTS   AGE
pod/mongodb-xxxxxxxxxx-xxxxx        1/1     Running   0          4h
pod/your-app-xxxxxxxxxx-xxxxx       1/1     Running   0          25m
pod/your-app-xxxxxxxxxx-xxxxx       1/1     Running   0          25m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/mongodb        ClusterIP   10.xxx.xxx.xx   <none>        27017/TCP        4h
service/your-app       NodePort    10.xxx.xxx.xx   <none>        3000:30000/TCP   24h

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mongodb        1/1     1            1           4h
deployment.apps/your-app       2/2     2            2           24h
```

## ❓ Troubleshooting Guide

### Common Issues & Solutions

#### 1. Token Authentication Issues

```bash
# Verify token is valid
curl -s -H "Authorization: token $GITEA_TOKEN" "https://gitea.com/api/v1/user" | jq .
```

#### 2. MongoDB Connection Issues

```bash
# Test MongoDB connection from app pod
kubectl exec -it pod/your-app-xxx -n your-namespace -- sh
# Inside container
curl mongodb:27017

# Check MongoDB logs
kubectl logs -f deployment/mongodb -n your-namespace
```

#### 3. PR Creation Fails

```bash
# Check if branch exists
curl -H "Authorization: token $GITEA_TOKEN" \
  "https://gitea.com/api/v1/repos/YOUR_ORG/YOUR_REPO/branches"

# Verify repository permissions
curl -H "Authorization: token $GITEA_TOKEN" \
  "https://gitea.com/api/v1/repos/YOUR_ORG/YOUR_REPO"
```

#### 4. Pod Startup Issues

```bash
# Check pod logs
kubectl logs -f deployment/your-app -n your-namespace

# Describe pod for events
kubectl describe pod your-app-xxx -n your-namespace

# Check secret exists
kubectl get secret mongo-db-creds -n your-namespace
```

### Database Initialization FAQ

**Q: Do I need to create init containers for MongoDB seeding?**  
**A:** No! Your application can contain auto-seeding logic that checks if the database is empty and seeds it only on first run.

**Q: Will data persist across pod restarts?**  
**A:** Yes, when using PersistentVolumeClaims (PVC), your MongoDB data persists. The application's idempotent seed function ensures no duplicate data.

**Q: My MongoDB is a fresh container with no data. How does the app get data?**  
**A:** The application automatically seeds the database on first connection. Implement a function that checks record count and inserts sample data only when empty.

## 🔐 Branch Protection Rules

Configure branch protection for `main` branch:

1. Navigate to Repository → Settings → Branches
2. Add protection rule for `main` branch
3. Enable:
   - ✅ Require pull requests before merging
   - ✅ Require approvals (minimum 1)
   - ✅ Dismiss stale approvals
   - ✅ Require status checks

## 📊 Monitoring & Observability

```bash
# Check application logs
kubectl logs -f deployment/your-app -n your-namespace

# Monitor MongoDB initialization
kubectl logs -f deployment/mongodb -n your-namespace

# Check services
kubectl get svc -n your-namespace

# Port-forward for local testing
kubectl port-forward svc/your-app 3000:3000 -n your-namespace

# Check persistent volumes
kubectl get pvc -n your-namespace
kubectl get pv
```

## 🧪 Testing the Setup

### 1. Test MongoDB Connection

```bash
# Port forward MongoDB
kubectl port-forward svc/mongodb 27017:27017 -n your-namespace

# Connect using mongosh
mongosh "mongodb://username:password@localhost:27017/your-database?authSource=admin"
```

### 2. Test Application Health

```bash
# Port forward application
kubectl port-forward svc/your-app 3000:3000 -n your-namespace

# Access application
curl http://localhost:3000/health
curl http://localhost:3000/api/planets
```

### 3. Test PR Creation

```bash
# Create test branch
git checkout -b feature-test-pr
git push origin feature-test-pr

# Manually test PR creation
curl -X POST \
  "https://gitea.com/api/v1/repos/YOUR_ORG/YOUR_REPO/pulls" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "base": "main",
    "head": "feature-test-pr",
    "title": "Test PR",
    "body": "Testing automated PR creation"
  }'
```

## 🚀 Deployment Checklist

- [ ] Gitea token created with required permissions
- [ ] Jenkins credentials configured
- [ ] Kubernetes namespace created
- [ ] MongoDB secrets created
- [ ] MongoDB PVC created
- [ ] MongoDB deployment & service applied
- [ ] Application deployment & service applied
- [ ] Branch protection rules configured
- [ ] Jenkins pipeline configured with conditional stage
- [ ] Application auto-seeding logic verified

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request (automated via Jenkins!)

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Gitea Team for excellent API documentation
- ArgoCD for GitOps continuous delivery
- Kubernetes community
- Jenkins project

---

**💡 Pro Tip**: The auto-seeding pattern demonstrated here is a production-grade pattern that works across any container environment - not just Kubernetes. It's simple, reliable, and requires no additional orchestration!

---

## 📚 Additional Resources

- [Gitea API Documentation](https://docs.gitea.io/en-us/api-usage/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [MongoDB Kubernetes Operator](https://github.com/mongodb/mongodb-kubernetes-operator)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

---

**⚠️ Security Note**: Always store sensitive information like tokens and credentials in secure secret management systems (Jenkins credentials, Kubernetes secrets, HashiCorp Vault, etc.) Never hardcode secrets in your pipelines or manifests.