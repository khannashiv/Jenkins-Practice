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
     - Add required plugins such as **Git plugin**, **Docker pipeline**, **SonarQube Scanner** used in this project.
     - Configure credentials for **Git**, **SonarQube**, and **Docker** for authentication purposes.

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
   }
   ```

<!-- Explanation of the agent block above:

- `agent`: Specifies where and how Jenkins should run the pipeline or specific stages.
- `docker`: Indicates the pipeline will run inside a Docker container.
- `image`: Specifies the Docker image (`khannashiv/maven-shiv-docker-agent:v1`) to use.
- `args`: Provides additional arguments to the Docker container:
  - `--user root`: Runs the container as the root user.
  - `-v /var/run/docker.sock:/var/run/docker.sock`: Mounts the host's Docker socket into the container, allowing Docker commands inside the container to interact with the host's Docker daemon.
-->

   ```groovy
   options {
       skipDefaultCheckout(true)
       buildDiscarder(logRotator(numToKeepStr: '10'))
   }
   ```

<!-- Explanation of the options block above:

- `skipDefaultCheckout(true)`: Prevents Jenkins from automatically checking out the repository source code at the start of the pipeline. This is useful for custom checkouts and avoiding permission issues.
- `buildDiscarder(logRotator(numToKeepStr: '10'))`: Configures Jenkins to retain only the last 10 builds, automatically discarding older build logs to save disk space.
-->

   ```groovy
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
   }
   ```

<!-- Explanation of the 'Clean Workspace & Fix Permissions' stage:

This stage ensures a clean workspace by removing old files and resetting permissions to avoid conflicts in subsequent stages.
-->

   ```groovy
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
   ```

<!-- Explanation of the 'Checkout' stage:

This stage checks out the source code from the Git repository using the specified branch (`main`) and credentials.
-->

   ```groovy
       stage('Build and Test') {
           steps {
               sh 'ls -ltr'
               sh 'cd Project-1/java-maven-sonar-argocd-helm-k8s/spring-boot-app && mvn clean package'
           }
       }
   ```

<!-- Explanation of the 'Build and Test' stage:

This stage compiles the Maven project and runs all unit tests defined in the codebase.
-->

   ```groovy
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
   ```

<!-- Explanation of the 'Static Code Analysis' stage:

This stage performs static code quality checks using SonarQube. It uses the SonarQube token for authentication and uploads the analysis results to the specified SonarQube server.
-->

   ```groovy
       stage('Build and Push Docker Image') {
           environment {
               DOCKER_IMAGE = "khannashiv/ultimate-cicd:${BUILD_NUMBER}"
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
   ```

<!-- Explanation of the 'Build and Push Docker Image' stage:

This stage builds a Docker image for the project and pushes it to Docker Hub using the provided credentials.
-->

   ```groovy
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
   ```

<!-- Explanation of the 'Update Deployment File' stage:

This stage updates the deployment manifest file (`deployment.yml`) to reference the new Docker image version and pushes the changes to the Git repository.
-->

}