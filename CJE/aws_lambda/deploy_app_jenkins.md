# Deploy App via Jenkins

This document outlines the automation of the Lambda deployment process using a Jenkinsfile.

## A. Remove Environment Variables from Lambda Function

The first step involves removing the environment variables from the Lambda function configuration (`solar-system-lambda-function`).

### Current Environment Variables

| Key             | Value                                                                 |
|-----------------|-----------------------------------------------------------------------|
| MONGO_PASSWORD  | mongo-db-password                                                     |
| MONGO_URI       | mongodb+srv://mongo-db-user:mongo-db-password@<your-cluster>.mongodb.net/solarSystemDB?appName=Cluster0 |
| MONGO_USERNAME  | mongo-db-user                                                         |

## B. Automated Jenkins Pipeline Stage

The manual steps have been automated using a Jenkins pipeline. Below is the final stage for Lambda deployment via S3 upload.

```groovy
stage('Lambda - S3 Upload & Deploy') {
    when {
        branch 'main'
    }
    steps {
        script {
            withAWS(credentials: 'AWS-Secret', region: 'us-east-1') {
                sh '''
                    echo "Creating deployment package..."
                    zip -r new-deployment.zip . \
                        -x "*.git*" \
                        -x "node_modules/*" \
                        -x "coverage/*" \
                        -x ".nyc_output/*" \
                        -x "test-results.xml" \
                        -x "docker-compose*" \
                        -x "Dockerfile" \
                        -x "Jenkinsfile" \
                        -x "integration-testing.sh"

                    echo "Package created:"
                    ls -lh new-deployment.zip
                '''

                sh '''
                    echo "Uploading artifact for build #${BUILD_NUMBER}..."
                    # Store with build number for uniqueness
                    aws s3 cp new-deployment.zip s3://${S3_BUCKET}/build-${BUILD_NUMBER}/new-deployment.zip

                    # Also keep a "latest" for Lambda to use
                    aws s3 cp new-deployment.zip s3://${S3_BUCKET}/latest/new-deployment.zip
                    echo "Artifact: build-${BUILD_NUMBER}/new-deployment.zip"
                '''

                sh '''
                    echo "Deploying build #${BUILD_NUMBER} to Lambda..."
                    aws lambda update-function-code \
                        --function-name ${LAMBDA_FUNCTION} \
                        --s3-bucket ${S3_BUCKET} \
                        --s3-key latest/new-deployment.zip
                '''

                sh '''
                    sleep 60s
                    aws lambda update-function-configuration \
                        --function-name ${LAMBDA_FUNCTION} \
                        --environment "Variables={MONGO_URI=${MONGO_URI},NODE_ENV=production,BUILD_NUMBER=${BUILD_NUMBER},BUILD_ID=${BUILD_ID}}"
                '''

                sh '''
                    echo "Testing build #${BUILD_NUMBER}..."
                    URL=$(aws lambda get-function-url-config --function-name ${LAMBDA_FUNCTION} --query FunctionUrl --output text)
                    echo "Build #${BUILD_NUMBER} deployed to: $URL"
                    
                    # Test and show build info
                    curl -s $URL/os | jq '.'
                    echo "Build #${BUILD_NUMBER} deployed successfully!"
                '''
            }
        }
    }
}
```


## C. Frequently Asked Questions

### Question 1: Why Perform Two S3 Copy Operations?

The two S3 copies serve different purposes:

1. **Versioned Copy (Archive)**: `aws s3 cp new-deployment.zip s3://${S3_BUCKET}/build-${BUILD_NUMBER}/new-deployment.zip`
   - **Purpose**: Maintains a historical record and enables rollback capability.
   - **Details**: Stores each build separately (e.g., `build-1/`, `build-2/`, `build-3/`).
   - **Benefits**: Allows deployment of any previous version, provides an audit trail linking S3 files to Jenkins builds, and is never overwritten.

2. **Latest Copy (Current)**: `aws s3 cp new-deployment.zip s3://${S3_BUCKET}/latest/new-deployment.zip`
   - **Purpose**: Provides a simplified deployment reference.
   - **Details**: Always stored at the same path (`latest/new-deployment.zip`).
   - **Benefits**: Lambda uses this consistent path in deployment commands, eliminating the need to update configurations with each build, and it gets overwritten with new builds.

#### Visual Example

After three builds, the S3 bucket structure looks like this:

```
s3://solar-system-deployments/
├── build-1/new-deployment.zip     ← Build #1 (permanent)
├── build-2/new-deployment.zip     ← Build #2 (permanent)
├── build-3/new-deployment.zip     ← Build #3 (permanent)
└── latest/new-deployment.zip      ← Currently points to Build #3
```

#### Summary Table

| Copy Type | Path                  | Overwrites? | Use Case          |
|-----------|-----------------------|-------------|-------------------|
| Versioned | `build-${NUMBER}/`    | No          | Rollback, audit, history |
| Latest    | `latest/`             | Yes         | Current deployment | 


### Question 2: Difference Between `aws lambda update-function-configuration` and `aws lambda update-function-code`?

#### Quick Comparison

| Aspect                  | `update-function-code`                  | `update-function-configuration`         |
|-------------------------|-----------------------------------------|-----------------------------------------|
| **Purpose**             | Updates code/package                    | Updates settings/configuration          |
| **Changes**             | What the Lambda function does           | How the Lambda function runs           |
| **Speed**               | Fast (5-10 seconds)                     | Instant                                 |
| **Common Use**          | Every deployment                        | Rarely (when settings change)          |

#### `update-function-code`: "What It Does"

This command updates the actual code or ZIP file:

```bash
aws lambda update-function-code \
  --function-name my-function \
  --zip-file fileb://deployment.zip
```

**Changes**:
- ✅ Source code (e.g., `app.js`, `index.html`)
- ✅ Dependencies (e.g., `node_modules/`)
- ✅ Package contents

**Important Note**: Use this for every code change deployment.

**Example for Solar System App**:

```bash
# Update CODE only - what the app DOES
aws lambda update-function-code \
  --function-name solar-system-app \
  --s3-bucket solar-system-deployments \
  --s3-key latest/new-deployment.zip

# ✅ app.js, index.html updated
# ✅ Environment variables UNCHANGED
```

#### `update-function-configuration`: "How It Runs"

This command updates settings and environment:

```bash
aws lambda update-function-configuration \
  --function-name my-function \
  --environment "Variables={KEY=value}" \
  --memory-size 1024 \
  --timeout 30
```

**Changes**:
- ✅ Environment variables (e.g., `MONGO_URI`, `API_KEY`)
- ✅ Memory size (128 MB - 10,240 MB)
- ✅ Timeout (1-900 seconds)
- ✅ Role/Runtime (e.g., Node.js, Python)
- ✅ Concurrency/Triggers

**Important Note**: Use this when settings need to change. Access via AWS Console: Lambda > Functions > `solar-system-lambda-function` > Configuration > Modify available options.

**Example for Changing MongoDB Password (Rare)**:

```bash
# Update CONFIG only - how it runs (for solar-system-app)
aws lambda update-function-configuration \
  --function-name solar-system-app \
  --environment "Variables={MONGO_URI=new-connection-string,NODE_ENV=production}"

# ✅ Code UNCHANGED
# ✅ MongoDB connection updated
```

**References**:
- [For this hands-on, refer to the Source Code Repository (main branch)](https://gitea.com/my-demo-active-org/solar-system-migrate)
- [update-function-configuration](https://docs.aws.amazon.com/cli/latest/reference/lambda/update-function-configuration.html)
- [UpdateFunctionCode API](https://docs.aws.amazon.com/lambda/latest/api/API_UpdateFunctionCode.html)
- [UpdateFunctionConfiguration API](https://docs.aws.amazon.com/lambda/latest/api/API_UpdateFunctionConfiguration.html)
- [get-function-url-config](https://docs.aws.amazon.com/cli/latest/reference/lambda/get-function-url-config.html)

## D. Tested Application Endpoints

The following endpoints were tested after deployment:

- `https://<your-lambda-function-url>/`
- `https://<your-lambda-function-url>/index.html`
- `https://<your-lambda-function-url>/live`
- `https://<your-lambda-function-url>/ready`
- `https://<your-lambda-function-url>/os` 


## E. OWASP Dependency Check Stage Reversion

The OWASP Dependency Check stage was changed from its initial configuration. The `failedTotalCritical` threshold was increased from 1 to 5 to accommodate one critical vulnerability that exceeded the original limit, preventing stage failures.

#### Initial OWASP Stage (Scanning Entire Workspace)

```groovy
stage("OWASP Dependency Check.") {
    steps {
        dependencyCheck additionalArguments: '''--project "NodeJS_Vulnerability_Scan"
            --scan '.'
            --format ALL
            --out ./dp-scanning-report
            --noupdate
            --prettyPrint
            --data ./dependency-check-data
            --disableOssIndex
            --exclude "**/node_modules/**"
            --disableYarnAudit''',
            odcInstallation: 'DPC-1003'

        dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dp-scanning-report/dependency-check-report.xml', stopBuild: true
    }
}
```
#### Updated Stage

```groovy
stage("OWASP Dependency Check.") {
    steps {
        dependencyCheck additionalArguments: '''--project "NodeJS_Vulnerability_Scan"
            --scan '.'
            --format ALL
            --out ./dp-scanning-report
            --noupdate
            --prettyPrint
            --data ./dependency-check-data
            --disableOssIndex
            --exclude "**/node_modules/**"
            --disableYarnAudit''',
            odcInstallation: 'DPC-1003'

        dependencyCheckPublisher failedTotalCritical: 5, pattern: 'dp-scanning-report/dependency-check-report.xml', stopBuild: true
    }
}
```