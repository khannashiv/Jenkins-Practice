
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