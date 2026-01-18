# Demo: Utilize Docker Image Agent

## Description
- In this demo, we added one more stage to the previous pipeline using a Docker agent.
- The agent uses a syntax from the Declarative Directive Generator.
- We are using a hardened Node.js Docker image: `dhi.io/node:25-debian13-dev`.
- This requires a registry URL and credentials.
- As soon as the stage runs, it pulls the image and runs a Docker container under the hood, printing information about Node, npm, and the OS.
- Once the tasks in the `script {}` block complete, the pipeline automatically removes the Docker container and associated volumes, as visible in the console logs.
- On the server/agent with the label `ubuntu-docker-jdk17-node18`, we can see the Docker image `dhi.io/node:25-debian13-dev` when running `docker images`, but no containers with `docker ps` or `docker ps -a`.

## Added Stage: S3-Docker-Agent
```groovy
stage('S3-Docker-Agent') {
    agent {
        docker {
            image 'dhi.io/node:25-debian13-dev'
            label 'ubuntu-docker-jdk17-node18'
            registryUrl 'https://dhi.io'
            registryCredentialsId 'Docker-hub-login-creds'
        }
    }
    steps {
        script {
            sh '''
                cat /etc/os-release
                node -v
                npm -v
            '''
        }
    }
}
```
