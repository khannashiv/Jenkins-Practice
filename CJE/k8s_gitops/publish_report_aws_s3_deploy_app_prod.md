# Jenkins CI/CD Demo: Publishing Reports to AWS S3 & Production Deployment

This repository demonstrates two key DevOps workflows implemented in Jenkins:
1.  **Publishing security and test reports** to an AWS S3 bucket.
2.  **Deploying to Production** with role-based approval gates.

We utilize the **Pipeline: AWS Steps** plugin to handle S3 uploads and Jenkins Pipeline `input` steps for controlled production deployments.

## 📖 Official Documentation
- [Pipeline: AWS Steps Plugin](https://plugins.jenkins.io/pipeline-aws/)
- [S3Upload Command Reference](https://plugins.jenkins.io/pipeline-aws/#plugin-content-s3upload)
- [Configuring Content Security Policy](https://www.jenkins.io/doc/book/security/configuring-content-security-policy/)

---

## 🧪 Demo 1: Upload Reports to AWS S3

In this demo, we upload various build artifacts (reports) from the Jenkins workspace to a dedicated S3 bucket.

### 🗂️ Artifacts Included
The following reports are generated during the CI process and uploaded:
- **DP Check Reports**
- **Trivy Vulnerability Scans**
- **Unit Test Results** (`test-results.xml`)
- **DAST ZAP Scans**

> **Reference:** Check Build #29 under `PR-2` in Jenkins for a full list of workspace reports.

### 🪣 AWS Setup
1.  **S3 Bucket:** Created bucket named `solar-system-app-artifacts-report-bucket`.
2.  **IAM User:** Created user `Terraform` with programmatic access.
    - **Access Key ID:** `AKIASBGQLCPWEAWMY2FJ` (stored in Jenkins as AWS Credentials).
3.  **Plugin:** Ensured **Pipeline: AWS Steps** plugin is installed on Jenkins.

### 🧩 Jenkins Stage: `Upload - AWS S3`
This stage runs on `PR*` branches. It consolidates all reports into a timestamped folder and uploads them to S3.

```groovy
stage ('Upload - AWS S3') {
    when {
        branch 'PR*'
    }
    steps {
        script {
            withAWS(credentials: 'AWS-Secret', region: 'us-east-1') {
                sh '''
                    ls -ltr
                    mkdir -p reports-$BUILD_ID
                    cp -rf coverage/ reports-$BUILD_ID/
                    cp -rf dp-scanning-report/ reports-$BUILD_ID/
                    cp -rf trivy*.* zap*.* test-results.xml reports-$BUILD_ID/
                    ls -ltr reports-$BUILD_ID/
                '''
                s3Upload(
                    file: "reports-$BUILD_ID",
                    bucket: 'solar-system-app-artifacts-report-bucket',
                    path: "jenkins-$BUILD_ID/"
                )
            }
        }
    }
}
```

**📌 Result:** Artifacts are stored at `s3://solar-system-app-artifacts-report-bucket/jenkins-<BUILD_ID>/`

**✅ Verification:** Check the build logs (e.g., PR-3 #5) for successful upload confirmation.

---

## 🌿 Branching Strategy Note
The `feature/enable-cicd` branch was created from the `release/enable-cicd` branch.
```bash
git reflog
# Output confirms: moving from release/enable-cicd to feature/enable-cicd
```
A Pull Request was raised from `feature/enable-cicd` ➡️ `main`.

---

## 🚀 Demo 2: Deploying Application to Production

This phase introduces a **manual approval gate** restricted to Jenkins Admins before deploying to production.

### 🔒 Approval Gate: Role-Based Access
We enforce that only members of the `admin` group can approve production deployments.

**Stage Configuration:**
```groovy
stage ('Deploy to Prod') {
    when {
        branch 'main'
    }
    steps {
        script {
            timeout(time: 1, unit: 'DAYS') {
                input message: 'Deploy application to Production?',
                      ok: 'Let us try deployment in production.',
                      submitter: 'admin'   // Restricts approval to admin group
            }
        }
    }
}
```

**Behavior:**
- ✅ **User `shiv` (Admin):** Can approve the deployment.
- ❌ **User `user4` (Dev):** Receives error: *"You need to be admin to submit this."*

### 📤 Extending S3 Upload to All Branches
Initially, the `Upload - AWS S3` stage only ran on `PR*` branches. To save artifacts from the `main` branch as well, the `when` condition was updated to use `anyOf`:

```groovy
when {
    anyOf {
        branch 'PR*'
        branch 'main'
        branch 'feature/*'
    }
}
```

---

## 🖥️ Environment Access

### Application & ArgoCD
The application and ArgoCD are exposed via `kubectl port-forward` on the Jenkins node.

**Initial Setup (IP: 192.168.10.21):**
- **App URL:** `http://192.168.10.21:1234`
- **ArgoCD URL:** `http://192.168.10.21:5678`

**Updated Setup (IP: 192.168.0.107):**
- **App URL:** `http://192.168.0.107:1234`
- **ArgoCD URL:** `http://192.168.0.107:5678`

**ArgoCD Credentials:**
- **Username:** `admin`
- **Password:** `XXXXX-XXXX`

### Port-Forward Commands
```bash
# Forward Solar System Application
kubectl port-forward -n solar-system svc/solar-system --address 0.0.0.0 1234:3000

# Forward ArgoCD Server
kubectl port-forward -n argocd pod/argocd-server-9dc66fd74-8sxfz --address 0.0.0.0 5678:8080
```

---

## 🔬 DAST Configuration
For Dynamic Application Security Testing (DAST), ensure the target OpenAPI specification is updated:
```bash
-t http://192.168.0.107:1234/api-docs
```

---

## 📊 Build References
| Build | Branch | Description | URL |
|-------|--------|-------------|-----|
| #29 | `PR-2` | Workspace reference for report structure | *Jenkins Blue Ocean* |
| #5 | `PR-3` | Successful S3 Upload demo | [View Pipeline](http://localhost:8080/blue/organizations/jenkins/Organization-folder-demo%2Fsolar-system-migrate/detail/PR-3/5/pipeline) |
| #5 | `main` | Production deployment with Admin approval | [View Pipeline](http://localhost:8080/blue/organizations/jenkins/Organization-folder-demo%2Fsolar-system-migrate/detail/main/5/pipeline) |

---

## 🔧 Troubleshooting & Notes

### Jenkins Content Security Policy
If HTML reports are not rendering, you may need to adjust the Jenkins CSP:
```bash
// Script Console
System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "sandbox allow-scripts; default-src 'self';")
```

### S3 Upload Failure
- Verify IAM User permissions (AmazonS3FullAccess policy recommended).
- Ensure the bucket name is globally unique.
- Check the credential ID (`AWS-Secret`) matches the one stored in Jenkins.

### Branch Source Confusion
Use `git reflog` to trace branch origins:
```bash
ubuntu@LAPTOP-49SH4K4V:~/solar-system-gitea$ git reflog
e2675dd HEAD@{2}: checkout: moving from release/enable-cicd to feature/enable-cicd
```

---

## 🏁 Summary
This demo successfully implements:
1.  **Automated Artifact Storage:** Centralized report management in AWS S3.
2.  **Secure Deployments:** Mandatory admin approval for production changes.
3.  **Cross-Branch Compatibility:** Flexible pipeline stages using conditional logic.

**Next Steps:** Integrate AWS Lambda invocation post-approval to dynamically update configuration functions.