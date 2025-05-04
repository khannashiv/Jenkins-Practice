
---

## Setting Up Jenkins
1. **Install Jenkins**:
   - Set up a Jenkins server on an EC2 instance (e.g., t2.large).
   - Use the following command to retrieve the initial admin password:
     ```bash
     cat /var/lib/jenkins/secrets/initialAdminPassword
     ```

2. **Log into Jenkins**:
   - Navigate to the Jenkins admin page.
   - Enter the username `Jenkins` and the password retrieved in Step 1.

3. **Create a New Pipeline**:
   - Click on "New Item" on the Jenkins home page.
   - Select "Pipeline" as the project type.

4. **Configure the Pipeline**:
   - Add a general description.
   - Set up the "Discard old builds" section.
   - Define the pipeline:
     - **SCM**: Git
     - **Repository URL**: `https://github.com/khannashiv/Jenkins-Practice`
     - **Branches to build**: Specify the branch name.
     - **Script Path**: Path to your `Jenkinsfile`.
     - Added required plugins such as **Git plugin**, **Docker pipeline**, **SonarQube Scanner** used in this project.
     - Configured credentials for **Git**, **SonarQube**, and **Docker** for authentication purposes.

    - ![](images/Jenkins-config-1.PNG "Jenkins-config-1")
    - ![](images/Jenkins-config-2.PNG "Jenkins-config-2")
    - ![](images/Jenkins-config-3.PNG "Jenkins-config-3")
    - ![](images/Jenkins-config-4.PNG "Jenkins-config-4")
    - ![](images/Jenkins-config-5.PNG "Jenkins-config-5")

---

## Configuring the Pipeline
- **Jenkinsfile**: Add the pipeline script in a file named `Jenkinsfile` at the root of the repository. Example:
   ```groovy
    pipeline {

    agent {
        docker {
        image 'khannashiv/maven-shiv-docker-agent:v1'
        args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

<!-- Meaning of agent block mentioned above .

agent: This directive tells Jenkins where and how to run the pipeline or stage. In this case, it's specifying to use a Docker container as the build environment.

    docker: This subdirective under agent specifies that the build should run inside a Docker container.

    image 'khannashiv/maven-shiv-docker-agent:v1': This tells Jenkins to use the Docker image khannashiv/maven-shiv-docker-agent with tag v1 as the container for running the pipeline.

    args '--user root -v /var/run/docker.sock:/var/run/docker.sock':

        These are additional Docker run arguments:
            --user root: Runs the container as the root user. This is often necessary if you need elevated permissions in the container.
            -v /var/run/docker.sock:/var/run/docker.sock: Mounts the host's Docker socket into the container, allowing Docker commands (e.g., building images, running containers) inside the Jenkins container to communicate with the host's Docker daemon. 
-->

<!-- Folow up questions on agent block .

Q: How Jenkins gets the Docker Image ?
Sol : 
Docker Plugin Usage: Jenkins must have the Docker Pipeline plugin installed. This plugin allows Jenkins to use Docker containers as agents for pipeline steps.

    Image Pulling:

    -- The Docker engine on the Jenkins agent node (where this is being executed) checks if the image khannashiv/maven-shiv-docker-agent:v1 is  already available locally.
    -- If the image is not available locally, it tries to pull it from Docker Hub (or another Docker registry, if configured).
    -- Docker Registry Authentication (if needed):
        -- If the image is private, Jenkins must have credentials configured (usually via Docker config file or Jenkins credentials system).
        -- If the image is public (like most images on Docker Hub), Jenkins will pull it without credentials.

    Container Execution:

    Once the image is available, Jenkins runs the container with the specified args, in this case:
        --user root: runs the container as the root user.
        -v /var/run/docker.sock:/var/run/docker.sock: mounts the host's Docker socket into the container, allowing Docker commands inside the container to control Docker on the host .
-->

    options {
        skipDefaultCheckout(true) // Disable default SCM checkout to fix permission issues
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

<!--  Meaning of options block mentioned above .

1. skipDefaultCheckout(true)
    Purpose: Prevents Jenkins from automatically checking out the source code from your Source Control Management (SCM) (like Git) at the start of the pipeline.

Why use it:

    -- We may have to handle the checkout manually in a specific stage (e.g., with custom credentials, paths, or logic).
    -- This helps to avoid permission issues, especially in Docker-based agents where file ownership or volume mounts could conflict with Jenkins’ default checkout behavior.

2. buildDiscarder(logRotator(numToKeepStr: '10'))
    Purpose: Automatically discards older build logs to save disk space.

What it does:

    -- Keeps only the last 10 builds.
    -- Older builds (build numbers > 10) are automatically deleted by Jenkins.
    -- logRotator is a utility that lets you control:
    -- Number of builds to keep (numToKeepStr)
    -- Number of days to keep builds (daysToKeepStr)
    -- Artifacts retention, etc. 

This options block overall disables the default source code checkout and configures Jenkins to keep only the last 10 builds, helping with permission handling and disk space management.
-->

    stages {

        stage('Clean Workspace & Fix Permissions') {
        steps {
            sh '''
            echo "Cleaning workspace and fixing permissions..."
            rm -rf ${WORKSPACE}/*
            mkdir -p ${WORKSPACE}
            chown -R 111:113 ${WORKSPACE}
            '''
            }
        }

        - ![](images/Pipeline-stage-1.PNG "Pipeline-stage-1")


        stage('Checkout') {
        steps {
            checkout([
            $class: 'GitSCM',
            branches: [[name: '*/main']],
            userRemoteConfigs: [[
                url: 'https://github.com/khannashiv/Jenkins-Practice.git',
                credentialsId: 'github'
            ]]
            ])
            }
        }

        stage('Build and Test') {
        steps {
            sh 'ls -ltr'
            sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn clean package'
        }
        }

        stage('Static Code Analysis') {
        environment {
            SONAR_URL = "http://52.90.245.58:9000"
        }
        steps {
            withCredentials([string(credentialsId: 'sonarqube_token', variable: 'SONAR_AUTH_TOKEN')]) {
            sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn sonar:sonar -Dsonar.login=$SONAR_AUTH_TOKEN -Dsonar.host.url=${SONAR_URL}'
            }
        }
        }

        stage('Build and Push Docker Image') {
        environment {
            DOCKER_IMAGE = "khannashiv/ultimate-cicd:${BUILD_NUMBER}"
            REGISTRY_CREDENTIALS = credentials('docker-cred')
        }
        steps {
            script {
            sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && docker build -t ${DOCKER_IMAGE} .'
            def dockerImage = docker.image("${DOCKER_IMAGE}")
            docker.withRegistry('https://index.docker.io/v1/', "docker-cred") {
                dockerImage.push()
            }
            }
        }
        }

        stage('Update Deployment File') {
        environment {
            GIT_REPO_NAME = "Jenkins-Practice"
            GIT_USER_NAME = "khannashiv"
        }
        steps {
            withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
            sh '''
                echo "Updating deployment.yml with image tag ${BUILD_NUMBER}"
                export GIT_DIR=$WORKSPACE/.git
                export GIT_WORK_TREE=$WORKSPACE
                git config user.email "khannashiv94@gmail.com"
                git config user.name "Shiv"

                sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app-manifests/deployment.yml
                git add Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app-manifests/deployment.yml

                git commit -m "Update deployment image to version ${BUILD_NUMBER}" || echo "Nothing to commit"
                git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main || echo "Nothing to push"
            '''
            }
        }
    }

}

## Meaning of Jenkins Pipeline