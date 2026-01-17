
# Deploy Node.js App to AWS Lambda Manually and Using Jenkins CI/CD Pipeline

## Using Generative AI to Generate Steps for Lambda Deployment

- Let's convert our Node.js application to be Lambda-compatible. The reason for this is that our initial Node.js application is not compatible with Lambda functions; rather, our base application was designed to deploy to EC2 using containers, and later we deployed it to K8s as pods using containers only. To deploy the same application to Lambda, we need to update the business logic.

- We will refer to the official AWS Lambda documentation for deploying Node.js applications: [AWS Lambda Node.js Documentation](https://docs.aws.amazon.com/lambda/latest/dg/lambda-nodejs.html).

- Since the documentation is a bit lengthy and overwhelming, we will use Gen AI tools such as Copilot to gain better clarity and obtain high-level steps. We have prepared a bunch of steps/questions to understand what changes we need to make to the Node.js application and how to build a Jenkins pipeline for deploying the application to Lambda.

## Questions:

1. What are the steps required to deploy a Node.js app to AWS Lambda using a Jenkins pipeline?
2. Are there any specific Lambda/serverless dependencies that we need to add to the Node.js application for deployment?
3. Is it necessary to modify the app.js file in the Node.js application to make it compatible with Lambda?
4. What AWS CLI command can be used to update the Lambda function?
5. How can I use AWS CLI commands to update a Lambda function with a file stored in an AWS S3 bucket?
6. What AWS CLI command can be used to retrieve the function URL configuration?

**References**:

- [For this hands-on, refer to the Source Code Repository (main branch)](https://gitea.com/my-demo-active-org/solar-system-migrate)