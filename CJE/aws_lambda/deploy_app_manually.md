# Deploy Your App to Lambda

## A. Create ZIP Package

Go to WSL where you have cloned the repository, installed the zip package on Ubuntu, and copy the zip file locally to your Windows machine from the WSL present directory.

Run the following commands to create the deployment package:

```bash
zip -r deployment.zip . \
  -x "*.git*" \
  -x "node_modules/aws-sdk/*" \
  -x "coverage/*" \
  -x ".nyc_output/*" \
  -x "test-results.xml" \
  -x "report.html" \
  -x ".env*" \
  -x "docker-compose*" \
  -x "Dockerfile" \
  -x "Jenkinsfile" \
  -x "integration-testing.sh" \
  -x "zap_ignore_rules" \
  -x "dependency-check-data/*" \
  -x "app-test.js"
```

List the files to verify:

```bash
ls
```

Example output:

```
app-controller.js  dependency-check-data       Dockerfile              node_modules       README.md
app.js             deployment.zip              index.html              oas.json           report.html
app-test.js        docker-compose-jenkins.yml  integration-testing.sh  package.json       test-results.xml
coverage           docker-compose-local.yml    Jenkinsfile             package-lock.json  zap_ignore_rules
```

Copy the zip file to your Windows machine:

```bash
cp deployment.zip /mnt/d/
```

## B. Create Lambda Function

1. Go to the AWS Lambda Console.
2. Click "Create function" → "Author from scratch".
3. Name: `solar-system-app`
4. Runtime: Node.js 18.x
5. Permissions: Create a new role with basic Lambda permissions.

## C. Upload Code & Configure

1. Upload `deployment.zip`.
2. Handler: `app.handler` (your file exports `app.handler`; by default, it was set to `index.handler`).

### Step 1: Edit the Handler

- In the Lambda Console, click the "Edit" button next to "Runtime settings".
- Change `index.handler` to `app.handler`.
- Click "Save".

It should look like this after the change:

- Runtime: Node.js 22.x
- Handler: `app.handler` ← Updated!
- Architecture: x86_64

### Concept

- `index.handler`: Looks for an `index.js` file and a `handler` function inside it.
- `app.handler`: Looks for an `app.js` file and a `handler` function inside it.
- Since you have `module.exports.handler = serverless(app);` in your `app.js`, you need to tell Lambda to look in `app.js`, not `index.js`.

### Quick Test After Change

After updating the handler:

1. Go to the "Test" tab.
2. Create or use this test event.
3. Click "Test".
4. You should see: `{"status": "live"}`

- Memory: 1024 MB
- Timeout: 30 seconds (later set to 1 minute).

## D. Set Environment Variables

Go to Configuration → Environment variables:

- Key: `MONGO_URI`, Value: `<YOUR_MONGO_URI>` (e.g., `mongodb+srv://<username>:<password>@cluster0.ncfuc8t.mongodb.net/solarSystemDB?appName=Cluster0`)
- Key: `MONGO_USERNAME`, Value: `<YOUR_MONGO_USERNAME>`
- Key: `MONGO_PASSWORD`, Value: `<YOUR_MONGO_PASSWORD>`

## E. Verify Data in MongoDB Atlas

Once the Lambda function test succeeds, confirm that data is loaded in MongoDB Atlas:

1. Go to the MongoDB Atlas Dashboard.
2. Click your cluster → "Collections".
3. You'll see the `solarSystemDB` database with the `planets` collection.
4. Click on `planets` → "Documents" tab to see your 8 planets.

## F. Performed test cases as mentioned in the test_cases_perfomred_during_manual_deployment.md file.

## G. After fixing the failing test cases, update the Lambda function with the new ZIP file.

### G.1. Replace your app.js with the improved version

### G.2. Update the ZIP file
```bash
zip -u deployment.zip app.js
```

### G.3. Upload the updated code to Lambda
```bash
aws lambda update-function-code \
  --function-name solar-system-lambda-function \
  --zip-file fileb://deployment.zip
```

### G.4. Verify the update
The output of the above command should be similar to:

```json
{
    "FunctionName": "solar-system-lambda-function",
    "FunctionArn": "arn:aws:lambda:us-east-1:<ACCOUNT_ID>:function:solar-system-lambda-function",
    "Runtime": "nodejs22.x",
    "Role": "arn:aws:iam::<ACCOUNT_ID>:role/solar-system-lambda-role",
    "Handler": "app.handler",
    "CodeSize": 13082868,
    "Description": "Updated timeout as well as memory for lambda function.",
    "Timeout": 60,
    "MemorySize": 1024,
    "LastModified": "2025-12-14T07:16:59.000+0000",
    "CodeSha256": "/8yycXh3Pmo7lffneTuD58jMl6cZDmixKdcTSQMkbQE=",
    "Version": "$LATEST",
    "Environment": {
        "Variables": {
            "MONGO_USERNAME": "mongo-db-user",
            "MONGO_PASSWORD": "mongo-db-password",
            "MONGO_URI": "mongodb+srv://mongo-db-user:mongo-db-password@cluster0.ncfuc8t.mongodb.net/solarSystemDB?appName=Cluster0"
        }
    },
    "TracingConfig": {
        "Mode": "PassThrough"
    },
    "RevisionId": "56866e58-25a4-446a-b80c-f7b73a3e4832",
    "State": "Active",
    "LastUpdateStatus": "InProgress",
    "LastUpdateStatusReason": "The function is being created.",
    "LastUpdateStatusReasonCode": "Creating",
    "PackageType": "Zip",
    "Architectures": [
        "x86_64"
    ],
    "EphemeralStorage": {
        "Size": 512
    },
    "SnapStart": {
        "ApplyOn": "None",
        "OptimizationStatus": "Off"
    },
    "RuntimeVersionConfig": {
        "RuntimeVersionArn": "arn:aws:lambda:us-east-1::runtime:fc822b897c0f33df4df3bc8d3c18d7449cfa5d4f32cd596bcfb8080fdefbad43"
    },
    "LoggingConfig": {
        "LogFormat": "Text",
        "LogGroup": "/aws/lambda/solar-system-lambda-function"
    }
}
```

## H. Perform final endpoint tests

After updating the Lambda function, perform comprehensive tests on all application endpoints to ensure everything is working correctly.

**Event Name:** app-debug-endpoint  
**Invocation Type:** Synchronous

### H.1. Debug Endpoint

**Input:**
```json
{
  "httpMethod": "GET",
  "path": "/debug"
}
```

**Output:**
```json
{
  "statusCode": 200,
  "headers": {
    "x-powered-by": "Express",
    "access-control-allow-origin": "*",
    "content-type": "application/json; charset=utf-8",
    "content-length": "192",
    "etag": "W/\"c0-NLpaKVurLFLjcm0dY8RZUHWEIsE\""
  },
  "isBase64Encoded": false,
  "body": "{\"mongooseState\":1,\"mongooseStateText\":\"connected\",\"environment\":\"development\",\"runningOnLambda\":true,\"samplePlanetsCount\":8,\"mongoURI\":\"Configured\",\"planetCount\":8,\"database\":\"solarSystemDB\"}"
}
```

### H.2. Debug Connection Endpoint

**Input:**
```json
{
  "httpMethod": "GET",
  "path": "/debug-connection"
}
```

**Output:**
```json
{
  "statusCode": 200,
  "headers": {
    "x-powered-by": "Express",
    "access-control-allow-origin": "*",
    "content-type": "application/json; charset=utf-8",
    "content-length": "101",
    "etag": "W/\"65-dKSwN2MTR65D4h2AHIpZ4B+q91c\""
  },
  "isBase64Encoded": false,
  "body": "{\"success\":true,\"connected\":true,\"database\":\"solarSystemDB\",\"message\":\"Direct connection successful\"}"
}
```

### H.3. Get All Planets Endpoint

**Input:**
```json
{
  "httpMethod": "GET",
  "path": "/planets"
}
```

**Output:**
```json
{
  "statusCode": 200,
  "headers": {
    "x-powered-by": "Express",
    "access-control-allow-origin": "*",
    "content-type": "application/json; charset=utf-8",
    "content-length": "1399",
    "etag": "W/\"577-Kt6M4Bl303kIlB1RaGLd1D94nGI\""
  },
  "isBase64Encoded": false,
  "body": "[{\"_id\":\"693e4eac9658d56e7168767b\",\"name\":\"Mercury\",\"id\":1,\"description\":\"The smallest planet in our solar system\",\"image\":\"mercury.jpg\",\"velocity\":\"47.87 km/s\",\"distance\":\"57.9 million km\",\"__v\":0},{\"_id\":\"693e4eac9658d56e7168767c\",\"name\":\"Venus\",\"id\":2,\"description\":\"The morning star\",\"image\":\"venus.jpg\",\"velocity\":\"35.02 km/s\",\"distance\":\"108.2 million km\",\"__v\":0},{\"_id\":\"693e4eac9658d56e7168767d\",\"name\":\"Earth\",\"id\":3,\"description\":\"Our home planet\",\"image\":\"earth.jpg\",\"velocity\":\"29.78 km/s\",\"distance\":\"149.6 million km\",\"__v\":0},{\"_id\":\"693e4eac9658d56e7168767e\",\"name\":\"Mars\",\"id\":4,\"description\":\"The red planet\",\"image\":\"mars.jpg\",\"velocity\":\"24.07 km/s\",\"distance\":\"227.9 million km\",\"__v\":0},{\"_id\":\"693e4eac9658d56e7168767f\",\"name\":\"Jupiter\",\"id\":5,\"description\":\"The gas giant\",\"image\":\"jupiter.jpg\",\"velocity\":\"13.07 km/s\",\"distance\":\"778.5 million km\",\"__v\":0},{\"_id\":\"693e4eac9658d56e71687680\",\"name\":\"Saturn\",\"id\":6,\"description\":\"The ringed planet\",\"image\":\"saturn.jpg\",\"velocity\":\"9.68 km/s\",\"distance\":\"1.4 billion km\",\"__v\":0},{\"_id\":\"693e4eac9658d56e71687681\",\"name\":\"Uranus\",\"id\":7,\"description\":\"The ice giant\",\"image\":\"uranus.jpg\",\"velocity\":\"6.80 km/s\",\"distance\":\"2.9 billion km\",\"__v\":0},{\"_id\":\"693e4eac9658d56e71687682\",\"name\":\"Neptune\",\"id\":8,\"description\":\"The windiest planet\",\"image\":\"neptune.jpg\",\"velocity\":\"5.43 km/s\",\"distance\":\"4.5 billion km\",\"__v\":0}]"
}
```

### H.4. Get Specific Planet Endpoint

**Input:**
```json
{
  "httpMethod": "POST",
  "path": "/planet",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"name\": \"Earth\"}"
}
```

**Output:**
```json
{
  "statusCode": 200,
  "headers": {
    "x-powered-by": "Express",
    "access-control-allow-origin": "*",
    "content-type": "application/json; charset=utf-8",
    "content-length": "170",
    "etag": "W/\"aa-BHQHs4Kkj3d8iodAKinINm0HgfU\""
  },
  "isBase64Encoded": false,
  "body": "{\"_id\":\"693e4eac9658d56e7168767d\",\"name\":\"Earth\",\"id\":3,\"description\":\"Our home planet\",\"image\":\"earth.jpg\",\"velocity\":\"29.78 km/s\",\"distance\":\"149.6 million km\",\"__v\":0}"
}
```

### H.5. Get Planets After Query Endpoint

**Input:**
```json
{
  "httpMethod": "GET",
  "path": "/planets"
}
```

**Output:**
```json
{
  "statusCode": 200,
  "headers": {
    "x-powered-by": "Express",
    "access-control-allow-origin": "*",
    "content-type": "application/json; charset=utf-8",
    "content-length": "1071",
    "etag": "W/\"42f-atqnzSU8DpuXrg1BBkn0kUdVN3o\""
  },
  "isBase64Encoded": false,
  "body": "[{\"name\":\"Mercury\",\"id\":1,\"description\":\"The smallest planet in our solar system\",\"image\":\"mercury.jpg\",\"velocity\":\"47.87 km/s\",\"distance\":\"57.9 million km\"},{\"name\":\"Venus\",\"id\":2,\"description\":\"The morning star\",\"image\":\"venus.jpg\",\"velocity\":\"35.02 km/s\",\"distance\":\"108.2 million km\"},{\"name\":\"Earth\",\"id\":3,\"description\":\"Our home planet\",\"image\":\"earth.jpg\",\"velocity\":\"29.78 km/s\",\"distance\":\"149.6 million km\"},{\"name\":\"Mars\",\"id\":4,\"description\":\"The red planet\",\"image\":\"mars.jpg\",\"velocity\":\"24.07 km/s\",\"distance\":\"227.9 million km\"},{\"name\":\"Jupiter\",\"id\":5,\"description\":\"The gas giant\",\"image\":\"jupiter.jpg\",\"velocity\":\"13.07 km/s\",\"distance\":\"778.5 million km\"},{\"name\":\"Saturn\",\"id\":6,\"description\":\"The ringed planet\",\"image\":\"saturn.jpg\",\"velocity\":\"9.68 km/s\",\"distance\":\"1.4 billion km\"},{\"name\":\"Uranus\",\"id\":7,\"description\":\"The ice giant\",\"image\":\"uranus.jpg\",\"velocity\":\"6.80 km/s\",\"distance\":\"2.9 billion km\"},{\"name\":\"Neptune\",\"id\":8,\"description\":\"The windiest planet\",\"image\":\"neptune.jpg\",\"velocity\":\"5.43 km/s\",\"distance\":\"4.5 billion km\"}]"
}
```

### H.6. Readiness Endpoint

**Input:**
```json
{
  "httpMethod": "GET",
  "path": "/ready"
}
```

**Output:**
```json
{
  "statusCode": 200,
  "headers": {
    "x-powered-by": "Express",
    "access-control-allow-origin": "*",
    "content-type": "application/json; charset=utf-8",
    "content-length": "57",
    "etag": "W/\"39-yDL1qkEdHDkyvf7AE8IjYDm6FaE\""
  },
  "isBase64Encoded": false,
  "body": "{\"status\":\"ready\",\"timestamp\":\"2025-12-14T07:59:01.858Z\"}"
}
```

## I. Create a public URL for the Solar System app

To make your application accessible to anyone, create a public Function URL for the Lambda function.

### I.1. Option A: Lambda Function URL (Recommended)

Using AWS CLI:

```bash
aws lambda create-function-url-config \
  --function-name solar-system-lambda-function \
  --auth-type NONE \
  --cors '{"AllowOrigins": ["*"], "AllowMethods": ["*"], "AllowHeaders": ["*"]}'
```

#### Handling Permission Errors

If you encounter a "403 Forbidden" error, it means the function lacks the necessary resource-based policy for public access.

**Understanding the Issue:**

- The `AWSLambda_FullAccess` policy grants execution permissions (what the Lambda can do internally).
- Resource-based policies control who can invoke the function from outside (e.g., public internet access).

**Solution:**

**Method 1: AWS Console (Recommended)**

1. Navigate to your Lambda function in the AWS Console.
2. Go to the "Configuration" tab → "Permissions".
3. Scroll to "Resource-based policy" and click "Add permissions".
4. Select "Function URL" from the dropdown.
5. Ensure "Auth type" is set to "NONE".
6. Save to automatically grant `lambda:InvokeFunctionUrl` and `lambda:InvokeFunction` permissions to all principals (`*`).

**Method 2: AWS CLI**

Grant permission for Function URL invocation:

```bash
aws lambda add-permission \
  --function-name solar-system-lambda-function \
  --statement-id "FunctionURLAllowPublicAccess" \
  --action "lambda:InvokeFunctionUrl" \
  --principal "*" \
  --function-url-auth-type "NONE"
```

Grant permission for function invocation:

```bash
aws lambda add-permission \
  --function-name solar-system-lambda-function \
  --statement-id "FunctionURLAllowPublicAccess-InvokeFunction" \
  --action "lambda:InvokeFunction" \
  --principal "*" \
  --invoked-via-function-url
```

## J. Deploy updates from S3

For more advanced deployments, push the ZIP file to an S3 bucket and update the Lambda function from there.

### J.1. Update index.html
Modify `index.html` (e.g., line 66) to reflect the new version, such as "SOLAR <i class=\"fa fa-rocket\"></i> SYSTEM v4.0".

### J.2. Push changes to repository
Commit and push the changes to your branch (e.g., `feature/enable-cicd`), but halt any automated Jenkins builds if necessary.

### J.3. Update the ZIP file
```bash
zip -u deployment.zip index.html
```

### J.4. Upload to S3
```bash
aws s3 cp deployment.zip s3://solar-system-s3-lambda-bucket/deployments/deployment.zip
```

Example output:
```
upload: ./deployment.zip to s3://solar-system-s3-lambda-bucket/deployments/deployment.zip
```

### J.5. Update Lambda from S3
```bash
aws lambda update-function-code \
  --function-name solar-system-lambda-function \
  --s3-bucket solar-system-s3-lambda-bucket \
  --s3-key deployments/deployment.zip
```

### J.6. Verify the deployment
Access your application via the Function URL to confirm the updates (e.g., version display changes).
